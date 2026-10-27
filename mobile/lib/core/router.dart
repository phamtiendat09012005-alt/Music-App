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
import 'theme.dart';

CustomTransitionPage<void> _fadeSlide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Màn hình phát nhạc trượt từ dưới lên như một "sheet" toàn màn hình.
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

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
      pageBuilder: (context, state) => _slideUp(state, const NowPlayingScreen()),
    ),
    // Khung giao diện chính có thanh điều hướng nổi và MiniPlayer
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _fadeSlide(state, const HomeScreen()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => _fadeSlide(state, const SearchScreen()),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => _fadeSlide(state, const LibraryScreen()),
        ),
        GoRoute(
          path: '/favorites',
          pageBuilder: (context, state) => _fadeSlide(state, const FavoritesScreen()),
        ),
        GoRoute(
          path: '/playlist/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _fadeSlide(state, PlaylistDetailScreen(playlistId: id));
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
      extendBody: true,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _FloatingNavBar(
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == 0) context.go('/home');
              if (index == 1) context.go('/search');
              if (index == 2) context.go('/library');
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

/// Thanh điều hướng dạng "viên thuốc" nổi, mục đang chọn sáng gradient và hiện nhãn.
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.explore_outlined, Icons.explore_rounded, 'Khám phá'),
    _NavItem(Icons.search_rounded, Icons.manage_search_rounded, 'Tìm kiếm'),
    _NavItem(Icons.library_music_outlined, Icons.library_music_rounded, 'Thư viện'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.cardGrey.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == currentIndex;
            return Expanded(
              flex: selected ? 5 : 3,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: selected ? AppTheme.accentGradient : null,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 22,
                        color: selected ? Colors.black : AppTheme.textGrey,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
