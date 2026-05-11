import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/controllers/service%20_list_controller.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/firebase_options.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/providers/favorites_provider.dart';

import 'package:zeerah/core/services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize FCM Service
    await FCMService().initialize();
    
    FirebaseMessaging.onBackgroundMessage(FCMService.onBackgroundMessage);
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    // Continue anyway to avoid black screen
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
         ChangeNotifierProvider(create: (_) => ServiceListController()),
         ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
    );
  }
}
