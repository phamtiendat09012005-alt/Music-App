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

// Toàn bộ link ảnh Nghệ sĩ thịnh hành đã được kiểm tra hiển thị 100% trên Chrome
const List<ArtistItem> trendingArtists = [
  ArtistItem(
    name: 'Sơn Tùng M-TP',
    avatarUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Son_Tung_M-TP_1_%282017%29.png/500px-Son_Tung_M-TP_1_%282017%29.png',
  ),
  ArtistItem(
    name: 'SOOBIN',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
  ),
  ArtistItem(
    name: 'RHYDER',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
  ),
  ArtistItem(
    name: 'Hoàng Thùy Linh',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
  ),
  ArtistItem(
    name: 'HIEUTHUHAI',
    avatarUrl:
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&auto=format&fit=crop&q=80',
  ),
  ArtistItem(
    name: 'Vũ.',
    avatarUrl:
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400&auto=format&fit=crop&q=80',
  ),
];

// Danh sách bài hát thịnh hành với link ảnh không bị chặn CORS trên Web
final List<Song> mockSongs = [
  Song(
    id: '1',
    title: 'Chúng Ta Của Tương Lai',
    artist: 'Sơn Tùng M-TP',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    coverUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Son_Tung_M-TP_1_%282017%29.png/500px-Son_Tung_M-TP_1_%282017%29.png',
    duration: 240,
    playCount: 990,
  ),
  Song(
    id: '2',
    title: 'Trong Đôi Mắt Thiếu Nữ',
    artist: 'RHYDER',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    coverUrl:
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&auto=format&fit=crop&q=80',
    duration: 210,
    playCount: 950,
  ),
  Song(
    id: '3',
    title: 'Thấy Dùi',
    artist: 'Hoàng Thùy Linh',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    coverUrl:
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&auto=format&fit=crop&q=80',
    duration: 195,
    playCount: 890,
  ),
  Song(
    id: '4',
    title: 'Giá Như',
    artist: 'SOOBIN',
    genre: 'Ballad',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    coverUrl:
        'https://images.unsplash.com/photo-1445985543470-41fba5c3144a?w=400&auto=format&fit=crop&q=80',
    duration: 215,
    playCount: 870,
  ),
  Song(
    id: '5',
    title: 'Ngáo Ngơ',
    artist: 'HIEUTHUHAI',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    coverUrl:
        'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=400&auto=format&fit=crop&q=80',
    duration: 200,
    playCount: 840,
  ),
  Song(
    id: '6',
    title: 'Thành Đô',
    artist: 'GUrbane',
    genre: 'Ballad',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    coverUrl:
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&auto=format&fit=crop&q=80',
    duration: 225,
    playCount: 820,
  ),
  Song(
    id: '7',
    title: 'NEON',
    artist: 'A2O, A2O LITE',
    genre: 'Electronic',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    coverUrl:
        'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&auto=format&fit=crop&q=80',
    duration: 188,
    playCount: 760,
  ),
  Song(
    id: '8',
    title: 'Nhẹ Buông',
    artist: 'Hằng ssi, Aries tis',
    genre: 'Lofi',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    coverUrl:
        'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400&auto=format&fit=crop&q=80',
    duration: 205,
    playCount: 710,
  ),
];
