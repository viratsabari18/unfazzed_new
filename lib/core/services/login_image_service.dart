/// ================= SERVICE =================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import '../models/login_image_model.dart';

class LoginImageService {
  static const String apiUrl =
      '${ApiConfig.apiBaseUrl}/login-image';

  Future<LoginImageModel?> fetchLoginImage() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return LoginImageModel.fromJson(jsonData);
      }
    } catch (e) {
      print("Login Image Error: $e");
    }

    return null;
  }
}