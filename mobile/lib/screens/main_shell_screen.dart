import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mini_player.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: navigationShell,
      bottomNavigationBar: Container(
        color: const Color(0xFF0F0F0F),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh MiniPlayer của Người 1
            const MiniPlayer(),
            // Thanh Bottom Navigation phong cách eSound / Spotify
            BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(index),
              backgroundColor: const Color(0xFF0F0F0F),
              selectedItemColor: const Color(0xFF1DB954),
              unselectedItemColor: Colors.white54,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 26),
                  activeIcon: Icon(Icons.home_filled, size: 26),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded, size: 26),
                  activeIcon: Icon(Icons.search_rounded, size: 26),
                  label: 'Tìm kiếm',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined, size: 26),
                  activeIcon: Icon(Icons.library_music_rounded, size: 26),
                  label: 'Thư viện',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}