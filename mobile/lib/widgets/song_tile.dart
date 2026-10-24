import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../core/theme.dart';

/// Dòng bài hát dạng thẻ bo tròn; bài đang phát được tô sáng viền gradient.
class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? customQueue;
  final VoidCallback? onTap;
  final int? index;
  final bool showTrackNumber;

  const SongTile({
    super.key,
    required this.song,
    this.customQueue,
    this.onTap,
    this.index,
    this.showTrackNumber = false,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final favProvider = context.watch<FavoriteProvider>();
    final isPlayingThis = playerProvider.currentSong?.id == song.id;
    final isFav = favProvider.isFavorite(song.id);
    final durationStr = _formatDuration(song.duration);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap ??
              () {
                playerProvider.playSong(song, customQueue: customQueue);
                context.push('/now-playing');
              },
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            decoration: BoxDecoration(
              color: isPlayingThis
                  ? AppTheme.accent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isPlayingThis
                    ? AppTheme.accent.withValues(alpha: 0.55)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (showTrackNumber && index != null)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${index! + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPlayingThis
                            ? AppTheme.accent
                            : AppTheme.textGrey,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                CoverImage(url: song.coverUrl, size: 52, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlayingThis ? AppTheme.accent : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (song.hasInstrumental)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPink.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'KARAOKE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accentPink,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isPlayingThis)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.graphic_eq_rounded,
                        color: AppTheme.accent, size: 20),
                  )
                else if (durationStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(
                      durationStr,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 11.5),
                    ),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppTheme.accentPink : AppTheme.textGrey,
                    size: 22,
                  ),
                  onPressed: () => favProvider.toggleFavorite(song),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
