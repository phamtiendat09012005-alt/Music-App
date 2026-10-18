import 'package:flutter/material.dart';
import '../models/song.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Song> _favorites = [mockSongs[0]];

  List<Song> get favorites => _favorites;

  bool isFavorite(String songId) {
    return _favorites.any((song) => song.id == songId);
  }

  void toggleFavorite(Song song) {
    if (isFavorite(song.id)) {
      _favorites.removeWhere((item) => item.id == song.id);
    } else {
      _favorites.add(song);
    }
    notifyListeners();
  }
}