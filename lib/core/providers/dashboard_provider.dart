import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:http/http.dart' as http;
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

  // Cache flags
  bool _dashboardLoaded = false;
  bool _categoriesLoaded = false;
  bool _offersLoaded = false;

  bool get isLoading => _isLoading;
  List<String> get sliderImages => _sliderImages;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get offers => _offers;
  List<Map<String, dynamic>> get currentSubCategories => 
      (_selectedCategoryId != null) ? (_subCategoriesMap[_selectedCategoryId] ?? []) : [];
  int? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;

  bool _isInitialLoading = true;
  bool get isInitialLoading => _isInitialLoading;

  bool _hasLoadedInitialSubCategory = false;
  bool get hasLoadedInitialSubCategory => _hasLoadedInitialSubCategory;

  String fixImageUrl(String imageUrl) {
    if (imageUrl.contains("127.0.0.1:8000")) {
      return imageUrl.replaceAll(
        "http://127.0.0.1:8000",
        baseUrl,
      );
    }
    return imageUrl;
  }

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
      debugPrint("Refresh already running");
      return;
    }
    
    double? lat = double.tryParse(location['latitude'].toString());
    double? lng = double.tryParse(location['longitude'].toString());
    
    if (lat == null || lng == null) {
      _isRefreshing = false;
      return;
    }
    
    if (_latitude == lat && _longitude == lng) return;
    
    _isRefreshing = true;
    
    try {
      setLocation(lat, lng);
      
      debugPrint("DashboardProvider: Location changed - Refreshing all data");
      debugPrint("NEW LAT: $_latitude, LNG: $_longitude");
      
      // Clear subcategory cache when location changes
      _subCategoriesMap.clear();
      _hasLoadedInitialSubCategory = false;
      
      // Reset cache flags
      _dashboardLoaded = false;
      _categoriesLoaded = false;
      _offersLoaded = false;
      
      // Refresh all main data
      await Future.wait([
        _fetchDashboardDataInternal(),
        _fetchCategoriesInternal(),
        _fetchOffersInternal(),
      ]);
      
      // After refreshing categories, refresh subcategories for current selection
      if (_selectedCategoryId != null) {
        debugPrint("Refreshing subcategories for selected category: $_selectedCategoryId");
        
        _isSubCategoryLoading = true;
        notifyListeners();

        try {
          await fetchSubCategories(_selectedCategoryId!);
          _hasLoadedInitialSubCategory = true;
        } finally {
          _isSubCategoryLoading = false;
          notifyListeners();
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> refreshAllData() async {
    if (_isRefreshing) {
      debugPrint("Refresh already running");
      return;
    }
    _isRefreshing = true;
    
    try {
      debugPrint("Manual refresh - Clearing all cache");
      
      // Reset cache flags
      _dashboardLoaded = false;
      _categoriesLoaded = false;
      _offersLoaded = false;
      
      // Clear cache on manual refresh
      _subCategoriesMap.clear();
      _hasLoadedInitialSubCategory = false;
      
      await Future.wait([
        _fetchDashboardDataInternal(),
        _fetchCategoriesInternal(),
        _fetchOffersInternal(),
      ]);
      
      if (_selectedCategoryId != null) {
        _isSubCategoryLoading = true;
        notifyListeners();

        try {
          await fetchSubCategories(_selectedCategoryId!);
          _hasLoadedInitialSubCategory = true;
        } finally {
          _isSubCategoryLoading = false;
          notifyListeners();
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> fetchInitialData({
    double? latitude,
    double? longitude,
  }) async {
    if (latitude != null) _latitude = latitude;
    if (longitude != null) _longitude = longitude;

    _isInitialLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchDashboardDataInternal(),
        _fetchCategoriesInternal(),
        _fetchOffersInternal(),
      ]);
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }

    if (_selectedCategoryId != null) {
      _isSubCategoryLoading = true;
      notifyListeners();

      try {
        await fetchSubCategories(_selectedCategoryId!);
      } finally {
        _hasLoadedInitialSubCategory = true;
        _isSubCategoryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchOffersInternal() async {
    if (_offersLoaded) return;

    try {
      final response = await http
          .get(Uri.parse(offerUrl))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> offerData = data['data'];
        final newOffers = offerData.map((item) {
          String imageUrl = item['offer_image'] ?? "";
          return {
            'id': item['id'],
            'title': item['title'],
            'subtitle': item['short_description_1'],
            'footer': item['short_description_2'] ?? 'Explore Now',
            'color': item['background_color'],
            'image': fixImageUrl(imageUrl),
          };
        }).toList();
        
        // Only notify if data actually changed
        if (!_areOffersEqual(_offers, newOffers)) {
          _offers = newOffers;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error fetching offers: $e");
    } finally {
      _offersLoaded = true;
    }
  }

  Future<void> fetchOffers() async {
    await _fetchOffersInternal();
  }

  Future<void> _fetchDashboardDataInternal() async {
    if (_dashboardLoaded) return;

    try {
      final response = await http
          .get(Uri.parse(dashboardUrl))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final List<dynamic> sliderData = data['slider'];
          final newSliderImages = sliderData.map((item) {
            String imageUrl = item['slider_image'] ?? "";
            return fixImageUrl(imageUrl);
          }).toList();
          
          // Only notify if data actually changed
          if (!_areSliderImagesEqual(_sliderImages, newSliderImages)) {
            _sliderImages = newSliderImages;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching dashboard: $e");
    } finally {
      _dashboardLoaded = true;
    }
  }

  Future<void> fetchDashboardData({bool force = false}) async {
    if (force) _dashboardLoaded = false;
    await _fetchDashboardDataInternal();
  }

  Future<void> _fetchCategoriesInternal() async {
    if (_categoriesLoaded) return;

    try {
      String url = categoryUrl;
      debugPrint("Fetch Categories URL: $url");

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Categories Response: ${response.body}");

        final List<dynamic> catData = data['data'];

        final newCategories = catData.map((item) {
          String imageUrl = item['category_image'] ?? "";
          return {
            'id': item['id'],
            'name': item['name'],
            'image': fixImageUrl(imageUrl),
          };
        }).toList();

        debugPrint("Categories Count: ${newCategories.length}");

        int? newSelectedCategoryId = _selectedCategoryId;

        // FIX: If categories are empty, clear selected category
        if (newCategories.isEmpty) {
          newSelectedCategoryId = null;
          debugPrint("No categories found, clearing selected category");
        } else if (newSelectedCategoryId == null) {
          // Only set initial category if none is selected
          newSelectedCategoryId = newCategories[0]['id'];
          debugPrint("Initial category selected: $newSelectedCategoryId");
        } else {
          // FIX: Check if selected category still exists in new categories
          final stillExists = newCategories.any((c) => c['id'] == newSelectedCategoryId);
          if (!stillExists) {
            newSelectedCategoryId = newCategories[0]['id'];
            debugPrint("Selected category no longer exists, switching to: $newSelectedCategoryId");
          }
        }

        // Only notify if data actually changed
        if (!_areCategoriesEqual(_categories, newCategories) || 
            _selectedCategoryId != newSelectedCategoryId) {
          _categories = newCategories;
          _selectedCategoryId = newSelectedCategoryId;
          notifyListeners();
        }
      } else {
        debugPrint("Fetch Categories Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      _categoriesLoaded = true;
    }
  }

  Future<void> fetchCategories({bool force = false}) async {
    if (force) _categoriesLoaded = false;
    await _fetchCategoriesInternal();
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

    try {
      await fetchSubCategories(categoryId);
    } finally {
      _isSubCategoryLoading = false;
      notifyListeners();
    }
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

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      
      debugPrint("SUB CATEGORY RESPONSE : ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> subCatData = data['data'] ?? [];

        final subCats = subCatData.map((item) {
          final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
          String imageUrl = itemMap['category_image'] ?? "";
          return {
            ...itemMap,
            'id': itemMap['id'],
            'name': itemMap['name'],
            'image': fixImageUrl(imageUrl),
            'description': itemMap['description'] ?? "Professional service at your doorstep",
          };
        }).toList();

        // Only notify if data actually changed
        if (!_areSubCategoriesEqual(_subCategoriesMap[categoryId], subCats)) {
          _subCategoriesMap[categoryId] = subCats;
          notifyListeners();
        }
        
        debugPrint("SUBCATEGORY COUNT => ${subCats.length}");
        debugPrint("============================================");
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
    _dashboardLoaded = false;
    _categoriesLoaded = false;
    _offersLoaded = false;
    _hasLoadedInitialSubCategory = false; // Added this line
    notifyListeners();
  }

  // Equality check helpers to prevent unnecessary rebuilds
  bool _areOffersEqual(List<Map<String, dynamic>> oldOffers, List<Map<String, dynamic>> newOffers) {
    if (oldOffers.length != newOffers.length) return false;
    for (int i = 0; i < oldOffers.length; i++) {
      if (oldOffers[i]['id'] != newOffers[i]['id']) return false;
      if (oldOffers[i]['image'] != newOffers[i]['image']) return false;
    }
    return true;
  }

  bool _areSliderImagesEqual(List<String> oldImages, List<String> newImages) {
    if (oldImages.length != newImages.length) return false;
    for (int i = 0; i < oldImages.length; i++) {
      if (oldImages[i] != newImages[i]) return false;
    }
    return true;
  }

  bool _areCategoriesEqual(List<Map<String, dynamic>> oldCats, List<Map<String, dynamic>> newCats) {
    if (oldCats.length != newCats.length) return false;
    for (int i = 0; i < oldCats.length; i++) {
      if (oldCats[i]['id'] != newCats[i]['id']) return false;
      if (oldCats[i]['name'] != newCats[i]['name']) return false;
      if (oldCats[i]['image'] != newCats[i]['image']) return false;
    }
    return true;
  }

  bool _areSubCategoriesEqual(List<Map<String, dynamic>>? oldSubs, List<Map<String, dynamic>> newSubs) {
    if (oldSubs == null) return false;
    if (oldSubs.length != newSubs.length) return false;
    for (int i = 0; i < oldSubs.length; i++) {
      if (oldSubs[i]['id'] != newSubs[i]['id']) return false;
      if (oldSubs[i]['name'] != newSubs[i]['name']) return false;
    }
    return true;
  }
}