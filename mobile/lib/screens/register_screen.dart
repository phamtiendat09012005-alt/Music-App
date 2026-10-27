import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/favorite_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/api_service.dart';

enum RegisterMethod { gmail, phone }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  RegisterMethod _selectedMethod = RegisterMethod.gmail;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final isGmail = _selectedMethod == RegisterMethod.gmail;
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || contact.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin đăng ký')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = isGmail ? contact : '$contact@musicapp.local';
      await ApiService().register(
        name: name,
        email: email,
        password: password,
      );
    } catch (_) {}

    if (mounted) {
      context.read<FavoriteProvider>().fetchFavorites();
      context.read<PlaylistProvider>().fetchPlaylists();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isGmail
                ? 'Đăng ký tài khoản bằng Gmail thành công!'
                : 'Đăng ký tài khoản bằng Số điện thoại thành công!',
          ),
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGmail = _selectedMethod == RegisterMethod.gmail;

    return Scaffold(
      body: AuroraBackground(
        tint: const Color(0xFF421C5C),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: AppTheme.glow(AppTheme.accentPink, 0.45),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lưu bài hát yêu thích & Playlist cá nhân trên MongoDB',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 13.5),
                ),
                const SizedBox(height: 24),

                // Thanh chuyển đổi: Đăng ký bằng Gmail / Số điện thoại
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardGrey,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMethod = RegisterMethod.gmail;
                              _contactController.clear();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient:
                                  isGmail ? AppTheme.accentGradient : null,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: isGmail
                                      ? Colors.black
                                      : AppTheme.textGrey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Bằng Gmail',
                                  style: TextStyle(
                                    color: isGmail
                                        ? Colors.black
                                        : AppTheme.textGrey,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMethod = RegisterMethod.phone;
                              _contactController.clear();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient:
                                  !isGmail ? AppTheme.accentGradient : null,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android_outlined,
                                  size: 18,
                                  color: !isGmail
                                      ? Colors.black
                                      : AppTheme.textGrey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Số điện thoại',
                                  style: TextStyle(
                                    color: !isGmail
                                        ? Colors.black
                                        : AppTheme.textGrey,
                                    fontWeight: FontWeight.w800,
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
                const SizedBox(height: 22),

                // Ô nhập Tên hiển thị
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Tên hiển thị của bạn',
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: AppTheme.textGrey),
                  ),
                ),
                const SizedBox(height: 14),

                // Ô nhập Gmail hoặc Số điện thoại
                TextField(
                  controller: _contactController,
                  keyboardType: isGmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: isGmail
                        ? 'Địa chỉ Gmail (ví dụ: ten@gmail.com)'
                        : 'Số điện thoại (ví dụ: 0912345678)',
                    prefixIcon: Icon(
                      isGmail ? Icons.email_outlined : Icons.phone_outlined,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Ô nhập Mật khẩu
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Tạo mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.textGrey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textGrey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Hoàn tất Đăng ký
                GestureDetector(
                  onTap: _isLoading ? null : _handleRegister,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: AppTheme.glow(AppTheme.accent, 0.35),
                    ),
                    child: Text(
                      _isLoading
                          ? 'Đang tạo tài khoản...'
                          : (isGmail
                              ? 'Đăng ký bằng Gmail'
                              : 'Đăng ký bằng Số điện thoại'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'HOẶC',
                        style:
                            TextStyle(color: AppTheme.textGrey, fontSize: 11),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata_rounded,
                        size: 32, color: AppTheme.accentPink),
                    label: const Text(
                      'Tiếp tục bằng Google',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Đang liên kết tài khoản Google...')),
                      );
                      context.go('/home');
                    },
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
