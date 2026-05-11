import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/widgets/custom/social_button.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool isLoading = false;
  String? errorText;

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    final userCredential = await _authService.signInWithGoogle();
    setState(() => isLoading = false);
    
    if (userCredential != null && userCredential.user != null) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(userCredential.user);
        Navigator.pushReplacementNamed(context, AppRoutes.landingPage);
      }
    }
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
    final w = AppSizes.width(context);
    final h = AppSizes.height(context);

    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Insets.sm,
                  vertical: Insets.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h * 0.025),

                    Center(
                      child: Image.asset(
                        UserMessages.signInImage,
                        height: h * 0.22,
                      ),
                    ),

                    SizedBox(height: h * 0.03),

                    Center(
                      child: Text(
                        UserMessages.welcomeBack,
                        style: TextStyles.h2.copyWith(
                          color: AppColors.naturalBlack,
                          fontSize: w * 0.06,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.015),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyles.bodySmall.copyWith(
                          color: AppColors.naturalBlack,
                          fontSize: w * 0.035,
                        ),
                        children: [
                          const TextSpan(
                            text: UserMessages.termsOfUse1,
                          ),
                          TextSpan(
                            text: UserMessages.termsOfUse2,
                            style: TextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: w * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: Insets.sm),
                          decoration: BoxDecoration(
                            color: AppColors.naturalWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: errorText != null
                                  ? Colors.red
                                  : AppColors.naturalGray,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "🇮🇳 +91",
                                style: TextStyles.bodyLarge.copyWith(
                                  fontSize: w * 0.04,
                                ),
                              ),
                              SizedBox(width: Insets.xs),
                              Expanded(
                                child: TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyles.bodyLarge.copyWith(
                                    fontSize: w * 0.04,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: UserMessages.enterThePhoneNumber,
                                    border: InputBorder.none,
                                    hintStyle: TextStyles.bodySmall.copyWith(
                                      color: AppColors.naturalGray,
                                      fontSize: w * 0.035,
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

                        if (errorText != null)
                          Padding(
                            padding:
                                EdgeInsets.only(left: Insets.xs, top: 5),
                            child: Text(
                              errorText!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: w * 0.032,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: h * 0.012),

                    Text(
                    UserMessages.sendOtpToYourNumber,
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.naturalBlack,
                        fontSize: w * 0.035,
                      ),
                    ),

                    SizedBox(height: h * 0.025),

                    SizedBox(
                      width: double.infinity,
                      height: h * 0.065,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _handlePhoneSignIn,
                        child: Text(
                          UserMessages.continueMsg,
                          style: TextStyles.button.copyWith(
                            color: AppColors.naturalBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: w * 0.045,
                          ),
                        ),
                      ),
                    ),


                    SizedBox(height: h * 0.025),

                    SocialButton(
                      onTap: _handleGoogleSignIn,
                      image: UserMessages.signInWithGoogleImage,
                      text: UserMessages.signInWithGoogle,
                      width: w,
                      height: h,
                    ),

                    SizedBox(height: h * 0.015),

                    SocialButton(
                      image:UserMessages.signInWithMailImage ,
                      text: UserMessages.signInWithMail,
                      width: w,
                      height: h,
                    ),

                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryYellow,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
