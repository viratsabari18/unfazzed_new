import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/models/favorite_service.dart';
import 'package:zeerah/core/providers/user_provider.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<FavoriteService> _favorites = [];

  List<FavoriteService> get favorites => _favorites;

  bool isLoading = false;

  /// =========================
  /// CHECK FAVORITE
  /// =========================
  bool isFavorite(int id) {
    return _favorites.any((s) => s.id == id);
  }

  /// =========================
  /// FETCH FAVORITES
  /// =========================
/// =========================
/// FETCH FAVORITES
/// =========================
Future<void> fetchFavorites(
  BuildContext context,
) async {
  try {
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );

    final token = userProvider.apiToken;

    debugPrint(
      "================ FETCH FAVORITES START ================",
    );

    debugPrint(
      "TOKEN => $token",
    );

    if (token == null || token.isEmpty) {
      debugPrint(
        "TOKEN IS NULL OR EMPTY",
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    final url = Uri.parse(
      '${ApiConfig.apiBaseUrl}/user-favourite-service',
    );

    debugPrint(
      "API URL => $url",
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    debugPrint(
      "STATUS CODE => ${response.statusCode}",
    );

    debugPrint(
      "RAW RESPONSE => ${response.body}",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      debugPrint(
        "DECODED RESPONSE => $data",
      );

      final List<dynamic> favList =
          data['data'] ?? [];

      debugPrint(
        "FAVORITES LIST LENGTH => ${favList.length}",
      );

      for (var item in favList) {
        debugPrint(
          "FAVORITE ITEM => $item",
        );

        debugPrint(
          "SERVICE ID => ${item['service_id']}",
        );

        debugPrint(
          "SERVICE NAME => ${item['name']}",
        );

        debugPrint(
          "SERVICE RATING => ${item['service_rating']}",
        );

        debugPrint(
          "REVIEWS COUNT => ${item['reviews_count']}",
        );

        debugPrint(
          "TOTAL REVIEWS => ${item['total_reviews']}",
        );

        debugPrint(
          "PRICE => ${item['price']}",
        );

        debugPrint(
          "IS FAVORITE => ${item['is_favourite']}",
        );

        debugPrint(
          "ATTACHMENTS => ${item['service_attchments']}",
        );

        debugPrint(
          "================================================",
        );
      }

      _favorites.clear();

      _favorites.addAll(
        favList
            .map(
              (e) => FavoriteService.fromApi(e),
            )
            .toList(),
      );

      debugPrint(
        "FINAL FAVORITES COUNT => ${_favorites.length}",
      );

      notifyListeners();
    } else {
      debugPrint(
        "FETCH FAVORITES FAILED",
      );

      debugPrint(
        "FAILED STATUS CODE => ${response.statusCode}",
      );

      debugPrint(
        "FAILED RESPONSE => ${response.body}",
      );
    }
  } catch (e) {
    debugPrint(
      "FETCH FAVORITES ERROR => $e",
    );
  } finally {
    isLoading = false;

    notifyListeners();

    debugPrint(
      "================ FETCH FAVORITES END ================",
    );
  }
}
  /// =========================
  /// ADD FAVORITE
  /// =========================
  Future<void> addFavorite({
    required BuildContext context,
    required FavoriteService service,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );

      final token = userProvider.apiToken;

      final userId =
          int.tryParse(
            userProvider.backendUserId ?? '',
          ) ??
          0;

      if (token == null || token.isEmpty) {
        debugPrint("TOKEN IS NULL");
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}/save-favourite',
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "service_id": service.id,
          "user_id": userId,
        }),
      );

      debugPrint(
        "SAVE FAVORITE RESPONSE => ${response.body}",
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!isFavorite(service.id)) {
          _favorites.add(
            service.copyWith(
              isFavorite: true,
            ),
          );
        }

        notifyListeners();
      } else {
        debugPrint(
          "SAVE FAVORITE FAILED => ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(
        "ADD FAVORITE ERROR => $e",
      );
    }
  }

  /// =========================
  /// REMOVE FAVORITE
  /// =========================
  Future<void> removeFavorite({
    required BuildContext context,
    required int serviceId,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );

      final token = userProvider.apiToken;

      final userId =
          int.tryParse(
            userProvider.backendUserId ?? '',
          ) ??
          0;

      if (token == null || token.isEmpty) {
        debugPrint("TOKEN IS NULL");
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}/delete-favourite',
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "service_id": serviceId,
          "user_id": userId,
        }),
      );

      debugPrint(
        "DELETE FAVORITE RESPONSE => ${response.body}",
      );

      if (response.statusCode == 200) {
        _favorites.removeWhere(
          (s) => s.id == serviceId,
        );

        notifyListeners();
      } else {
        debugPrint(
          "DELETE FAVORITE FAILED => ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(
        "REMOVE FAVORITE ERROR => $e",
      );
    }
  }

  /// =========================
  /// TOGGLE FAVORITE
  /// =========================
  Future<void> toggleFavorite({
    required BuildContext context,
    required FavoriteService service,
  }) async {
    if (isFavorite(service.id)) {
      await removeFavorite(
        context: context,
        serviceId: service.id,
      );
    } else {
      await addFavorite(
        context: context,
        service: service,
      );
    }
  }

  /// =========================
  /// CLEAR FAVORITES
  /// =========================
  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }
}