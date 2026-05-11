import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeerah/core/services/fcm_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _apiToken;
  String? _backendUserId;
  DateTime? _serviceStartTime;
  DateTime? _serviceEndTime;
  bool _isServicePaused = false;
  int _elapsedSeconds = 0;
  double _walletBalance = 0.0;
  int _unreadNotificationCount = 0;

  UserProvider() {
    // Check if a user is already logged in via Firebase
    _user = FirebaseAuth.instance.currentUser;
    _loadApiToken();
  }

  User? get user => _user;
  String? get apiToken => _apiToken;
  String? get backendUserId => _backendUserId;
  DateTime? get serviceStartTime => _serviceStartTime;
  DateTime? get serviceEndTime => _serviceEndTime;
  bool get isServicePaused => _isServicePaused;
  int get elapsedSeconds => _elapsedSeconds;
  double get walletBalance => _walletBalance;
  int get unreadNotificationCount => _unreadNotificationCount;

  void updateUnreadNotificationCount(int count) {
    _unreadNotificationCount = count;
    notifyListeners();
  }

  void updateWalletBalance(double balance) {
    _walletBalance = balance;
    notifyListeners();
  }

  Future<void> setServiceStartTime(DateTime time) async {
    _serviceStartTime = time;
    _elapsedSeconds = 0;
    _isServicePaused = false;
    notifyListeners();
  }

  void updateElapsedSeconds(int seconds) {
    _elapsedSeconds = seconds;
    notifyListeners();
  }

  void togglePause() {
    _isServicePaused = !_isServicePaused;
    notifyListeners();
  }

  Future<void> setServiceEndTime(DateTime time) async {
    _serviceEndTime = time;
    notifyListeners();
  }

  Future<void> _loadApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    _apiToken = prefs.getString('api_token');
    _backendUserId = prefs.getString('backend_user_id');
    
    // Register FCM token if already logged in
    syncFCMToken();
    
    notifyListeners();
  }

  Future<void> syncFCMToken() async {
    if (_apiToken != null && _backendUserId != null) {
      debugPrint("Syncing FCM Token for User: $_backendUserId");
      await FCMService().registerTokenWithBackend(
        _backendUserId!, 
        _apiToken!, 
        firebaseUid: _user?.uid,
      );
    }
  }

  Future<void> setApiToken(String token) async {
    _apiToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    syncFCMToken(); // Sync on token set
    notifyListeners();
  }

  Future<void> setBackendUserId(String id) async {
    _backendUserId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_user_id', id);
    syncFCMToken(); // Sync on ID set
    notifyListeners();
  }

  String get displayName => _user?.displayName ?? "Guest";
  String get email => _user?.email ?? "";
  
  // Extract first name from display name or email
  String get firstName {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!.split(' ').first;
    }
    if (_user?.email != null && _user!.email!.isNotEmpty) {
      return _user!.email!.split('@').first;
    }
    return "User";
  }

  // Generate unique referral code from UID
  String get referralCode {
    if (_user == null) return "ZEERAH";
    final uid = _user!.uid;
    if (uid.length < 6) return uid.toUpperCase();
    return uid.substring(uid.length - 6).toUpperCase();
  }

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() async {
    _user = null;
    _apiToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    notifyListeners();
  }

  Future<void> updateProfile({required String firstName, required String lastName, required String email}) async {
    if (_user != null) {
      try {
        final fullName = "$firstName $lastName".trim();
        await _user!.updateDisplayName(fullName);
        
        // Try updating email, might fail if re-auth is needed or email is taken
        try {
          await _user!.updateEmail(email);
        } catch (e) {
          debugPrint("Email update failed: $e");
          // Some Firebase projects require verification or recent login for email updates
        }
        
        // Reload user to get updated info
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
        notifyListeners();
      } catch (e) {
        debugPrint("Profile update error: $e");
        rethrow;
      }
    }
  }
}
