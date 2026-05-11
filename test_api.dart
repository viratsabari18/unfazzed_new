import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://luxvam.digital/api/otp-login');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'contact_number': '+919787657599'}),
    );
    print('Status: ' + response.statusCode.toString());
    print('Body: ' + response.body);
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
