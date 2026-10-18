import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/theme.dart';

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
    if (_rememberPassword) {
      await _storage.write(
          key: 'saved_account', value: _accountController.text.trim());
      await _storage.write(
          key: 'saved_password', value: _passwordController.text);
      await _storage.write(key: 'remember_me', value: 'true');
    } else {
      await _storage.delete(key: 'saved_account');
      await _storage.delete(key: 'saved_password');
      await _storage.write(key: 'remember_me', value: 'false');
    }

    if (mounted) {
      context.go('/home');
    }
  }

  // Hộp thoại Quên mật khẩu
  void _showForgotPasswordDialog() {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Quên mật khẩu?',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
              decoration: InputDecoration(
                hintText: 'Gmail hoặc Số điện thoại',
                filled: true,
                fillColor: AppTheme.surfaceBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Huỷ', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi yêu cầu khôi phục mật khẩu!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.music_note_rounded,
                    size: 72, color: AppTheme.primaryGreen),
                const SizedBox(height: 12),
                const Text(
                  'Đăng nhập vào Music App',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // Ô nhập Gmail hoặc Số điện thoại
                TextField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    labelText: 'Gmail hoặc Số điện thoại',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppTheme.textGrey),
                    filled: true,
                    fillColor: AppTheme.cardGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ô nhập Mật khẩu kèm nút ẩn/hiện
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textGrey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textGrey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppTheme.cardGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Hàng Ghi nhớ mật khẩu & Quên mật khẩu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberPassword,
                            activeColor: AppTheme.primaryGreen,
                            checkColor: Colors.black,
                            onChanged: (value) {
                              setState(
                                  () => _rememberPassword = value ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(
                              () => _rememberPassword = !_rememberPassword),
                          child: const Text(
                            'Ghi nhớ mật khẩu',
                            style: TextStyle(
                                color: AppTheme.textGrey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nút Đăng nhập chính
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('ĐĂNG NHẬP'),
                  ),
                ),
                const SizedBox(height: 24),

                // Đường kẻ phân cách "HOẶC"
                const Row(
                  children: [
                    Expanded(
                        child: Divider(color: AppTheme.cardGrey, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('HOẶC',
                          style: TextStyle(
                              color: AppTheme.textGrey, fontSize: 12)),
                    ),
                    Expanded(
                        child: Divider(color: AppTheme.cardGrey, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // Nút Đăng nhập bằng Google
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.textGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.g_mobiledata,
                        size: 32, color: Colors.redAccent),
                    label: const Text(
                      'Tiếp tục bằng Google',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

                // Chuyển sang màn hình Đăng ký
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
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
