import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/main.dart';
import 'package:zeerah/core/routes/app_routes.dart';
import 'package:zeerah/firebase_options.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint("Background message received: ${message.data}");
    // We can show a notification here if it's a data-only message
    // but usually FCM handles this if there's a notification object.
  }

  Future<void> initialize() async {
    // 1. Request Permissions (especially for Android 13+ and iOS)
    await requestPermission();

    // 2. Initialize Local Notifications for Foreground Messages
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click when app is in foreground
        debugPrint("Notification clicked: ${details.payload}");
        if (details.payload != null) {
          final Map<String, dynamic> data = json.decode(details.payload!);
          handleNotificationClick(RemoteMessage(data: data));
        }
      },
    );

    // 3. Create Android Notification Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'zeerah_high_importance', // New unique ID to ensure high importance
        'High Importance Notifications', 
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 4. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // 5. Handle Notification click when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification opened app: ${message.data}");
      handleNotificationClick(message);
    });

    // 6. Handle Initial Message (App opened from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint("Initial message received: ${message.data}");
        handleNotificationClick(message);
      }
    });

    // 7. Get and save token
    String? token = await getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
    }
  }

  void handleNotificationClick(RemoteMessage message) {
    debugPrint("Handling notification click with data: ${message.data}");
    
    final String? type = message.data['type']?.toString();
    final String? serviceId = message.data['service_id']?.toString();

    // Determine where to navigate based on message data
    if (message.data.containsKey('is_chat')) {
       // Navigate to chat
       navigatorKey.currentState?.pushNamed(AppRoutes.chatHomeScreen);
    } else if (type == 'booking' || message.data.containsKey('booking_id')) {
       final String? bookingId = message.data['booking_id']?.toString() ?? serviceId;
       if (bookingId != null) {
         navigatorKey.currentState?.pushNamed(
           AppRoutes.bookingDetail, 
           arguments: bookingId,
         );
       } else {
         navigatorKey.currentState?.pushNamed(AppRoutes.notificationHistory);
       }
    } else if (type == 'service' && serviceId != null) {
       // Optional: Navigate to a specific service if needed
       navigatorKey.currentState?.pushNamed(AppRoutes.notificationHistory);
    } else {
       // Default: Notification History
       navigatorKey.currentState?.pushNamed(AppRoutes.notificationHistory);
    }
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    Map<String, dynamic> data = message.data;

    // Use notification title/body or fallback to data values (for data-only messages)
    String title = notification?.title ?? data['title'] ?? 'New Notification';
    String body = notification?.body ?? data['body'] ?? '';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'zeerah_high_importance',
          'High Importance Notifications', 
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode(message.data),
    );
  }

  /// Sends the FCM token to the backend so the admin can send notifications
  Future<void> registerTokenWithBackend(String backendUserId, String apiToken, {String? firebaseUid}) async {
    String? fcmToken = await getToken();
    if (fcmToken == null) return;

    try {
      // 1. Subscribe to topics (Topic-based notifications)
      // Standard topic: user_[NumericID]
      await _fcm.subscribeToTopic('user_$backendUserId');
      debugPrint("Subscribed to topic: user_$backendUserId");
      
      // Additional topic if Firebase UID is provided
      if (firebaseUid != null) {
        await _fcm.subscribeToTopic('user_$firebaseUid');
        debugPrint("Subscribed to topic: user_$firebaseUid");
      }
      
      // Global topics
      await _fcm.subscribeToTopic('all');
      await _fcm.subscribeToTopic('user');
      await _fcm.subscribeToTopic('userApp'); // Match backend topic for User App
      debugPrint("Subscribed to global topic: userApp");

      // 2. Register Token with Backend (Token-based notifications)
      // Endpoint 1: save-player-id (Common in Handyman system)
      final url = Uri.parse("${ApiConfig.apiBaseUrl}/save-player-id"); 
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: json.encode({
          'player_id': fcmToken,
          'uid': backendUserId, // Numeric ID
          'firebase_uid': firebaseUid, // Add Firebase UID just in case
        }),
      );

      debugPrint("Register Token Response (save-player-id): ${response.statusCode}");

      // Endpoint 2: update-user (Alternative)
      final altUrl = Uri.parse("${ApiConfig.apiBaseUrl}/update-user");
      await http.post(
        altUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: json.encode({
          'fcm_token': fcmToken,
          'id': backendUserId,
          'uid': firebaseUid, // Sometimes 'uid' is used for Firebase UID in alt endpoints
        }),
      );
      
    } catch (e) {
      debugPrint("Error registering token with backend: $e");
    }
  }
}
