import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/library_screen.dart';
import '../screens/now_playing_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../widgets/mini_player.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home', // Đổi thành '/login' nếu muốn vào màn hình đăng nhập trước
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/now-playing',
      builder: (context, state) => const NowPlayingScreen(),
    ),
    // Khung giao diện chính có BottomNavigationBar và MiniPlayer
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/playlist/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PlaylistDetailScreen(playlistId: id);
          },
        ),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/library') ||
        location.startsWith('/favorites') ||
        location.startsWith('/playlist')) {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/search');
          if (index == 2) context.go('/library');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Thư viện'),
        ],
      ),
    );
  }
}