import 'dart:convert';
import 'package:zeerah/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class BookingService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  Future<Map<String, dynamic>> fetchBookingList({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/booking-list"),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print("Error fetching booking list: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchBookingDetail({required String bookingId, String? token}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/booking-detail?booking_id=$bookingId"),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print("Error fetching booking detail: $e");
      return {};
    }
  }

  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
    String? reason,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/booking-update"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
        body: json.encode({
          "id": bookingId,
          "status": status,
          if (reason != null) "reason": reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error updating booking status: $e");
      return false;
    }
  }
}
