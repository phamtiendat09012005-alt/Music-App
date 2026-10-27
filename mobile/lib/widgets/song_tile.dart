import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/playlist_provider.dart';
import '../core/theme.dart';

/// Dòng bài hát dạng thẻ bo tròn; bài đang phát được tô sáng viền gradient.
class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? customQueue;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final int? index;
  final bool showTrackNumber;

  const SongTile({
    super.key,
    required this.song,
    this.customQueue,
    this.onTap,
    this.onRemove,
    this.index,
    this.showTrackNumber = false,
  });

  /// Hiển thị Bottom Sheet chọn hoặc tạo mới Playlist để thêm bài hát
  static void showAddToPlaylistSheet(BuildContext context, Song song) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return Consumer<PlaylistProvider>(
          builder: (ctx, playlistProvider, _) {
            final playlists = playlistProvider.playlists;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CoverImage(url: song.coverUrl, size: 46, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THÊM VÀO PLAYLIST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppTheme.accentAqua,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tạo nhanh playlist mới kèm bài hát này
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Tạo playlist mới và thêm bài này...',
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.create_new_folder_rounded,
                              size: 18,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final created = await playlistProvider.createPlaylist(
                            name,
                            initialSong: song,
                          );
                          if (created != null) {
                            await playlistProvider.addSongToPlaylist(
                                created.id, song);
                          }
                          if (sheetCtx.mounted) {
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Đã tạo playlist "$name" và thêm "${song.title}"'),
                              ),
                            );
                          }
                        },
                        child: const Text('Tạo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Chưa có playlist nào. Hãy nhập tên ở trên để tạo mới!',
                          style: TextStyle(
                              color: AppTheme.textGrey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final pl = playlists[i];
                          final hasSong =
                              pl.songs.any((item) => item.id == song.id);
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            tileColor: Colors.white.withValues(alpha: 0.04),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.queue_music_rounded,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              pl.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${pl.songs.length} bài hát',
                              style: const TextStyle(
                                  color: AppTheme.textGrey, fontSize: 12),
                            ),
                            trailing: Icon(
                              hasSong
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: hasSong
                                  ? AppTheme.accentAqua
                                  : AppTheme.accent,
                            ),
                            onTap: () async {
                              if (hasSong) {
                                await playlistProvider.removeSongFromPlaylist(
                                    pl.id, song.id);
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Đã gỡ "${song.title}" khỏi "${pl.name}"'),
                                    ),
                                  );
                                }
                              } else {
                                await playlistProvider.addSongToPlaylist(
                                    pl.id, song);
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Đã thêm "${song.title}" vào "${pl.name}"'),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                                color:
                                    AppTheme.accentPink.withValues(alpha: 0.18),
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
                  tooltip: isFav ? 'Bỏ yêu thích' : 'Yêu thích',
                  icon: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? AppTheme.accentPink : AppTheme.textGrey,
                    size: 20,
                  ),
                  onPressed: () => favProvider.toggleFavorite(song),
                ),
                if (onRemove != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Gỡ khỏi Playlist',
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppTheme.textGrey,
                      size: 20,
                    ),
                    onPressed: onRemove,
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Thêm vào Playlist',
                    icon: const Icon(
                      Icons.playlist_add_rounded,
                      color: AppTheme.textGrey,
                      size: 21,
                    ),
                    onPressed: () => showAddToPlaylistSheet(context, song),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
