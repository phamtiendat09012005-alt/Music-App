import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/playlist.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  void _showAddSongsDialog(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return Consumer2<PlayerProvider, PlaylistProvider>(
          builder: (ctx, playerProvider, playlistProvider, _) {
            final allSongs = playlistProvider.playlists
              .expand((p) => p.songs)
              .toSet()
              .toList();
            final currentPl = playlistProvider.playlists.firstWhere(
              (p) => p.id == playlist.id,
              orElse: () => playlist,
            );

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHỌN BÀI HÁT TỪ MONGODB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppTheme.accentAqua,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Thêm vào "${currentPl.name}"',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text('Xong'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: allSongs.isEmpty
                            ? const Center(
                                child: Text(
                                  'Chưa có bài hát nào trong thư viện MongoDB',
                                  style: TextStyle(color: AppTheme.textGrey),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: allSongs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (_, i) {
                                  final song = allSongs[i];
                                  final added = currentPl.songs
                                      .any((s) => s.id == song.id);
                                  return ListTile(
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    tileColor: added
                                        ? AppTheme.accent
                                            .withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.04),
                                    leading: CoverImage(
                                        url: song.coverUrl,
                                        size: 44,
                                        radius: 10),
                                    title: Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Icon(
                                      added
                                          ? Icons.check_circle_rounded
                                          : Icons.add_circle_outline_rounded,
                                      color: added
                                          ? AppTheme.accentAqua
                                          : AppTheme.accent,
                                    ),
                                    onTap: () {
                                      if (added) {
                                        playlistProvider.removeSongFromPlaylist(
                                            currentPl.id, song.id);
                                      } else {
                                        playlistProvider.addSongToPlaylist(
                                            currentPl.id, song);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final playlists = playlistProvider.playlists;
    final index = playlists.indexWhere((p) => p.id == playlistId);

    if (index == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: const Center(child: Text('Không tìm thấy Playlist')),
      );
    }

    final playlist = playlists[index];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        tint: const Color(0xFF1B2A5C),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: () => context.pop(),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddSongsDialog(context, playlist),
                      icon: const Icon(Icons.add_rounded,
                          size: 18, color: AppTheme.accent),
                      label: const Text(
                        'Thêm bài hát',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.glow(),
                      ),
                      child: const Icon(Icons.queue_music_rounded,
                          size: 42, color: Colors.black),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(playlist.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('${playlist.songs.length} bài hát',
                              style: const TextStyle(
                                  color: AppTheme.textGrey, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (playlist.songs.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          context.read<PlayerProvider>().playSong(
                              playlist.songs.first,
                              customQueue: playlist.songs);
                          context.push('/now-playing');
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 32),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: playlist.songs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.library_music_outlined,
                                size: 48, color: AppTheme.textGrey),
                            const SizedBox(height: 10),
                            const Text('Playlist chưa có bài hát nào',
                                style: TextStyle(color: AppTheme.textGrey)),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showAddSongsDialog(context, playlist),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Thêm bài hát vào Playlist'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 150),
                        itemCount: playlist.songs.length,
                        itemBuilder: (context, i) {
                          final song = playlist.songs[i];
                          return SongTile(
                            song: song,
                            index: i,
                            showTrackNumber: true,
                            customQueue: playlist.songs,
                            onRemove: () => playlistProvider
                                .removeSongFromPlaylist(playlist.id, song.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
