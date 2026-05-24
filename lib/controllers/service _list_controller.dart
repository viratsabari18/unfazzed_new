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

  int _requestId = 0;

void setSubcategory(int id) {
  // ALWAYS reset everything
  subcategoryId = id;

  // cancel old requests
  _requestId++;

  // reset state
  offset = 0;
  serviceList.clear();

  errorMessage = null;

  isLoading = false;
  isPaginationLoading = false;

  notifyListeners();
}
void setLocation(double? lat, double? lng) {
  latitude = lat;
  longitude = lng;

  debugPrint(
    "📍 UPDATED LOCATION => LAT: $latitude LNG: $longitude",
  );
}

  Future<void> fetchServices({bool isLoadMore = false}) async {

    final int currentRequestId = ++_requestId;
if (isLoading && !isLoadMore) return;

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

      if (currentRequestId != _requestId) {
  debugPrint("❌ OLD API RESPONSE IGNORED");
  return;
}

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (currentRequestId != _requestId) {
  return;
}
        
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
     
          }
        }
      } else {
        errorMessage = "Error ${response.statusCode}: Failed to load services";
        debugPrint("API ERROR: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
      }
    } catch (e) {
      errorMessage = "Error: $e";
      if (currentRequestId != _requestId) {
  return;
}
      debugPrint("ERROR: $e");
    }finally {
  if (currentRequestId == _requestId) {
    isLoading = false;
    isPaginationLoading = false;
    notifyListeners();
  }
}
  }


  Future<void> refreshServices() async {
    offset = 0;
    await fetchServices();
  }

void clearServices() {
  serviceList.clear();

  offset = 0;

  errorMessage = null;

  isLoading = false;
  isPaginationLoading = false;

}

  Future<void> loadMoreServices() async {
    if (!isPaginationLoading && serviceList.isNotEmpty) {
      await fetchServices(isLoadMore: true);
    }
  }
}
