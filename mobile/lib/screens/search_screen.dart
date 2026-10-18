import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/song_tile.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Song> _songs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs([String? keyword]) async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiService().getSongs(search: keyword);
      if (mounted) {
        setState(() {
          _songs = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _songs = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _fetchSongs,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Tên bài hát hoặc nghệ sĩ...',
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.black87),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _songs.isEmpty
                    ? const Center(
                        child: Text('Không tìm thấy bài hát', style: TextStyle(color: AppTheme.textGrey)),
                      )
                    : ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) => SongTile(song: _songs[index]),
                      ),
          ),
        ],
      ),
    );
  }
}