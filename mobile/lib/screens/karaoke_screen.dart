import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/lyrics_view.dart';

/// ============================================================================
/// 1. MÀN HÌNH PHÒNG HÁT KARAOKE RIÊNG BIỆT (FULL-SCREEN KARAOKE STUDIO)
/// Hiển thị lời bài hát đồng bộ theo từng câu giống Lyric (không bôi từng chữ)
/// ============================================================================
class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({super.key});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _lastSongId = '';
  int _lastScrolledIndex = -1;
  static const double _itemExtent = 54.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(String songId, int activeIndex) {
    if (_lastSongId != songId) {
      _lastSongId = songId;
      _lastScrolledIndex = -1;
    }
    if (activeIndex < 0 || activeIndex == _lastScrolledIndex) return;
    _lastScrolledIndex = activeIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final viewport = _scrollController.position.viewportDimension;
      final target =
          (activeIndex * _itemExtent) - (viewport / 2) + (_itemExtent / 2);
      final clamped = target.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _formatTimestamp(double seconds) {
    final totalSec = seconds.floor();
    final mins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final Song? song = player.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Phòng Hát Karaoke')),
        body: const Center(child: Text('Chưa chọn bài hát')),
      );
    }

    final List<LyricLine> lines = player.currentLyricLines;
    final int activeIdx = player.activeLyricIndex;
    final int countdown = player.countdownSecondsToNextLine;
    final bool hasTrueBeat = song.hasInstrumental;
    final double maxDuration = player.totalDuration.toDouble();

    if (lines.isNotEmpty) {
      _scrollToActiveLine(song.id, activeIdx);
    }

    final String currentLineText = player.isLoadingLyrics
        ? 'Đang tải lời bài hát từ MongoDB...'
        : lines.isEmpty
            ? '♪ Bài hát hiện chưa có lời trên MongoDB'
            : (activeIdx >= 0 && activeIdx < lines.length)
                ? lines[activeIdx].text
                : '♪ Nhạc dạo...';

    final String nextLineText =
        (activeIdx + 1 >= 0 && activeIdx + 1 < lines.length)
            ? lines[activeIdx + 1].text
            : '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Quay lại trình phát',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: () => player.toggleBeatMode(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient:
                        player.isBeatMode ? AppTheme.accentGradient : null,
                    color: player.isBeatMode ? null : AppTheme.cardGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: player.isBeatMode
                          ? Colors.transparent
                          : AppTheme.outline,
                    ),
                  ),
                  child: Text(
                    player.isBeatMode
                        ? (hasTrueBeat ? '🎵 BEAT CHUẨN' : '🎤 ĐỆM HÁT')
                        : '🔊 CÓ LỜI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: player.isBeatMode ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AuroraBackground(
        tint: const Color(0xFF3B1A6B),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                // 1. KHUNG TIÊU ĐIỂM CÂU ĐANG HÁT (HIỂN THỊ NHƯ LYRIC - KHÔNG BÔI CHỮ)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardGrey.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: player.isBeatMode
                          ? AppTheme.primaryGreen.withValues(alpha: 0.6)
                          : Colors.white12,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Đếm nhịp 3 - 2 - 1 chấm tròn nếu sắp vào câu hát
                      if (countdown > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Chuẩn bị vào nhịp: ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...List.generate(3, (dotIndex) {
                              final activeDot = (3 - dotIndex) <= countdown;
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: activeDot
                                      ? Colors.amberAccent
                                      : Colors.white24,
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Câu đang hát (sáng rõ nguyên câu như Lyric)
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          height: 1.35,
                        ),
                        child: Text(
                          currentLineText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (nextLineText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Tiếp: $nextLineText',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 2. THANH CĂN CHỈNH NHỊP LỜI (-0.5s / 0.0s / +0.5s)
                if (lines.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          player.lyricOffset == 0.0
                              ? '⏱ Đồng bộ lời (.LRC/.SRT): Chuẩn (0.0s)'
                              : '⏱ Bù độ trễ lời: ${player.lyricOffset > 0 ? '+' : ''}${player.lyricOffset.toStringAsFixed(1)}s',
                          style: TextStyle(
                            fontSize: 11,
                            color: player.lyricOffset == 0.0
                                ? AppTheme.textGrey
                                : AppTheme.primaryGreen,
                            fontWeight: player.lyricOffset == 0.0
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => player.adjustLyricOffset(-0.5),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '-0.5s',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white70),
                                ),
                              ),
                            ),
                            if (player.lyricOffset != 0.0) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => player.resetLyricOffset(),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '0.0s',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => player.adjustLyricOffset(0.5),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '+0.5s',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white70),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // 3. DANH SÁCH LỜI BÀI HÁT HIỂN THỊ NHƯ LYRIC (CUỘN TỰ ĐỘNG, CHẠM ĐỂ TUA)
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardGrey.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: player.isLoadingLyrics
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          )
                        : lines.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lyrics_outlined,
                                      size: 42,
                                      color: AppTheme.textGrey,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Bài hát này chưa có lời (.LRC/.SRT) trên MongoDB.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryGreen,
                                        side: const BorderSide(
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                      onPressed: () =>
                                          player.refreshCurrentSongFromMongo(),
                                      icon: const Icon(Icons.refresh_rounded,
                                          size: 16),
                                      label: const Text(
                                        'Đồng bộ lại từ MongoDB',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemExtent: _itemExtent,
                                itemCount: lines.length,
                                itemBuilder: (context, index) {
                                  final item = lines[index];
                                  final isCurrent = index == activeIdx;
                                  final isPast = index < activeIdx;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => player.seek(
                                      (item.timeSec + player.lyricOffset).clamp(
                                        0.0,
                                        player.totalDuration.toDouble(),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: isCurrent
                                          ? BoxDecoration(
                                              color: AppTheme.primaryGreen
                                                  .withValues(alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            )
                                          : null,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 44,
                                            child: Text(
                                              _formatTimestamp(item.timeSec),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isCurrent
                                                    ? AppTheme.primaryGreen
                                                    : AppTheme.textGrey
                                                        .withValues(alpha: 0.5),
                                                fontWeight: isCurrent
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                  milliseconds: 220),
                                              style: TextStyle(
                                                fontSize: isCurrent ? 18 : 15,
                                                fontWeight: isCurrent
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isCurrent
                                                    ? AppTheme.primaryGreen
                                                    : isPast
                                                        ? Colors.white60
                                                        : Colors.white,
                                              ),
                                              child: Text(
                                                item.text,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),

                const SizedBox(height: 10),

                // 4. BẢNG ĐIỀU KHIỂN PHÒNG KARAOKE & NHẠC BEAT
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Hàng nút Chế độ Beat & Hát lại câu
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: player.isBeatMode
                                    ? AppTheme.primaryGreen
                                    : AppTheme.cardElevated,
                                foregroundColor: player.isBeatMode
                                    ? Colors.black
                                    : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: Icon(
                                player.isBeatMode
                                    ? Icons.voice_over_off_rounded
                                    : Icons.record_voice_over_rounded,
                                size: 17,
                              ),
                              label: Text(
                                player.isBeatMode
                                    ? 'Đang bật Nhạc Beat'
                                    : 'Bật Chế độ Beat (Tắt lời)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () => player.toggleBeatMode(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(
                              Icons.replay_rounded,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                            label: const Text(
                              'Hát lại câu',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => player.replayCurrentLine(),
                          ),
                        ],
                      ),

                      // Thanh chỉnh Âm lượng Beat
                      Row(
                        children: [
                          const Icon(
                            Icons.volume_up_rounded,
                            size: 16,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Âm lượng Beat:',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12),
                                activeTrackColor: AppTheme.primaryGreen,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: player.beatVolume,
                                min: 0.1,
                                max: 1.0,
                                onChanged: (v) => player.setBeatVolume(v),
                              ),
                            ),
                          ),
                          Text(
                            '${(player.beatVolume * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Thanh tua nhạc + Điều khiển Phát / Tạm dừng / Qua bài
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10),
                          activeTrackColor: AppTheme.primaryGreen,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value:
                              player.currentPosition.clamp(0.0, maxDuration),
                          max: maxDuration > 0 ? maxDuration : 1.0,
                          onChanged: (val) => player.seek(val),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(player.currentPosition.toInt()),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textGrey),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded,
                                    color: Colors.white, size: 30),
                                onPressed: () => player.previousSong(),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => player.togglePlayPause(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    player.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded,
                                    color: Colors.white, size: 30),
                                onPressed: () => player.nextSong(),
                              ),
                            ],
                          ),
                          Text(
                            _formatTime(player.totalDuration),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 2. WIDGET KARAOKE GỌN TRONG MÀN HÌNH NOW PLAYING (HIỂN THỊ NHƯ LYRIC + NÚT MỞ MÀN HÌNH RIÊNG)
/// ============================================================================
class KaraokeView extends StatefulWidget {
  const KaraokeView({super.key});

  @override
  State<KaraokeView> createState() => _KaraokeViewState();
}

class _KaraokeViewState extends State<KaraokeView> {
  final ScrollController _scrollController = ScrollController();
  String _lastSongId = '';
  int _lastScrolledIndex = -1;
  static const double _itemExtent = 50.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(String songId, int index) {
    if (_lastSongId != songId) {
      _lastSongId = songId;
      _lastScrolledIndex = -1;
    }
    if (index < 0 || index == _lastScrolledIndex) return;
    _lastScrolledIndex = index;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final viewport = _scrollController.position.viewportDimension;
      final target =
          (index * _itemExtent) - (viewport / 2) + (_itemExtent / 2);
      final clamped = target.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatTimestamp(double seconds) {
    final totalSec = seconds.floor();
    final mins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final Song? song = player.currentSong;
    final lines = player.currentLyricLines;
    final activeIdx = player.activeLyricIndex;
    final hasTrueBeat = song?.hasInstrumental == true;

    if (song != null && lines.isNotEmpty) {
      _scrollToActiveLine(song.id, activeIdx);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: player.isBeatMode
              ? AppTheme.primaryGreen.withValues(alpha: 0.6)
              : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          // Header: Tiêu đề + Nút mở giao diện Phòng Karaoke riêng toàn màn hình
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.mic_rounded,
                    color: AppTheme.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    player.isBeatMode
                        ? (hasTrueBeat
                            ? 'Karaoke • Beat Chuẩn'
                            : 'Karaoke • Đệm Hát')
                        : 'Karaoke • Nhạc Có Lời',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KaraokeScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGreen),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 13,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Mở Phòng Karaoke ↗',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Danh sách lời bài hát hiển thị giống Lyric (không bôi chữ từng từ)
          Expanded(
            child: player.isLoadingLyrics
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : lines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Bài hát hiện chưa có lời (.LRC/.SRT) trên MongoDB',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              onPressed: () =>
                                  player.refreshCurrentSongFromMongo(),
                              icon: const Icon(Icons.refresh_rounded, size: 15),
                              label: const Text(
                                'Tải lại từ MongoDB',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemExtent: _itemExtent,
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          final isCurrentLine = index == activeIdx;
                          final isPastLine = index < activeIdx;

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => player.seek(
                              (line.timeSec + player.lyricOffset)
                                  .clamp(0.0, player.totalDuration.toDouble()),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 42,
                                    child: Text(
                                      _formatTimestamp(line.timeSec),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isCurrentLine
                                            ? AppTheme.primaryGreen
                                            : AppTheme.textGrey
                                                .withValues(alpha: 0.5),
                                        fontWeight: isCurrentLine
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      style: TextStyle(
                                        fontSize: isCurrentLine ? 18 : 15,
                                        fontWeight: isCurrentLine
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isCurrentLine
                                            ? AppTheme.primaryGreen
                                            : isPastLine
                                                ? Colors.white70
                                                : AppTheme.textGrey,
                                      ),
                                      child: Text(
                                        line.text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          const SizedBox(height: 8),

          // Thanh điều khiển Beat nhanh ở đáy
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: player.isBeatMode
                        ? AppTheme.primaryGreen
                        : AppTheme.cardElevated,
                    foregroundColor:
                        player.isBeatMode ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(
                    player.isBeatMode
                        ? Icons.voice_over_off_rounded
                        : Icons.record_voice_over_rounded,
                    size: 16,
                  ),
                  label: Text(
                    player.isBeatMode
                        ? 'Đang bật Chế độ Beat'
                        : 'Bật Chế độ Beat (Tắt lời)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => player.toggleBeatMode(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(
                  Icons.replay_rounded,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                label: const Text(
                  'Hát lại câu',
                  style: TextStyle(fontSize: 11),
                ),
                onPressed: () => player.replayCurrentLine(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

