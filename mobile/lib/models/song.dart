class Song {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String audioUrl;
  final String coverUrl;
  final String lyricsUrl;
  final String lyrics;
  final int duration;
  final int playCount;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.audioUrl,
    required this.coverUrl,
    this.lyricsUrl = '',
    this.lyrics = '',
    required this.duration,
    this.playCount = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      genre: (json['genre'] ?? '').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      coverUrl: (json['coverUrl'] ?? '').toString(),
      lyricsUrl: (json['lyricsUrl'] ?? '').toString(),
      lyrics: (json['lyrics'] ?? '').toString(),
      duration: (json['duration'] is num) ? (json['duration'] as num).toInt() : 0,
      playCount: (json['playCount'] is num) ? (json['playCount'] as num).toInt() : 0,
    );
  }

  // Tách danh sách từng nghệ sĩ nếu bài hát có nhiều nghệ sĩ (ngăn cách bởi ',', ';', '&', 'ft.', 'feat.', 'x')
  List<String> get artistList {
    return artist
        .split(RegExp(r'\s*(?:,|;|(?:\b(?:ft|feat)\.?\b)|&|\bx\b)\s*',
            caseSensitive: false))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  // Kiểm tra bài hát có sự tham gia của nghệ sĩ này không (không phân biệt hoa/thường)
  bool hasArtist(String artistName) {
    final target = artistName.trim().toLowerCase();
    return artistList.any((a) => a.toLowerCase() == target);
  }
}

class ArtistItem {
  final String name;
  final String avatarUrl;
  final String role;

  const ArtistItem({
    required this.name,
    required this.avatarUrl,
    this.role = 'Nghệ sĩ',
  });
}

// Danh sách rỗng (không cài cứng bài hát hay nghệ sĩ, toàn bộ được tổng hợp trực tiếp từ MongoDB)
const List<ArtistItem> trendingArtists = [];
final List<Song> mockSongs = [];
