import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/playlist.dart';

class PlaylistProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Playlist> _playlists = [];
  bool _isLoading = false;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;

  Future<void> fetchPlaylists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _playlists = await _apiService.getPlaylists();
    } catch (e) {
      print('Lỗi tải playlists: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPlaylist(String name) async {
    try {
      final newPl = await _apiService.createPlaylist(name);
      _playlists.insert(0, newPl);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((pl) => pl.id == playlistId);
    notifyListeners();
    await _apiService.deletePlaylist(playlistId);
  }

  Future<void> addSong(String playlistId, String songId) async {
    await _apiService.addSongToPlaylist(playlistId, songId);
    await fetchPlaylists();
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await _apiService.removeSongFromPlaylist(playlistId, songId);
    await fetchPlaylists();
  }
}