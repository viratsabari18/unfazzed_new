import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';

class PaymentService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  Future<List<dynamic>> fetchPaymentGateways({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payment-gateways"),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print("Error fetching payment gateways: $e");
      return [];
    }
  }

  Future<bool> savePayment({
    required String bookingId,
    required String customerId,
    required double discount,
    required double totalAmount,
    required String paymentType,
    required String status,
    String? transactionId,
    required String datetime,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/save-payment"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
        body: json.encode({
          "booking_id": bookingId,
          "customer_id": customerId,
          "discount": discount,
          "total_amount": totalAmount,
          "payment_type": paymentType,
          "payment_status": status,
          "txn_id": transactionId ?? "TXN_${DateTime.now().millisecondsSinceEpoch}",
          "datetime": datetime,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == true || data['message']?.toString().contains('successfully') == true;
      }
      return false;
    } catch (e) {
      print("Error saving payment: $e");
      return false;
    }
  }

  Future<bool> topUpWallet({
    required String userId,
    required double amount,
    required String transactionId,
    required String transactionType,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/wallet-top-up"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
        body: json.encode({
          "amount": amount,
          "transaction_type": transactionType,
          "transaction_id": transactionId,
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == true || data['message']?.toString().contains('successfully') == true;
      }
      return false;
    } catch (e) {
      print("Error topping up wallet: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchWalletHistory({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/wallet-history"),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print("Error fetching wallet history: $e");
      return {};
    }
  }
  Future<Map<String, dynamic>> fetchPaymentList({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payment-list"),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print("Error fetching payment list: $e");
      return {};
    }
  }

  Future<bool> saveBank({
    required String providerId,
    required String bankName,
    required String accountNo,
    required String branchName,
    required String ifscNo,
    int status = 1,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/save-bank"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
        body: json.encode({
          "provider_id": providerId,
          "bank_name": bankName,
          "account_no": accountNo,
          "branch_name": branchName,
          "ifsc_no": ifscNo,
          "status": status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == true || data['message']?.toString().contains('successfully') == true;
      }
      return false;
    } catch (e) {
      print("Error saving bank: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchUserBanks({required String userId, String? token}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user-bank-detail?user_id=$userId"),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print("Error fetching user banks: $e");
      return {};
    }
  }
}
