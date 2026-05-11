import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    // Try GET
    final getUrl = Uri.parse('https://luxvam.digital/api/service-list?subcategory_id=79');
    final getRes = await http.get(getUrl, headers: {});
    print('GET Status: ' + getRes.statusCode.toString());
    print('GET Body: ' + getRes.body);

    // Try POST
    final postUrl = Uri.parse('https://luxvam.digital/api/service-list');
    final postRes = await http.post(postUrl, headers: {'Content-Type': 'application/json', }, body: json.encode({'subcategory_id': 79}));
    print('POST Status: ' + postRes.statusCode.toString());
    print('POST Body: ' + postRes.body);
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
