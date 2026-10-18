import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../core/theme.dart';

class SongTile extends StatelessWidget {
  final Song song;

  const SongTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final favProvider = context.watch<FavoriteProvider>();
    final isPlayingThis = playerProvider.currentSong?.id == song.id;
    final isFav = favProvider.isFavorite(song.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        playerProvider.playSong(song);
        context.push('/now-playing');
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          song.coverUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 50,
            height: 50,
            color: AppTheme.cardGrey,
            child: const Icon(Icons.music_note, color: AppTheme.primaryGreen),
          ),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isPlayingThis ? AppTheme.primaryGreen : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
        maxLines: 1,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPlayingThis)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child:
                  Icon(Icons.equalizer, color: AppTheme.primaryGreen, size: 20),
            ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppTheme.primaryGreen : AppTheme.textGrey,
            ),
            onPressed: () => favProvider.toggleFavorite(song),
          ),
        ],
      ),
    );
  }
}
