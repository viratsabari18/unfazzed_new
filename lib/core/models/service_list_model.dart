class ServiceListModel {
  List<ServiceData>? data;
  dynamic userServices;
  int? max;
  int? min;

  ServiceListModel({
    this.data,
    this.userServices,
    this.max,
    this.min,
  });

  factory ServiceListModel.fromJson(Map<String, dynamic> json) {
    return ServiceListModel(
      data: json['data'] != null
          ? List<ServiceData>.from(
              json['data'].map((x) => ServiceData.fromJson(x)))
          : [],
      userServices: json['user_services'],
      max: json['max'],
      min: json['min'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "data": data?.map((x) => x.toJson()).toList(),
      "user_services": userServices,
      "max": max,
      "min": min,
    };
  }
}

class ServiceData {
  int? id;
  String? name;
  int? categoryId;
  int? subcategoryId;
  dynamic providerId;
  int? price;
  String? priceFormat;
  String? type;
  int? discount;
  String? duration;
  int? status;
  String? description;
  int? isFeatured;
  dynamic providerName;
  String? providerImage;
  dynamic cityId;
  String? categoryName;
  String? subcategoryName;
  List<String>? attachments;
  List<AttachmentArray>? attachmentsArray;
  int? totalReview;
  int? totalRating;
  int? isFavourite;
  List<dynamic>? serviceAddressMapping;
  bool? attachmentExtension;
  dynamic deletedAt;
  int? isSlot;
  List<Slot>? slots;
  String? visitType;
  int? isEnableAdvancePayment;
  int? advancePaymentAmount;
  String? translations;
  dynamic rejectReason;
  String? serviceRequestStatus;

  double? serviceRating;
  String? serviceReview;

  ServiceData({
    this.id,
    this.name,
    this.categoryId,
    this.subcategoryId,
    this.providerId,
    this.price,
    this.priceFormat,
    this.type,
    this.discount,
    this.duration,
    this.status,
    this.description,
    this.isFeatured,
    this.providerName,
    this.providerImage,
    this.cityId,
    this.categoryName,
    this.subcategoryName,
    this.attachments,
    this.attachmentsArray,
    this.totalReview,
    this.totalRating,
    this.isFavourite,
    this.serviceAddressMapping,
    this.attachmentExtension,
    this.deletedAt,
    this.isSlot,
    this.slots,
    this.visitType,
    this.isEnableAdvancePayment,
    this.advancePaymentAmount,
    this.translations,
    this.rejectReason,
    this.serviceRequestStatus,
    this.serviceRating,
    this.serviceReview,
  });

  factory ServiceData.fromJson(Map<String, dynamic> json) {
    return ServiceData(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      subcategoryId: json['subcategory_id'],
      providerId: json['provider_id'],
      price: json['price'],
      priceFormat: json['price_format'],
      type: json['type'],
      discount: json['discount'],
      duration: json['duration'],
      status: json['status'],
      description: json['description'],
      isFeatured: json['is_featured'],
      providerName: json['provider_name'],
      providerImage: json['provider_image'],
      cityId: json['city_id'],
      categoryName: json['category_name'],
      subcategoryName: json['subcategory_name'],

      attachments: json['attchments'] != null
          ? List<String>.from(json['attchments'])
          : [],

      attachmentsArray: json['attchments_array'] != null
          ? List<AttachmentArray>.from(
              json['attchments_array']
                  .map((x) => AttachmentArray.fromJson(x)),
            )
          : [],

      totalReview: json['total_review'],
      totalRating: json['total_rating'],
      isFavourite: json['is_favourite'],
      serviceAddressMapping:
          json['service_address_mapping'] ?? [],

      attachmentExtension:
          json['attchment_extension'],

      deletedAt: json['deleted_at'],

      isSlot: json['is_slot'],

      slots: json['slots'] != null
          ? List<Slot>.from(
              json['slots'].map((x) => Slot.fromJson(x)),
            )
          : [],

      visitType: json['visit_type'],

      isEnableAdvancePayment:
          json['is_enable_advance_payment'],

      advancePaymentAmount:
          json['advance_payment_amount'],

      translations: json['translations'],

      rejectReason: json['reject_reason'],

      serviceRequestStatus:
          json['service_request_status'],

      serviceRating: json['service_rating'] != null
          ? double.tryParse(
              json['service_rating'].toString(),
            )
          : null,

      serviceReview:
          json['service_review']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "category_id": categoryId,
      "subcategory_id": subcategoryId,
      "provider_id": providerId,
      "price": price,
      "price_format": priceFormat,
      "type": type,
      "discount": discount,
      "duration": duration,
      "status": status,
      "description": description,
      "is_featured": isFeatured,
      "provider_name": providerName,
      "provider_image": providerImage,
      "city_id": cityId,
      "category_name": categoryName,
      "subcategory_name": subcategoryName,
      "attchments": attachments,
      "attchments_array":
          attachmentsArray?.map((x) => x.toJson()).toList(),
      "total_review": totalReview,
      "total_rating": totalRating,
      "is_favourite": isFavourite,
      "service_address_mapping": serviceAddressMapping,
      "attchment_extension": attachmentExtension,
      "deleted_at": deletedAt,
      "is_slot": isSlot,
      "slots": slots?.map((x) => x.toJson()).toList(),
      "visit_type": visitType,
      "is_enable_advance_payment":
          isEnableAdvancePayment,
      "advance_payment_amount":
          advancePaymentAmount,
      "translations": translations,
      "reject_reason": rejectReason,
      "service_request_status":
          serviceRequestStatus,

      "service_rating": serviceRating,
      "service_review": serviceReview,
    };
  }
}

class AttachmentArray {
  int? id;
  String? url;

  AttachmentArray({this.id, this.url});

  factory AttachmentArray.fromJson(Map<String, dynamic> json) {
    return AttachmentArray(
      id: json['id'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "url": url,
    };
  }
}

class Slot {
  String? day;
  List<dynamic>? slot;

  Slot({this.day, this.slot});

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      day: json['day'],
      slot: json['slot'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "day": day,
      "slot": slot,
    };
  }
}
