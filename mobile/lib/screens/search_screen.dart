import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/song_tile.dart';
import '../core/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredSongs = mockSongs.where((song) {
      final q = _query.toLowerCase();
      return song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
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
            child: filteredSongs.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy bài hát', style: TextStyle(color: AppTheme.textGrey)),
                  )
                : ListView.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) => SongTile(song: filteredSongs[index]),
                  ),
          ),
        ],
      ),
    );
  }
}