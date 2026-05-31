import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/models/adderss_model.dart';

class AddressService {
  static const String baseUrl = "${ApiConfig.apiBaseUrl}";

  /// COMMON HEADERS
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("api_token");

    debugPrint("================================");
    debugPrint("TOKEN : $token");
    debugPrint("================================");

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// =========================================
  /// SAVE ADDRESS
  /// =========================================
  static Future<AddressSaveResponseModel?> saveAddress({
    required String address,
    required double lat,
    required double long,
    required int status,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/address-save");

      final bodyData = {
        "address": address,
        "lat": lat,
        "long": long,
        "status": status,
      };

      debugPrint("========== SAVE ADDRESS API ==========");
      debugPrint("URL : $url");
      debugPrint("BODY : ${jsonEncode(bodyData)}");

      final response = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode(bodyData),
      );

      debugPrint("STATUS CODE : ${response.statusCode}");
      debugPrint("RESPONSE : ${response.body}");
      debugPrint("=====================================");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final model = AddressSaveResponseModel.fromJson(
          jsonData,
        );



        return model;
      } else {
        debugPrint("SAVE ADDRESS API FAILED");
      }
    } catch (e, stackTrace) {
      debugPrint("Save Address Error : $e");
      debugPrint("StackTrace : $stackTrace");
    }

    return null;
  }

  /// =========================================
  /// FETCH ADDRESS LIST
  /// =========================================
  static Future<AddressListModel?> fetchAddressList() async {
    try {
      final url = Uri.parse("$baseUrl/address-list");

      debugPrint("========== FETCH ADDRESS LIST API ==========");
      debugPrint("URL : $url");

      final response = await http.get(
        url,
        headers: await _headers(),
      );

      debugPrint("STATUS CODE : ${response.statusCode}");
      debugPrint("RESPONSE : ${response.body}");
      debugPrint("============================================");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final model = AddressListModel.fromJson(
          jsonData,
        );

        /// PRINT ALL RECORDS
        debugPrint("========= ADDRESS RECORDS =========");

        for (var item in model.data) {
          debugPrint("--------------------------------");
          debugPrint("ID : ${item.id}");
          debugPrint("USER ID : ${item.userId}");
          debugPrint("ADDRESS : ${item.address}");
          debugPrint("LATITUDE : ${item.latitude}");
          debugPrint("LONGITUDE : ${item.longitude}");
          debugPrint("STATUS : ${item.status}");
          debugPrint("USERNAME : ${item.userName}");
          debugPrint("PHONE : ${item.userPhone}");
        }

        debugPrint("===================================");

        return model;
      } else {
        debugPrint("FETCH ADDRESS API FAILED");
      }
    } catch (e, stackTrace) {
      debugPrint("Fetch Address Error : $e");
      debugPrint("StackTrace : $stackTrace");
    }

    return null;
  }

  /// =========================================
  /// DELETE ADDRESS
  /// =========================================
  static Future<DeleteAddressModel?> deleteAddress(
    int id,
  ) async {
    try {
      final url = Uri.parse(
        "$baseUrl/address-delete/$id",
      );

      debugPrint("========== DELETE ADDRESS API ==========");
      debugPrint("URL : $url");
      debugPrint("DELETE ID : $id");

      final response = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode({
          "id": id,
        }),
      );

      debugPrint("STATUS CODE : ${response.statusCode}");
      debugPrint("RESPONSE : ${response.body}");
      debugPrint("========================================");

      if (response.statusCode == 200) {
        final model = DeleteAddressModel.fromJson(
          jsonDecode(response.body),
        );

        debugPrint("ADDRESS DELETED SUCCESSFULLY");

        return model;
      } else {
        debugPrint("DELETE ADDRESS API FAILED");
      }
    } catch (e, stackTrace) {
      debugPrint("Delete Address Error : $e");
      debugPrint("StackTrace : $stackTrace");
    }

    return null;
  }
}