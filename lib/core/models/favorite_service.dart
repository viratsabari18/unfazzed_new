class FavoriteService {
  final int id;
  final String serviceImage;
  final String serviceTitle;
  final double rating;
  final int reviewsCount;
  final int rate;
  final bool isFavorite; // ✅ NEW FIELD

  FavoriteService({
    required this.id,
    required this.serviceImage,
    required this.serviceTitle,
    required this.rating,
    required this.reviewsCount,
    required this.rate,
    required this.isFavorite,
  });

  /// FROM JSON
  factory FavoriteService.fromJson(Map<String, dynamic> json) {
    return FavoriteService(
      id: json['id'] ?? 0,
      serviceImage: json['serviceImage'] ?? '',
      serviceTitle: json['serviceTitle'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      rate: json['rate'] ?? 0,
      isFavorite: json['isFavorite'] ?? false, // ✅
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "serviceImage": serviceImage,
      "serviceTitle": serviceTitle,
      "rating": rating,
      "reviewsCount": reviewsCount,
      "rate": rate,
      "isFavorite": isFavorite, // ✅
    };
  }

  /// 🔥 DUMMY DATA
  static List<FavoriteService> dummyList() {
    return [
      FavoriteService(
        id: 1,
        serviceImage: "https://picsum.photos/300/200",
        serviceTitle: "AC Repair Service",
        rating: 4.8,
        reviewsCount: 120,
        rate: 499,
        isFavorite: true,
      ),
      FavoriteService(
        id: 2,
        serviceImage: "https://picsum.photos/301/200",
        serviceTitle: "Home Cleaning",
        rating: 4.5,
        reviewsCount: 95,
        rate: 699,
        isFavorite: false,
      ),
      FavoriteService(
        id: 3,
        serviceImage: "https://picsum.photos/302/200",
        serviceTitle: "Plumbing Service",
        rating: 4.2,
        reviewsCount: 80,
        rate: 299,
        isFavorite: true,
      ),
      FavoriteService(
        id: 4,
        serviceImage: "https://picsum.photos/303/200",
        serviceTitle: "Electrician Service",
        rating: 4.7,
        reviewsCount: 150,
        rate: 399,
        isFavorite: false,
      ),
    ];
  }
  FavoriteService copyWith({
  int? id,
  String? serviceImage,
  String? serviceTitle,
  double? rating,
  int? reviewsCount,
  int? rate,
  bool? isFavorite,
}) {
  return FavoriteService(
    id: id ?? this.id,
    serviceImage: serviceImage ?? this.serviceImage,
    serviceTitle: serviceTitle ?? this.serviceTitle,
    rating: rating ?? this.rating,
    reviewsCount: reviewsCount ?? this.reviewsCount,
    rate: rate ?? this.rate,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
}
