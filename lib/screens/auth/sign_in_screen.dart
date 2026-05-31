import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/services/auth_service.dart';
import 'package:zeerah/core/services/login_image_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController phoneController = TextEditingController();
  final PageController _pageController = PageController();

  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorText;

  int currentIndex = 0;
  Timer? _timer;

  final LoginImageService _loginImageService = LoginImageService();

  List<String> bannerImages = [];

  Future<void> _fetchLoginImages() async {
    final response = await _loginImageService.fetchLoginImage();

    if (response != null &&
        response.status &&
        response.loginImages.isNotEmpty) {
      setState(() {
        bannerImages = response.loginImages;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchLoginImages();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && bannerImages.isNotEmpty) {
        currentIndex++;

        if (currentIndex >= bannerImages.length) {
          currentIndex = 0;
        }

        _pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneSignIn() async {
    String? error = Validations.validatePhone(phoneController.text);

    if (error != null) {
      setState(() => errorText = error);
      return;
    }

    setState(() => isLoading = true);

    final formattedPhone = "+91${phoneController.text.trim()}";

    await _authService.verifyPhoneNumber(
      phoneNumber: formattedPhone,
   onCodeSent: (verificationId) {
  setState(() => isLoading = false);

  Navigator.pushNamed(
    context,
    AppRoutes.otpVerifly,
    arguments: {
      'verificationId': verificationId,
      'phoneNumber': formattedPhone,
    },
  );


},
      onVerificationFailed: (e) {
        setState(() {
          isLoading = false;
          errorText = e.message ?? "Verification failed";
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                /// ================= HERO SECTION (60% of screen height) =================
                SizedBox(
                  height: h * 0.6, // Fixed height - 60% of screen height
                  child: Stack(
                    children: [
                      /// CAROUSEL
                      PageView.builder(
                        controller: _pageController,
                        itemCount: bannerImages.isEmpty
                            ? 1
                            : bannerImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          if (bannerImages.isEmpty) {
                            return Image.asset(
                              'lib/assets/images/sign_in.jpeg',
                              fit: BoxFit.cover,
                            );
                          }

                          return Image.network(
                            bannerImages[index],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;

                              return Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          );
                        },
                      ),

                      /// INDICATOR POSITIONED AT BOTTOM OF IMAGES (OVERLAY)
                      Positioned(
                        bottom: 26,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: bannerImages.length,
                            effect: ExpandingDotsEffect(
                              dotHeight: 5,
                              dotWidth: 5,
                              expansionFactor: 3,
                              spacing: 5,
                              activeDotColor: Colors.white,
                              dotColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Transform.translate(
                  offset: Offset(0, -h * 0.025),
                  child: SizedBox(
                    height: h * 0.40, // Fixed height - 40% of screen height
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.06,
                        vertical: h * 0.03,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(34),
                          topRight: Radius.circular(34),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Log in or sign up",
                            style: TextStyle(
                              fontSize: w * 0.055, // Decreased from 0.07
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1C1C),
                            ),
                          ),

                          SizedBox(height: h * 0.02),

                          /// PHONE FIELD
                          Container(
                            height: h * 0.075,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                /// COUNTRY
                                Container(
                                  width: w * 0.22,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.03,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "🇮🇳",
                                        style: TextStyle(
                                          fontSize:
                                              w * 0.055, // Decreased from 0.07
                                        ),
                                      ),
                                      SizedBox(width: w * 0.015),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: w * 0.045, // Added fixed size
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  child: TextField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: TextStyle(
                                      fontSize:
                                          w * 0.038, // Decreased from 0.045
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "Enter Mobile Number",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize:
                                            w * 0.038, // Decreased from 0.045
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: w * 0.04,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        errorText = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (errorText != null) ...[
                            SizedBox(height: h * 0.012),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                errorText!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: w * 0.03, // Decreased from 0.035
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: h * 0.02),

                          /// CONTINUE BUTTON
                          GestureDetector(
                            onTap: _handlePhoneSignIn,
                            child: Container(
                              height: h * 0.072,
                              width: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                "Continue",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: w * 0.045, // Decreased from 0.055
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.015),

                          /// TERMS
                          Column(
                            children: [
                              Text(
                                "By continuing, you agree to our",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: w * 0.032, // Decreased from 0.038
                                ),
                              ),
                              SizedBox(height: h * 0.008),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 14,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.termsAndCondtions,
                                      );
                                    },
                                    child: _bottomText("Terms of Service"),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.privacyPolicy,
                                      );
                                    },
                                    child: _bottomText("Privacy Policy"),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.helpAndSupport,
                                    ),
                                    
                                    child: _bottomText("Help & Support")),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// LOADER - Now properly centered on screen
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE9435A)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomText(String text) {
    return Text(
      text,
      style: const TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.black87,
        fontSize: 11, // Decreased from 13
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
