import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/address_provider.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = false;
  List<String> _sliderImages = [];
  List<Map<String, dynamic>> _categories = [];
  Map<int, List<Map<String, dynamic>>> _subCategoriesMap = {};
  List<Map<String, dynamic>> _offers = [];
  int? _selectedCategoryId;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  
  bool _isRefreshing = false;
  AddressProvider? _addressProvider;

  bool get isLoading => _isLoading;
  List<String> get sliderImages => _sliderImages;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get offers => _offers;
  List<Map<String, dynamic>> get currentSubCategories => 
      (_selectedCategoryId != null) ? (_subCategoriesMap[_selectedCategoryId] ?? []) : [];
  int? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;

  void setLocation(double? lat, double? lng) {
    if (_latitude == lat && _longitude == lng) return;
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  final String baseUrl = ApiConfig.baseUrl;
  final String dashboardUrl = "${ApiConfig.apiBaseUrl}/dashboard-detail";
  final String categoryUrl = "${ApiConfig.apiBaseUrl}/category-list";
  final String subCategoryUrl = "${ApiConfig.apiBaseUrl}/subcategory-list";
  final String offerUrl = "${ApiConfig.apiBaseUrl}/offer-list";

  void listenToAddressProvider(AddressProvider addressProvider) {
    _addressProvider = addressProvider;
    addressProvider.addListener(_onAddressChanged);
  }

  void disposeListener() {
    _addressProvider?.removeListener(_onAddressChanged);
  }

  Future<void> _onAddressChanged() async {
    if (_addressProvider == null) return;
    
    final location = _addressProvider!.selectedLocation;
    if (location == null) return;
    
    if (_isRefreshing) {
      debugPrint("Already refreshing, skipping duplicate call");
      return;
    }
    
    _isRefreshing = true;
    
    double? lat = double.tryParse(location['latitude'].toString());
    double? lng = double.tryParse(location['longitude'].toString());
    
    setLocation(lat, lng);
    
    debugPrint("DashboardProvider: Location changed - Refreshing all data");
    debugPrint("NEW LAT: $_latitude, LNG: $_longitude");
    
    // Clear subcategory cache when location changes
    _subCategoriesMap.clear();
    
    // Refresh all main data
    await Future.wait([
      fetchDashboardData(),
      fetchCategories(),
      fetchOffers(),
    ]);
    
    // After refreshing categories, refresh subcategories for current selection
    if (_selectedCategoryId != null) {
      debugPrint("Refreshing subcategories for selected category: $_selectedCategoryId");
      await fetchSubCategories(_selectedCategoryId!);
    }
    
    _isRefreshing = false;
  }

  Future<void> refreshAllData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    debugPrint("Manual refresh - Clearing all cache");
    
    // Clear cache on manual refresh
    _subCategoriesMap.clear();
    
    await Future.wait([
      fetchDashboardData(),
      fetchCategories(),
      fetchOffers(),
    ]);
    
    if (_selectedCategoryId != null) {
      await fetchSubCategories(_selectedCategoryId!);
    }
    
    _isRefreshing = false;
  }

  Future<void> fetchInitialData({double? latitude, double? longitude}) async {
    if (latitude != null) _latitude = latitude;
    if (longitude != null) _longitude = longitude;

    if (_categories.isEmpty && !_isRefreshing) {
      _isRefreshing = true;
      await Future.wait([
        fetchDashboardData(),
        fetchCategories(),
        fetchOffers(),
      ]);
      
      // Fetch subcategories for selected category if exists
      if (_selectedCategoryId != null) {
        await fetchSubCategories(_selectedCategoryId!);
      }
      
      _isRefreshing = false;
    }
  }

  Future<void> fetchOffers() async {
    try {
      final response = await http.get(Uri.parse(offerUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> offerData = data['data'];
        _offers = offerData.map((item) {
          String imageUrl = item['offer_image'] ?? "";
          if (imageUrl.contains("127.0.0.1:8000")) {
            imageUrl = imageUrl.replaceAll("http://127.0.0.1:8000", baseUrl);
          }
          return {
            'id': item['id'],
            'title': item['title'],
            'subtitle': item['short_description_1'],
            'footer': item['short_description_2'] ?? 'Explore Now',
            'color': item['background_color'],
            'image': imageUrl,
          };
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching offers: $e");
    }
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(dashboardUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final List<dynamic> sliderData = data['slider'];
          _sliderImages = sliderData.map((item) {
            String imageUrl = item['slider_image'] ?? "";
            if (imageUrl.contains("127.0.0.1:8000")) {
              imageUrl = imageUrl.replaceAll("http://127.0.0.1:8000", baseUrl);
            }
            return imageUrl;
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching dashboard: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      String url = categoryUrl;

      debugPrint("Fetch Categories URL: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Categories Response: ${response.body}");

        final List<dynamic> catData = data['data'];

        _categories = catData.map((item) {
          String imageUrl = item['category_image'] ?? "";
          if (imageUrl.contains("127.0.0.1:8000")) {
            imageUrl = imageUrl.replaceAll("http://127.0.0.1:8000", baseUrl);
          }
          return {
            'id': item['id'],
            'name': item['name'],
            'image': imageUrl,
          };
        }).toList();

        debugPrint("Categories Count: ${_categories.length}");

        // FIX: If categories are empty, clear selected category
        if (_categories.isEmpty) {
          _selectedCategoryId = null;
          debugPrint("No categories found, clearing selected category");
        } else if (_selectedCategoryId == null) {
          // Only set initial category if none is selected
          _selectedCategoryId = _categories[0]['id'];
          debugPrint("Initial category selected: $_selectedCategoryId");
        } else {
          // FIX: Check if selected category still exists in new categories
          final stillExists = _categories.any((c) => c['id'] == _selectedCategoryId);
          if (!stillExists) {
            _selectedCategoryId = _categories[0]['id'];
            debugPrint("Selected category no longer exists, switching to: $_selectedCategoryId");
          }
        }
      } else {
        debugPrint("Fetch Categories Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isSubCategoryLoading = false;
  bool get isSubCategoryLoading => _isSubCategoryLoading;

  Future<void> selectCategory(int categoryId) async {
    if (_selectedCategoryId == categoryId) return;

    debugPrint("Selecting category: $categoryId");
    
    // FIX: Clear old subcategory data immediately to prevent showing stale data
    _selectedCategoryId = categoryId;
    _subCategoriesMap[categoryId] = []; // Clear immediately
    _isSubCategoryLoading = true;
    notifyListeners();

    await fetchSubCategories(categoryId);

    _isSubCategoryLoading = false;
    notifyListeners();
  }

  void searchCategory(String query) {
    if (query.isEmpty) return;
    
    final lowercaseQuery = query.toLowerCase();
    for (var category in _categories) {
      if (category['name'].toString().toLowerCase().contains(lowercaseQuery)) {
        selectCategory(category['id']);
        break;
      }
    }
  }

  Future<void> fetchSubCategories(int categoryId) async {
    try {
      String url = "$subCategoryUrl?category_id=$categoryId";

      if (_latitude != null && _longitude != null) {
        url += "&latitude=$_latitude&longitude=$_longitude";
      }

      debugPrint("========== FETCHING SUB CATEGORIES ==========");
      debugPrint("CATEGORY ID => $categoryId");
      debugPrint("LATITUDE => $_latitude");
      debugPrint("LONGITUDE => $_longitude");
      debugPrint("SUB CATEGORY URL : $url");

      final response = await http.get(Uri.parse(url));
      debugPrint("SUB CATEGORY RESPONSE : ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> subCatData = data['data'] ?? [];

        final subCats = subCatData.map((item) {
          final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
          String imageUrl = itemMap['category_image'] ?? "";

          if (imageUrl.contains("127.0.0.1:8000")) {
            imageUrl = imageUrl.replaceAll("http://127.0.0.1:8000", baseUrl);
          }

          return {
            ...itemMap,
            'id': itemMap['id'],
            'name': itemMap['name'],
            'image': imageUrl,
            'description': itemMap['description'] ?? "Professional service at your doorstep",
          };
        }).toList();

        _subCategoriesMap[categoryId] = subCats;
        
        debugPrint("SUBCATEGORY COUNT => ${subCats.length}");
        debugPrint("============================================");
        notifyListeners();
      } else {
        debugPrint("Failed to fetch subcategories: ${response.statusCode}");
        _subCategoriesMap[categoryId] = [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("ERROR FETCHING SUB CATEGORY : $e");
      debugPrint("============================================");
      _subCategoriesMap[categoryId] = [];
      notifyListeners();
    }
  }
  
  // Helper method to check if a category has subcategories
  bool hasSubcategories(int categoryId) {
    final subs = _subCategoriesMap[categoryId];
    return subs != null && subs.isNotEmpty;
  }
  
  // Helper method to clear all cached data
  void clearAllCache() {
    _subCategoriesMap.clear();
    _categories.clear();
    _sliderImages.clear();
    _offers.clear();
    _selectedCategoryId = null;
    notifyListeners();
  }
}