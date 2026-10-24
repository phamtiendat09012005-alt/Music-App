import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../core/theme.dart';

/// Mini player dạng thẻ nổi: ảnh bìa, tên bài, lời đang chạy, thanh tiến độ gradient mảnh.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) return const SizedBox.shrink();

    final lines = player.currentLyricLines;
    final activeIdx = player.activeLyricIndex;
    final currentLyricText =
        (activeIdx >= 0 && activeIdx < lines.length) ? lines[activeIdx].text : '';
    final total = player.totalDuration.toDouble();
    final progress =
        total > 0 ? (player.currentPosition / total).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push('/now-playing'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.glow(AppTheme.accentPink, 0.25),
                    ),
                    child: CoverImage(url: song.coverUrl, size: 48, radius: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentLyricText.isNotEmpty
                              ? '♪ $currentLyricText'
                              : song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: currentLyricText.isNotEmpty
                                ? AppTheme.accent
                                : AppTheme.textGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hát Karaoke',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.mic_rounded,
                        color: AppTheme.accentPink, size: 22),
                    onPressed: () {
                      player.setViewMode(2);
                      context.push('/now-playing');
                    },
                  ),
                  GestureDetector(
                    onTap: () => player.togglePlayPause(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bài tiếp theo',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white, size: 26),
                    onPressed: () => player.nextSong(),
                  ),
                ],
              ),
            ),
            // Thanh tiến độ gradient
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    Container(height: 3, color: Colors.white12),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.accentGradient,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
