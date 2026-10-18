import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Song> _songs = [];
  bool _loading = true;
  int _selectedChip = 0;

  final List<Song> _fallbackSongs = [
    Song(
      id: 'esound_1',
      title: 'Acoustic Breeze',
      artist: 'Benjamin Tissot',
      genre: 'Acoustic',
      audioUrl: 'https://www.bensound.com/bensound-music/bensound-acousticbreeze.mp3',
      coverUrl: 'https://picsum.photos/id/1025/600/600',
      duration: 161,
    ),
    Song(
      id: 'esound_2',
      title: 'Sunny Day Melodies',
      artist: 'SoundHelix',
      genre: 'Pop',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      coverUrl: 'https://picsum.photos/id/103/600/600',
      duration: 372,
    ),
    Song(
      id: 'esound_3',
      title: 'Midnight Electronic',
      artist: 'Free Music Archive',
      genre: 'Electronic',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      coverUrl: 'https://picsum.photos/id/146/600/600',
      duration: 423,
    ),
    Song(
      id: 'esound_4',
      title: 'Cyberpunk Vibes',
      artist: 'Jamendo Studio',
      genre: 'Synthwave',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      coverUrl: 'https://picsum.photos/id/250/600/600',
      duration: 315,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final list = await _apiService.getSongs();
      setState(() {
        _songs = list.isNotEmpty ? list : _fallbackSongs;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _songs = _fallbackSongs;
        _loading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng ✨';
    if (hour < 18) return 'Chào buổi chiều 🎧';
    return 'Chào buổi tối 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final chips = ['Khám phá', 'Thịnh hành', 'Acoustic', 'Chill Lo-Fi'];
    final featuredSong = _songs.isNotEmpty ? _songs.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.9),
            radius: 1.4,
            colors: [Color(0xFF1A3826), Color(0xFF09090B)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
              : RefreshIndicator(
                  color: const Color(0xFF1DB954),
                  onRefresh: _loadSongs,
                  child: CustomScrollView(
                    slivers: [
                      // 1. Header hiện đại
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MUSIC STREAMING',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1.8,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1DB954).withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getGreeting(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => context.push('/login'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Chips lọc có hiệu ứng chuyển màu
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: chips.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (ctx, i) {
                              final selected = _selectedChip == i;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedChip = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFF1DB954) : Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: selected ? Colors.transparent : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      chips[i],
                                      style: TextStyle(
                                        color: selected ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 3. Spotlight Hero Card (Banner Bài hát Tâm điểm)
                      if (featuredSong != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: GestureDetector(
                              onTap: () => context.read<PlayerProvider>().playPlaylist(_songs, 0),
                              child: Container(
                                height: 175,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: featuredSong.coverUrl,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.black.withOpacity(0.9),
                                              Colors.black.withOpacity(0.55),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1DB954),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'TÂM ĐIỂM HÔM NAY',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              featuredSong.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              featuredSong.artist,
                                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: const Row(
                                                    children: [
                                                      Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Phát ngay',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 4. Carousel Tuyển tập dành riêng
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Text(
                            'Đề xuất cho bạn',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 210,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _songs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (ctx, idx) {
                              final song = _songs[idx];
                              return GestureDetector(
                                onTap: () => context.read<PlayerProvider>().playPlaylist(_songs, idx),
                                child: SizedBox(
                                  width: 148,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: CachedNetworkImage(
                                              imageUrl: song.coverUrl,
                                              width: 148,
                                              height: 148,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            right: 10,
                                            bottom: 10,
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1DB954),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.5),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
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
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 5. Danh sách Top Xu Hướng
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            'Bảng xếp hạng Thịnh hành',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, idx) => SongTile(
                            song: _songs[idx],
                            playlist: _songs,
                            index: idx,
                          ),
                          childCount: _songs.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}