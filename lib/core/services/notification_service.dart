import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';

class NotificationService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  Future<Map<String, dynamic>> fetchNotificationList({required String customerId, String? token}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/notification-list"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
        body: json.encode({
          'customer_id': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print("Error fetching notification list: $e");
      return {};
    }
  }

  Future<bool> markAsRead({required String notificationId, String? token}) async {
    // Assuming there's an API for this, or it's handled differently
    // For now we just focus on fetching
    return true;
  }
}
