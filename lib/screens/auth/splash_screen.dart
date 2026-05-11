import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Pre-fetch dashboard and category data while splash is showing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchInitialData();
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // User is already logged in, go to Home
          Navigator.pushReplacementNamed(context, AppRoutes.landingPage);
        } else {
          // No user, go to Sign In
          Navigator.pushReplacementNamed(context, AppRoutes.signIn);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = AppSizes.width(context);

    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(Insets.md),
            child: Image.asset(
              UserMessages.splashScreenImage,
              width: width * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
