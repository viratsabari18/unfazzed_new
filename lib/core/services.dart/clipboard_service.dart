import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeerah/core/common/app_exports.dart';

void copydata(BuildContext context, String data) {
  Clipboard.setData(ClipboardData(text: data));

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD600), size: 20),
          const SizedBox(width: 12),
          Text(
            "Code copied to clipboard",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF131B1B),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.only(
        bottom: AppSizes.h(context, 40),
        left: 24,
        right: 24,
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
