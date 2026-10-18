import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGmail = _selectedMethod == RegisterMethod.gmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chọn phương thức đăng ký',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Thanh chuyển đổi: Đăng ký bằng Gmail / Số điện thoại
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.cardGrey,
                  borderRadius: BorderRadius.circular(30),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isGmail
                                ? AppTheme.primaryGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: isGmail ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bằng Gmail',
                                style: TextStyle(
                                  color: isGmail ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isGmail
                                ? AppTheme.primaryGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android_outlined,
                                size: 18,
                                color: !isGmail ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Số điện thoại',
                                style: TextStyle(
                                  color: !isGmail ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 24),

              // Ô nhập Tên hiển thị (name)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên hiển thị (name)',
                  prefixIcon: const Icon(Icons.badge_outlined,
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

              // Ô nhập thay đổi linh hoạt theo phương thức đã chọn (Gmail hoặc SĐT)
              TextField(
                controller: _contactController,
                keyboardType:
                    isGmail ? TextInputType.emailAddress : TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isGmail
                      ? 'Địa chỉ Gmail (ví dụ: ten@gmail.com)'
                      : 'Số điện thoại (ví dụ: 0912345678)',
                  prefixIcon: Icon(
                    isGmail ? Icons.email_outlined : Icons.phone_outlined,
                    color: AppTheme.textGrey,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ô nhập Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Tạo mật khẩu',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: AppTheme.textGrey),
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
              const SizedBox(height: 24),

              // Nút Hoàn tất Đăng ký
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isGmail
                              ? 'Đăng ký tài khoản bằng Gmail thành công!'
                              : 'Đăng ký tài khoản bằng Số điện thoại thành công!',
                        ),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                    context.go('/home');
                  },
                  child: Text(isGmail
                      ? 'ĐĂNG KÝ BẰNG GMAIL'
                      : 'ĐĂNG KÝ BẰNG SỐ ĐIỆN THOẠI'),
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
                        style:
                            TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ),
                  Expanded(
                      child: Divider(color: AppTheme.cardGrey, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // Nút Đăng nhập / Đăng ký bằng Google
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
                    'Đăng nhập bằng Google',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đang liên kết tài khoản Google...')),
                    );
                    context.go('/home');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
