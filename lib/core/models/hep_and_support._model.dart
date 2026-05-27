// lib/features/profile/model/help_and_support_model.dart

class HelpAndSupportModel {
  final bool status;
  final String data;

  HelpAndSupportModel({
    required this.status,
    required this.data,
  });

  factory HelpAndSupportModel.fromJson(Map<String, dynamic> json) {
    return HelpAndSupportModel(
      status: json['status'] ?? false,
      data: json['data'] ?? '',
    );
  }
}