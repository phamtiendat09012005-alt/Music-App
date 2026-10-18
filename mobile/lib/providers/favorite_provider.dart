import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/api_service.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Song> _favorites = [];

  FavoriteProvider() {
    fetchFavorites();
  }

  List<Song> get favorites => _favorites;

  Future<void> fetchFavorites() async {
    try {
      _favorites = await ApiService().getFavorites();
      notifyListeners();
    } catch (_) {
      // Chưa đăng nhập hoặc chưa có token
    }
  }

  bool isFavorite(String songId) {
    return _favorites.any((song) => song.id == songId);
  }

  Future<void> toggleFavorite(Song song) async {
    if (isFavorite(song.id)) {
      _favorites.removeWhere((item) => item.id == song.id);
    } else {
      _favorites.add(song);
    }
    notifyListeners();

    try {
      await ApiService().toggleFavorite(song.id);
    } catch (_) {}
  }
}