import 'package:flutter/material.dart';
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
    final maxDuration = player.totalDuration.toDouble();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          tooltip: 'Thu nhỏ',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'ĐANG PHÁT TỪ DANH SÁCH',
              style: TextStyle(
                  fontSize: 10, letterSpacing: 1.2, color: AppTheme.textGrey),
            ),
            Text(
              song.genre.toUpperCase(),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
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
            Expanded(
              child: Center(
                child: _showLyrics
                    ? const LyricsView()
                    : ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 360, maxHeight: 360),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            song.coverUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppTheme.cardGrey,
                              child: const Icon(Icons.music_note,
                                  size: 80, color: AppTheme.primaryGreen),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: const TextStyle(
                            fontSize: 16, color: AppTheme.textGrey),
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
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
                activeTrackColor: AppTheme.primaryGreen,
                inactiveTrackColor: AppTheme.cardGrey,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: player.currentPosition.clamp(0.0, maxDuration),
                max: maxDuration > 0 ? maxDuration : 1.0,
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
                    style:
                        const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(player.totalDuration),
                    style:
                        const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Phát ngẫu nhiên',
                  icon: Icon(
                    Icons.shuffle,
                    color: player.isShuffle
                        ? AppTheme.primaryGreen
                        : AppTheme.textGrey,
                    size: 26,
                  ),
                  onPressed: () => player.toggleShuffle(),
                ),
                IconButton(
                  tooltip: 'Bài trước (Back)',
                  icon: const Icon(Icons.skip_previous_rounded,
                      size: 42, color: Colors.white),
                  onPressed: () => player.previousSong(),
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
                      player.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bài tiếp theo (Skip)',
                  icon: const Icon(Icons.skip_next_rounded,
                      size: 42, color: Colors.white),
                  onPressed: () => player.nextSong(),
                ),
                IconButton(
                  tooltip: player.isRepeat
                      ? 'Đang lặp lại bài này'
                      : 'Lặp lại bài hát',
                  icon: Icon(
                    player.isRepeat
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: player.isRepeat
                        ? AppTheme.primaryGreen
                        : AppTheme.textGrey,
                    size: 26,
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
