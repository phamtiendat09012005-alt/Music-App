import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/lyrics_view.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showLyrics = false;

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatRemainingTime(Duration pos, Duration dur) {
    final remaining = dur - pos;
    if (remaining.isNegative) return '-00:00';
    return '-${_formatTime(remaining)}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final favProvider = context.watch<FavoriteProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: Text('Chưa chọn bài hát', style: TextStyle(color: Colors.white))),
      );
    }

    final isFav = favProvider.isFavorite(song.id);
    final double totalSec = player.duration.inSeconds.toDouble();
    final double currentSec = player.position.inSeconds.toDouble().clamp(0.0, totalSec > 0 ? totalSec : 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Nền Ambient động lấy từ ảnh bìa bài hát
          CachedNetworkImage(
            imageUrl: song.coverUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: const Color(0xFF121212)),
          ),
          // Lớp kính mờ sâu (Deep Blur)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    const Color(0xFF09090B).withOpacity(0.85),
                    const Color(0xFF09090B),
                  ],
                ),
              ),
            ),
          ),

          // 2. Nội dung chính
          SafeArea(
            child: Column(
              children: [
                // Thanh頂 Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, size: 26, color: Colors.white),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            'ĐANG PHÁT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            song.genre.isNotEmpty ? song.genre : 'Music App Studio',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_horiz_rounded, size: 22, color: Colors.white),
                        ),
                        onPressed: () => _showQueueBottomSheet(context, player),
                      ),
                    ],
                  ),
                ),

                // Khung giữa: Đĩa nhạc co giãn theo nhịp Play/Pause hoặc Lyrics
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _showLyrics
                        ? const LyricsView()
                        : Center(
                            child: AnimatedScale(
                              scale: player.isPlaying ? 1.0 : 0.88,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutBack,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.80,
                                height: MediaQuery.of(context).size.width * 0.80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.65),
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: CachedNetworkImage(
                                    imageUrl: song.coverUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),

                // Tên bài hát + Nút Thả tim
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
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
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFF1DB954) : Colors.white70,
                          size: 30,
                        ),
                        onPressed: () => favProvider.toggleFavorite(song),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Thanh tua nhạc (Glowing Slider)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.5,
                      activeTrackColor: const Color(0xFF1DB954),
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                      overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                    ),
                    child: Slider(
                      value: currentSec,
                      max: totalSec > 0 ? totalSec : 1.0,
                      onChanged: (val) => player.seek(Duration(seconds: val.toInt())),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(player.position),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatRemainingTime(player.position, player.duration),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Cụm nút điều khiển chính
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: player.isShuffle ? const Color(0xFF1DB954) : Colors.white54,
                          size: 26,
                        ),
                        onPressed: player.toggleShuffle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 42, color: Colors.white),
                        onPressed: player.previous,
                      ),
                      // Nút Play nổi bật có hiệu ứng đổ bóng xanh
                      GestureDetector(
                        onTap: player.playOrPause,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1ED760), Color(0xFF1DB954)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1DB954).withOpacity(0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 42,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 42, color: Colors.white),
                        onPressed: player.next,
                      ),
                      IconButton(
                        icon: Icon(
                          player.loopMode == LoopModeState.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                          color: player.loopMode != LoopModeState.off ? const Color(0xFF1DB954) : Colors.white54,
                          size: 26,
                        ),
                        onPressed: player.toggleRepeat,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Thanh chuyển đổi Lyrics & Hàng đợi dạng thuốc (Pill Bar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _showLyrics = !_showLyrics),
                          icon: Icon(
                            Icons.lyrics_rounded,
                            size: 20,
                            color: _showLyrics ? const Color(0xFF1DB954) : Colors.white70,
                          ),
                          label: Text(
                            'Lời bài hát',
                            style: TextStyle(
                              color: _showLyrics ? const Color(0xFF1DB954) : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(width: 1, height: 18, color: Colors.white12),
                        TextButton.icon(
                          onPressed: () => _showQueueBottomSheet(context, player),
                          icon: const Icon(Icons.queue_music_rounded, size: 20, color: Colors.white70),
                          label: const Text(
                            'Danh sách phát',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final playlist = player.playlist;
        final currentIndex = player.currentIndex;

        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiếp theo trong hàng đợi',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text('${playlist.length} bài', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: playlist.length,
                  itemBuilder: (ctx, idx) {
                    final item = playlist[idx];
                    final isCurrent = idx == currentIndex;
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: item.coverUrl, width: 44, height: 44, fit: BoxFit.cover),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        style: TextStyle(
                          color: isCurrent ? const Color(0xFF1DB954) : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(item.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: isCurrent
                          ? const Icon(Icons.graphic_eq_rounded, color: Color(0xFF1DB954))
                          : const Icon(Icons.play_arrow_rounded, color: Colors.white30),
                      onTap: () {
                        player.skipToQueueItem(idx);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}