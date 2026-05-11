import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:flutter/material.dart';

class HelpDeskService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  Future<bool> saveTicket({
    required String subject,
    required String description,
    required String employeeId,
    String? token,
    File? attachment,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/helpdesk-save");
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        
      });

      request.fields['subject'] = subject;
      request.fields['description'] = description;
      request.fields['employee_id'] = employeeId;
      request.fields['mode'] = 'app';

      if (attachment != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'helpdesk_attachment', // Changed from helpdesk_attachment_[]
          attachment.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("HelpDesk Save Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // API might return status: true or just a success message
        return data['status'] == true || 
               (data['message'] != null && data['message'].toString().toLowerCase().contains('successfully'));
      }
      return false;
    } catch (e) {
      debugPrint("HelpDesk Save Error: $e");
      return false;
    }
  }

  Future<List<dynamic>> fetchTickets({required String status, String? employeeId, String? token}) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      if (status.isNotEmpty) queryParams['status'] = status;
      if (employeeId != null) queryParams['employee_id'] = employeeId;

      final uri = Uri.parse("$baseUrl/helpdesk-list").replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      debugPrint("HelpDesk List Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The API returns 'data' as a list. Sometimes 'status' might be missing.
        if (data['data'] is List) {
          return data['data'];
        }
        if (data['status'] == true && data['data'] is List) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      debugPrint("HelpDesk List Error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchTicketDetail(String id, {String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/helpdesk-detail?id=$id");
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return data['data'];
        }
        if (data['status'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("HelpDesk Detail Error: $e");
      return null;
    }
  }

  Future<bool> addMessage({
    required String ticketId,
    required String description,
    String? token,
    File? attachment,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/helpdesk-activity-save/$ticketId");
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        
      });

      request.fields['description'] = description;

      if (attachment != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'helpdesk_activity_attachment', // Changed from helpdesk_activity_attachment_[]
          attachment.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == true || 
               (data['message'] != null && data['message'].toString().toLowerCase().contains('successfully'));
      }
      return false;
    } catch (e) {
      debugPrint("HelpDesk Activity Save Error: $e");
      return false;
    }
  }

  Future<bool> closeTicket(String id, {String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/helpdesk-closed/$id");
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == true || 
               (data['message'] != null && data['message'].toString().toLowerCase().contains('successfully'));
      }
      return false;
    } catch (e) {
      debugPrint("HelpDesk Close Error: $e");
      return false;
    }
  }
}
