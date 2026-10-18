import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistProvider extends ChangeNotifier {
  final List<Playlist> _playlists = [
    Playlist(id: 'p1', name: 'Nhạc Học Bài', owner: 'user1', songs: [mockSongs[0], mockSongs[1]]),
    Playlist(id: 'p2', name: 'Chill Cuối Tuần', owner: 'user1', songs: [mockSongs[2]]),
  ];

  List<Playlist> get playlists => _playlists;

  void createPlaylist(String name) {
    _playlists.add(
      Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        owner: 'user1',
        songs: [],
      ),
    );
    notifyListeners();
  }

  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}