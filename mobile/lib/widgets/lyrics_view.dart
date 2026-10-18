import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final lyrics = player.lyrics;
    final activeIndex = player.currentLyricIndex;

    if (lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            const Text(
              'Không có lời bài hát đồng bộ',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Cuộn mượt mà giữ dòng đang hát nằm ở khoảng giữa màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && activeIndex >= 0) {
        const itemHeight = 60.0;
        final targetOffset = (activeIndex * itemHeight) - 150.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final isSelected = index == activeIndex;
        return GestureDetector(
          onTap: () {
            // Nhấn trực tiếp vào dòng chữ để tua nhạc đến mốc thời gian đó
            player.seek(lyrics[index].time);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              lyrics[index].text,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white24,
                fontSize: isSelected ? 22 : 17,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}