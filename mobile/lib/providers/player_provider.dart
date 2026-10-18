import 'package:flutter/material.dart';
import '../models/song.dart';

class PlayerProvider extends ChangeNotifier {
  Song? _currentSong = mockSongs[0]; // Mặc định có 1 bài để hiển thị MiniPlayer
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _currentPosition = 45.0; // Giả lập đang phát ở giây 45

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  double get currentPosition => _currentPosition;

  void playSong(Song song) {
    _currentSong = song;
    _isPlaying = true;
    _currentPosition = 0;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void seek(double seconds) {
    _currentPosition = seconds;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }
}