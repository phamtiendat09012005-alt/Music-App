import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/song_tile.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bài hát đã thích', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: fav.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : fav.favorites.isEmpty
              ? const Center(child: Text('Chưa có bài hát yêu thích nào', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: fav.favorites.length,
                  itemBuilder: (ctx, idx) => SongTile(
                    song: fav.favorites[idx],
                    playlist: fav.favorites,
                    index: idx,
                  ),
                ),
    );
  }
}