import 'package:flutter/material.dart';
import 'package:zeerah/core/models/favorite_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<FavoriteService> _favorites = [];

  List<FavoriteService> get favorites => _favorites;

  bool isFavorite(int id) {
    return _favorites.any((s) => s.id == id);
  }

  void toggleFavorite(FavoriteService service) {
    if (isFavorite(service.id)) {
      _favorites.removeWhere((s) => s.id == service.id);
    } else {
      _favorites.add(service.copyWith(isFavorite: true));
    }
    notifyListeners();
  }
}
