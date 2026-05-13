import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

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

  bool get isLoading => _isLoading;
  List<String> get sliderImages => _sliderImages;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get offers => _offers;
  List<Map<String, dynamic>> get currentSubCategories => 
      (_selectedCategoryId != null) ? (_subCategoriesMap[_selectedCategoryId] ?? []) : [];
  int? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;

  void setLocation(double? lat, double? lng) {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  final String baseUrl = ApiConfig.baseUrl;
  final String dashboardUrl = "${ApiConfig.apiBaseUrl}/dashboard-detail";
  final String categoryUrl = "${ApiConfig.apiBaseUrl}/category-list";
  final String subCategoryUrl = "${ApiConfig.apiBaseUrl}/subcategory-list";
  final String offerUrl = "${ApiConfig.apiBaseUrl}/offer-list";

  Future<void> fetchInitialData({double? latitude, double? longitude}) async {
    if (latitude != null) _latitude = latitude;
    if (longitude != null) _longitude = longitude;

    if (_categories.isEmpty) {
      // Fetch dashboard, categories, and offers in parallel for speed
      await Future.wait([
        fetchDashboardData(),
        fetchCategories(),
        fetchOffers(),
      ]);
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

    // if (_latitude != null && _longitude != null) {
    //   url += "?latitude=$_latitude&longitude=$_longitude";
    // }

    debugPrint("Fetch Categories URL: $url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      debugPrint("Categories Response: ${response.body}");

      final List<dynamic> catData = data['data'];

      _categories = catData.map((item) {
        String imageUrl = item['category_image'] ?? "";

        if (imageUrl.contains("127.0.0.1:8000")) {
          imageUrl =
              imageUrl.replaceAll("http://127.0.0.1:8000", baseUrl);
        }

        return {
          'id': item['id'],
          'name': item['name'],
          'image': imageUrl,
        };
      }).toList();

      debugPrint("Categories Count: ${_categories.length}");

      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories[0]['id'];

        await fetchSubCategories(_selectedCategoryId!);
      }
    } else {
      debugPrint(
        "Fetch Categories Failed: ${response.statusCode}",
      );
    }
  } catch (e) {
    debugPrint("Error fetching categories: $e");
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  Future<void> selectCategory(int categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();

    if (!_subCategoriesMap.containsKey(categoryId)) {
      await fetchSubCategories(categoryId);
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
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("📊 DashboardProvider: SubCategory Data for Category $categoryId -> ${response.body}");
        final List<dynamic> subCatData = data['data'];
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
        notifyListeners();

        // High-fidelity Optimization: Pre-cache images for the current category
        if (subCats.isNotEmpty) {
          _precacheImages(subCats);
        }
      }
    } catch (e) {
      debugPrint("Error fetching sub-categories: $e");
    }
  }

  void _precacheImages(List<Map<String, dynamic>> items) {
    for (var item in items) {
      final String? imageUrl = item['image'];
      if (imageUrl != null && imageUrl.startsWith('http')) {
        // Pre-fetching image into disk and memory cache
        CachedNetworkImageProvider(
          imageUrl, 
          headers: const {}
        ).resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, synchronousCall) {
            // Image is now cached and ready for instant display
          }),
        );
      }
    }
  }
}
