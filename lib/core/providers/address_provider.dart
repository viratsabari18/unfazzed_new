import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressProvider with ChangeNotifier {
  AddressProvider() {
    _loadFromPrefs();
  }

  final List<Map<String, dynamic>> _savedAddresses = [];

  Map<String, dynamic>? _selectedLocation;

  List<Map<String, dynamic>> get savedAddresses =>
      List.unmodifiable(_savedAddresses);

  Map<String, dynamic>? get selectedLocation => _selectedLocation;

  void clearAddressData() async {
    _selectedLocation = null;
    _savedAddresses.clear();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('selected_location');
    await prefs.remove('saved_addresses');

    notifyListeners();
  }

  /// ADD ADDRESS
  /// Returns true if added
  /// Returns false if label already exists
  Future<bool> addAddress(
    BuildContext context,
    Map<String, dynamic> address,
  ) async {
    final String newLabel =
        (address['label'] ?? '').toString().trim().toLowerCase();

    final alreadyExists = _savedAddresses.any(
      (item) =>
          (item['label'] ?? '')
              .toString()
              .trim()
              .toLowerCase() ==
          newLabel,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${address['label']} address already exists',
          ),
        ),
      );

      return false;
    }

    _savedAddresses.insert(0, address);

    await _saveAllToPrefs();

    notifyListeners();

    return true;
  }

  /// DELETE ADDRESS
  Future<void> deleteAddress(Map<String, dynamic> address) async {
    _savedAddresses.remove(address);

    await _saveAllToPrefs();

    notifyListeners();
  }

  void setSelectedLocation(Map<String, dynamic> location) {
    _selectedLocation = location;

    _saveToPrefs(location);

    notifyListeners();
  }

  Future<void> _saveToPrefs(Map<String, dynamic> location) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final mapToSave = Map<String, dynamic>.from(location);

      mapToSave.remove('icon');

      await prefs.setString(
        'selected_location',
        jsonEncode(mapToSave),
      );
    } catch (e) {
      debugPrint("Error saving selected location: $e");
    }
  }

  Future<void> _saveAllToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> listToSave =
          _savedAddresses.map((addr) {
        final map = Map<String, dynamic>.from(addr);

        map.remove('icon');

        return map;
      }).toList();

      await prefs.setString(
        'saved_addresses',
        jsonEncode(listToSave),
      );
    } catch (e) {
      debugPrint("Error saving addresses list: $e");
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final selectedStr = prefs.getString('selected_location');

      if (selectedStr != null) {
        final Map<String, dynamic> loadedMap =
            jsonDecode(selectedStr);

        loadedMap['icon'] =
            _getIconForLabel(loadedMap['label']);

        _selectedLocation = loadedMap;
      }

      final savedListStr =
          prefs.getString('saved_addresses');

      if (savedListStr != null) {
        final List<dynamic> decodedList =
            jsonDecode(savedListStr);

        _savedAddresses.clear();

        for (var item in decodedList) {
          final Map<String, dynamic> addr =
              Map<String, dynamic>.from(item);

          addr['icon'] =
              _getIconForLabel(addr['label']);

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
    try {
      if (_selectedLocation != null) return;

      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint("Location service disabled");
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        debugPrint("Location permission denied");
        return;
      }

      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      String fullAddress =
          "${place.street}, ${place.locality}, ${place.administrativeArea}";

      final locationData = {
        'label': 'Current Location',
        'address': fullAddress,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'icon': Icons.location_on_outlined,
      };

      _selectedLocation = locationData;

      await _saveToPrefs(locationData);

      notifyListeners();
    } catch (e) {
      debugPrint("Current location error: $e");
    }
  }
}