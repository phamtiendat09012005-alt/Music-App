import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/favorite_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>().favorites;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        tint: const Color(0xFF4A1736),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: () => context.pop(),
                    ),
                  ],
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5FA2), Color(0xFF6D3BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow:
                            AppTheme.glow(const Color(0xFFFF5FA2), 0.35),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 42, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bài hát đã thích',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('${favorites.length} bài hát',
                              style: const TextStyle(
                                  color: AppTheme.textGrey, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (favorites.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          context.read<PlayerProvider>().playSong(
                              favorites.first,
                              customQueue: favorites);
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
                child: favorites.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                size: 60, color: AppTheme.textGrey),
                            SizedBox(height: 10),
                            Text('Chưa có bài hát yêu thích nào',
                                style: TextStyle(color: AppTheme.textGrey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 155),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) => SongTile(
                          song: favorites[index],
                          customQueue: favorites,
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
