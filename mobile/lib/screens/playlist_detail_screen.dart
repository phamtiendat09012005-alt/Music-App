import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/playlist.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final ApiService _apiService = ApiService();
  Playlist? _playlist;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _apiService.getPlaylistDetail(widget.playlistId);
      setState(() {
        _playlist = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_playlist?.name ?? 'Playlist', style: const TextStyle(color: Colors.white)),
      ),
      body: _playlist == null || _playlist!.songs.isEmpty
          ? const Center(child: Text('Playlist đang trống', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: _playlist!.songs.length,
              itemBuilder: (ctx, idx) => SongTile(
                song: _playlist!.songs[idx],
                playlist: _playlist!.songs,
                index: idx,
              ),
            ),
    );
  }
}