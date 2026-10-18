import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/song.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Song> _results = [];
  Timer? _debounce;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Nhạc Trẻ', 'color': const Color(0xFFE8115B)},
    {'title': 'Pop Âu Mỹ', 'color': const Color(0xFF148A08)},
    {'title': 'Acoustic', 'color': const Color(0xFFBC5900)},
    {'title': 'Hip-Hop', 'color': const Color(0xFF503750)},
    {'title': 'Electronic', 'color': const Color(0xFF0D73EC)},
    {'title': 'Indie Việt', 'color': const Color(0xFF8D67AB)},
    {'title': 'Lo-Fi Chill', 'color': const Color(0xFF1E3264)},
    {'title': 'Tập luyện', 'color': const Color(0xFF777777)},
  ];

  void _onSearchChanged(String query) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (query.trim().isEmpty) {
        setState(() => _results = []);
        return;
      }
      setState(() => _isLoading = true);
      try {
        final list = await _apiService.getSongs(search: query.trim());
        setState(() {
          _results = list;
          _isLoading = false;
        });
      } catch (_) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Tìm kiếm',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 14),
              // Thanh Search trắng kiểu Spotify / eSound
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Bạn muốn nghe gì?',
                  hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.black87, size: 26),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black87),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              // Nội dung bên dưới: Kết quả tìm kiếm hoặc Lưới thể loại
              Expanded(
                child: isSearching
                    ? _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                        : _results.isEmpty
                            ? const Center(
                                child: Text('Không tìm thấy bài hát phù hợp', style: TextStyle(color: Colors.white54)),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (ctx, idx) => SongTile(
                                  song: _results[idx],
                                  playlist: _results,
                                  index: idx,
                                  showIndex: false,
                                ),
                              )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Duyệt tìm tất cả',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.75,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (ctx, idx) {
                                final cat = _categories[idx];
                                return GestureDetector(
                                  onTap: () {
                                    _searchCtrl.text = cat['title'];
                                    _onSearchChanged(cat['title']);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cat['color'],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        cat['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
}