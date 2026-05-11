import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:zeerah/core/colors/app_colors.dart';

class NotificationSwitch extends StatefulWidget {
  const NotificationSwitch({super.key});

  @override
  State<NotificationSwitch> createState() => _NotificationSwitchState();
}

class _NotificationSwitchState extends State<NotificationSwitch> {
  bool _isSubscribed = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSubscribed = prefs.getBool('is_subscribed_notification') ?? true;
    });
  }

  Future<void> _toggleSubscription(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed_notification', value);
    
    if (value) {
      // Re-enable notifications (you might want to re-register the token)
      await FirebaseMessaging.instance.subscribeToTopic('all');
    } else {
      // Disable notifications
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
    }

    setState(() {
      _isSubscribed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: _isSubscribed,
      activeColor: AppColors.primaryRed,
      onChanged: _toggleSubscription,
    );
  }
}
