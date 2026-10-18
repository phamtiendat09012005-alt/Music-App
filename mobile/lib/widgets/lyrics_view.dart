import 'package:flutter/material.dart';
import '../core/theme.dart';

class LyricsView extends StatelessWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả lập các câu lời bài hát từ file .lrc
    final List<String> sampleLyrics = [
      "♪ Nhạc dạo đầu...",
      "Dòng lời bài hát thứ nhất",
      "Đang phát câu hát này (Highlight)",
      "Dòng lời bài hát tiếp theo",
      "Giai điệu nhẹ nhàng sâu lắng",
      "Kết thúc đoạn điệp khúc ♪",
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lời bài hát',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: sampleLyrics.length,
              itemBuilder: (context, index) {
                final isCurrentLine = index == 2; // Giả lập dòng số 2 đang phát
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    sampleLyrics[index],
                    style: TextStyle(
                      fontSize: isCurrentLine ? 20 : 16,
                      fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentLine ? AppTheme.primaryGreen : AppTheme.textGrey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}