import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import '../models/faq_model.dart';

class FaqService {
  static const String faqUrl =
      '${ApiConfig.apiBaseUrl}/faq-list';

  Future<List<FaqModel>> fetchFaqs() async {
    try {
      print(
        '================ FAQ API START ================',
      );
      print('FAQ API Called');
      print('URL: $faqUrl');

      final response = await http.get(
        Uri.parse(faqUrl),
      );

      print(
        'FAQ Status Code: ${response.statusCode}',
      );
      print(
        'FAQ Response Body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        print('FAQ Parsed JSON: $jsonData');

        final List data =
            jsonData['data'] ?? [];

        print(
          'FAQ Data Count: ${data.length}',
        );

        final faqs = data
            .map(
              (e) => FaqModel.fromJson(e),
            )
            .toList();

        print(
          'FAQ Model Count: ${faqs.length}',
        );
        print(
          '================ FAQ API SUCCESS ================',
        );

        return faqs;
      }

      print(
        'FAQ API Failed. Status Code: ${response.statusCode}',
      );
      print(
        '================ FAQ API FAILED ================',
      );

      return [];
    } catch (e, stackTrace) {
      print(
        '================ FAQ API EXCEPTION ================',
      );
      print('Error: $e');
      print('StackTrace: $stackTrace');

      return [];
    }
  }
}