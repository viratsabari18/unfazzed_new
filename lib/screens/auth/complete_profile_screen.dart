import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/fcm_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool isGoogleLogin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        // Update Firebase Profile in background
        userProvider
            .updateProfile(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
            )
            .catchError(
              (e) => debugPrint("Firebase profile update background error: $e"),
            );

        final phoneNumber = isGoogleLogin
            ? _phoneController.text.trim()
            : (userProvider.user?.phoneNumber ?? '');
        if (phoneNumber.isNotEmpty) {
          final url = Uri.parse("${ApiConfig.apiBaseUrl}/user-save");
          http
              .post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: json.encode({
                  'contact_number': phoneNumber,
                  'first_name': _firstNameController.text.trim(),
                  'last_name': _lastNameController.text.trim(),
                  'email': _emailController.text.trim(),
                }),
              )
              .then((response) {
                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['status'] == true && data['data'] != null) {
                    final apiToken = data['data']['api_token'];
                    if (apiToken != null && apiToken.isNotEmpty) {
                      userProvider.setApiToken(apiToken);
                    }

                    final backendId =
                        data['data']['employee_id']?.toString() ??
                        data['data']['id']?.toString();
                    if (backendId != null) {
                      userProvider.setBackendUserId(backendId);
                    }
                  }
                }
              })
              .catchError(
                (e) => debugPrint("Backend background save error: $e"),
              );
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.landingPage,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = "Error updating profile: $e";
          if (e.toString().contains("requires-recent-login")) {
            errorMessage =
                "Email update requires re-authentication. Please sign in again later to update email.";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.primaryRed,
              duration: const Duration(seconds: 4),
            ),
          );

          // Still navigate to home if it's just an email issue,
          // as the user is already authenticated with phone
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.landingPage,
              (route) => false,
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSizes.width(context);
    final h = AppSizes.height(context);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    isGoogleLogin = args?['isGoogleLogin'] ?? false;
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(Insets.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h * 0.05),
                    Text(
                      "Complete Your Profile",
                      style: TextStyles.h1.copyWith(
                        color: AppColors.primaryRed,
                        fontSize: w * 0.07,
                      ),
                    ),
                    SizedBox(height: h * 0.01),
                    Text(
                      "Tell us a bit more about yourself to get started with Unfazzed.",
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.naturalGray,
                        fontSize: w * 0.04,
                      ),
                    ),
                    SizedBox(height: h * 0.06),

                    _buildTextField(
                      controller: _firstNameController,
                      label: "First Name",
                      hint: "Enter your first name",
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v!.isEmpty ? "First name is required" : null,
                    ),
                    SizedBox(height: h * 0.025),

                    _buildTextField(
                      controller: _lastNameController,
                      label: "Last Name",
                      hint: "Enter your last name",
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v!.isEmpty ? "Last name is required" : null,
                    ),
                    SizedBox(height: h * 0.025),
                    if (isGoogleLogin) ...[
                      _buildTextField(
                        controller: _phoneController,
                        label: "Contact Number",
                        hint: "Enter your contact number",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Contact number is required";
                          }

                          if (v.length < 10) {
                            return "Enter valid phone number";
                          }

                          return null;
                        },
                      ),

                      SizedBox(height: h * 0.025),
                    ],

                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      hint: isGoogleLogin ? "Google email" : "Enter your email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return "Email is required";
                        return null;
                      },
                      readOnly: isGoogleLogin,
                    ),

                    SizedBox(height: h * 0.08),

                    SizedBox(
                      width: double.infinity,
                      height: h * 0.065,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _handleSave,
                        child: Text(
                          "Save & Continue",
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
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryRed),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
