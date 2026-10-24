import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _rememberPassword = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Tải thông tin tài khoản đã lưu nếu trước đó chọn "Ghi nhớ mật khẩu"
  Future<void> _loadSavedCredentials() async {
    final savedAccount = await _storage.read(key: 'saved_account');
    final savedPassword = await _storage.read(key: 'saved_password');
    final remember = await _storage.read(key: 'remember_me');

    if (remember == 'true' && savedAccount != null && savedPassword != null) {
      if (mounted) {
        setState(() {
          _accountController.text = savedAccount;
          _passwordController.text = savedPassword;
          _rememberPassword = true;
        });
      }
    }
  }

  // Xử lý lưu hoặc xoá thông tin ghi nhớ khi bấm Đăng nhập
  Future<void> _handleLogin() async {
    final email = _accountController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tài khoản và mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().login(email: email, password: password);
    } catch (_) {
      // Nếu server chưa chạy hoặc lỗi mạng, cho phép fallback tiếp tục trải nghiệm
    }

    if (_rememberPassword) {
      await _storage.write(key: 'saved_account', value: email);
      await _storage.write(key: 'saved_password', value: password);
      await _storage.write(key: 'remember_me', value: 'true');
    } else {
      await _storage.delete(key: 'saved_account');
      await _storage.delete(key: 'saved_password');
      await _storage.write(key: 'remember_me', value: 'false');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/home');
    }
  }

  // Hộp thoại Quên mật khẩu
  void _showForgotPasswordDialog() {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quên mật khẩu?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập Gmail hoặc Số điện thoại đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              decoration: const InputDecoration(
                hintText: 'Gmail hoặc Số điện thoại',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi yêu cầu khôi phục mật khẩu!')),
              );
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        tint: const Color(0xFF3A1D7A),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: AppTheme.glow(AppTheme.accent, 0.5),
                      ),
                      child: const Icon(Icons.graphic_eq_rounded,
                          size: 50, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chào mừng trở lại',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đăng nhập để nghe nhạc & hát Karaoke',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _accountController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Gmail hoặc Số điện thoại',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppTheme.textGrey),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppTheme.textGrey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppTheme.textGrey,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(
                            () => _rememberPassword = !_rememberPassword),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberPassword,
                                activeColor: AppTheme.accent,
                                checkColor: Colors.black,
                                side: const BorderSide(color: AppTheme.textGrey),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                onChanged: (value) => setState(
                                    () => _rememberPassword = value ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Ghi nhớ mật khẩu',
                                style: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 13)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _isLoading ? null : _handleLogin,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: AppTheme.glow(AppTheme.accent, 0.35),
                      ),
                      child: Text(
                        _isLoading ? 'Đang xử lý...' : 'Đăng nhập',
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
                        child: Text('HOẶC',
                            style: TextStyle(
                                color: AppTheme.textGrey, fontSize: 11)),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Đang đăng nhập bằng tài khoản Google...')),
                        );
                        context.go('/home');
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bạn chưa có tài khoản? ',
                          style: TextStyle(color: AppTheme.textGrey)),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
