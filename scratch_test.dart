import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse("https://luxvam.digital/api/otp-login");
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      
    },
    body: json.encode({'contact_number': '+919876543210'}),
  );
  print(response.statusCode);
  print(response.body);
}
