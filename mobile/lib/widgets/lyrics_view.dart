import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';

export '../screens/karaoke_screen.dart';

class LyricLine {
  final double timeSec;
  final double? endTimeSec;
  final String text;

  const LyricLine({
    required this.timeSec,
    this.endTimeSec,
    required this.text,
  });

  LyricLine copyWith({
    double? timeSec,
    double? endTimeSec,
    String? text,
  }) {
    return LyricLine(
      timeSec: timeSec ?? this.timeSec,
      endTimeSec: endTimeSec ?? this.endTimeSec,
      text: text ?? this.text,
    );
  }
}

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  /// Kiểm tra nội dung lời bài hát từ MongoDB có nhãn thời gian đồng bộ (.LRC hoặc .SRT) hay không
  static bool hasSyncedTags(String raw) {
    if (raw.trim().isEmpty) return false;
    final tagRegex = RegExp(r'\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]');
    final srtRegex = RegExp(
      r'(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?\s*-->',
    );
    return tagRegex.hasMatch(raw) || srtRegex.hasMatch(raw);
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

  /// Bóc tách lời bài hát thực tế từ MongoDB (hỗ trợ .LRC, [start --> end], thẻ [offset:±ms], .SRT và văn bản thuần)
  static List<LyricLine> parseRawLyrics(String raw, int totalDuration) {
    final cleaned = raw.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
    if (cleaned.isEmpty) return const [];

    final lines = cleaned.split(RegExp(r'\r?\n'));
    final tagRegex = RegExp(r'\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]');
    final inlineTagRegex = RegExp(r'<\d{1,3}:\d{1,2}(?:\.\d{1,3})?>');
    final lrcRangeRegex = RegExp(
      r'^\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\s*-->\s*(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]\s*(.*)$',
    );
    final offsetRegex =
        RegExp(r'^\[offset:\s*([+-]?\d+)\s*\]$', caseSensitive: false);
    final srtArrowRegex = RegExp(
      r'^(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?\s*-->\s*(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?',
    );
    final metadataRegex = RegExp(
      r'^(\[(ti|ar|al|by|offset|re|ve|length):.*\]|WEBVTT.*)$',
      caseSensitive: false,
    );
    final indexOnlyRegex = RegExp(r'^\d+$');
    final htmlTagRegex = RegExp(r'<[^>]+>');

    double fileOffsetSec = 0.0;
    final List<LyricLine> synced = [];
    final List<String> plainLines = [];

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;

      final offsetMatch = offsetRegex.firstMatch(trimmed);
      if (offsetMatch != null) {
        final offsetMs = int.tryParse(offsetMatch.group(1) ?? '0') ?? 0;
        fileOffsetSec = offsetMs / 1000.0;
        continue;
      }

      if (metadataRegex.hasMatch(trimmed)) continue;

      // 1. Bỏ qua dòng số thứ tự câu (1, 2, 3...) của file .SRT
      if (indexOnlyRegex.hasMatch(trimmed) &&
          i + 1 < lines.length &&
          srtArrowRegex.hasMatch(lines[i + 1].trim())) {
        continue;
      }

      // 2. Xử lý định dạng [mm:ss.xx --> mm:ss.xx] Dòng lời
      final rangeMatch = lrcRangeRegex.firstMatch(trimmed);
      if (rangeMatch != null) {
        final sMins = int.tryParse(rangeMatch.group(1) ?? '0') ?? 0;
        final sSecs = double.tryParse(rangeMatch.group(2) ?? '0') ?? 0.0;
        final eMins = int.tryParse(rangeMatch.group(3) ?? '0') ?? 0;
        final eSecs = double.tryParse(rangeMatch.group(4) ?? '0') ?? 0.0;
        final textPart = (rangeMatch.group(5) ?? '')
            .replaceAll(inlineTagRegex, '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        final startSec =
            (sMins * 60.0 + sSecs + fileOffsetSec).clamp(0.0, 99999.0);
        final endSec =
            (eMins * 60.0 + eSecs + fileOffsetSec).clamp(0.0, 99999.0);
        if (textPart.isNotEmpty) {
          synced.add(
            LyricLine(
              timeSec: startSec,
              endTimeSec: endSec > startSec ? endSec : null,
              text: textPart,
            ),
          );
        }
        continue;
      }

      // 3. Xử lý định dạng phụ đề .SRT (VD: 00:00:04,500 --> 00:00:10,000)
      final srtMatch = srtArrowRegex.firstMatch(trimmed);
      if (srtMatch != null) {
        final rawStart = _parseSrtTime(
          srtMatch.group(1),
          srtMatch.group(2),
          srtMatch.group(3),
          srtMatch.group(4),
        );
        final rawEnd = _parseSrtTime(
          srtMatch.group(5),
          srtMatch.group(6),
          srtMatch.group(7),
          srtMatch.group(8),
        );
        final startSec =
            (rawStart + fileOffsetSec) > 0 ? (rawStart + fileOffsetSec) : 0.0;
        final endSec = (rawEnd + fileOffsetSec) > startSec
            ? (rawEnd + fileOffsetSec)
            : null;
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
              endTimeSec: endSec,
              text: textParts.join(' '),
            ),
          );
        }
        continue;
      }

      // 4. Xử lý định dạng .LRC (VD: [00:04.50] Dòng lời...)
      final matches = tagRegex.allMatches(trimmed).toList();
      if (matches.isNotEmpty) {
        final lyricText = trimmed
            .replaceAll(tagRegex, '')
            .replaceAll(inlineTagRegex, '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (lyricText.isEmpty ||
            lyricText == '♪' ||
            lyricText == '...' ||
            lyricText == '♪ ...') {
          final firstMatch = matches.first;
          final mins = int.tryParse(firstMatch.group(1) ?? '0') ?? 0;
          final secs = double.tryParse(firstMatch.group(2) ?? '0') ?? 0.0;
          final breakSec =
              (mins * 60.0 + secs + fileOffsetSec).clamp(0.0, 99999.0);
          if (synced.isNotEmpty &&
              synced.last.endTimeSec == null &&
              breakSec > synced.last.timeSec) {
            synced[synced.length - 1] =
                synced.last.copyWith(endTimeSec: breakSec);
          }
          continue;
        }

        for (final match in matches) {
          final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
          final seconds = double.tryParse(match.group(2) ?? '0') ?? 0.0;
          final rawSec = minutes * 60.0 + seconds + fileOffsetSec;
          synced.add(
            LyricLine(
              timeSec: rawSec > 0 ? rawSec : 0.0,
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
          endTimeSec: double.parse((step * (i + 1)).toStringAsFixed(1)),
          text: plainLines[i],
        ),
      );
    }
    return const [];
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
  String _lastSongId = '';
  int _lastScrolledIndex = -1;

  static const double _itemExtent = 52.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(String songId, int activeIndex) {
    if (_lastSongId != songId) {
      _lastSongId = songId;
      _lastScrolledIndex = -1;
    }
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
    final Song? song = player.currentSong;
    final lines = player.currentLyricLines;
    final activeIndex = player.activeLyricIndex;

    if (song != null && lines.isNotEmpty) {
      _scrollToActiveLine(song.id, activeIndex);
    }

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
                'Lời bài hát (MongoDB)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (lines.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    player.hasSyncedTimestamps
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
          // Thanh căn chỉnh lệch nhịp lời bài hát trực tiếp (-0.5s / +0.5s)
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    player.lyricOffset == 0.0
                        ? '⏱ Nhịp lời: Chuẩn (0.0s)'
                        : '⏱ Bù trễ lời: ${player.lyricOffset > 0 ? '+' : ''}${player.lyricOffset.toStringAsFixed(1)}s',
                    style: TextStyle(
                      fontSize: 11,
                      color: player.lyricOffset == 0.0
                          ? AppTheme.textGrey
                          : AppTheme.primaryGreen,
                      fontWeight: player.lyricOffset == 0.0
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => player.adjustLyricOffset(-0.5),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '-0.5s (Sớm hơn)',
                            style:
                                TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ),
                      ),
                      if (player.lyricOffset != 0.0) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => player.resetLyricOffset(),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '0.0s',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => player.adjustLyricOffset(0.5),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '+0.5s (Trễ hơn)',
                            style:
                                TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: player.isLoadingLyrics
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryGreen),
                        SizedBox(height: 10),
                        Text(
                          'Đang tải lời bài hát từ MongoDB...',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : lines.isEmpty
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
                                  : 'Bài hát "${song.title}" hiện chưa có lời (.LRC/.SRT) trên MongoDB.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 14,
                              ),
                            ),
                            if (song != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                  side: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                onPressed: () =>
                                    player.refreshCurrentSongFromMongo(),
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text(
                                  'Tải lại dữ liệu từ MongoDB',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemExtent: _itemExtent,
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          final isCurrentLine = index == activeIndex;
                          final isPastLine = index < activeIndex;

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => player.seek(
                              (line.timeSec + player.lyricOffset)
                                  .clamp(0.0, player.totalDuration.toDouble()),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
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
                                            : AppTheme.textGrey
                                                .withValues(alpha: 0.5),
                                        fontWeight: isCurrentLine
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 220),
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
