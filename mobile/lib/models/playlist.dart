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
    required this.songs,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? owner,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
      songs: songs ?? this.songs,
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawSongs = json['songs'] as List? ?? [];
    final parsedSongs = rawSongs
        .whereType<Map>()
        .map((item) => Song.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return Playlist(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      owner: (json['owner'] ?? 'user1').toString(),
      songs: parsedSongs,
    );
  }
}