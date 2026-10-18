import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/api_service.dart';

class LyricLine {
  final double timeSec;
  final String text;

  const LyricLine({
    required this.timeSec,
    required this.text,
  });
}

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  static String buildFallbackLrc(String title, String artist) {
    return [
      '[00:00.00] ♪ $title - $artist',
      '[00:04.50] Giai điệu mở đầu nhẹ nhàng vang lên...',
      '[00:10.00] Đưa cảm xúc trôi theo từng nốt nhạc',
      '[00:16.50] Từng lời ca ngân vang giữa không gian',
      '[00:23.00] Khoảnh khắc bình yên lắng đọng trong tim',
      '[00:30.00] Điệp khúc cao trào đầy cảm xúc ($title)',
      '[00:38.00] Hòa quyện cùng giọng hát của $artist',
      '[00:46.00] Giai điệu còn mãi ngân nga...',
      '[00:54.00] ♪ Kết thúc bản nhạc ♪',
    ].join('\n');
  }

  static double _parseSrtTime(
    String? hoursStr,
    String? minsStr,
    String? secsStr,
    String? msStr,
  ) {
    final hours = hoursStr != null ? (int.tryParse(hoursStr) ?? 0) : 0;
    final mins = int.tryParse(minsStr ?? '0') ?? 0;
    final secs = int.tryParse(secsStr ?? '0') ?? 0;
    final ms = (msStr != null && msStr.isNotEmpty)
        ? (double.tryParse('0.$msStr') ?? 0.0)
        : 0.0;
    return hours * 3600.0 + mins * 60.0 + secs + ms;
  }

  static List<LyricLine> parseRawLyrics(String raw, int totalDuration) {
    final cleaned = raw.replaceFirst(RegExp(r'^\uFEFF'), '');
    final lines = cleaned.split(RegExp(r'\r?\n'));
    final tagRegex = RegExp(r'\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]');
    final srtArrowRegex = RegExp(
      r'^(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?\s*-->\s*(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?',
    );
    final metadataRegex = RegExp(
      r'^(\[(ti|ar|al|by|offset):.*\]|WEBVTT.*)$',
      caseSensitive: false,
    );
    final indexOnlyRegex = RegExp(r'^\d+$');
    final htmlTagRegex = RegExp(r'<[^>]+>');

    final List<LyricLine> synced = [];
    final List<String> plainLines = [];

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty || metadataRegex.hasMatch(trimmed)) continue;

      // 1. Bỏ qua dòng số thứ tự câu (1, 2, 3...) của file .SRT
      if (indexOnlyRegex.hasMatch(trimmed) &&
          i + 1 < lines.length &&
          srtArrowRegex.hasMatch(lines[i + 1].trim())) {
        continue;
      }

      // 2. Xử lý định dạng phụ đề .SRT (VD: 00:00:04,500 --> 00:00:10,000)
      final srtMatch = srtArrowRegex.firstMatch(trimmed);
      if (srtMatch != null) {
        final startSec = _parseSrtTime(
          srtMatch.group(1),
          srtMatch.group(2),
          srtMatch.group(3),
          srtMatch.group(4),
        );
        final List<String> textParts = [];
        int j = i + 1;
        while (j < lines.length) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) break;
          if (indexOnlyRegex.hasMatch(nextLine) &&
              j + 1 < lines.length &&
              srtArrowRegex.hasMatch(lines[j + 1].trim())) {
            break;
          }
          if (srtArrowRegex.hasMatch(nextLine)) break;
          final stripped = nextLine.replaceAll(htmlTagRegex, '').trim();
          if (stripped.isNotEmpty) {
            textParts.add(stripped);
          }
          j++;
        }
        i = j - 1;
        if (textParts.isNotEmpty) {
          synced.add(
            LyricLine(
              timeSec: startSec,
              text: textParts.join(' '),
            ),
          );
        }
        continue;
      }

      // 3. Xử lý định dạng .LRC (VD: [00:04.50] Dòng lời...)
      final matches = tagRegex.allMatches(trimmed).toList();
      if (matches.isNotEmpty) {
        final lyricText = trimmed.replaceAll(tagRegex, '').trim();
        if (lyricText.isEmpty) continue;
        for (final match in matches) {
          final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
          final seconds = double.tryParse(match.group(2) ?? '0') ?? 0.0;
          synced.add(
            LyricLine(
              timeSec: minutes * 60.0 + seconds,
              text: lyricText,
            ),
          );
        }
      } else {
        plainLines.add(trimmed);
      }
    }

    if (synced.isNotEmpty) {
      synced.sort((a, b) => a.timeSec.compareTo(b.timeSec));
      return synced;
    } else if (plainLines.isNotEmpty) {
      final effectiveDuration =
          (totalDuration > 0 ? totalDuration : 180).toDouble();
      final step = effectiveDuration / (plainLines.length + 1);
      return List.generate(
        plainLines.length,
        (i) => LyricLine(
          timeSec: double.parse((step * i).toStringAsFixed(1)),
          text: plainLines[i],
        ),
      );
    }
    return [];
  }

  static int findActiveIndex(List<LyricLine> lines, double currentPosition) {
    if (lines.isEmpty) return -1;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentPosition >= lines[i].timeSec) {
        return i;
      }
    }
    return 0;
  }

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  String _loadedSongId = '';
  String _loadedLyricsHash = '';
  bool _isLoadingUrl = false;
  String _rawLyrics = '';
  List<LyricLine> _parsedLines = [];
  bool _hasSyncedTimestamps = false;
  int _lastScrolledIndex = -1;

  static const double _itemExtent = 52.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureLyricsLoaded(Song? song, int totalDuration) {
    if (song == null) {
      _loadedSongId = '';
      _loadedLyricsHash = '';
      _isLoadingUrl = false;
      _rawLyrics = '';
      _parsedLines = [];
      _hasSyncedTimestamps = false;
      _lastScrolledIndex = -1;
      return;
    }

    final currentHash = '${song.id}_${song.lyrics.length}_${song.lyricsUrl}';
    if (_loadedSongId == song.id && _loadedLyricsHash == currentHash) return;
    _loadedSongId = song.id;
    _loadedLyricsHash = currentHash;
    _lastScrolledIndex = -1;

    // 1. Ưu tiên lấy nội dung lời bài hát lưu trực tiếp trong MongoDB (song.lyrics)
    if (song.lyrics.trim().isNotEmpty) {
      _isLoadingUrl = false;
      _rawLyrics = song.lyrics;
      _parseLyrics(_rawLyrics, totalDuration);
      return;
    }

    // 2. Nếu song.lyrics trống nhưng có đường dẫn file .lrc (lyricsUrl), tải về từ URL
    if (song.lyricsUrl.trim().isNotEmpty) {
      _isLoadingUrl = true;
      _rawLyrics = '';
      _parsedLines = [];
      _hasSyncedTimestamps = false;
      _fetchRemoteLyrics(song, totalDuration);
      return;
    }

    // 3. Nếu bài hát cũ chưa kịp đồng bộ lyrics từ DB, tạo lời .lrc đồng bộ mặc định theo tên bài hát
    _isLoadingUrl = false;
    _rawLyrics = LyricsView.buildFallbackLrc(song.title, song.artist);
    _parseLyrics(_rawLyrics, totalDuration);
  }

  Future<void> _fetchRemoteLyrics(
    Song song,
    int totalDuration,
  ) async {
    final fetched = await ApiService().fetchLyricsFromUrl(song.lyricsUrl);
    if (!mounted || _loadedSongId != song.id) return;
    setState(() {
      _isLoadingUrl = false;
      _rawLyrics = fetched.trim().isNotEmpty
          ? fetched
          : LyricsView.buildFallbackLrc(song.title, song.artist);
      _parseLyrics(_rawLyrics, totalDuration);
    });
  }

  void _parseLyrics(String raw, int totalDuration) {
    final tagRegex = RegExp(r'\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]');
    final srtRegex = RegExp(
      r'(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?\s*-->',
    );
    _hasSyncedTimestamps = tagRegex.hasMatch(raw) || srtRegex.hasMatch(raw);
    _parsedLines = LyricsView.parseRawLyrics(raw, totalDuration);
  }

  int _findActiveLineIndex(double currentPosition) {
    return LyricsView.findActiveIndex(_parsedLines, currentPosition);
  }

  void _scrollToActiveLine(int activeIndex) {
    if (activeIndex < 0 || activeIndex == _lastScrolledIndex) return;
    _lastScrolledIndex = activeIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetOffset =
          (activeIndex * _itemExtent) - (viewportHeight / 2) + (_itemExtent / 2);
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatTimestamp(double seconds) {
    final totalSec = seconds.floor();
    final mins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    _ensureLyricsLoaded(song, player.totalDuration);

    final activeIndex = _findActiveLineIndex(player.currentPosition);
    _scrollToActiveLine(activeIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lời bài hát',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_parsedLines.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _hasSyncedTimestamps
                        ? 'Đồng bộ .LRC/.SRT • Chạm để tua'
                        : 'Tự động cuộn • Chạm để tua',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingUrl
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  )
                : _parsedLines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lyrics_outlined,
                              size: 44,
                              color: AppTheme.textGrey,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              song == null
                                  ? 'Chưa chọn bài hát'
                                  : 'Bài hát "${song.title}" hiện chưa có lời bài hát.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemExtent: _itemExtent,
                        itemCount: _parsedLines.length,
                        itemBuilder: (context, index) {
                          final line = _parsedLines[index];
                          final isCurrentLine = index == activeIndex;
                          final isPastLine = index < activeIndex;

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => player.seek(line.timeSec),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 42,
                                    child: Text(
                                      _formatTimestamp(line.timeSec),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isCurrentLine
                                            ? AppTheme.primaryGreen
                                            : AppTheme.textGrey.withValues(alpha: 0.5),
                                        fontWeight: isCurrentLine
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 220),
                                      style: TextStyle(
                                        fontSize: isCurrentLine ? 18 : 15,
                                        fontWeight: isCurrentLine
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isCurrentLine
                                            ? AppTheme.primaryGreen
                                            : isPastLine
                                                ? Colors.white70
                                                : AppTheme.textGrey,
                                      ),
                                      child: Text(
                                        line.text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}