import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services.dart/clipboard_service.dart';
import 'package:zeerah/core/services/share_service.dart';

class ReferSection extends StatefulWidget {
  const ReferSection({super.key});

  @override
  State<ReferSection> createState() => _ReferSectionState();
}

class _ReferSectionState extends State<ReferSection> {
  Future<String?> getAppShareLink() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/app-share-link'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          return data['app_share_link'];
        }
      }
    } catch (e) {
      debugPrint("Share Link Error: $e");
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final referCode = userProvider.referralCode;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Referral Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'lib/assets/images/hands.png',
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Get a friend to unfazzed',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.naturalBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.naturalBlack,
                        ),
                        children: [
                          const TextSpan(text: 'Get '),
                          TextSpan(
                            text: '₹50',
                            style: const TextStyle(color: AppColors.primaryRed),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your friend get 25 off on their first\norder',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.naturalBlack.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Promo Code Pill
                    GestureDetector(
                      onTap: () => copydata(context, referCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              spreadRadius: 0,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              referCode,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppColors.naturalBlack,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.copy_rounded,
                              size: 22,
                              color: AppColors.primaryRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // How it works section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.naturalBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Share the link with your friend',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.naturalBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Primary Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          final shareLink = await getAppShareLink();

                          await ShareService.shareText(
                            "🏠 Need trusted home services?\n\n"
                            "Book electricians, plumbers, AC repair, cleaning, painting, and more — all in one app 🔧✨\n\n"
                            "Fast booking • Trusted professionals • Affordable pricing\n\n"
                            "Use my referral code: $referCode\n\n"
                            "Download now:\n"
                            "${shareLink ?? 'https://unfazzed.online'}",
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE30606),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Share invite link',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // // Secondary Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 54,
                    //   child: OutlinedButton(
                    //     onPressed: () {},
                    //     style: OutlinedButton.styleFrom(
                    //       side: const BorderSide(
                    //         color: Color(0xFFE30606),
                    //         width: 1.5,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //     ),
                    //     child: Text(
                    //       'Find friends to refer',
                    //       style: GoogleFonts.poppins(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w600,
                    //         color: const Color(0xFFE30606),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
