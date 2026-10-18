import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../services/audio_handler.dart';
import '../services/lyrics_parser.dart';

class PlayerProvider extends ChangeNotifier {
  final MyAudioHandler _audioHandler;

  Song? _currentSong;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isShuffle = false;
  LoopModeState _loopMode = LoopModeState.off;

  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = 0;

  // Xử lý ghi lịch sử (POST /api/history khi nghe > 30s)
  bool _hasLoggedHistory = false;
  void Function(String songId)? onTrackListenedOver30s;

  PlayerProvider(this._audioHandler) {
    _audioHandler.onSongStarted = _handleSongStarted;
    _listenToStreams();
  }

  // Các getter cung cấp cho UI (NowPlayingScreen & MiniPlayer)
  Song? get currentSong => _currentSong;
  List<Song> get playlist => _audioHandler.playlist;
  int get currentIndex => _audioHandler.currentIndex;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  LoopModeState get loopMode => _loopMode;
  List<LyricLine> get lyrics => _lyrics;
  int get currentLyricIndex => _currentLyricIndex;

  void _handleSongStarted(Song song) {
    _hasLoggedHistory = false;
  }

  void _listenToStreams() {
    _audioHandler.player.positionStream.listen((pos) {
      _position = pos;
      _updateLyricIndex(pos);

      if (!_hasLoggedHistory && pos.inSeconds >= 30 && _currentSong != null) {
        _hasLoggedHistory = true;
        if (onTrackListenedOver30s != null) {
          onTrackListenedOver30s!(_currentSong!.id);
        }
      }
      notifyListeners();
    });

    _audioHandler.player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _audioHandler.player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioHandler.mediaItem.listen((item) {
      if (item != null &&
          _audioHandler.currentIndex >= 0 &&
          _audioHandler.currentIndex < _audioHandler.playlist.length) {
        _currentSong = _audioHandler.playlist[_audioHandler.currentIndex];
        _loadLyrics(_currentSong?.lyricsUrl);
        notifyListeners();
      }
    });
  }

  void playPlaylist(List<Song> songs, int index) {
    _audioHandler.setQueue(songs, index);
  }

  void playOrPause() {
    if (_isPlaying) {
      _audioHandler.pause();
    } else {
      _audioHandler.play();
    }
  }

  void seek(Duration pos) => _audioHandler.seek(pos);
  void next() => _audioHandler.skipToNext();
  void previous() => _audioHandler.skipToPrevious();

  /// Nhảy trực tiếp tới bài hát ở vị trí [index] trong hàng đợi
  void skipToQueueItem(int index) {
    _audioHandler.skipToIndex(index);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _audioHandler.setShuffleMode(
      _isShuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    notifyListeners();
  }

  void toggleRepeat() {
    if (_loopMode == LoopModeState.off) {
      _loopMode = LoopModeState.all;
      _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
    } else if (_loopMode == LoopModeState.all) {
      _loopMode = LoopModeState.one;
      _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
    } else {
      _loopMode = LoopModeState.off;
      _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
    }
    notifyListeners();
  }

  Future<void> _loadLyrics(String? url) async {
    _lyrics = [];
    _currentLyricIndex = 0;
    if (url == null || url.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        _lyrics = LyricsParser.parse(res.body);
      }
    } catch (e) {
      print('Không tải được lời bài hát: $e');
    }
    notifyListeners();
  }

  void _updateLyricIndex(Duration currentPos) {
    if (_lyrics.isEmpty) return;
    int index = _lyrics.lastIndexWhere((line) => line.time <= currentPos);
    if (index != -1 && index != _currentLyricIndex) {
      _currentLyricIndex = index;
      notifyListeners();
    }
  }
}

enum LoopModeState { off, all, one }