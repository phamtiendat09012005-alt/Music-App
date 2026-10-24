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
  int _viewMode = 0; // 0: Đĩa nhạc, 1: Lời bài hát (.LRC), 2: Chế độ Karaoke 🎤
  bool _isBeatMode = false; // Bật/Tắt chế độ Nhạc Beat (Tách lời / Đệm hát)
  double _beatVolume = 0.9; // Âm lượng nhạc nền khi hát Karaoke
  double _currentPosition = 0.0;
  int _totalDuration = 0;

  // Bộ nhớ đệm (cache) lời bài hát lấy từ MongoDB cho bài hiện tại
  String _cachedLyricsKey = '';
  List<LyricLine> _cachedLyricLines = [];
  bool _hasSyncedTimestamps = false;
  bool _isLoadingLyrics = false;
  String _lastSyncedSongId = '';
  double _lyricOffset = 0.0; // Độ trễ căn chỉnh lời bài hát (giây): âm = chữ hiện sớm hơn, dương = chữ hiện trễ hơn

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
  int get viewMode => _viewMode;
  bool get showLyrics => _viewMode == 1;
  bool get isKaraokeMode => _viewMode == 2;
  bool get isBeatMode => _isBeatMode;
  double get beatVolume => _beatVolume;
  bool get isLoadingLyrics => _isLoadingLyrics;
  bool get hasSyncedTimestamps => _hasSyncedTimestamps;
  double get lyricOffset => _lyricOffset;
  double get currentPosition => _currentPosition;
  // Vị trí thời gian thực tế dùng để so khớp lời bài hát sau khi trừ bù độ trễ (offset)
  double get effectiveLyricPosition =>
      (_currentPosition - _lyricOffset).clamp(0.0, totalDuration.toDouble());
  int get totalDuration =>
      _totalDuration > 0 ? _totalDuration : (currentSong?.duration ?? 180);

  void adjustLyricOffset(double deltaSeconds) {
    _lyricOffset = double.parse(
      (_lyricOffset + deltaSeconds).clamp(-15.0, 15.0).toStringAsFixed(1),
    );
    notifyListeners();
  }

  void resetLyricOffset() {
    if (_lyricOffset != 0.0) {
      _lyricOffset = 0.0;
      notifyListeners();
    }
  }

  // Lấy danh sách câu hát thực tế từ MongoDB (không dùng lời giả lập)
  List<LyricLine> get currentLyricLines {
    final song = currentSong;
    if (song == null) return const [];
    final raw = song.lyrics.trim();
    if (raw.isEmpty) {
      _cachedLyricsKey = '';
      _cachedLyricLines = const [];
      _hasSyncedTimestamps = false;
      return const [];
    }
    final key = '${song.id}_${raw.length}_$totalDuration';
    if (_cachedLyricsKey != key) {
      _cachedLyricsKey = key;
      _hasSyncedTimestamps = LyricsView.hasSyncedTags(raw);
      _cachedLyricLines = LyricsView.parseRawLyrics(raw, totalDuration);
    }
    return _cachedLyricLines;
  }

  int get activeLyricIndex =>
      LyricsView.findActiveIndex(currentLyricLines, effectiveLyricPosition);

  // Đếm nhịp 3 - 2 - 1 (số chấm tròn sáng lên trước khi vào câu hát đầu tiên hoặc sau đoạn nhạc dạo dài)
  int get countdownSecondsToNextLine {
    final lines = currentLyricLines;
    if (lines.isEmpty) return 0;

    final pos = effectiveLyricPosition;
    // Kiểm tra trước khi vào câu đầu tiên
    if (pos < lines.first.timeSec) {
      final remain = lines.first.timeSec - pos;
      if (remain > 0 && remain <= 3.5) {
        return remain.ceil().clamp(1, 3);
      }
    }

    // Hoặc trong khoảng nghỉ nhạc dạo dài giữa 2 câu (> 6 giây)
    final idx = activeLyricIndex;
    if (idx >= 0 && idx + 1 < lines.length) {
      final nextStart = lines[idx + 1].timeSec;
      final gap = nextStart - lines[idx].timeSec;
      final remain = nextStart - pos;
      if (gap >= 6.0 && remain > 0 && remain <= 3.2) {
        return remain.ceil().clamp(1, 3);
      }
    }
    return 0;
  }

  void setViewMode(int mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void setShowLyrics(bool value) {
    final targetMode = value ? 1 : 0;
    if (_viewMode != targetMode) {
      _viewMode = targetMode;
      notifyListeners();
    }
  }

  void toggleShowLyrics() {
    _viewMode = (_viewMode == 0) ? 1 : 0;
    notifyListeners();
  }

  // Bật / Tắt chế độ Nhạc Beat (Karaoke Instrumental / Giảm lời ca sĩ)
  Future<void> toggleBeatMode() async {
    await setBeatMode(!_isBeatMode);
  }

  Future<void> setBeatMode(bool enable) async {
    if (_isBeatMode == enable) return;
    _isBeatMode = enable;
    notifyListeners();

    final song = currentSong;
    if (song == null) return;

    // Trường hợp 1: Bài hát có file nhạc Beat (instrumentalUrl) riêng -> Chuyển luồng nhạc giữ nguyên vị trí giây
    if (song.hasInstrumental) {
      final targetUrl = _isBeatMode ? song.instrumentalUrl : song.audioUrl;
      final savedPos = _currentPosition;
      final wasPlaying = _isPlaying;
      try {
        await _audioPlayer.setUrl(targetUrl);
        await _audioPlayer.setVolume(_beatVolume);
        await _audioPlayer.seek(Duration(milliseconds: (savedPos * 1000).round()));
        if (wasPlaying) {
          await _audioPlayer.play();
        }
      } catch (_) {
        // Nếu URL beat lỗi, quay về chế độ giảm âm giọng hát dự phòng
        await _applyEffectiveVolume();
      }
    } else {
      // Trường hợp 2: Chưa có file Beat riêng -> Bật chế độ Đệm Hát (Vocal Ducking / Giảm lời gốc để hát đè lên)
      await _applyEffectiveVolume();
    }
    notifyListeners();
  }

  Future<void> setBeatVolume(double volume) async {
    _beatVolume = volume.clamp(0.1, 1.0);
    await _applyEffectiveVolume();
    notifyListeners();
  }

  Future<void> _applyEffectiveVolume() async {
    final song = currentSong;
    double effective = _beatVolume;
    if (_isBeatMode && (song == null || !song.hasInstrumental)) {
      // Khi bật chế độ Beat trên nhạc gốc có lời: hạ nhẹ nền xuống 55% để giọng người hát nổi bật hơn
      effective = (_beatVolume * 0.55).clamp(0.15, 0.85);
    }
    try {
      await _audioPlayer.setVolume(effective);
    } catch (_) {}
  }

  // Nạp và đồng bộ dữ liệu bài hát mới nhất (bao gồm lyrics & instrumentalUrl) từ MongoDB vào hàng đợi
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
    _syncCurrentSongFromMongo();
  }

  // Đồng bộ lời bài hát (.LRC/.SRT) & nhạc Beat của bài đang phát trực tiếp từ MongoDB
  Future<void> _syncCurrentSongFromMongo({bool forceRefresh = false}) async {
    final song = currentSong;
    if (song == null || song.id.trim().isEmpty) return;

    if (!forceRefresh &&
        _lastSyncedSongId == song.id &&
        song.lyrics.trim().isNotEmpty) {
      return;
    }
    _lastSyncedSongId = song.id;
    final targetId = song.id;

    final needsRemoteFetch = song.lyrics.trim().isEmpty;
    if (needsRemoteFetch) {
      _isLoadingLyrics = true;
      notifyListeners();
    }

    try {
      // 1. Lấy bản ghi bài hát mới nhất trực tiếp từ MongoDB (GET /api/songs/:id)
      Song? freshSong = await ApiService().getSongById(targetId);
      Song updatedSong = freshSong ?? song;

      // 2. Nếu trong MongoDB trường lyrics đang trống nhưng có file lyricsUrl (.lrc/.srt trên Cloudinary), tải nội dung về
      if (updatedSong.lyrics.trim().isEmpty &&
          updatedSong.lyricsUrl.trim().isNotEmpty) {
        final fetchedText =
            await ApiService().fetchLyricsFromUrl(updatedSong.lyricsUrl);
        if (fetchedText.trim().isNotEmpty) {
          updatedSong = updatedSong.copyWith(lyrics: fetchedText.trim());
        }
      }

      // 3. Cập nhật lại bài hát trong hàng đợi để cả LyricsView, KaraokeView và NowPlayingScreen cùng nhận dữ liệu MongoDB
      final idx = _queue.indexWhere((s) => s.id == targetId);
      if (idx != -1) {
        _queue[idx] = updatedSong;
      }
    } catch (_) {
      // Giữ nguyên dữ liệu hiện có nếu mất kết nối tạm thời
    } finally {
      if (currentSong?.id == targetId) {
        _isLoadingLyrics = false;
        notifyListeners();
      }
    }
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!_isPlaying || _audioPlayer.playing) return;

      final maxDur = totalDuration.toDouble();
      if (_currentPosition + 0.15 < maxDur) {
        _currentPosition += 0.15;
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
    // Ở chế độ Lời bài hát (_viewMode == 1) và Karaoke (_viewMode == 2), cập nhật mỗi 70ms để bắt nhịp chữ chuẩn xác;
    // Ở chế độ Đĩa nhạc (_viewMode == 0), giữ throttle 150ms để tiết kiệm CPU trên máy ảo Android
    _audioPlayer.positionStream.listen((position) {
      final newPos = position.inMilliseconds / 1000.0;
      final threshold = (_viewMode == 0) ? 0.15 : 0.07;
      if ((newPos - _currentPosition).abs() >= threshold || newPos < 0.12) {
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

  Future<void> refreshCurrentSongFromMongo() async {
    await _syncCurrentSongFromMongo(forceRefresh: true);
  }

  Future<void> _loadAndPlayCurrent() async {
    final song = currentSong;
    if (song == null) return;

    _stopFallbackTimer();
    _currentPosition = 0;
    _lyricOffset = 0.0;
    _totalDuration = song.duration > 0 ? song.duration : 180;
    _isPlaying = true;
    notifyListeners();

    // Đồng bộ lyrics & instrumentalUrl mới nhất của bài hát từ MongoDB
    _syncCurrentSongFromMongo();

    final targetUrl =
        (_isBeatMode && song.hasInstrumental) ? song.instrumentalUrl : song.audioUrl;

    try {
      await _audioPlayer.stop();
      await _applyEffectiveVolume();
      await _audioPlayer.setUrl(targetUrl);
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

  // Hát lại câu hiện tại (Rewind current lyric line)
  void replayCurrentLine() {
    final lines = currentLyricLines;
    final idx = activeLyricIndex;
    if (lines.isNotEmpty && idx >= 0 && idx < lines.length) {
      seek(lines[idx].timeSec);
    } else {
      seek(0);
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
