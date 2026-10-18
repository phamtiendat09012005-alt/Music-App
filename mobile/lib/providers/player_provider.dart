import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../widgets/lyrics_view.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _fallbackTimer;

  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false; // Lặp lại bài hiện tại
  bool _showLyrics = false; // Trạng thái mở màn hình Lời bài hát (.LRC)
  double _currentPosition = 0.0;
  int _totalDuration = 0;

  // Bộ nhớ đệm (cache) lời bài hát đã bóc tách cho bài hiện tại để tránh chạy Regex liên tục gây rè tiếng trên máy ảo Android
  String _cachedLyricsKey = '';
  List<LyricLine> _cachedLyricLines = [];

  PlayerProvider() {
    _initAudioPlayer();
  }

  Song? get currentSong =>
      (_queue.isNotEmpty && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;
  List<Song> get queue => _queue;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get showLyrics => _showLyrics;
  double get currentPosition => _currentPosition;
  int get totalDuration =>
      _totalDuration > 0 ? _totalDuration : (currentSong?.duration ?? 180);

  // Lấy danh sách câu hát đã được cache (chỉ parse 1 lần duy nhất khi đổi bài)
  List<LyricLine> get currentLyricLines {
    final song = currentSong;
    if (song == null) return const [];
    final key = '${song.id}_${song.lyrics.length}_$totalDuration';
    if (_cachedLyricsKey != key) {
      _cachedLyricsKey = key;
      final raw = song.lyrics.trim().isNotEmpty
          ? song.lyrics
          : LyricsView.buildFallbackLrc(song.title, song.artist);
      _cachedLyricLines = LyricsView.parseRawLyrics(raw, totalDuration);
    }
    return _cachedLyricLines;
  }

  int get activeLyricIndex =>
      LyricsView.findActiveIndex(currentLyricLines, _currentPosition);

  void setShowLyrics(bool value) {
    if (_showLyrics != value) {
      _showLyrics = value;
      notifyListeners();
    }
  }

  void toggleShowLyrics() {
    _showLyrics = !_showLyrics;
    notifyListeners();
  }

  // Nạp và đồng bộ dữ liệu bài hát mới nhất (bao gồm lyrics) từ MongoDB vào hàng đợi
  void setInitialQueue(List<Song> songs) {
    if (songs.isEmpty) return;
    if (_queue.isEmpty) {
      _queue = List<Song>.from(songs);
      _currentIndex = 0;
    } else {
      final currentId = currentSong?.id;
      _queue = _queue.map((oldSong) {
        final fresh = songs.where((s) => s.id == oldSong.id);
        return fresh.isNotEmpty ? fresh.first : oldSong;
      }).toList();
      if (currentId != null) {
        final idx = _queue.indexWhere((s) => s.id == currentId);
        if (idx != -1) _currentIndex = idx;
      }
    }
    notifyListeners();
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!_isPlaying || _audioPlayer.playing) return;

      final maxDur = totalDuration.toDouble();
      if (_currentPosition + 0.3 < maxDur) {
        _currentPosition += 0.3;
        notifyListeners();
      } else {
        if (_isRepeat) {
          _currentPosition = 0.0;
          notifyListeners();
        } else {
          nextSong();
        }
      }
    });
  }

  void _stopFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  void _initAudioPlayer() {
    // Giới hạn tần suất cập nhật UI (throttle >= 180ms) để giảm tải CPU trên máy ảo Android,
    // tránh hiện tượng nghẽn bộ đệm âm thanh (audio buffer underrun) gây tiếng nổ lách tách
    _audioPlayer.positionStream.listen((position) {
      final newPos = position.inMilliseconds / 1000.0;
      if ((newPos - _currentPosition).abs() >= 0.18 || newPos < 0.2) {
        _currentPosition = newPos;
        notifyListeners();
      }
    });

    // Lắng nghe tổng thời lượng bài hát
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null && duration.inSeconds > 0) {
        if (_totalDuration != duration.inSeconds) {
          _totalDuration = duration.inSeconds;
          notifyListeners();
        }
      }
    });

    // Lắng nghe trạng thái đang phát hay tạm dừng và khi hết bài
    _audioPlayer.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      if (state.playing) {
        _isPlaying = true;
        _stopFallbackTimer();
      }
      if (state.processingState == ProcessingState.completed) {
        if (_isRepeat) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else {
          nextSong();
        }
        return;
      }
      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }
    });
  }

  // Phát 1 bài hát được click vào
  Future<void> playSong(Song song, {List<Song>? customQueue}) async {
    if (customQueue != null && customQueue.isNotEmpty) {
      _queue = List<Song>.from(customQueue);
    }
    final index = _queue.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      _queue[index] = song;
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

    _stopFallbackTimer();
    _currentPosition = 0;
    _totalDuration = song.duration > 0 ? song.duration : 180;
    _isPlaying = true;
    notifyListeners();

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(0.9); // Giữ mức âm lượng 90% để tránh clipping/vỡ tiếng trên loa máy ảo
      await _audioPlayer.setUrl(song.audioUrl);
      await _audioPlayer.play();
      ApiService().recordPlay(song.id);
    } catch (e) {
      // Chỉ bật bộ đếm dự phòng khi đường link nhạc thực sự lỗi hoặc mất mạng
      _isPlaying = true;
      _startFallbackTimer();
      notifyListeners();
    }
  }

  // Play / Pause
  void togglePlayPause() {
    if (_isPlaying) {
      _isPlaying = false;
      _stopFallbackTimer();
      _audioPlayer.pause();
      notifyListeners();
    } else {
      _isPlaying = true;
      if (_audioPlayer.processingState == ProcessingState.idle &&
          currentSong != null) {
        _loadAndPlayCurrent();
      } else {
        _audioPlayer.play();
      }
      notifyListeners();
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

  // Tua nhạc (hỗ trợ độ chính xác mili-giây khi chạm vào từng câu lời bài hát .lrc)
  void seek(double seconds) {
    _currentPosition = seconds;
    try {
      _audioPlayer.seek(Duration(milliseconds: (seconds * 1000).round()));
    } catch (_) {}
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
    _stopFallbackTimer();
    _audioPlayer.dispose();
    super.dispose();
  }
}
