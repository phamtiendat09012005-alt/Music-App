import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/song.dart';

class FavoriteProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Song> _favorites = [];
  bool _isLoading = false;

  List<Song> get favorites => _favorites;
  bool get isLoading => _isLoading;

  bool isFavorite(String songId) {
    return _favorites.any((s) => s.id == songId);
  }

  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      _favorites = await _apiService.getFavorites();
    } catch (e) {
      print('Lỗi tải favorites: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    final exists = isFavorite(song.id);
    if (exists) {
      _favorites.removeWhere((s) => s.id == song.id);
      notifyListeners();
      try {
        await _apiService.removeFavorite(song.id);
      } catch (_) {
        _favorites.add(song);
        notifyListeners();
      }
    } else {
      _favorites.add(song);
      notifyListeners();
      try {
        await _apiService.addFavorite(song.id);
      } catch (_) {
        _favorites.removeWhere((s) => s.id == song.id);
        notifyListeners();
      }
    }
  }
}