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
        title: const Text('Tạo Playlist mới',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ',
                style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context
                    .read<PlaylistProvider>()
                    .createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Widget _collectionCard({
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GlassCard(
        onTap: onTap,
        radius: 20,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 12.5)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final favCount = context.watch<FavoriteProvider>().favorites.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        tint: const Color(0xFF3B1A3F),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Thư viện',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCreatePlaylistDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded,
                                color: Colors.black, size: 20),
                            SizedBox(width: 4),
                            Text('Playlist',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              _collectionCard(
                onTap: () => context.push('/favorites'),
                leading: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5FA2), Color(0xFF6D3BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 28),
                ),
                title: 'Bài hát đã thích',
                subtitle: '$favCount bài hát',
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textGrey),
              ),
              if (playlistProvider.playlists.isNotEmpty)
                const SectionHeader(title: 'Playlist của bạn'),
              if (playlistProvider.playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: const Icon(Icons.queue_music_rounded,
                            size: 44, color: AppTheme.accent),
                      ),
                      const SizedBox(height: 14),
                      const Text('Chưa có playlist nào',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Bấm "+ Playlist" để tạo bộ sưu tập đầu tiên',
                          style: TextStyle(
                              color: AppTheme.textGrey, fontSize: 13)),
                    ],
                  ),
                ),
              ...playlistProvider.playlists.map((playlist) {
                return _collectionCard(
                  onTap: () => context.push('/playlist/${playlist.id}'),
                  leading: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.queue_music_rounded,
                        color: AppTheme.accent, size: 28),
                  ),
                  title: playlist.name,
                  subtitle: '${playlist.songs.length} bài hát',
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.textGrey),
                    onPressed: () =>
                        playlistProvider.deletePlaylist(playlist.id),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
