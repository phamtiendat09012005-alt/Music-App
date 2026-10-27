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
  List<ArtistItem> _customArtists = [];
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
      final results = await Future.wait([
        ApiService().getSongs(),
        ApiService().getArtists(),
      ]);
      final songs = results[0] as List<Song>;
      final artists = results[1] as List<ArtistItem>;

      if (mounted) {
        setState(() {
          _songs = songs;
          _customArtists = artists;
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Chào buổi sáng';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  void _play(Song song, List<Song> queue, {int? viewMode}) {
    final player = context.read<PlayerProvider>();
    player.playSong(song, customQueue: queue);
    if (viewMode != null) player.setViewMode(viewMode);
    context.push('/now-playing');
  }

  // ---------------------------------------------------------------------------
  // Bottom sheets
  // ---------------------------------------------------------------------------
  void _showArtistSongsSheet(BuildContext context, ArtistItem artist) {
    final artistSongs = _songs.where((s) => s.hasArtist(artist.name)).toList();
    final totalPlays = artistSongs.fold<int>(0, (sum, s) => sum + s.playCount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                  child: Row(
                    children: [
                      _GradientRingAvatar(url: artist.avatarUrl, size: 78),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${artistSongs.length} bài hát • $totalPlays lượt nghe',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (artist.bio.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                artist.bio,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.textGrey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                if (artistSongs.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _GradientButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'Phát tất cả',
                            onTap: () {
                              Navigator.pop(context);
                              _play(artistSongs.first, artistSongs);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                          ),
                          icon: const Icon(Icons.shuffle_rounded,
                              size: 20, color: AppTheme.accentPink),
                          label: const Text('Trộn bài',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () {
                            final shuffled = List<Song>.from(artistSongs)
                              ..shuffle();
                            Navigator.pop(context);
                            _play(shuffled.first, shuffled);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: artistSongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_off_rounded,
                                  size: 54, color: AppTheme.textGrey),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có bài hát nào của ${artist.name}',
                                style: const TextStyle(
                                    color: AppTheme.textGrey, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: artistSongs.length,
                          itemBuilder: (context, index) => SongTile(
                            song: artistSongs[index],
                            customQueue: artistSongs,
                            index: index,
                            showTrackNumber: true,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAllSheet(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
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

  // Tổng hợp nghệ sĩ từ các bài hát trên MongoDB (gộp theo key chuẩn hoá)
  List<ArtistItem> _getTrendingArtists(List<Song> sortedSongs) {
    final Map<String, List<Song>> artistSongsMap = {};
    final Map<String, String> displayNames = {};

    for (final song in sortedSongs) {
      for (final singleArtist in song.artistList) {
        final key = normalizeArtistKey(singleArtist);
        if (key.isEmpty) continue;
        if (!displayNames.containsKey(key) ||
            singleArtist.trim().length > displayNames[key]!.length) {
          displayNames[key] = cleanArtistName(singleArtist);
        }
        final list = artistSongsMap.putIfAbsent(key, () => []);
        if (!list.any((s) => s.id == song.id)) {
          list.add(song);
        }
      }
    }

    final customMap = {
      for (final a in _customArtists) normalizeArtistKey(a.name): a
    };

    final Map<String, ArtistItem> mergedMap = {};

    for (final entry in artistSongsMap.entries) {
      final key = entry.key;
      final custom = customMap[key];
      final songList = entry.value;
      final totalPlayCount =
          songList.fold<int>(0, (sum, item) => sum + item.playCount);

      final firstWithCover = songList.firstWhere(
        (s) => s.coverUrl.isNotEmpty,
        orElse: () => songList.first,
      );

      final avatarUrl = (custom != null && custom.avatarUrl.trim().isNotEmpty)
          ? custom.avatarUrl.trim()
          : firstWithCover.coverUrl;

      mergedMap[key] = ArtistItem(
        id: custom?.id ?? '',
        name: (custom != null && custom.name.trim().isNotEmpty)
            ? custom.name.trim()
            : (displayNames[key] ?? key),
        avatarUrl: avatarUrl,
        role: 'Nghệ sĩ • ${songList.length} bài hát',
        bio: custom?.bio ?? '',
        songCount: songList.length,
        totalPlayCount: totalPlayCount,
        hasCustomAvatar: custom?.hasCustomAvatar ??
            (custom != null && custom.avatarUrl.trim().isNotEmpty),
      );
    }

    for (final custom in _customArtists) {
      final key = normalizeArtistKey(custom.name);
      if (!mergedMap.containsKey(key)) {
        mergedMap[key] = custom;
      }
    }

    final result = mergedMap.values.toList();
    result.sort((a, b) {
      final playCmp = b.totalPlayCount.compareTo(a.totalPlayCount);
      if (playCmp != 0) return playCmp;
      return b.songCount.compareTo(a.songCount);
    });
    return result;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()} 👋',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (r) => AppTheme.accentGradient.createShader(r),
                  child: const Text(
                    'Hôm nay nghe gì nào?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.07),
            ),
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              await ApiService().logout();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Song song, List<Song> queue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: GestureDetector(
        onTap: () => _play(song, queue),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF6D3BFF), Color(0xFFFF5FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppTheme.glow(const Color(0xFF6D3BFF), 0.45),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '🔥 NGHE NHIỀU NHẤT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow_rounded,
                                        color: Colors.black, size: 20),
                                    SizedBox(width: 4),
                                    Text('Phát ngay',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _play(song, queue, viewMode: 2),
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mic_rounded,
                                      size: 20, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Transform.rotate(
                      angle: 0.08,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CoverImage(
                            url: song.coverUrl, size: 124, radius: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard(Song song, int rank, List<Song> queue) {
    return GestureDetector(
      onTap: () => _play(song, queue),
      child: SizedBox(
        width: 150,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CoverImage(url: song.coverUrl, size: 136, radius: 22),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: AppTheme.accentAqua,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.black, size: 24),
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
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKaraokeCard(Song song, List<Song> queue) {
    return GestureDetector(
      onTap: () => _play(song, queue, viewMode: 2),
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardGrey,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            CoverImage(url: song.coverUrl, size: 62, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.mic_rounded,
                          size: 14, color: AppTheme.accentPink),
                      const SizedBox(width: 4),
                      Text(
                        song.hasInstrumental ? 'Có nhạc Beat' : 'Có lời',
                        style: const TextStyle(
                          color: AppTheme.accentPink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildArtistCard(ArtistItem artist) {
    return GestureDetector(
      onTap: () => _showArtistSongsSheet(context, artist),
      child: SizedBox(
        width: 108,
        child: Column(
          children: [
            _GradientRingAvatar(url: artist.avatarUrl, size: 92),
            const SizedBox(height: 10),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '${artist.songCount} bài hát',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trendingSongs = List<Song>.from(_songs)
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final trendingArtists = _getTrendingArtists(trendingSongs);
    final karaokeSongs =
        _songs.where((s) => s.hasInstrumental || s.hasLyrics).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent))
              : _errorMsg != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 64, color: AppTheme.textGrey),
                            const SizedBox(height: 16),
                            Text(
                              _errorMsg!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textGrey),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _fetchSongs,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.accent,
                      backgroundColor: AppTheme.cardGrey,
                      onRefresh: _fetchSongs,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 155),
                        children: [
                          _buildHeader(),
                          if (trendingSongs.isNotEmpty)
                            _buildHero(trendingSongs.first, trendingSongs),

                          const SizedBox(height: 18),

                          // 1. THỊNH HÀNH
                          SectionHeader(
                            title: 'Đang thịnh hành',
                            subtitle: 'Xếp hạng theo lượt nghe',
                            onSeeAll: () => _showAllSheet(
                              'Đang thịnh hành',
                              ListView.builder(
                                itemCount: trendingSongs.length,
                                itemBuilder: (context, i) => SongTile(
                                  song: trendingSongs[i],
                                  customQueue: trendingSongs,
                                  index: i,
                                  showTrackNumber: true,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 214,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 13),
                              itemCount: trendingSongs.length,
                              itemBuilder: (context, index) =>
                                  _buildTrendingCard(
                                      trendingSongs[index],
                                      index + 1,
                                      trendingSongs),
                            ),
                          ),

                          // 2. SÂN KHẤU KARAOKE
                          if (karaokeSongs.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const SectionHeader(
                              title: '🎤 Sân khấu Karaoke',
                              subtitle: 'Chọn bài và hát theo lời chạy',
                            ),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                itemCount: karaokeSongs.length,
                                itemBuilder: (context, i) =>
                                    _buildKaraokeCard(
                                        karaokeSongs[i], karaokeSongs),
                              ),
                            ),
                          ],

                          // 3. NGHỆ SĨ
                          const SizedBox(height: 14),
                          SectionHeader(
                            title: 'Nghệ sĩ nổi bật',
                            onSeeAll: () => _showAllSheet(
                              'Nghệ sĩ nổi bật',
                              ListView.builder(
                                itemCount: trendingArtists.length,
                                itemBuilder: (context, i) {
                                  final artist = trendingArtists[i];
                                  return ListTile(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showArtistSongsSheet(context, artist);
                                    },
                                    leading: CoverImage(
                                        url: artist.avatarUrl,
                                        size: 52,
                                        circle: true),
                                    title: Text(artist.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    subtitle: Text(artist.role,
                                        style: const TextStyle(
                                            color: AppTheme.textGrey)),
                                    trailing: const Icon(
                                        Icons.chevron_right_rounded),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: trendingArtists.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, index) =>
                                  _buildArtistCard(trendingArtists[index]),
                            ),
                          ),

                          // 4. GỢI Ý
                          const SizedBox(height: 14),
                          const SectionHeader(
                            title: 'Gợi ý cho bạn',
                            subtitle: 'Tất cả bài hát trong thư viện',
                          ),
                          ..._songs.map((song) => SongTile(
                                song: song,
                                customQueue: _songs,
                              )),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

/// Avatar tròn có viền gradient.
class _GradientRingAvatar extends StatelessWidget {
  final String url;
  final double size;
  const _GradientRingAvatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.accentGradient,
        boxShadow: AppTheme.glow(AppTheme.accent, 0.3),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.backgroundBlack,
        ),
        padding: const EdgeInsets.all(3),
        child: CoverImage(url: url, size: size - 12, circle: true),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GradientButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.glow(AppTheme.accent, 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
