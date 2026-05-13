import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeerah/core/common/app_exports.dart';

class ComingSoonSection extends StatelessWidget {
  const ComingSoonSection({super.key});

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline, color: Color(0xFF1B9E56), size: 64),
        content: Text(
          "We will notify you once we are live in your area!",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Done", style: GoogleFonts.poppins(color: const Color(0xFF1B9E56), fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: AppSizes.w(context, 32),
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              children: [
                const TextSpan(
                  text: "WE ARE\n",
                  style: TextStyle(color: Color(0xFFC5C5C5)),
                ),
                const TextSpan(
                  text: "COMING ",
                  style: TextStyle(color: Color(0xFFC5C5C5)),
                ),
                TextSpan(
                  text: "SOON",
                  style: TextStyle(color: AppColors.primaryRed),
                ),
              ],
            ),
          ),
          SizedBox(height: Insets.md),
          Text(
            "We're currently live in select areas and expanding quickly. Get notified when we are near you!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.w(context, 16),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF747981),
            ),
          ),
          SizedBox(height: Insets.lg),
          GestureDetector(
            onTap: () => _showNotificationDialog(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.sm),
              decoration: BoxDecoration(
                color: AppColors.blinkingRed,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "Notify me!",
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.w(context, 20),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
