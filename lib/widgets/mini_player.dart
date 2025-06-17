import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import '../models/song.dart';

// Hàm format thời gian
String formatTime(Duration duration) {
  final twoDigits = (int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});
  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  double _dragDx = 0.0;
  double _dragDy = 0.0;
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    );
    if (provider.isPlaying) {
      _controller?.repeat(period: const Duration(seconds: 1));
    } else {
      _controller?.stop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<Song> _getOriginalSongs(PlayerProvider provider) {
    return provider.queue.isNotEmpty ? provider.queue : [];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();
        final Duration current = provider.position;
        final bool isPlaying = provider.isPlaying;
        if (isPlaying) {
          _controller?.repeat(period: const Duration(seconds: 1));
        } else {
          _controller?.stop();
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) {
            _dragDy = 0.0;
          },
          onVerticalDragUpdate: (details) {
            _dragDy += details.delta.dy;
          },
          onVerticalDragEnd: (details) async {
            // Ngưỡng vuốt (px)
            const threshold = 40;
            if (_dragDy > threshold) {
              // Vuốt xuống: dừng nhạc, ẩn miniplayer
              Provider.of<PlayerProvider>(context, listen: false).clear();
              HapticFeedback.mediumImpact();
            } else if (_dragDy < -threshold) {
              // Vuốt lên: mở PlayerScreen
              HapticFeedback.selectionClick();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    originalSongs: _getOriginalSongs(provider),
                  ),
                ),
              );
            }
            _dragDy = 0.0;
          },
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  originalSongs: _getOriginalSongs(provider),
                ),
              ),
            );
          },
          onHorizontalDragStart: (_) {
            _dragDx = 0.0;
          },
          onHorizontalDragUpdate: (details) {
            _dragDx += details.delta.dx;
          },
          onHorizontalDragEnd: (details) {
            if (_dragDx > 40) {
              Provider.of<PlayerProvider>(context, listen: false).previous();
              HapticFeedback.selectionClick();
            } else if (_dragDx < -40) {
              Provider.of<PlayerProvider>(context, listen: false).next();
              HapticFeedback.selectionClick();
            }
            _dragDx = 0.0;
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Container(
              key: ValueKey(song.id),
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.96),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10, width: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: (song.coverUrl != null && song.coverUrl!.isNotEmpty)
                        ? Image.network(
                      song.coverUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        color: Colors.black26,
                        child: const Icon(Icons.music_note, color: Colors.white54, size: 16),
                      ),
                    )
                        : Container(
                      width: 32,
                      height: 32,
                      color: Colors.black26,
                      child: const Icon(Icons.music_note, color: Colors.white54, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          // Progress bar
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation: _controller ?? AlwaysStoppedAnimation(0),
                              builder: (context, _) {
                                final Duration updated = provider.position;
                                final Duration total = provider.duration;
                                final double progress = (total.inMilliseconds > 0)
                                    ? updated.inMilliseconds / total.inMilliseconds
                                    : 0.0;
                                return ClipRect(
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: progress.clamp(0.0, 1.0),
                                        child: Container(
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.withOpacity(0.87),
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Song info
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => provider.togglePlayPause(),
                        tooltip: provider.isPlaying ? 'Tạm dừng' : 'Phát',
                      ),
                      Text(
                        formatTime(current),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 8.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}