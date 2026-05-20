import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/models/service_list_model.dart';

class ServiceListController extends ChangeNotifier {
  List<ServiceData> serviceList = [];

  bool isLoading = false;
  bool isPaginationLoading = false;
  String? errorMessage;

  int offset = 0;
  int limit = 10;

  int? subcategoryId;
  double? latitude;
  double? longitude;

void setSubcategory(int id) {
  // Prevent unnecessary reload
  if (subcategoryId == id) return;

  subcategoryId = id;

  // VERY IMPORTANT
  // Clear old services immediately
  serviceList.clear();

  // Reset pagination
  offset = 0;

  notifyListeners();
}

  void setLocation(double? lat, double? lng) {
    debugPrint("📱 ServiceListController: Setting Location -> Lat: $lat, Lng: $lng");
    latitude = lat;
    longitude = lng;
  }


  Future<void> fetchServices({bool isLoadMore = false}) async {
    if (isLoading) return;

    if (subcategoryId == null) {
      errorMessage = "Subcategory ID is not set";
      notifyListeners();
      return;
    }

    if (isLoadMore) {
      isPaginationLoading = true;
    } else {
      isLoading = true;
      errorMessage = null;
      offset = 0;
      serviceList.clear();
    }

    notifyListeners();

    try {
      String url =
          "${ApiConfig.apiBaseUrl}/service-list"
          "?subcategory_id=$subcategoryId&limit=$limit&offset=$offset";

      if (latitude != null && longitude != null) {
        url += "&latitude=$latitude&longitude=$longitude";
      }

      debugPrint("🔍 SERVICE API CALL:");
      debugPrint("📍 Coordinates: Lat: $latitude, Lng: $longitude");
      debugPrint("🌐 URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Connection timeout");
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        debugPrint("API Response: ${jsonData.toString()}");
        
        if (jsonData['status'] == false) {
          errorMessage = jsonData['message'] ?? "Failed to fetch services";
          notifyListeners();
          return;
        }

        ServiceListModel model = ServiceListModel.fromJson(jsonData);

        if (model.data != null && model.data!.isNotEmpty) {
         // REMOVE DUPLICATES
  final uniqueMap = <int, ServiceData>{};

  for (var item in model.data!) {
    if (item.id != null) {
      uniqueMap[item.id!] = item;
    }
  }

  final uniqueServices = uniqueMap.values.toList();

  if (isLoadMore) {
    serviceList.addAll(uniqueServices);
  } else {
    serviceList = uniqueServices;
  }

  offset += limit;
  errorMessage = null;
        } else {
          if (!isLoadMore) {
            serviceList = [];
            errorMessage = "No services found";
          }
        }
      } else {
        errorMessage = "Error ${response.statusCode}: Failed to load services";
        debugPrint("API ERROR: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
      }
    } catch (e) {
      errorMessage = "Error: $e";
      debugPrint("ERROR: $e");
    } finally {
      isLoading = false;
      isPaginationLoading = false;
      notifyListeners();
    }
  }


  Future<void> refreshServices() async {
    offset = 0;
    await fetchServices();
  }

  Future<void> loadMoreServices() async {
    if (!isPaginationLoading && serviceList.isNotEmpty) {
      await fetchServices(isLoadMore: true);
    }
  }
}
