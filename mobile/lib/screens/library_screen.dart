import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/favorite_provider.dart';
import '../core/theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardGrey,
        title: const Text('Tạo Playlist mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập tên playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<PlaylistProvider>().createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final favCount = context.watch<FavoriteProvider>().favorites.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Mục Bài hát đã thích
          ListTile(
            onTap: () => context.push('/favorites'),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.favorite, color: Colors.white),
            ),
            title: const Text('Bài hát đã thích', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$favCount bài hát', style: const TextStyle(color: AppTheme.textGrey)),
          ),
          const Divider(color: AppTheme.cardGrey),
          // Danh sách Playlist cá nhân
          ...playlistProvider.playlists.map((playlist) {
            return ListTile(
              onTap: () => context.push('/playlist/${playlist.id}'),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.cardGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.queue_music, color: AppTheme.textGrey),
              ),
              title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${playlist.songs.length} bài hát', style: const TextStyle(color: AppTheme.textGrey)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.textGrey),
                onPressed: () => playlistProvider.deletePlaylist(playlist.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}