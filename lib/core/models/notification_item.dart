import 'package:flutter/material.dart';

/// 🔥 ENUM
enum NotificationType { rating, accepted, payment, driving }

extension NotificationTypeExt on NotificationType {
  String get value => toString().split('.').last;

  static NotificationType fromString(String? value) {
    switch (value) {
      case "accepted":
        return NotificationType.accepted;
      case "payment":
        return NotificationType.payment;
      case "driving":
        return NotificationType.driving;
      case "rating":
        return NotificationType.rating;
      default:
        return NotificationType.rating; // fallback
    }
  }
}

/// 🔥 MODEL
class NotificationItem {
  final String title;
  final String description;
  final NotificationType type;
  final String image;
  final String? buttonText;

  NotificationItem({
    required this.title,
    required this.description,
    required this.type,
    required this.image,
    this.buttonText,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: NotificationTypeExt.fromString(json['type']), // ✅ FIX
      image: json['image'] ?? '',
      buttonText: json['buttonText'],
    );
  }

  /// ✅ TO JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.value, // ✅ enum → string
      'image': image,
      'buttonText': buttonText,
    };
  }

  static List<NotificationItem> dummydata() {
    return [
      NotificationItem(
        title: "Rate your recent service",
        description:
            "Help others by rating the air condition services provided to you.",
        type: NotificationType.rating,
        image: "",
        buttonText: "Rate Now",
      ),
      NotificationItem(
        title: "Your order has been accepted",
        description: "Verfly your Kyc",
        type: NotificationType.accepted,
        image: "",
        buttonText: "Go to Bookings",
      ),
      NotificationItem(
        title: "Payment of ₹750 Confirmed!",
        description: "Your payment has been successfully processed. Thank you!",
        type: NotificationType.payment,
        image: "",
      ),
      NotificationItem(
        title: "Your handyman is on the way",
        description:
            "Your handyman is heading to your location and will arrive shortly.",
        type: NotificationType.driving,
        image: "",
        buttonText: "Go to Bookings",
      ),
    ];
  }
}
