import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
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

  Future<Playlist?> createPlaylist(String name, {Song? initialSong}) async {
    try {
      final created = await ApiService().createPlaylist(
        name,
        songIds: initialSong != null ? [initialSong.id] : null,
      );
      _playlists.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      debugPrint('Lỗi tạo Playlist trên MongoDB: $e');
      return null;
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

  /// Thêm bài hát vào Playlist (Cập nhật tức thì trên UI + Đồng bộ MongoDB)
  Future<bool> addSongToPlaylist(String playlistId, Song song) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return false;

    final current = _playlists[idx];
    final alreadyExists = current.songs.any((s) => s.id == song.id);
    if (!alreadyExists) {
      _playlists[idx] = current.copyWith(songs: [...current.songs, song]);
      notifyListeners();
    }

    try {
      final updated =
          await ApiService().addSongToPlaylist(playlistId, song.id);
      if (updated != null) {
        final newIdx = _playlists.indexWhere((p) => p.id == playlistId);
        if (newIdx != -1) {
          _playlists[newIdx] = updated;
          notifyListeners();
        }
      }
      return !alreadyExists;
    } catch (e) {
      debugPrint('Đồng bộ thêm bài hát vào Playlist: $e');
      return !alreadyExists;
    }
  }

  /// Xóa bài hát khỏi Playlist (Cập nhật tức thì trên UI + Đồng bộ MongoDB)
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    final current = _playlists[idx];
    _playlists[idx] = current.copyWith(
      songs: current.songs.where((s) => s.id != songId).toList(),
    );
    notifyListeners();

    try {
      final updated =
          await ApiService().removeSongFromPlaylist(playlistId, songId);
      if (updated != null) {
        final newIdx = _playlists.indexWhere((p) => p.id == playlistId);
        if (newIdx != -1) {
          _playlists[newIdx] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Đồng bộ xóa bài hát khỏi Playlist: $e');
    }
  }
}