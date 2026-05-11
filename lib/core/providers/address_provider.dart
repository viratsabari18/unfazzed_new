import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressProvider with ChangeNotifier {
  AddressProvider() {
    _loadFromPrefs();
  }

  final List<Map<String, dynamic>> _savedAddresses = [];

  Map<String, dynamic>? _selectedLocation;

  List<Map<String, dynamic>> get savedAddresses => List.unmodifiable(_savedAddresses);
  Map<String, dynamic>? get selectedLocation => _selectedLocation;

  void clearAddressData() async {
    _selectedLocation = null;
    _savedAddresses.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_location');
    await prefs.remove('saved_addresses');
    notifyListeners();
  }

  void addAddress(Map<String, dynamic> address) {
    _savedAddresses.insert(0, address);
    _saveAllToPrefs();
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
      
      await prefs.setString('selected_location', jsonEncode(mapToSave));
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
      
      // Load selected location
      final selectedStr = prefs.getString('selected_location');
      if (selectedStr != null) {
        final Map<String, dynamic> loadedMap = jsonDecode(selectedStr);
        loadedMap['icon'] = _getIconForLabel(loadedMap['label']);
        _selectedLocation = loadedMap;
      }

      // Load saved addresses list
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
      case 'College':
        return Icons.school_outlined;
      case 'Hotel':
        return Icons.apartment_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}
