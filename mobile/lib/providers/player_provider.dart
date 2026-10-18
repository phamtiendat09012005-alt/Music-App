import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _queue = mockSongs;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false; // Lặp lại bài hiện tại
  double _currentPosition = 0.0;
  int _totalDuration = 0;

  PlayerProvider() {
    _initAudioPlayer();
  }

  Song? get currentSong => _queue.isNotEmpty ? _queue[_currentIndex] : null;
  List<Song> get queue => _queue;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  double get currentPosition => _currentPosition;
  int get totalDuration =>
      _totalDuration > 0 ? _totalDuration : (currentSong?.duration ?? 180);

  void _initAudioPlayer() {
    // Lắng nghe vị trí phát hiện tại để cập nhật thanh trượt (Slider)
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position.inSeconds.toDouble();
      notifyListeners();
    });

    // Lắng nghe tổng thời lượng bài hát
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration.inSeconds;
        notifyListeners();
      }
    });

    // Lắng nghe trạng thái đang phát hay tạm dừng và khi hết bài
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        if (_isRepeat) {
          // Nếu bật nút Lặp bài nhạc -> tua về 0 và phát lại bài đó
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else {
          // Nếu không lặp -> tự động qua bài tiếp theo
          nextSong();
        }
      }
      notifyListeners();
    });
  }

  // Phát 1 bài hát được click vào
  Future<void> playSong(Song song, {List<Song>? customQueue}) async {
    if (customQueue != null && customQueue.isNotEmpty) {
      _queue = customQueue;
    }
    final index = _queue.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      _currentIndex = index;
    } else {
      _queue.add(song);
      _currentIndex = _queue.length - 1;
    }

    await _loadAndPlayCurrent();
  }

  Future<void> _loadAndPlayCurrent() async {
    final song = currentSong;
    if (song == null) return;

    _currentPosition = 0;
    _totalDuration = song.duration;
    notifyListeners();

    try {
      await _audioPlayer.setUrl(song.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      // Nếu đường link nhạc lỗi hoặc mất mạng, vẫn cho phép hiển thị trạng thái UI
      _isPlaying = true;
      notifyListeners();
    }
  }

  // Play / Pause
  void togglePlayPause() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == ProcessingState.idle &&
          currentSong != null) {
        _loadAndPlayCurrent();
      } else {
        _audioPlayer.play();
      }
    }
  }

  // Nút SKIP: Chuyển sang bài tiếp theo
  void nextSong() {
    if (_queue.isEmpty) return;
    if (_isShuffle && _queue.length > 1) {
      _currentIndex = Random().nextInt(_queue.length);
    } else {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    }
    _loadAndPlayCurrent();
  }

  // Nút BACK: Quay lại bài trước đó
  void previousSong() {
    if (_queue.isEmpty) return;
    // Nếu bài hát đã phát trên 3 giây thì bấm Back sẽ phát lại từ đầu bài đó
    if (_currentPosition > 3) {
      seek(0);
    } else {
      _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
      _loadAndPlayCurrent();
    }
  }

  // Tua nhạc
  void seek(double seconds) {
    _currentPosition = seconds;
    _audioPlayer.seek(Duration(seconds: seconds.toInt()));
    notifyListeners();
  }

  // Bật / Tắt phát ngẫu nhiên (Shuffle)
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  // Bật / Tắt lặp lại 1 bài hát (Repeat)
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    _audioPlayer.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
