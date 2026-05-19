// lib/features/profile/model/policy_model.dart

class PolicyModel {
  final bool status;
  final String data;

  PolicyModel({
    required this.status,
    required this.data,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      status: json['status'] ?? false,
      data: json['data'] ?? '',
    );
  }
}