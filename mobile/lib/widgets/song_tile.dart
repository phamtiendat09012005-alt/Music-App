import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
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
      onTap: () => playerProvider.playSong(song),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: song.coverUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: AppTheme.cardGrey),
          errorWidget: (context, url, error) => const Icon(Icons.music_note),
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
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppTheme.primaryGreen : AppTheme.textGrey,
            ),
            onPressed: () => favProvider.toggleFavorite(song),
          ),
          const Icon(Icons.more_vert, color: AppTheme.textGrey),
        ],
      ),
    );
  }
}