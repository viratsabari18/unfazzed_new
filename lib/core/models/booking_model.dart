import 'package:zeerah/core/models/service_models.dart';

class BookingModel {
  final String title;
  final String price;
  final String address;
  final String date;
  final String time;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String image;
  final ProfessionalMatch professional;

  BookingModel({
    required this.title,
    required this.price,
    required this.address,
    required this.date,
    required this.time,
    required this.status,
    required this.paymentStatus,
    required this.image,
    required this.professional,
  });

  /// FROM JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      title: json['title'] ?? '',
      price: json['price'] ?? '',
      address: json['address'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: BookingStatusExt.fromString(json['status']),
      paymentStatus:
          PaymentStatusExt.fromString(json['paymentStatus']),
      image: json['image'] ?? '',
      professional:
          ProfessionalMatch.fromJson(json['professional'] ?? {}),
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "price": price,
      "address": address,
      "date": date,
      "time": time,
      "status": status.value,
      "paymentStatus": paymentStatus.value,
      "image": image,
      "professional": professional.toJson(),
    };
  }


  static List<BookingModel> dummyList() {
    return [
      BookingModel(
        title: "Bathroom Cleaning",
        price: "₹200",
        address: "2,2 Katampe, Abuja, Nigeria",
        date: "March 16, 2026",
        time: "10:00AM",
        status: BookingStatus.inProgress,
        paymentStatus: PaymentStatus.pending,
        image: "https://picsum.photos/200",
        professional: ProfessionalMatch.dummy(),
      ),
      BookingModel(
        title: "Deep Cleaning",
        price: "₹2,599",
        address: "2,2 Katampe, Abuja",
        date: "March 16, 2026",
        time: "10:00AM",
        status: BookingStatus.accepted,
        paymentStatus: PaymentStatus.pending,
        image: "https://picsum.photos/201",
        professional: ProfessionalMatch.dummy(),
      ),
      BookingModel(
        title: "Filter Replacement",
        price: "₹650",
        address: "2,2 Katampe, Abuja",
        date: "March 16, 2026",
        time: "10:00AM",
        status: BookingStatus.completed,
        paymentStatus: PaymentStatus.paid,
        image: "https://picsum.photos/202",
        professional: ProfessionalMatch.dummy(),
      ),
      BookingModel(
        title: "Deep Cleaning",
        price: "₹2,399",
        address: "2,2 Katampe, Abuja",
        date: "March 16, 2026",
        time: "10:00AM",
        status: BookingStatus.rejected,
        paymentStatus: PaymentStatus.failed,
        image: "https://picsum.photos/203",
        professional: ProfessionalMatch.dummy(),
      ),
    ];
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

enum BookingStatus {
  pending,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  completed,
  rejected,
  cancelled,
  onHold,
}

extension PaymentStatusExt on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return "Pending";
      case PaymentStatus.paid:
        return "Paid";
      case PaymentStatus.failed:
        return "Failed";
      case PaymentStatus.refunded:
        return "Refunded";
    }
  }

  static PaymentStatus fromString(String? status) {
    final s = status?.toLowerCase() ?? "";
    if (s.contains("paid")) return PaymentStatus.paid;
    if (s.contains("failed")) return PaymentStatus.failed;
    if (s.contains("refund")) return PaymentStatus.refunded;
    return PaymentStatus.pending;
  }
}

extension BookingStatusExt on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return "Pending";
      case BookingStatus.accepted:
        return "Accepted";
      case BookingStatus.onTheWay:
        return "On the Way";
      case BookingStatus.arrived:
        return "Arrived";
      case BookingStatus.inProgress:
        return "In Progress";
      case BookingStatus.completed:
        return "Completed";
      case BookingStatus.rejected:
        return "Rejected";
      case BookingStatus.cancelled:
        return "Cancelled";
      case BookingStatus.onHold:
        return "On Hold";
    }
  }

  static BookingStatus fromString(String? status) {
    final s = status?.toLowerCase() ?? "";
    switch (s) {
      case "pending":
        return BookingStatus.pending;
      case "accept":
      case "accepted":
        return BookingStatus.accepted;
      case "on_going":
      case "ongoing":
      case "on the way":
        return BookingStatus.onTheWay;
      case "arrived":
        return BookingStatus.arrived;
      case "in_progress":
      case "in progress":
      case "pending_approval":
      case "pending approval":
        return BookingStatus.inProgress;
      case "completed":
        return BookingStatus.completed;
      case "rejected":
        return BookingStatus.rejected;
      case "cancelled":
        return BookingStatus.cancelled;
      case "hold":
      case "on hold":
        return BookingStatus.onHold;
      default:
        return BookingStatus.pending;
    }
  }
}
