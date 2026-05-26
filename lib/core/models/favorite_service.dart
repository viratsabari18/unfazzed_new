class FavoriteService {
  final int id;
  final String serviceImage;
  final String serviceTitle;
  final double rating;
  final String reviewsCount;
  final int rate;
  final bool isFavorite;

  FavoriteService({
    required this.id,
    required this.serviceImage,
    required this.serviceTitle,
    required this.rating,
    required this.reviewsCount,
    required this.rate,
    required this.isFavorite,
  });

  factory FavoriteService.fromApi(
    Map<String, dynamic> json,
  ) {
    return FavoriteService(
      id: json['service_id'] ?? 0,

      serviceImage:
          (json['service_attchments'] != null &&
                  (json['service_attchments']
                          as List)
                      .isNotEmpty)
              ? json['service_attchments'][0]
              : "",

      serviceTitle: json['name'] ?? "",

      rating:
          double.tryParse(
            json['service_rating']
                .toString(),
          ) ??
          0.0,

      reviewsCount:
          json['service_review']
              ?.toString() ??
          "0",

      rate:
          int.tryParse(
            json['price'].toString(),
          ) ??
          0,

      isFavorite:
          json['is_favourite'] == 1,
    );
  }

  FavoriteService copyWith({
    bool? isFavorite,
  }) {
    return FavoriteService(
      id: id,
      serviceImage: serviceImage,
      serviceTitle: serviceTitle,
      rating: rating,
      reviewsCount: reviewsCount,
      rate: rate,
      isFavorite:
          isFavorite ?? this.isFavorite,
    );
  }
}