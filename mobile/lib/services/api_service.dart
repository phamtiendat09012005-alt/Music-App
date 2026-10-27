import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Xác định baseURL linh hoạt:
  // - Máy ảo Android: 10.0.2.2:5000
  // - Web / Windows Desktop / iOS Simulator: localhost:5000
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Tự động gắn token Bearer vào header nếu đã đăng nhập
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint('API Error: ${e.response?.statusCode} - ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  // 1. Đăng ký tài khoản
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    if (response.data['token'] != null) {
      await _storage.write(key: 'jwt_token', value: response.data['token']);
    }
    return response.data;
  }

  // 2. Đăng nhập
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (response.data['token'] != null) {
      await _storage.write(key: 'jwt_token', value: response.data['token']);
    }
    return response.data;
  }

  // 3. Đăng xuất
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // 4. Lấy danh sách bài hát trực tiếp từ MongoDB (có hỗ trợ tìm kiếm)
  Future<List<Song>> getSongs({String? search}) async {
    final query = (search ?? '').trim();
    final response = await _dio.get('/songs', queryParameters: {
      if (query.isNotEmpty) 'search': query,
    });

    final data = response.data;
    final List songList =
        data is Map ? (data['songs'] ?? []) : (data is List ? data : []);
    return songList
        .whereType<Map>()
        .map((item) => Song.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // 4b. Lấy chi tiết 1 bài hát mới nhất trực tiếp từ MongoDB (GET /api/songs/:id)
  Future<Song?> getSongById(String songId) async {
    if (songId.trim().isEmpty) return null;
    try {
      final response = await _dio.get('/songs/$songId');
      if (response.data is Map) {
        return Song.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // 5. Tăng lượt nghe trên MongoDB khi phát bài hát
  Future<void> recordPlay(String songId) async {
    try {
      await _dio.post('/songs/$songId/play');
    } catch (_) {}
  }

  // 6. Bật/Tắt bài hát yêu thích trên MongoDB
  Future<bool> toggleFavorite(String songId) async {
    final response = await _dio.post('/users/favorites/$songId');
    return response.data['isFavorite'] ?? false;
  }

  // 7. Lấy danh sách bài hát yêu thích từ MongoDB
  Future<List<Song>> getFavorites() async {
    final response = await _dio.get('/users/favorites');
    final List list = response.data is List ? response.data : [];
    return list
        .whereType<Map>()
        .map((item) => Song.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // 8. Lấy danh sách Playlist từ MongoDB
  Future<List<Playlist>> getPlaylists() async {
    final response = await _dio.get('/playlists');
    final List list = response.data is List ? response.data : [];
    return list
        .whereType<Map>()
        .map((item) => Playlist.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // 9. Tạo Playlist mới trên MongoDB (có thể kèm danh sách bài hát ban đầu)
  Future<Playlist> createPlaylist(String name, {List<String>? songIds}) async {
    final response = await _dio.post('/playlists', data: {
      'name': name,
      if (songIds != null && songIds.isNotEmpty) 'songs': songIds,
    });
    return Playlist.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // 10. Xoá Playlist trên MongoDB
  Future<void> deletePlaylist(String id) async {
    await _dio.delete('/playlists/$id');
  }

  // 10b. Thêm bài hát vào Playlist trên MongoDB
  Future<Playlist?> addSongToPlaylist(String playlistId, String songId) async {
    final response = await _dio.post(
      '/playlists/$playlistId/songs',
      data: {'songId': songId},
    );
    if (response.data is Map) {
      return Playlist.fromJson(Map<String, dynamic>.from(response.data as Map));
    }
    return null;
  }

  // 10c. Xoá bài hát khỏi Playlist trên MongoDB
  Future<Playlist?> removeSongFromPlaylist(
      String playlistId, String songId) async {
    final response = await _dio.delete('/playlists/$playlistId/songs/$songId');
    if (response.data is Map) {
      return Playlist.fromJson(Map<String, dynamic>.from(response.data as Map));
    }
    return null;
  }

  // 11. Tải nội dung file lời bài hát (.lrc) từ URL (dự phòng khi song.lyrics trống nhưng có lyricsUrl)
  Future<String> fetchLyricsFromUrl(String url) async {
    if (url.trim().isEmpty) return '';
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } catch (_) {
      return '';
    }
  }

  // 12. Lấy danh sách nghệ sĩ & ảnh đại diện chân dung từ MongoDB
  Future<List<ArtistItem>> getArtists({String? search}) async {
    try {
      final query = (search ?? '').trim();
      final response = await _dio.get('/artists', queryParameters: {
        if (query.isNotEmpty) 'search': query,
      });
      final data = response.data;
      final List list =
          data is Map ? (data['artists'] ?? []) : (data is List ? data : []);
      return list
          .whereType<Map>()
          .map((item) => ArtistItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Lỗi lấy danh sách nghệ sĩ: $e');
      return [];
    }
  }
}
