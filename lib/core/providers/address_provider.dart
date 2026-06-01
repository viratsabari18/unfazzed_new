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

  AddressProvider() {
    _initializeAddresses();
  }

  List<Map<String, dynamic>> get savedAddresses =>
      List.unmodifiable(_savedAddresses);

  Map<String, dynamic>? get selectedLocation => _selectedLocation;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
Future<void> _initializeAddresses() async {
  await _loadFromPrefs();

  await fetchAddressesFromBackend();
}

Future<void> fetchAddressesFromBackend() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final response = await AddressService.fetchAddressList();

    // BACKEND HAS NO SAVED ADDRESSES
    if (response != null &&
        response.status &&
        response.data.isEmpty) {
      debugPrint("NO ADDRESS FROM BACKEND");

      _savedAddresses.clear();

      _selectedLocation = null;

      await _saveAllToPrefs();
      await _saveSelectedToPrefs(null);

      notifyListeners();

      await setCurrentLocationAutomatically();

      return;
    }

    // BACKEND HAS SAVED ADDRESSES
    if (response != null &&
        response.status &&
        response.data.isNotEmpty) {
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
        if (_selectedLocation == null ||
            _selectedLocation!['label'] == 'Current Location') {
          _selectedLocation = _savedAddresses.first;
        }

        await _saveSelectedToPrefs(_selectedLocation);
      }

      debugPrint(
        "SELECTED ADDRESS => ${_selectedLocation?['address']}",
      );

      debugPrint("ADDRESS COUNT : ${_savedAddresses.length}");

      notifyListeners();
    }
  } catch (e) {
    _errorMessage = "Failed to fetch addresses";
    debugPrint("Fetch addresses error: $e");
  } finally {
    _isLoading = false;
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

  /// ADD ADDRESS - Saves to both local and backend
  Future<bool> addAddress(
    BuildContext context,
    Map<String, dynamic> address,
  ) async {
    final String newLabel = (address['label'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final alreadyExists = _savedAddresses.any(
      (item) =>
          (item['label'] ?? '').toString().trim().toLowerCase() == newLabel,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${address['label']} address already exists')),
      );
      return false;
    }

    // Save to backend first
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
        // Add backend ID to address
        final addressWithId = Map<String, dynamic>.from(address);
        addressWithId['id'] = response.data?.id;

        _savedAddresses.insert(0, addressWithId);
        await _saveAllToPrefs();
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

  /// DELETE ADDRESS - Deletes from both local and backend
  Future<bool> deleteAddress(
    BuildContext context,
    Map<String, dynamic> address,
  ) async {
    final addressId = address['id'];

    if (addressId != null && addressId is int) {
      try {
        final response = await AddressService.deleteAddress(addressId);

        if (response != null) {
          // Remove deleted address first
          _savedAddresses.removeWhere((item) => item['id'] == addressId);

          // If deleted address was selected
          if (_selectedLocation != null &&
              _selectedLocation!['id'] == addressId) {
            // CASE 1 : Other saved addresses available
            if (_savedAddresses.isNotEmpty) {
              _selectedLocation = _savedAddresses.first;

              await _saveSelectedToPrefs(_selectedLocation);
            } else {
              // CASE 2 : No saved addresses available
              // Clear old deleted location immediately
              _selectedLocation = null;

              notifyListeners();

              // Fetch current GPS location
              await setCurrentLocationAutomatically();
            }
          }

          // Save latest addresses
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
      // LOCAL DELETE

      _savedAddresses.remove(address);

      if (_selectedLocation != null &&
          _selectedLocation!['address'] == address['address']) {
        if (_savedAddresses.isNotEmpty) {
          if (_selectedLocation == null ||
              _selectedLocation!['label'] == 'Current Location') {
            _selectedLocation = _savedAddresses.first;

            await _saveSelectedToPrefs(_selectedLocation);
          }

          await _saveSelectedToPrefs(_selectedLocation);
        } else {
          _selectedLocation = null;

          notifyListeners();

          await setCurrentLocationAutomatically();
        }
      }

      await _saveAllToPrefs();

      notifyListeners();

      return true;
    }
  }

  void setSelectedLocation(Map<String, dynamic> location) {
    _selectedLocation = location;
    _saveSelectedToPrefs(location);
    notifyListeners();
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
    debugPrint("_savedAddresses count => ${_savedAddresses.length}");

    debugPrint("_selectedLocation => ${_selectedLocation?['address']}");
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

  Future<void> setCurrentLocationAutomatically() async {
    debugPrint("GPS CALLED => saved count ${_savedAddresses.length}");
    debugPrint("setCurrentLocationAutomatically CALLED");
    if (_savedAddresses.isNotEmpty) {
      debugPrint("Saved address exists. Skipping GPS selection");
      return;
    }
    if (_selectedLocation != null &&
        _selectedLocation!['label'] != 'Current Location') {
      debugPrint("User already selected a saved address");
      return;
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location service disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        debugPrint("Location permission denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;
      if (_savedAddresses.isNotEmpty) {
        debugPrint("Addresses loaded while GPS running. Ignore GPS.");
        return;
      }
      String fullAddress =
          "${place.street}, ${place.locality}, ${place.administrativeArea}";
      final locationData = {
        'label': 'Current Location',
        'address': fullAddress,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'icon': Icons.location_on_outlined,
      };

      _selectedLocation = Map<String, dynamic>.from(locationData);

      await _saveSelectedToPrefs(_selectedLocation);

      // FORCE UI UPDATE
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      notifyListeners();

      debugPrint("Current location updated successfully");
      notifyListeners();
      debugPrint("Current location updated successfully");
    } catch (e) {
      debugPrint("Current location error: $e");
    }
  }
}
