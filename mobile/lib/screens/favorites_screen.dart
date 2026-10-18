import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/song_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>().favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Bài hát đã thích')),
      body: favorites.isEmpty
          ? const Center(child: Text('Chưa có bài hát yêu thích nào'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) => SongTile(song: favorites[index]),
            ),
    );
  }
}