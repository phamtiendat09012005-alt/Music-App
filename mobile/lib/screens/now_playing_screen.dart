import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/lyrics_view.dart';
import '../core/theme.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

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
    final showLyrics = player.showLyrics;

    // Lấy câu hát đang phát từ bộ nhớ đệm (cache) của PlayerProvider
    final parsedLines = player.currentLyricLines;
    final activeIdx = player.activeLyricIndex;
    final currentLineText = (activeIdx >= 0 && activeIdx < parsedLines.length)
        ? parsedLines[activeIdx].text
        : '♪ Đang phát nhạc...';
    final nextLineText =
        (activeIdx + 1 >= 0 && activeIdx + 1 < parsedLines.length)
            ? parsedLines[activeIdx + 1].text
            : '';

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
              color: showLyrics ? AppTheme.primaryGreen : Colors.white,
            ),
            tooltip: 'Bật / Tắt Lời bài hát',
            onPressed: () => player.toggleShowLyrics(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            // THANH CHUYỂN ĐỔI RÕ RÀNG: [ Đĩa nhạc ] | [ Lời bài hát (.LRC) ]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => player.setShowLyrics(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !showLyrics
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.album_outlined,
                              size: 16,
                              color: !showLyrics ? Colors.black : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Đĩa nhạc',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    !showLyrics ? Colors.black : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => player.setShowLyrics(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: showLyrics
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lyrics_outlined,
                              size: 16,
                              color: showLyrics ? Colors.black : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lời bài hát (.LRC)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    showLyrics ? Colors.black : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // NỘI DUNG CHÍNH: MÀN HÌNH LỜI BÀI HÁT HOẶC ẢNH BÌA + KHUNG CHẠY LYRIC TRỰC TIẾP
            Expanded(
              child: showLyrics
                  ? const LyricsView()
                  : Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: 300, maxHeight: 300),
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
                        const SizedBox(height: 12),
                        // KHUNG CHẠY LỜI BÀI HÁT TRỰC TIẾP (LIVE LYRICS PREVIEW)
                        GestureDetector(
                          onTap: () => player.setShowLyrics(true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardGrey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.lyrics_rounded,
                                          size: 14,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'LỜI BÀI HÁT ĐANG CHẠY',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Mở rộng ↗',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textGrey.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentLineText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (nextLineText.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    nextLineText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
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
                            fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: const TextStyle(
                            fontSize: 15, color: AppTheme.textGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      player.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 38,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
