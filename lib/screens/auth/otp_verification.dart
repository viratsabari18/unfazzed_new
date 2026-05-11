import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/auth_service.dart';
import 'package:zeerah/core/services/fcm_service.dart';

class OtpVerification extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerification({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final int otpLength = 6;
  final AuthService _authService = AuthService();

  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(otpLength, (index) => TextEditingController());
    focusNodes = List.generate(otpLength, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void handleOtpChange(String value, int index) {
    if (value.isNotEmpty) {
      if (index < otpLength - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        focusNodes[index - 1].requestFocus();
      }
    }
  }

  String getOtp() {
    return controllers.map((e) => e.text).join();
  }

  Future<void> _handleVerifyOtp() async {
    String otp = getOtp();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UserMessages.enterVaildOtp)),
      );
      return;
    }

    setState(() => isLoading = true);
    
    final userCredential = await _authService.signInWithPhoneNumber(
      widget.verificationId, 
      otp,
    );
    
    if (userCredential != null && userCredential.user != null) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(userCredential.user);
        
        bool forceProfileCompletion = false;

        // Backend API Check
        try {
          final url = Uri.parse("${ApiConfig.apiBaseUrl}/otp-login");
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              
            },
            body: json.encode({'contact_number': widget.phoneNumber}),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == true && data['data'] != null) {
              // Always save API token if present
              final apiToken = data['data']['api_token'];
              if (apiToken != null && apiToken.isNotEmpty) {
                await userProvider.setApiToken(apiToken);
                debugPrint("Token SAVED: $apiToken");
              }
              
              final backendId = data['data']['employee_id']?.toString() ?? data['data']['id']?.toString();
              if (backendId != null) {
                // Background task: Register FCM Token (UserProvider also handles this internally)
                userProvider.setBackendUserId(backendId); 
              }

              if (data['data']['first_name'] != null) {
                final firstName = data['data']['first_name'];
                final lastName = data['data']['last_name'] ?? '';
                
                // Background task: Update profile info without blocking the UI
                userProvider.updateProfile(
                  firstName: firstName, 
                  lastName: lastName, 
                  email: data['data']['email'] ?? ''
                ).catchError((e) => debugPrint("Profile background update error: $e"));
              }
            } else {
              debugPrint("API returned status false: ${response.body}");
            }
          } else if (response.statusCode == 406) {
             debugPrint("API 406: User needs to complete profile.");
             forceProfileCompletion = true;
          }
        } catch (e) {
          debugPrint("Backend API Error: $e");
        }
        
        if (mounted) {
          setState(() => isLoading = false);
          showOtpSuccessDialog(context, forceProfileCompletion: forceProfileCompletion);
        }
      }
    } else {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP. Please try again.")),
        );
      }
    }
  }

  void showOtpSuccessDialog(BuildContext context, {bool forceProfileCompletion = false}) {
    final w = AppSizes.width(context);
    final h = AppSizes.height(context);
    
    // Check if user already has a profile (displayName is not empty)
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final bool hasProfile = !forceProfileCompletion && user?.displayName != null && user!.displayName!.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.naturalWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: h * 0.12,
                  width: h * 0.12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFBC0D),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.red,
                      size: 50,
                      weight: 700,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.025),
                Text(
                  UserMessages.otpVerified,
                  style: TextStyles.h2.copyWith(
                    color: AppColors.naturalBlack,
                    fontSize: w * 0.055,
                  ),
                ),
                SizedBox(height: h * 0.012),
                Text(
                  UserMessages.phoneNumberVerified,
                  textAlign: TextAlign.center,
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
                    onPressed: () {
                      if (hasProfile) {
                        Navigator.pushNamedAndRemoveUntil(
                          context, 
                          AppRoutes.landingPage,
                          (route) => false,
                        );
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context, 
                          AppRoutes.completeProfile,
                          (route) => false,
                        );
                      }
                    },
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget otpBox(int index, double boxWidth) {
    return Container(
      width: boxWidth,
      height: boxWidth * 1.2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.naturalWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => handleOtpChange(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSizes.width(context);
    final h = AppSizes.height(context);

    double horizontalPadding = Insets.md * 2;
    double spacing = Insets.xs * (otpLength - 1);
    double availableWidth = w - horizontalPadding - spacing;
    double boxWidth = availableWidth / otpLength;

    boxWidth = boxWidth.clamp(45.0, 75.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.primaryRed,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Insets.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.02),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),

                  SizedBox(height: h * 0.03),

                  Text(
                    UserMessages.logIn,
                    style: TextStyles.h2.copyWith(
                      color: Colors.white,
                      fontSize: w * 0.06,
                    ),
                  ),

                  SizedBox(height: h * 0.01),

                  Text(
                    "Enter OTP sent to ${widget.phoneNumber}",
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.naturalWhite,
                      fontWeight: FontWeight.w500,
                      fontSize: w * 0.035,
                    ),
                  ),

                  SizedBox(height: h * 0.04),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(otpLength, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == otpLength - 1 ? 0 : Insets.xs,
                        ),
                        child: otpBox(index, boxWidth),
                      );
                    }),
                  ),

                  SizedBox(height: h * 0.04),

                  SizedBox(
                    width: double.infinity,
                    height: h * 0.065,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _handleVerifyOtp,
                      child: Text(
                        UserMessages.veriflyOtp,
                        style: TextStyles.button.copyWith(
                          color: AppColors.naturalBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: w * 0.045,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  RichText(
                    text: TextSpan(
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                        fontSize: w * 0.035,
                      ),
                      children: [
                        TextSpan(text: UserMessages.doNotReciveYourCode),
                        TextSpan(
                          text: UserMessages.resendOtp,
                          style: TextStyles.bodySmall.copyWith(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.w600,
                            fontSize: w * 0.035,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.08),

                  Center(
                    child: Image.asset(
                      UserMessages.veriflyOtpImage,
                      height: h * 0.28,
                      width: w * 0.6,
                    ),
                  ),
                ],
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
