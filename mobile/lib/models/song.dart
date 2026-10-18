class Song {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String audioUrl;
  final String coverUrl;
  final String lyricsUrl;
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
    required this.duration,
    this.playCount = 0,
  });

  // Chuyển đổi từ JSON của API sang Object
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      genre: json['genre'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      lyricsUrl: json['lyricsUrl'] ?? '',
      duration: json['duration'] ?? 0,
      playCount: json['playCount'] ?? 0,
    );
  }
}

// Dữ liệu giả (Mock Data) để test giao diện trước khi nối Backend
final List<Song> mockSongs = [
  Song(
    id: '1',
    title: 'Acoustic Breeze',
    artist: 'Benjamin Tissot',
    genre: 'Acoustic',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
    duration: 185,
    playCount: 120,
  ),
  Song(
    id: '2',
    title: 'Creative Minds',
    artist: 'FMA Artist',
    genre: 'Electronic',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
    duration: 215,
    playCount: 85,
  ),
  Song(
    id: '3',
    title: 'Sunny Days',
    artist: 'Jamendo Tracks',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    coverUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400',
    duration: 198,
    playCount: 240,
  ),
];