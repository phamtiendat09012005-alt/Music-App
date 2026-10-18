class AppConstants {
  // 10.0.2.2 trỏ về localhost máy tính nếu chạy Android Emulator
  // Đổi thành IP LAN máy tính (VD: 192.168.1.x:5000) nếu cắm điện thoại thật
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
}