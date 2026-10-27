import 'package:flutter/material.dart';

/// Hệ thiết kế "Aurora": nền mực đậm + màu nhấn tím → hồng → ngọc lam.
/// Các tên cũ (primaryGreen, darkBackground, surfaceBlack, cardGrey...) được giữ làm alias
/// để toàn bộ màn hình cũ tự động đổi sang bảng màu mới.
class AppTheme {
  // ---- Màu nền ----
  static const Color backgroundBlack = Color(0xFF0A0A12);
  static const Color surfaceBlack = Color(0xFF12121D);
  static const Color cardGrey = Color(0xFF1C1C2B);
  static const Color cardElevated = Color(0xFF26263A);
  static const Color outline = Color(0x1FFFFFFF);

  // ---- Màu nhấn ----
  static const Color accent = Color(0xFFB794FF); // tím nhạt
  static const Color accentPink = Color(0xFFFF7EB6); // hồng
  static const Color accentAqua = Color(0xFF5EEAD4); // ngọc lam

  // ---- Chữ ----
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textGrey = Color(0xFFA5A3BA);

  // ---- Alias tương thích code cũ ----
  static const Color primaryGreen = accent;
  static const Color darkBackground = backgroundBlack;

  // ---- Gradient dùng chung ----
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFB794FF), Color(0xFFFF7EB6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraGradient = LinearGradient(
    colors: [Color(0xFF2A1B5C), Color(0xFF0A0A12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<BoxShadow> glow([Color color = accent, double alpha = 0.35]) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: accent,
      secondary: accentPink,
      tertiary: accentAqua,
      surface: surfaceBlack,
      onPrimary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundBlack,
      primaryColor: accent,
      colorScheme: colorScheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textPrimary),
        bodyLarge: TextStyle(color: textPrimary),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardGrey,
        hintStyle: const TextStyle(color: textGrey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceBlack,
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: accent,
        inactiveTrackColor: Colors.white12,
        thumbColor: Colors.white,
        overlayColor: accent.withValues(alpha: 0.18),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Nền gradient "aurora" dùng cho các màn hình chính.
class AuroraBackground extends StatelessWidget {
  final Widget child;
  final Color tint;
  const AuroraBackground({
    super.key,
    required this.child,
    this.tint = const Color(0xFF2A1B5C),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tint, AppTheme.backgroundBlack],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Thẻ kính mờ bo góc, dùng cho khối nội dung nổi.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppTheme.outline),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Tiêu đề từng khu vực (có nút "Xem tất cả").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ảnh bìa có placeholder gradient khi lỗi / chưa có ảnh.
class CoverImage extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  final bool circle;
  const CoverImage({
    super.key,
    required this.url,
    required this.size,
    this.radius = 14,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: AppTheme.accentGradient),
      child: Icon(Icons.music_note_rounded,
          color: Colors.black54, size: size * 0.42),
    );
    final img = url.isEmpty
        ? placeholder
        : Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          );
    return circle
        ? ClipOval(child: img)
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }
}
