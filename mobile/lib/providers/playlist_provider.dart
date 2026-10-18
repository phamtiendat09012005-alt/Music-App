import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  bool _isLoading = false;

  PlaylistProvider() {
    fetchPlaylists();
  }

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;

  Future<void> fetchPlaylists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _playlists = await ApiService().getPlaylists();
    } catch (e) {
      debugPrint('Lỗi tải danh sách Playlist từ MongoDB: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      final created = await ApiService().createPlaylist(name);
      _playlists.insert(0, created);
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tạo Playlist trên MongoDB: $e');
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await ApiService().deletePlaylist(id);
      _playlists.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi xóa Playlist trên MongoDB: $e');
    }
  }
}