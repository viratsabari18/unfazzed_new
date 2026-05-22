import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zeerah/controllers/service%20_list_controller.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:zeerah/core/providers/favorites_provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/fcm_service.dart';
import 'package:zeerah/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize FCM
    await FCMService().initialize();

    // Background notification handler
    FirebaseMessaging.onBackgroundMessage(
      FCMService.onBackgroundMessage,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AddressProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceListController(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _isLoggedIn = true;

        // Fetch dashboard data only if logged in
        await Provider.of<DashboardProvider>(
          context,
          listen: false,
        ).fetchInitialData();
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // IMPORTANT
      // Do NOT use home:
      // because routes already contains "/"

      initialRoute: _isLoading
          ? AppRoutes.splash
          : _isLoggedIn
              ? AppRoutes.landingPage
              : AppRoutes.signIn,

      routes: AppPages.routes,
    );
  }
}