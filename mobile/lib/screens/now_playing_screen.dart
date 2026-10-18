import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/lyrics_view.dart';
import '../core/theme.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showLyrics = false;

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final favProvider = context.watch<FavoriteProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text('Chưa chọn bài hát')));
    }

    final isFav = favProvider.isFavorite(song.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          song.genre.toUpperCase(),
          style: const TextStyle(fontSize: 12, letterSpacing: 1.5, color: AppTheme.textGrey),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.lyrics_outlined,
              color: _showLyrics ? AppTheme.primaryGreen : Colors.white,
            ),
            tooltip: 'Lời bài hát',
            onPressed: () => setState(() => _showLyrics = !_showLyrics),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            // Khu vực hiển thị Ảnh bìa hoặc Lời bài hát đồng bộ
            Expanded(
              child: Center(
                child: _showLyrics
                    ? const LyricsView()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: song.coverUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Tên bài hát, nghệ sĩ & nút yêu thích
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: const TextStyle(fontSize: 16, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? AppTheme.primaryGreen : Colors.white,
                    size: 28,
                  ),
                  onPressed: () => favProvider.toggleFavorite(song),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Thanh trượt thời gian (Seek bar)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
                activeTrackColor: Colors.white,
                inactiveTrackColor: AppTheme.cardGrey,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: player.currentPosition.clamp(0.0, song.duration.toDouble()),
                max: song.duration.toDouble(),
                onChanged: (val) => player.seek(val),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(player.currentPosition.toInt()),
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(song.duration),
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Bộ nút điều khiển: Shuffle, Prev, Play/Pause, Next, Repeat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: player.isShuffle ? AppTheme.primaryGreen : AppTheme.textGrey,
                  ),
                  onPressed: () => player.toggleShuffle(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 38),
                  onPressed: () {},
                ),
                GestureDetector(
                  onTap: () => player.togglePlayPause(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 38,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 38),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: player.isRepeat ? AppTheme.primaryGreen : AppTheme.textGrey,
                  ),
                  onPressed: () => player.toggleRepeat(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}