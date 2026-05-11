import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final listUrl = Uri.parse('https://luxvam.digital/api/service-list');
    final listRes = await http.post(listUrl, headers: {'Content-Type': 'application/json', }, body: json.encode({'category_id': 1}));
    final listData = json.decode(listRes.body);
    final serviceId = listData['data'][0]['id'];
    
    final urlPost = Uri.parse('https://luxvam.digital/api/service-detail');
    final response = await http.post(
      urlPost,
      headers: {'Content-Type': 'application/json', },
      body: json.encode({'service_id': serviceId}),
    );
    print('POST Status: ' + response.statusCode.toString());
    print('POST Body: ' + response.body);
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
