import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/song.dart';
import '../models/user.dart';
import '../models/playlist.dart';

class ApiService {
  final Dio _dio = DioClient().dio;

  // --- XÁC THỰC ---
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<User> getMe() async {
    final response = await _dio.get('/auth/me');
    return User.fromJson(response.data);
  }

  // --- BÀI HÁT ---
  Future<List<Song>> getSongs({String search = '', int page = 1, int limit = 20}) async {
    final response = await _dio.get('/songs', queryParameters: {
      'search': search,
      'page': page,
      'limit': limit,
    });
    final list = response.data as List<dynamic>;
    return list.map((json) => Song.fromJson(json)).toList();
  }

  // --- YÊU THÍCH ---
  Future<List<Song>> getFavorites() async {
    final response = await _dio.get('/favorites');
    final list = response.data as List<dynamic>;
    return list.map((json) => Song.fromJson(json)).toList();
  }

  Future<void> addFavorite(String songId) async {
    await _dio.post('/favorites/$songId');
  }

  Future<void> removeFavorite(String songId) async {
    await _dio.delete('/favorites/$songId');
  }

  // --- PLAYLIST ---
  Future<List<Playlist>> getPlaylists() async {
    final response = await _dio.get('/playlists');
    final list = response.data as List<dynamic>;
    return list.map((json) => Playlist.fromJson(json)).toList();
  }

  Future<Playlist> createPlaylist(String name) async {
    final response = await _dio.post('/playlists', data: {'name': name});
    return Playlist.fromJson(response.data);
  }

  Future<Playlist> getPlaylistDetail(String playlistId) async {
    final response = await _dio.get('/playlists/$playlistId');
    return Playlist.fromJson(response.data);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _dio.delete('/playlists/$playlistId');
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _dio.post('/playlists/$playlistId/songs/$songId');
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _dio.delete('/playlists/$playlistId/songs/$songId');
  }

  // --- LỊCH SỬ NGHE ---
  Future<void> logHistory(String songId) async {
    await _dio.post('/history', data: {'songId': songId});
  }

  Future<List<Song>> getHistory() async {
    final response = await _dio.get('/history');
    final list = response.data as List<dynamic>;
    return list.map((json) => Song.fromJson(json)).toList();
  }
}