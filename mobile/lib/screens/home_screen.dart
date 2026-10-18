import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    final playerProvider = context.read<PlayerProvider>();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final songs = await ApiService().getSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
        playerProvider.setInitialQueue(songs);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg =
              'Không kết nối được tới Backend (${ApiService.baseUrl}).\nHãy chạy "npm run dev" trong thư mục backend.';
        });
      }
    }
  }

  void _showArtistSongsSheet(BuildContext context, ArtistItem artist) {
    final artistSongs =
        _songs.where((s) => s.hasArtist(artist.name)).toList();
    final displaySongs =
        artistSongs.isNotEmpty ? artistSongs : _songs.take(3).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipOval(
                  child: Image.network(
                    artist.avatarUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.cardGrey,
                      child: Text(artist.name[0],
                          style: const TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ),
                ),
                title: Text(
                  artist.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Nghệ sĩ thịnh hành • Bài hát nổi bật',
                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
                ),
              ),
              const Divider(color: AppTheme.cardGrey),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: displaySongs.length,
                  itemBuilder: (context, index) =>
                      SongTile(song: displaySongs[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllDialog(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  // Tổng hợp danh sách Nghệ sĩ thịnh hành trực tiếp từ các bài hát trên MongoDB
  // Tự động tách từng nghệ sĩ nếu 1 bài hát có nhiều nghệ sĩ hợp tác (VD: "Sơn Tùng M-TP, RHYDER")
  List<ArtistItem> _getTrendingArtists(List<Song> sortedSongs) {
    final Map<String, List<Song>> artistSongsMap = {};
    final Map<String, String> displayNames = {};

    for (final song in sortedSongs) {
      for (final singleArtist in song.artistList) {
        final key = singleArtist.toLowerCase();
        displayNames.putIfAbsent(key, () => singleArtist);
        final list = artistSongsMap.putIfAbsent(key, () => []);
        if (!list.any((s) => s.id == song.id)) {
          list.add(song);
        }
      }
    }

    final entries = artistSongsMap.entries.toList()
      ..sort((a, b) {
        final totalPlayA =
            a.value.fold<int>(0, (sum, item) => sum + item.playCount);
        final totalPlayB =
            b.value.fold<int>(0, (sum, item) => sum + item.playCount);
        return totalPlayB.compareTo(totalPlayA);
      });

    return entries.map((entry) {
      final firstWithCover = entry.value.firstWhere(
        (s) => s.coverUrl.isNotEmpty,
        orElse: () => entry.value.first,
      );
      return ArtistItem(
        name: displayNames[entry.key] ?? entry.key,
        avatarUrl: firstWithCover.coverUrl,
        role: 'Nghệ sĩ • ${entry.value.length} bài hát',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final trendingSongs = List<Song>.from(_songs)
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final trendingArtists = _getTrendingArtists(trendingSongs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá'),
        actions: [
          // Đã xóa bỏ icon hồ sơ cá nhân ở đây, chỉ giữ lại nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _errorMsg != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 60, color: AppTheme.textGrey),
                        const SizedBox(height: 16),
                        Text(
                          _errorMsg!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textGrey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchSongs,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: _fetchSongs,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
          // 1. NHỮNG BÀI HÁT THỊNH HÀNH
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Những bài hát thịnh hành',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    _showAllDialog(
                      context,
                      'Những bài hát thịnh hành',
                      ListView.builder(
                        itemCount: trendingSongs.length,
                        itemBuilder: (context, i) =>
                            SongTile(song: trendingSongs[i]),
                      ),
                    );
                  },
                  child: const Text(
                    'Hiện tất cả',
                    style: TextStyle(
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: trendingSongs.length,
              itemBuilder: (context, index) {
                final song = trendingSongs[index];
                return GestureDetector(
                  onTap: () {
                    context
                        .read<PlayerProvider>()
                        .playSong(song, customQueue: trendingSongs);
                    context.push('/now-playing');
                  },
                  child: Container(
                    width: 155,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBlack,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.coverUrl,
                                width: 135,
                                height: 135,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 135,
                                  height: 135,
                                  color: AppTheme.cardGrey,
                                  child: const Icon(Icons.music_note,
                                      size: 48, color: AppTheme.primaryGreen),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 2. NGHỆ SĨ THỊNH HÀNH
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nghệ sĩ thịnh hành',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    _showAllDialog(
                      context,
                      'Nghệ sĩ thịnh hành',
                      ListView.builder(
                        itemCount: trendingArtists.length,
                        itemBuilder: (context, i) {
                          final artist = trendingArtists[i];
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              _showArtistSongsSheet(context, artist);
                            },
                            leading: ClipOval(
                              child: Image.network(
                                artist.avatarUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => CircleAvatar(
                                  backgroundColor: AppTheme.cardGrey,
                                  child: Text(artist.name[0]),
                                ),
                              ),
                            ),
                            title: Text(artist.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(artist.role,
                                style:
                                    const TextStyle(color: AppTheme.textGrey)),
                            trailing: const Icon(Icons.chevron_right),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text(
                    'Hiện tất cả',
                    style: TextStyle(
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: trendingArtists.length,
              itemBuilder: (context, index) {
                final artist = trendingArtists[index];
                return GestureDetector(
                  onTap: () => _showArtistSongsSheet(context, artist),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 124,
                          height: 124,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              artist.avatarUrl,
                              fit: BoxFit.cover,
                              width: 124,
                              height: 124,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.cardGrey,
                                  alignment: Alignment.center,
                                  child: Text(
                                    artist.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artist.role,
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 3. DANH SÁCH GỢI Ý CHO BẠN
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Gợi ý cho bạn hôm nay',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ..._songs.map((song) => SongTile(song: song)),
        ],
      ),
    ),
  );
  }
}
