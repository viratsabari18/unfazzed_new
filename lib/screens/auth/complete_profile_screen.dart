import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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

  // Regex patterns for validation
  final RegExp _phoneRegex = RegExp(r'^[0-9]{10}$');
  final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

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
    // Step 1: Validate Form
    if (_formKey.currentState!.validate()) {
      // Step 2: Show Button Loader
      setState(() => _isLoading = true);
      
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Step 3: Get Phone Number
        final phoneNumber = isGoogleLogin
            ? _phoneController.text.trim()
            : (userProvider.user?.phoneNumber ?? '');
        
        // Step 4: Validate Phone Number
        if (phoneNumber.isEmpty) {
          throw Exception("Phone number is missing. Please sign in again.");
        }
        
        // Step 5: POST to /user-save with timeout
        final url = Uri.parse("${ApiConfig.apiBaseUrl}/user-save");
        final response = await http.post(
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
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception("Connection timeout. Please try again."),
        );

        // Check if widget is still mounted after long API call
        if (!mounted) return;

        // Step 6: Check Response Status
        if (response.statusCode != 200) {
          throw Exception("Server error: ${response.statusCode}");
        }

        // Step 7: Safely decode JSON (handle malformed responses)
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          throw Exception("Invalid server response format");
        }
        
        // Step 8: Check Business Logic Status
        if (data['status'] != true || data['data'] == null) {
          throw Exception(data['message'] ?? "Profile save failed");
        }

        // Step 9: Save Token and Backend ID (await if async)
        final apiToken = data['data']['api_token'];
        
        // If token is mandatory, uncomment this check
        // if (apiToken == null || apiToken.isEmpty) {
        //   throw Exception("Invalid server response: Missing API token");
        // }
        
        if (apiToken != null && apiToken.isNotEmpty) {
          // Assuming setApiToken might be async, await it
          await userProvider.setApiToken(apiToken);
        }

        final backendId = data['data']['employee_id']?.toString() ??
            data['data']['id']?.toString();
        if (backendId != null) {
          await userProvider.setBackendUserId(backendId);
        }

        // Step 10: Update Firebase Profile (Don't fail if this fails)
        try {
          await userProvider.updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Firebase update timeout"),
          );
        } catch (firebaseError) {
          // Log error but don't block navigation
          debugPrint("Firebase profile update failed but backend succeeded: $firebaseError");
          // Optional: Show non-blocking notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile saved but some features may be delayed"),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        // Step 11: Navigate (with optional delay to show success message)
        if (mounted) {
          // Short delay to show success message (optional)
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.landingPage,
              (route) => false,
            );
          }
        }
        
      } catch (e) {
        // Step 12: Handle Errors - Stay on Complete Profile Screen
        debugPrint("Error in _handleSave: $e");
        
        if (mounted) {
          String errorMessage = "Unable to save profile. Please check your internet connection and try again.";
          
          if (e.toString().contains("Phone number is missing")) {
            errorMessage = "Session expired. Please sign in again.";
          } else if (e.toString().contains("Connection timeout")) {
            errorMessage = "Connection timeout. Please check your internet and try again.";
          } else if (e.toString().contains("Missing API token")) {
            errorMessage = "Server configuration error. Please contact support.";
          } else if (e.toString().contains("Invalid server response")) {
            errorMessage = "Server error. Please try again later.";
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.primaryRed,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // DO NOT navigate - User stays on this screen to retry
        
      } finally {
        // Step 13: Hide Loader
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
    
    return PopScope(
      canPop: !_isLoading, // Prevent back navigation while saving
      child: Scaffold(
        backgroundColor: AppColors.naturalWhite,
        body: SafeArea(
          child: SingleChildScrollView(
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
                      color: Colors.black,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Contact number is required";
                        }
                        // Strict phone number validation
                        if (!_phoneRegex.hasMatch(v)) {
                          return "Enter valid 10-digit phone number";
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
                      // Strict email validation
                      if (!_emailRegex.hasMatch(v)) {
                        return "Enter valid email address (e.g., name@example.com)";
                      }
                      return null;
                    },
                    readOnly: isGoogleLogin,
                  ),

                  SizedBox(height: h * 0.08),

                  // Button with loading state
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
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
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
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
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