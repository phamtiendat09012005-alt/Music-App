import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistProvider>().playlists;
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
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.pop(),
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
                    ? const Center(
                        child: Text('Playlist trống',
                            style: TextStyle(color: AppTheme.textGrey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: playlist.songs.length,
                        itemBuilder: (context, i) => SongTile(
                          song: playlist.songs[i],
                          customQueue: playlist.songs,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
