import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundGradient = isDark
        ? const LinearGradient(
      colors: [Color(0xFF232323), Color(0xFF171717)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    )
        : const LinearGradient(
      colors: [Color(0xFFF6F6F6), Color(0xFFEDEDED)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final mainTextColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    final subTextColor = theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.black54);
    final accentColor = Colors.greenAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
      ),
      child: FutureBuilder<String?>(
        future: _futureLyric,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }
          if (snapshot.hasError) {
            return _buildError(tr('lyric_error'), subTextColor);
          }
          final lyric = snapshot.data;
          if (lyric == null || lyric.trim().isEmpty) {
            return _buildError(tr('lyric_not_found'), subTextColor);
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
                        style: TextStyle(
                          color: mainTextColor,
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
                        style: TextStyle(
                          color: accentColor,
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
                          style: TextStyle(
                            color: mainTextColor,
                            fontSize: 17.5,
                            height: 1.55,
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            shadows: [
                              if (isDark)
                                const Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))
                              else
                                const Shadow(color: Colors.white54, blurRadius: 1, offset: Offset(0, 1)),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 50,
                          cursorColor: accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
                // Icon nhạc nhỏ trang trí
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 7),
                  child: Icon(Icons.music_note_rounded, color: subTextColor.withOpacity(0.16), size: 28),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String message, Color subTextColor) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.library_music_outlined, size: 48, color: subTextColor.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(color: subTextColor, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}