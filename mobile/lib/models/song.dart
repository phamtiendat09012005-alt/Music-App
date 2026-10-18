class Song {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String audioUrl;
  final String coverUrl;
  final String? lyricsUrl;
  final int duration;
  final int playCount;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.audioUrl,
    required this.coverUrl,
    this.lyricsUrl,
    required this.duration,
    this.playCount = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      genre: json['genre'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      lyricsUrl: json['lyricsUrl'],
      duration: json['duration'] ?? 0,
      playCount: json['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'genre': genre,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'lyricsUrl': lyricsUrl,
      'duration': duration,
      'playCount': playCount,
    };
  }
}