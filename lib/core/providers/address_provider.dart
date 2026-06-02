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
        
        // FIXED: Only clear if we have no saved addresses AND no selected location
        // This prevents clearing existing addresses when backend temporarily fails
        if (_savedAddresses.isEmpty && _selectedLocation == null) {
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
        // Store current selected ID before clearing
        final currentSelectedId = _selectedLocation?['id'];
        debugPrint("CURRENT SELECTED ID => $currentSelectedId");
        debugPrint("CURRENT SELECTED ADDRESS => ${_selectedLocation?['address']}");

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

        // Smart selection - ONLY use ID matching
        if (_savedAddresses.isNotEmpty) {
          Map<String, dynamic>? matchedAddress;

          // Try to find the currently selected address by ID only
          if (currentSelectedId != null) {
            try {
              matchedAddress = _savedAddresses.firstWhere(
                (e) => e['id'] == currentSelectedId,
              );
              debugPrint("Found matching address by ID: ${matchedAddress['label']} (ID: ${matchedAddress['id']})");
            } catch (_) {
              debugPrint("No matching address found by ID: $currentSelectedId");
            }
          }

          // If no match by ID, select first address (e.g., when previous was deleted)
          _selectedLocation = matchedAddress ?? _savedAddresses.first;
          
          await _saveSelectedToPrefs(_selectedLocation);

          debugPrint("SELECTED ADDRESS AFTER REFRESH => ${_selectedLocation?['address']}");
          debugPrint("SELECTED ADDRESS LABEL => ${_selectedLocation?['label']}");
          debugPrint("SELECTED ADDRESS ID => ${_selectedLocation?['id']}");
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
      // Handle GPS disabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location service disabled - Opening settings");
        
        _errorMessage = "Please enable location services";
        notifyListeners();
        
        await Geolocator.openLocationSettings();
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint("Location service still disabled");
          _errorMessage = "Location services are required. Please enable them in settings.";
          notifyListeners();
          return false;
        }
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint("CURRENT PERMISSION => $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint("AFTER REQUEST PERMISSION => $permission");
      }

      if (permission == LocationPermission.denied) {
        debugPrint("User denied permission - showing error");
        _errorMessage = "Location permission denied. Please enable it in settings.";
        notifyListeners();
        return false;
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Permission permanently denied - opening settings");
        _errorMessage = "Location permission is permanently denied. Please enable it in settings.";
        notifyListeners();
        
        await Geolocator.openAppSettings();
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
      _errorMessage = "Error accessing location: $e";
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchAndSetCurrentLocation() async {
    debugPrint("START GPS FETCH");
    _isFetchingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint("GETTING GPS POSITION");
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      debugPrint("GPS => ${position.latitude}, ${position.longitude}");

      debugPrint("REVERSE GEOCODING");
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;
      
      // Build address without null values
      List<String> addressParts = [];
      
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }
      if (place.postalCode != null && place.postalCode!.isNotEmpty) {
        addressParts.add(place.postalCode!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }
      
      String fullAddress = addressParts.isNotEmpty 
          ? addressParts.join(", ") 
          : "Current Location";
      
      debugPrint("FULL ADDRESS => $fullAddress");
      
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
      _errorMessage = "Failed to get current location: $e";
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
              // Select first remaining address when deleted address was selected
              _selectedLocation = _savedAddresses.first;
              await _saveSelectedToPrefs(_selectedLocation);
              notifyListeners();
            } else {
              debugPrint("DELETE LAST ADDRESS - clearing and fetching current location");
              _selectedLocation = null;
              _isFetchingLocation = true;
              notifyListeners();
              
              await _handleNoAddressFlow();
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
          // Select first remaining address when deleted address was selected
          _selectedLocation = _savedAddresses.first;
          await _saveSelectedToPrefs(_selectedLocation);
          notifyListeners();
        } else {
          debugPrint("DELETE LAST ADDRESS (local) - clearing and fetching current location");
          _selectedLocation = null;
          _isFetchingLocation = true;
          notifyListeners();
          
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

  // FIXED: Returns bool so callers know if location fetching succeeded
  Future<bool> requestPermissionAndGetLocation() async {
    return await _requestLocationAndSetAddress();
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
      // REMOVED: notifyListeners() - unnecessary rebuild during initialization
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