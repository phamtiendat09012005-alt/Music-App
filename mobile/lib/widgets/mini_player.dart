import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../core/theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/now-playing'),
      child: Container(
        height: 66,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                song.coverUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
                  color: AppTheme.surfaceBlack,
                  child: const Icon(Icons.music_note,
                      color: AppTheme.primaryGreen),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style:
                        const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Lặp bài',
              icon: Icon(
                player.isRepeat
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color:
                    player.isRepeat ? AppTheme.primaryGreen : AppTheme.textGrey,
                size: 20,
              ),
              onPressed: () => player.toggleRepeat(),
            ),
            IconButton(
              tooltip: 'Bài trước',
              icon: const Icon(Icons.skip_previous_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => player.previousSong(),
            ),
            IconButton(
              tooltip: player.isPlaying ? 'Tạm dừng' : 'Phát',
              icon: Icon(
                player.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: AppTheme.primaryGreen,
                size: 36,
              ),
              onPressed: () => player.togglePlayPause(),
            ),
            IconButton(
              tooltip: 'Bài tiếp theo',
              icon: const Icon(Icons.skip_next_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => player.nextSong(),
            ),
          ],
        ),
      ),
    );
  }
}
