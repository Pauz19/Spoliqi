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
      duration: const Duration(milliseconds: 800),
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
    // Nền gradient nhẹ
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF212121), Color(0xFF1DB954)],
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
                const SizedBox(height: 28),
                // Tên bài hát và nghệ sĩ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.artist,
                        style: const TextStyle(
                          color: Color(0xFFB2FFB2),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Lyric
                Expanded(
                  child: Scrollbar(
                    thickness: 4,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Center(
                        child: Text(
                          lyric,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.6,
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                // Icon nhạc nhỏ trang trí
                Padding(
                  padding: const EdgeInsets.only(bottom: 22, top: 10),
                  child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 36),
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
        Icon(Icons.library_music_outlined, size: 56, color: Colors.white24),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(color: Colors.white54, fontSize: 17),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}