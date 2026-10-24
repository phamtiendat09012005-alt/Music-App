// Loại bỏ toàn bộ dấu tiếng Việt (cả tổ hợp NFD và dựng sẵn NFC)
String removeVietnameseDiacritics(String str) {
  var result = str;
  // Bỏ dấu tổ hợp NFD
  result = result.replaceAll(RegExp(r'[\u0300\u0301\u0303\u0309\u0323]'), '');
  result = result.replaceAll(RegExp(r'[\u0302\u0306\u031b]'), '');

  const map = {
    'a': 'áàảãạăắằẳẵặâấầẩẫậ',
    'A': 'ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ',
    'd': 'đ',
    'D': 'Đ',
    'e': 'éèẻẽẹêếềểễệ',
    'E': 'ÉÈẺẼẸÊẾỀỂỄỆ',
    'i': 'íìỉĩị',
    'I': 'ÍÌỈĨỊ',
    'o': 'óòỏõọôốồổỗộơớờởỡợ',
    'O': 'ÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ',
    'u': 'úùủũụưứừửữự',
    'U': 'ÚÙỦŨỤƯỨỪỬỮỰ',
    'y': 'ýỳỷỹỵ',
    'Y': 'ÝỲỶỸỴ',
  };

  map.forEach((nonDia, dia) {
    for (int i = 0; i < dia.length; i++) {
      result = result.replaceAll(dia[i], nonDia);
    }
  });

  return result;
}

// Helper chuẩn hóa tên nghệ sĩ hiển thị sạch sẽ
String cleanArtistName(String raw) {
  return raw
      .replaceAll(RegExp(r'^[(\[\s]+|[)\]\s]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// Helper chuẩn hóa canonical key so sánh nghệ sĩ (bỏ qua dấu tiếng Việt, dấu nối, khoảng trắng thừa, chữ hoa/thường, và hợp nhất bí danh)
String normalizeArtistKey(String raw) {
  final cleaned = cleanArtistName(raw);
  if (cleaned.isEmpty) return '';

  final simple = removeVietnameseDiacritics(cleaned)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  // Hợp nhất các biến thể tên gọi thường gặp của cùng một nghệ sĩ
  if (simple == 'sontung' || simple == 'sontungmtp' || simple == 'sontungm') {
    return 'sontungmtp';
  }
  if (simple == 'jack' || simple == 'j97' || simple == 'jackj97' || simple == 'jack97') {
    return 'jackj97';
  }
  if (simple == 'soobin' || simple == 'soobinhoangson') {
    return 'soobin';
  }
  if (simple == 'hieuthuhai' || simple == 'hieuthu2') {
    return 'hieuthuhai';
  }
  if (simple == 'hoangthuylinh') {
    return 'hoangthuylinh';
  }
  if (simple == 'phuongly') {
    return 'phuongly';
  }
  if (simple == 'vu' || simple == 'hoangthaiu') {
    return 'vu';
  }

  return simple;
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String audioUrl;
  final String instrumentalUrl;
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
    this.instrumentalUrl = '',
    required this.coverUrl,
    this.lyricsUrl = '',
    this.lyrics = '',
    required this.duration,
    this.playCount = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final rawLyrics = (json['lyrics'] ?? '').toString();
    // Bỏ qua chuỗi lời mẫu giả lập cũ (nếu có) để chỉ dùng lời bài hát thật từ MongoDB
    final cleanLyrics =
        rawLyrics.contains('Giai điệu mở đầu nhẹ nhàng vang lên...')
            ? ''
            : rawLyrics;

    return Song(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      genre: (json['genre'] ?? '').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      instrumentalUrl: (json['instrumentalUrl'] ?? '').toString(),
      coverUrl: (json['coverUrl'] ?? '').toString(),
      lyricsUrl: (json['lyricsUrl'] ?? '').toString(),
      lyrics: cleanLyrics,
      duration: (json['duration'] is num) ? (json['duration'] as num).toInt() : 0,
      playCount: (json['playCount'] is num) ? (json['playCount'] as num).toInt() : 0,
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? genre,
    String? audioUrl,
    String? instrumentalUrl,
    String? coverUrl,
    String? lyricsUrl,
    String? lyrics,
    int? duration,
    int? playCount,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      audioUrl: audioUrl ?? this.audioUrl,
      instrumentalUrl: instrumentalUrl ?? this.instrumentalUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      lyricsUrl: lyricsUrl ?? this.lyricsUrl,
      lyrics: lyrics ?? this.lyrics,
      duration: duration ?? this.duration,
      playCount: playCount ?? this.playCount,
    );
  }

  bool get hasInstrumental => instrumentalUrl.trim().isNotEmpty;
  bool get hasLyrics => lyrics.trim().isNotEmpty || lyricsUrl.trim().isNotEmpty;

  static final RegExp _artistSplitRegex = RegExp(
    r'(?:\s*[,;/&]\s*|\s+(?:ft|feat|featuring|vs)\.?\s+|\b(?:ft|feat|featuring|vs)\.\s*|\s+x\s+|\s+v[àa]\s+)',
    caseSensitive: false,
  );

  // Tách danh sách từng nghệ sĩ nếu bài hát có nhiều nghệ sĩ (ngăn cách bởi ',', ';', '/', '&', 'ft.', 'feat.', 'x'...)
  List<String> get artistList {
    final list = artist
        .split(_artistSplitRegex)
        .map((name) => cleanArtistName(name))
        .where((name) => name.isNotEmpty)
        .toList();
    return list.isNotEmpty ? list : [cleanArtistName(artist)];
  }

  // Kiểm tra bài hát có sự tham gia của nghệ sĩ này không (chuẩn hóa key và so khớp linh hoạt)
  bool hasArtist(String artistName) {
    final targetKey = normalizeArtistKey(artistName);
    if (targetKey.isEmpty) return false;

    // 1. Khớp chính xác với bất kỳ nghệ sĩ nào trong danh sách đã tách
    for (final a in artistList) {
      if (normalizeArtistKey(a) == targetKey) return true;
    }

    // 2. So khớp với toàn bộ chuỗi artist
    final fullKey = normalizeArtistKey(artist);
    if (fullKey == targetKey) return true;

    // 3. Khớp nếu targetKey xuất hiện trọn vẹn trong chuỗi artist
    if (fullKey.contains(targetKey)) return true;

    return false;
  }
}

class ArtistItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String role;
  final String bio;
  final int songCount;
  final int totalPlayCount;
  final bool hasCustomAvatar;

  const ArtistItem({
    this.id = '',
    required this.name,
    required this.avatarUrl,
    this.role = 'Nghệ sĩ',
    this.bio = '',
    this.songCount = 0,
    this.totalPlayCount = 0,
    this.hasCustomAvatar = false,
  });

  factory ArtistItem.fromJson(Map<String, dynamic> json) {
    return ArtistItem(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
      role: (json['songCount'] != null && json['songCount'] > 0)
          ? 'Nghệ sĩ • ${json['songCount']} bài hát'
          : 'Nghệ sĩ',
      bio: (json['bio'] ?? '').toString(),
      songCount: (json['songCount'] is num) ? (json['songCount'] as num).toInt() : 0,
      totalPlayCount:
          (json['totalPlayCount'] is num) ? (json['totalPlayCount'] as num).toInt() : 0,
      hasCustomAvatar: json['hasCustomAvatar'] == true,
    );
  }
}

// Danh sách rỗng (không cài cứng bài hát hay nghệ sĩ, toàn bộ được tổng hợp trực tiếp từ MongoDB)
const List<ArtistItem> trendingArtists = [];
final List<Song> mockSongs = [];
