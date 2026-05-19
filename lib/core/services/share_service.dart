import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();

  static Future<void> shareText(String text) async {
    await Share.share(text);
  }
}