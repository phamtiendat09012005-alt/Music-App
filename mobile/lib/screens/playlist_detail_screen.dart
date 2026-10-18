import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final playlist = context
        .watch<PlaylistProvider>()
        .playlists
        .firstWhere((p) => p.id == playlistId);

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