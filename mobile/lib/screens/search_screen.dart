import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/song_tile.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Song> _songs = [];
  bool _isLoading = false;
  String _keyword = '';
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();

  static const _quickTags = ['Pop', 'Ballad', 'Rap', 'Lofi', 'Acoustic', 'Remix'];

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _keyword = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetchSongs(value));
    setState(() {});
  }

  void _applyTag(String tag) {
    _controller.text = tag;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: tag.length));
    _keyword = tag;
    _fetchSongs(tag);
  }

  Future<void> _fetchSongs([String? keyword]) async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiService().getSongs(search: keyword);
      if (mounted) {
        setState(() {
          _songs = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _songs = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        tint: const Color(0xFF14304A),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'Tìm kiếm',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Bài hát, nghệ sĩ, thể loại...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.accent),
                    suffixIcon: _keyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.textGrey),
                            onPressed: () {
                              _controller.clear();
                              _keyword = '';
                              _fetchSongs();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _quickTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = _keyword.toLowerCase() ==
                        _quickTags[i].toLowerCase();
                    return ChoiceChip(
                      label: Text(_quickTags[i]),
                      selected: selected,
                      onSelected: (_) => _applyTag(_quickTags[i]),
                      showCheckmark: false,
                      backgroundColor: AppTheme.cardGrey,
                      selectedColor: AppTheme.accent,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Text(
                  _keyword.isEmpty
                      ? 'Tất cả bài hát (${_songs.length})'
                      : '${_songs.length} kết quả cho "$_keyword"',
                  style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accent))
                    : _songs.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 60, color: AppTheme.textGrey),
                                SizedBox(height: 10),
                                Text('Không tìm thấy bài hát nào',
                                    style:
                                        TextStyle(color: AppTheme.textGrey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 155),
                            itemCount: _songs.length,
                            itemBuilder: (context, index) => SongTile(
                              song: _songs[index],
                              customQueue: _songs,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
