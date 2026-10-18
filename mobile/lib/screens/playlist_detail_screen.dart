import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(title: Text(playlist.name)),
      body: playlist.songs.isEmpty
          ? const Center(child: Text('Playlist trống'))
          : ListView.builder(
              itemCount: playlist.songs.length,
              itemBuilder: (context, index) => SongTile(song: playlist.songs[index]),
            ),
    );
  }
}