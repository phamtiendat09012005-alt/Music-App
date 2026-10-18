import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/playlist_provider.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> playlist;
  final int index;
  final bool showIndex;

  const SongTile({
    super.key,
    required this.song,
    required this.playlist,
    required this.index,
    this.showIndex = true,
  });

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final favProvider = context.watch<FavoriteProvider>();
    final isCurrent = player.currentSong?.id == song.id;
    final isFav = favProvider.isFavorite(song.id);

    return InkWell(
      onTap: () => context.read<PlayerProvider>().playPlaylist(playlist, index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.white.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Cột số thứ tự hoặc icon đang phát
            if (showIndex)
              SizedBox(
                width: 28,
                child: isCurrent
                    ? const Icon(Icons.equalizer_rounded, color: Color(0xFF1DB954), size: 20)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
              ),
            // Ảnh bìa bo góc
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: song.coverUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFF282828),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tiêu đề & Nghệ sĩ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? const Color(0xFF1DB954) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Thời lượng bài hát
            Text(
              _formatDuration(song.duration),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(width: 4),
            // Nút Yêu thích
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? const Color(0xFF1DB954) : Colors.white38,
                size: 20,
              ),
              onPressed: () => favProvider.toggleFavorite(song),
            ),
            // Nút thêm vào Playlist
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 20),
              onPressed: () => _showSongOptions(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final playlists = context.watch<PlaylistProvider>().playlists;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(imageUrl: song.coverUrl, width: 40, height: 40, fit: BoxFit.cover),
                ),
                title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54)),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                title: const Text('Thêm vào Playlist cá nhân', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddToPlaylistDialog(context, playlists);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, List<dynamic> playlists) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Chọn Playlist', style: TextStyle(color: Colors.white)),
        content: playlists.isEmpty
            ? const Text('Chưa có playlist nào. Hãy tạo mới ở Thư viện!', style: TextStyle(color: Colors.white70))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (_, i) {
                    final pl = playlists[i];
                    return ListTile(
                      leading: const Icon(Icons.queue_music, color: Color(0xFF1DB954)),
                      title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        context.read<PlaylistProvider>().addSong(pl.id, song.id);
                        Navigator.pop(dlgContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm vào "${pl.name}"')),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}