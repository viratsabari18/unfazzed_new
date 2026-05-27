// lib/features/profile/service/policy_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/models/hep_and_support._model.dart';
import 'package:zeerah/core/models/policy_model.dart';


class PolicyService {
  static const String privacyUrl =
      '${ApiConfig.apiBaseUrl}/privacy-policy';

  static const String termsUrl =
      '${ApiConfig.apiBaseUrl}/terms-conditions';

    static const String helpUrl =
      '${ApiConfig.apiBaseUrl}/help-support';

  Future<PolicyModel?> getPrivacyPolicy() async {
    try {
      final response = await http.get(Uri.parse(privacyUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return PolicyModel.fromJson(jsonData);
      }
    } catch (e) {
      print('Privacy Policy Error: $e');
    }

    return null;
  }

  Future<PolicyModel?> getTermsConditions() async {
    try {
      final response = await http.get(Uri.parse(termsUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return PolicyModel.fromJson(jsonData);
      }
    } catch (e) {
      print('Terms Conditions Error: $e');
    }

    return null;
  }

   Future<HelpAndSupportModel?> getHelpSupport() async {
    try {
      final response = await http.get(Uri.parse(helpUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return HelpAndSupportModel.fromJson(jsonData);
      }
    } catch (e) {
      print('Help Support Error: $e');
    }

    return null;
  }

  
}