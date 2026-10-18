import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String owner;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.owner,
    this.songs = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    var rawSongs = json['songs'] as List<dynamic>? ?? [];
    List<Song> parsedSongs = [];

    // Hỗ trợ trường hợp songs là mảng Object Song hoặc mảng ID String
    for (var item in rawSongs) {
      if (item is Map<String, dynamic>) {
        parsedSongs.add(Song.fromJson(item));
      }
    }

    return Playlist(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      owner: json['owner'] is Map ? json['owner']['_id'] : (json['owner'] ?? ''),
      songs: parsedSongs,
    );
  }
}