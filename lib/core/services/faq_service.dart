import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import '../models/faq_model.dart';

class FaqService {
  static const String faqUrl =
      '${ApiConfig.baseUrl}/faq-list';

  Future<List<FaqModel>> fetchFaqs() async {
    try {
      final response = await http.get(
        Uri.parse(faqUrl),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final List data = jsonData['data'] ?? [];

        return data
            .map((e) => FaqModel.fromJson(e))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}