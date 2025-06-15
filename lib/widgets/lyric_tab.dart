import 'package:flutter/material.dart';
import '../services/lyric_service.dart';

class LyricTab extends StatefulWidget {
  final String artist;
  final String title;
  const LyricTab({super.key, required this.artist, required this.title});

  @override
  State<LyricTab> createState() => _LyricTabState();
}

class _LyricTabState extends State<LyricTab> with SingleTickerProviderStateMixin {
  Future<String?>? _futureLyric;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _futureLyric = LyricService.fetchLyric(
      artist: widget.artist,
      title: widget.title,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant LyricTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artist != widget.artist || oldWidget.title != widget.title) {
      setState(() {
        _futureLyric = LyricService.fetchLyric(
          artist: widget.artist,
          title: widget.title,
        );
        _fadeController.reset();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nền gradient nhẹ, bớt nổi bật để lyric dễ đọc hơn
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF232323), Color(0xFF171717)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: FutureBuilder<String?>(
        future: _futureLyric,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
          }
          if (snapshot.hasError) {
            return _buildError("Có lỗi khi tải lyric.\nVui lòng thử lại sau.");
          }
          final lyric = snapshot.data;
          if (lyric == null || lyric.trim().isEmpty) {
            return _buildError("Không tìm thấy lyric cho bài hát này.");
          }
          _fadeController.forward();

          return FadeTransition(
            opacity: _fadeController,
            child: Column(
              children: [
                const SizedBox(height: 18),
                // Tên bài hát và nghệ sĩ (tối giản, nhỏ gọn, font nhỏ hơn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.artist,
                        style: const TextStyle(
                          color: Color(0xFF7EE687),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                // Lyric
                Expanded(
                  child: Scrollbar(
                    thickness: 3,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Center(
                        child: SelectableText(
                          lyric.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            height: 1.55,
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1)),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 50,
                          cursorColor: Color(0xFF1DB954),
                        ),
                      ),
                    ),
                  ),
                ),
                // Icon nhạc nhỏ trang trí
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 7),
                  child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 28),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.library_music_outlined, size: 48, color: Colors.white24),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(color: Colors.white54, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}