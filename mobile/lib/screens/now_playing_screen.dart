import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/song_tile.dart';
import '../core/theme.dart';

/// Màn hình đang phát: nền mờ theo ảnh bìa, 3 chế độ (Đĩa nhạc / Lời / Karaoke).
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _modeTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.accentGradient : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: selected ? Colors.black : AppTheme.textGrey),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.black : AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    double size = 26,
    String? tooltip,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: size),
    );
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
    final viewMode = player.viewMode; // 0: Đĩa nhạc, 1: Lời .LRC, 2: Karaoke

    final parsedLines = player.currentLyricLines;
    final activeIdx = player.activeLyricIndex;
    final String currentLineText;
    if (player.isLoadingLyrics) {
      currentLineText = 'Đang tải lời bài hát...';
    } else if (parsedLines.isEmpty) {
      currentLineText = 'Bài hát chưa có lời (.LRC/.SRT)';
    } else if (activeIdx >= 0 && activeIdx < parsedLines.length) {
      currentLineText = parsedLines[activeIdx].text;
    } else {
      currentLineText = '♪ Đang phát nhạc...';
    }
    final nextLineText =
        (activeIdx + 1 >= 0 && activeIdx + 1 < parsedLines.length)
            ? parsedLines[activeIdx + 1].text
            : '';

    return Scaffold(
      body: Stack(
        children: [
          // 1. NỀN: ảnh bìa phóng to + làm mờ + phủ gradient tối
          Positioned.fill(
            child: song.coverUrl.isNotEmpty
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Image.network(
                      song.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.backgroundBlack),
                    ),
                  )
                : Container(color: AppTheme.backgroundBlack),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundBlack.withValues(alpha: 0.55),
                    AppTheme.backgroundBlack.withValues(alpha: 0.88),
                    AppTheme.backgroundBlack,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  // 2. THANH TRÊN
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 34),
                        tooltip: 'Thu nhỏ',
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              player.isBeatMode
                                  ? 'CHẾ ĐỘ BEAT KARAOKE'
                                  : 'ĐANG PHÁT',
                              style: TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w800,
                                color: player.isBeatMode
                                    ? AppTheme.accentPink
                                    : AppTheme.textGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.genre.isEmpty ? 'Music' : song.genre,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Thêm vào Playlist',
                        icon: const Icon(
                          Icons.playlist_add_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            SongTile.showAddToPlaylistSheet(context, song),
                      ),
                      IconButton(
                        tooltip: isFav ? 'Bỏ thích' : 'Yêu thích',
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? AppTheme.accentPink : Colors.white,
                        ),
                        onPressed: () => favProvider.toggleFavorite(song),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 3. CHUYỂN CHẾ ĐỘ
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Row(
                      children: [
                        _modeTab(
                          label: 'Đĩa nhạc',
                          icon: Icons.album_rounded,
                          selected: viewMode == 0,
                          onTap: () => player.setViewMode(0),
                        ),
                        _modeTab(
                          label: 'Lời',
                          icon: Icons.lyrics_rounded,
                          selected: viewMode == 1,
                          onTap: () => player.setViewMode(1),
                        ),
                        _modeTab(
                          label: 'Karaoke',
                          icon: Icons.mic_rounded,
                          selected: viewMode == 2,
                          onTap: () => player.setViewMode(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. NỘI DUNG CHÍNH
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: KeyedSubtree(
                        key: ValueKey('mode_$viewMode'),
                        child: viewMode == 2
                            ? const KaraokeView()
                            : viewMode == 1
                                ? const LyricsView()
                                : _buildCoverMode(
                                    context,
                                    player,
                                    song.coverUrl,
                                    currentLineText,
                                    nextLineText,
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. THÔNG TIN BÀI HÁT + BEAT
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => player.toggleBeatMode(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: player.isBeatMode
                                ? AppTheme.accentGradient
                                : null,
                            color: player.isBeatMode
                                ? null
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: player.isBeatMode
                                  ? Colors.transparent
                                  : AppTheme.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                player.isBeatMode
                                    ? Icons.voice_over_off_rounded
                                    : Icons.graphic_eq_rounded,
                                size: 16,
                                color: player.isBeatMode
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'BEAT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: player.isBeatMode
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 6. THANH TIẾN ĐỘ
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      trackHeight: 4,
                      activeTrackColor: AppTheme.accent,
                      inactiveTrackColor: Colors.white12,
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
                        Text(_formatDuration(player.currentPosition.toInt()),
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 12)),
                        Text(_formatDuration(player.totalDuration),
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 12)),
                      ],
                    ),
                  ),

                  // 7. ĐIỀU KHIỂN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _roundIcon(
                        icon: Icons.shuffle_rounded,
                        tooltip: 'Phát ngẫu nhiên',
                        color: player.isShuffle
                            ? AppTheme.accent
                            : AppTheme.textGrey,
                        onTap: () => player.toggleShuffle(),
                      ),
                      _roundIcon(
                        icon: Icons.skip_previous_rounded,
                        tooltip: 'Bài trước',
                        size: 42,
                        onTap: () => player.previousSong(),
                      ),
                      GestureDetector(
                        onTap: () => player.togglePlayPause(),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.glow(AppTheme.accent, 0.45),
                          ),
                          child: Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 42,
                          ),
                        ),
                      ),
                      _roundIcon(
                        icon: Icons.skip_next_rounded,
                        tooltip: 'Bài tiếp theo',
                        size: 42,
                        onTap: () => player.nextSong(),
                      ),
                      _roundIcon(
                        icon: player.isRepeat
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        tooltip: 'Lặp lại',
                        color: player.isRepeat
                            ? AppTheme.accent
                            : AppTheme.textGrey,
                        onTap: () => player.toggleRepeat(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chế độ "Đĩa nhạc": ảnh bìa lớn + thẻ lời đang chạy.
  Widget _buildCoverMode(
    BuildContext context,
    PlayerProvider player,
    String coverUrl,
    String currentLineText,
    String nextLineText,
  ) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AnimatedScale(
              scale: player.isPlaying ? 1.0 : 0.88,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 320, maxHeight: 320),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.35),
                          blurRadius: 50,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) => CoverImage(
                        url: coverUrl,
                        size: c.maxWidth,
                        radius: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => player.setViewMode(2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lyrics_rounded,
                            size: 14, color: AppTheme.accentAqua),
                        SizedBox(width: 6),
                        Text(
                          'LỜI ĐANG CHẠY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppTheme.accentAqua,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Hát Karaoke ↗',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentPink.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentLineText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (nextLineText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    nextLineText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
