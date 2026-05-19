class AddressSaveResponseModel {
  final bool status;
  final String message;
  final AddressData? data;

  AddressSaveResponseModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory AddressSaveResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AddressSaveResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AddressData.fromJson(json['data'])
          : null,
    );
  }
}
class AddressListModel {
  final bool status;
  final String message;
  final Pagination pagination;
  final List<AddressData> data;

  AddressListModel({
    required this.status,
    required this.message,
    required this.pagination,
    required this.data,
  });

  factory AddressListModel.fromJson(Map<String, dynamic> json) {
    return AddressListModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => AddressData.fromJson(e))
          .toList(),
    );
  }
}

class Pagination {
  final int totalItems;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.totalItems,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['total_items'] ?? 0,
      perPage: json['per_page'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class AddressData {
  final int id;
  final int userId;
  final double latitude;
  final double longitude;
  final int status;
  final String address;
  final String userName;
  final String? userPhone;

  AddressData({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.address,
    required this.userName,
    this.userPhone,
  });

  factory AddressData.fromJson(
    Map<String, dynamic> json,
  ) {
    return AddressData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,

      latitude:
          (json['latitude'] ?? 0).toDouble(),

      longitude:
          (json['longitude'] ?? 0).toDouble(),

      status: json['status'] ?? 0,
      address: json['address'] ?? '',
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'],
    );
  }
}
class DeleteAddressModel {
  final String message;

  DeleteAddressModel({
    required this.message,
  });

  factory DeleteAddressModel.fromJson(Map<String, dynamic> json) {
    return DeleteAddressModel(
      message: json['message'] ?? '',
    );
  }
}