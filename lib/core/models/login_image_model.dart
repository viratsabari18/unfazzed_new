/// ================= MODEL =================

class LoginImageModel {
  final bool status;
  final List<String> loginImages;

  LoginImageModel({
    required this.status,
    required this.loginImages,
  });

  factory LoginImageModel.fromJson(Map<String, dynamic> json) {
    return LoginImageModel(
      status: json['status'] ?? false,
      loginImages: List<String>.from(json['login_image'] ?? []),
    );
  }
}