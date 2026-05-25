// lib/core/models/booking_model.dart

enum BookingStatus {
  pending,
  onHold,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  completed,
  rejected,
  cancelled,
  unknown;

  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.onHold:
        return 'On Hold';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.onTheWay:
        return 'On The Way';
      case BookingStatus.arrived:
        return 'Arrived';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.unknown:
        return 'Unknown';
    }
  }
}

extension BookingStatusExt on BookingStatus {
  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'onhold':
      case 'on_hold':
        return BookingStatus.onHold;
      case 'accepted':
        return BookingStatus.accepted;
      case 'ontheway':
      case 'on_the_way':
        return BookingStatus.onTheWay;
      case 'arrived':
        return BookingStatus.arrived;
      case 'inprogress':
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
      case 'canceled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.unknown;
    }
  }
}

class BookingModel {
  final String id;
  final String? serviceName;
  final double totalAmount;
  final double price;
  final String? status;
  final String? statusLabel;
  final String? address;
  final String? bookingDate;
  final String? bookingSlot;
  final String? paymentId;
  final HandymanModel? handymanData;
  final ProviderModel? providerData;
  final ServiceModel? service;
  final List<String> serviceAttachments;
  final String? providerImage;
  final String? providerName;

  BookingModel({
    required this.id,
    this.serviceName,
    required this.totalAmount,
    required this.price,
    this.status,
    this.statusLabel,
    this.address,
    this.bookingDate,
    this.bookingSlot,
    this.paymentId,
    this.handymanData,
    this.providerData,
    this.service,
    this.serviceAttachments = const [],
    this.providerImage,
    this.providerName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Helper function to convert dynamic map to String map
    Map<String, dynamic> _toStrMap(dynamic data) {
      if (data == null) return {};
      if (data is Map<String, dynamic>) return data;
      if (data is Map<dynamic, dynamic>) {
        return Map<String, dynamic>.fromEntries(
          data.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
        );
      }
      return {};
    }

    final rawHandyman = json['handyman_data'];
    HandymanModel? handyman;
    if (rawHandyman != null) {
      if (rawHandyman is List && rawHandyman.isNotEmpty) {
        handyman = HandymanModel.fromJson(_toStrMap(rawHandyman.first));
      } else if (rawHandyman is Map) {
        handyman = HandymanModel.fromJson(_toStrMap(rawHandyman));
      }
    }

    final rawProvider = json['provider_data'];
    ProviderModel? provider;
    if (rawProvider != null) {
      if (rawProvider is List && rawProvider.isNotEmpty) {
        provider = ProviderModel.fromJson(_toStrMap(rawProvider.first));
      } else if (rawProvider is Map) {
        provider = ProviderModel.fromJson(_toStrMap(rawProvider));
      }
    }

    final rawService = json['service'];
    ServiceModel? service;
    if (rawService != null) {
      if (rawService is List && rawService.isNotEmpty) {
        service = ServiceModel.fromJson(_toStrMap(rawService.first));
      } else if (rawService is Map) {
        service = ServiceModel.fromJson(_toStrMap(rawService));
      }
    }

    final attachments = json['service_attchments'] as List?;
    List<String> serviceAttachments = [];
    if (attachments != null) {
      serviceAttachments = attachments.map((e) => e.toString()).toList();
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',
      serviceName: json['service_name']?.toString(),
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString(),
      statusLabel: json['status_label']?.toString(),
      address: json['address']?.toString(),
      bookingDate: json['booking_date']?.toString(),
      bookingSlot: json['booking_slot']?.toString(),
      paymentId: json['payment_id']?.toString(),
      handymanData: handyman,
      providerData: provider,
      service: service,
      serviceAttachments: serviceAttachments,
      providerImage: json['provider_image']?.toString(),
      providerName: json['provider_name']?.toString(),
    );
  }

  BookingStatus get bookingStatus {
    return BookingStatusExt.fromString(status ?? 'unknown');
  }

  String get displayImage {
    if (handymanData?.profileImage != null && handymanData!.profileImage!.isNotEmpty) {
      return handymanData!.profileImage!;
    }
    if (serviceAttachments.isNotEmpty) {
      return serviceAttachments.first;
    }
    if (providerImage != null && providerImage!.isNotEmpty) {
      return providerImage!;
    }
    return '';
  }

  String get displayName {
    if (bookingStatus == BookingStatus.cancelled || 
        bookingStatus == BookingStatus.rejected) {
      return "Cancelled";
    }
    return handymanData?.displayName ?? 
           providerName ?? 
           "Finding...";
  }

  bool get isPaymentPending => 
      bookingStatus == BookingStatus.completed && paymentId == null;
}

class HandymanModel {
  final String? id;
  final String? displayName;
  final String? firstName;
  final String? profileImage;
  final double? rating;
  final int? totalJobs;

  HandymanModel({
    this.id,
    this.displayName,
    this.firstName,
    this.profileImage,
    this.rating,
    this.totalJobs,
  });

  factory HandymanModel.fromJson(Map<String, dynamic> json) {
    return HandymanModel(
      id: json['id']?.toString(),
      displayName: json['display_name']?.toString(),
      firstName: json['first_name']?.toString(),
      profileImage: json['profile_image']?.toString(),
      rating: double.tryParse(json['providers_service_rating']?.toString() ?? '0'),
      totalJobs: int.tryParse(json['total_services_booked']?.toString() ?? '0'),
    );
  }
}

class ProviderModel {
  final String? id;
  final String? displayName;
  final String? profileImage;
  final double? rating;
  final int? totalJobs;

  ProviderModel({
    this.id,
    this.displayName,
    this.profileImage,
    this.rating,
    this.totalJobs,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id']?.toString(),
      displayName: json['display_name']?.toString(),
      profileImage: json['profile_image']?.toString(),
      rating: double.tryParse(json['providers_service_rating']?.toString() ?? '0'),
      totalJobs: int.tryParse(json['total_services_booked']?.toString() ?? '0'),
    );
  }
}

class ServiceModel {
  final String? id;
  final String? name;
  final Map<String, dynamic>? rawData;

  ServiceModel({this.id, this.name, this.rawData});

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      rawData: json,
    );
  }
}

// Add these classes if not defined elsewhere
class BookingStatusModel {
  final BookingState currentState;
  final ProfessionalMatch professional;
  final String appointmentDate;
  final String appointmentTime;

  BookingStatusModel({
    required this.currentState,
    required this.professional,
    required this.appointmentDate,
    required this.appointmentTime,
  });
}

enum BookingState {
  pending,
  assigned,
  onTheWay,
  arrived,
  inProgress,
  completed,
  cancelled;
}

class ProfessionalMatch {
  final String name;
  final double rating;
  final int jobsDone;
  final String avatarUrl;

  ProfessionalMatch({
    required this.name,
    required this.rating,
    required this.jobsDone,
    required this.avatarUrl,
  });
}