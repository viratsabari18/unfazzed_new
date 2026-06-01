import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeerah/core/services/address_service.dart';

class AddressProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _savedAddresses = [];
  Map<String, dynamic>? _selectedLocation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isInitialized = false;
  bool _isFetchingLocation = false;

  AddressProvider() {
    _isLoading = true;
    _initializeAddresses();
  }

  List<Map<String, dynamic>> get savedAddresses =>
      List.unmodifiable(_savedAddresses);

  Map<String, dynamic>? get selectedLocation => _selectedLocation;

  bool get isLoading => _isLoading || _isFetchingLocation;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  Future<void> _initializeAddresses() async {
    await _loadFromPrefs();
    await fetchAddressesFromBackend();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
    
    debugPrint("AddressProvider initialized - isLoading: $_isLoading, isInitialized: $_isInitialized");
  }

  Future<void> fetchAddressesFromBackend() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AddressService.fetchAddressList();

      if (response == null || !response.status) {
        debugPrint("Backend fetch failed, keeping local addresses");
        _isRefreshing = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (response.data.isEmpty) {
        debugPrint("NO ADDRESS FROM BACKEND");
        
        if (_savedAddresses.isEmpty) {
          _selectedLocation = null;
          await _saveSelectedToPrefs(null);
        }

        await _saveAllToPrefs();
        notifyListeners();

        if (_savedAddresses.isEmpty && _selectedLocation == null) {
          await _handleNoAddressFlow();
        }
        return;
      }

      // BACKEND HAS SAVED ADDRESSES
      if (response.data.isNotEmpty) {
        _savedAddresses.clear();

        for (var e in response.data) {
          _savedAddresses.add({
            "id": e.id,
            "label": _getLabelFromStatus(e.status),
            "address": e.address,
            "latitude": e.latitude,
            "longitude": e.longitude,
            "icon": _getIconForLabel(_getLabelFromStatus(e.status)),
            "phone": e.userPhone ?? "",
            "receiver_name": e.userName,
            "status": e.status,
          });
        }

        await _saveAllToPrefs();

        if (_savedAddresses.isNotEmpty) {
          _selectedLocation = _savedAddresses.first;
          await _saveSelectedToPrefs(_selectedLocation);

          debugPrint("BACKEND ADDRESS SELECTED => ${_selectedLocation?['address']}");
          debugPrint("BACKEND ADDRESS ID => ${_selectedLocation?['id']}");
          debugPrint("ADDRESS COUNT : ${_savedAddresses.length}");
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Fetch addresses error: $e");
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  String _getLabelFromStatus(int status) {
    switch (status) {
      case 1:
        return "Home";
      case 2:
        return "Work";
      default:
        return "Other";
    }
  }

  Future<void> _handleNoAddressFlow() async {
    debugPrint("No address exists - checking location permission");
    await _requestLocationAndSetAddress();
  }

  Future<bool> _requestLocationAndSetAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location service disabled");
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("Location permission denied or denied forever");
        _handlePermissionDenied();
        return false;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _fetchAndSetCurrentLocation();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Location error: $e");
      return false;
    }
  }

  Future<void> _fetchAndSetCurrentLocation() async {
    debugPrint("START GPS FETCH");
    _isFetchingLocation = true;
    notifyListeners();

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;
      
      String fullAddress = "${place.street}, ${place.locality}, ${place.administrativeArea}";
      
      final locationData = {
        'label': 'Current Location',
        'address': fullAddress,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'icon': Icons.location_on_outlined,
      };

      _selectedLocation = Map<String, dynamic>.from(locationData);
      await _saveSelectedToPrefs(_selectedLocation);
      
      debugPrint("CURRENT LOCATION SET => $fullAddress");
    } catch (e) {
      debugPrint("Error fetching current location: $e");
      _handlePermissionDenied();
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  void _handlePermissionDenied() {
    debugPrint("Permission denied - clearing selected location");
    _selectedLocation = null;
    _isFetchingLocation = false;
    notifyListeners();
  }

  Future<bool> addAddress(BuildContext context, Map<String, dynamic> address) async {
    final String newLabel = (address['label'] ?? '').toString().trim().toLowerCase();

    final alreadyExists = _savedAddresses.any(
      (item) => (item['label'] ?? '').toString().trim().toLowerCase() == newLabel,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${address['label']} address already exists')),
      );
      return false;
    }

    try {
      final status = address['label'] == 'Home'
          ? 1
          : (address['label'] == 'Work' ? 2 : 0);

      final response = await AddressService.saveAddress(
        address: address['address'],
        lat: address['latitude'],
        long: address['longitude'],
        status: status,
      );

      if (response != null && response.status) {
        final addressWithId = Map<String, dynamic>.from(address);
        addressWithId['id'] = response.data?.id;

        _savedAddresses.insert(0, addressWithId);
        await _saveAllToPrefs();
        
        _selectedLocation = addressWithId;
        await _saveSelectedToPrefs(_selectedLocation);
        
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to save address'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      debugPrint("Save address error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  Future<bool> deleteAddress(BuildContext context, Map<String, dynamic> address) async {
    final addressId = address['id'];

    if (addressId != null && addressId is int) {
      try {
        final response = await AddressService.deleteAddress(addressId);

        if (response != null) {
          _savedAddresses.removeWhere((item) => item['id'] == addressId);

          if (_selectedLocation != null && _selectedLocation!['id'] == addressId) {
            if (_savedAddresses.isNotEmpty) {
              _selectedLocation = _savedAddresses.first;
              await _saveSelectedToPrefs(_selectedLocation);
              notifyListeners();
            } else {
              // FIXED: Immediately clear the deleted address and show loading state
              debugPrint("DELETE LAST ADDRESS - clearing and fetching current location");
              _selectedLocation = null;
              _isFetchingLocation = true;
              notifyListeners(); // This will show "Fetching current location..." in UI
              
              await _handleNoAddressFlow();
              // _handleNoAddressFlow will set _selectedLocation when GPS completes
            }
          }

          await _saveAllToPrefs();
          notifyListeners();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete address'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      } catch (e) {
        debugPrint("Delete address error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } else {
      _savedAddresses.remove(address);

      if (_selectedLocation != null && _selectedLocation!['address'] == address['address']) {
        if (_savedAddresses.isNotEmpty) {
          _selectedLocation = _savedAddresses.first;
          await _saveSelectedToPrefs(_selectedLocation);
          notifyListeners();
        } else {
          // FIXED: Immediately clear the deleted address and show loading state
          debugPrint("DELETE LAST ADDRESS (local) - clearing and fetching current location");
          _selectedLocation = null;
          _isFetchingLocation = true;
          notifyListeners(); // This will show "Fetching current location..." in UI
          
          await _handleNoAddressFlow();
        }
      }

      await _saveAllToPrefs();
      notifyListeners();
      return true;
    }
  }

  void setSelectedLocation(Map<String, dynamic> location) {
    if (_selectedLocation != null && 
        _selectedLocation!['address'] == location['address'] &&
        _selectedLocation!['id'] == location['id']) {
      return;
    }
    
    _selectedLocation = location;
    _saveSelectedToPrefs(location);
    notifyListeners();
  }

  bool get hasSelectedLocation => _selectedLocation != null;

  Future<void> requestPermissionAndGetLocation() async {
    await _requestLocationAndSetAddress();
  }

  void clearAddressData() async {
    _selectedLocation = null;
    _savedAddresses.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_location');
    await prefs.remove('saved_addresses');
    notifyListeners();
  }

  Future<void> _saveSelectedToPrefs(Map<String, dynamic>? location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (location != null) {
        final mapToSave = Map<String, dynamic>.from(location);
        mapToSave.remove('icon');
        await prefs.setString('selected_location', jsonEncode(mapToSave));
      } else {
        await prefs.remove('selected_location');
      }
    } catch (e) {
      debugPrint("Error saving selected location: $e");
    }
  }

  Future<void> _saveAllToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> listToSave = _savedAddresses.map((addr) {
        final map = Map<String, dynamic>.from(addr);
        map.remove('icon');
        return map;
      }).toList();
      await prefs.setString('saved_addresses', jsonEncode(listToSave));
    } catch (e) {
      debugPrint("Error saving addresses list: $e");
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final selectedStr = prefs.getString('selected_location');
      if (selectedStr != null) {
        final Map<String, dynamic> loadedMap = jsonDecode(selectedStr);
        loadedMap['icon'] = _getIconForLabel(loadedMap['label']);
        _selectedLocation = loadedMap;
      }

      final savedListStr = prefs.getString('saved_addresses');
      if (savedListStr != null) {
        final List<dynamic> decodedList = jsonDecode(savedListStr);
        _savedAddresses.clear();
        for (var item in decodedList) {
          final Map<String, dynamic> addr = Map<String, dynamic>.from(item);
          addr['icon'] = _getIconForLabel(addr['label']);
          _savedAddresses.add(addr);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading from prefs: $e");
    }
  }

  IconData _getIconForLabel(String? label) {
    switch (label) {
      case 'Home':
        return Icons.home_outlined;
      case 'Work':
        return Icons.work_outline;
      case 'Other':
        return Icons.location_on_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}