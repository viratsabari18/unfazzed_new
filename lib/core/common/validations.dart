import 'app_exports.dart';

class Validations {
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return UserMessages.phoneNumberRequired;
    }

    String phone = value.trim();

    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return UserMessages.onlyDigitsAllowed;
    }

    if (phone.length != 10) {
      return UserMessages.invalidPhone;
    }

    return null;
  }
}
