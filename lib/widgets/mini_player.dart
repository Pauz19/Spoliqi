import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }
        final Duration current = provider.position;
        final bool isPlaying = provider.isPlaying;

        // Sync AnimationController state
        if (isPlaying) {
          _controller?.repeat(period: const Duration(seconds: 1));
        } else {
          _controller?.stop();
        }

        return Dismissible(
          key: const ValueKey('miniplayer'),
          direction: DismissDirection.up,
          onDismissed: (_) {
            provider.clearQueue();
            HapticFeedback.mediumImpact();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              }
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
              _dragDx = 0;
            },
            onTap: () async {
              HapticFeedback.lightImpact();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlayerScreen(),
                ),
              );
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: AnimatedContainer(
                key: ValueKey(song.id),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 12), // Only horizontal margin to avoid overflow
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12, width: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    ClipOval(
                      child: (song.coverUrl != null && song.coverUrl!.isNotEmpty)
                          ? Image.network(
                        song.coverUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 36,
                          height: 36,
                          color: Colors.black26,
                          child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
                        ),
                      )
                          : Container(
                        width: 36,
                        height: 36,
                        color: Colors.black26,
                        child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.3,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          AnimatedBuilder(
                            animation: _controller ?? AlwaysStoppedAnimation(0),
                            builder: (context, _) {
                              final Duration updated = provider.position;
                              final Duration total = provider.duration;
                              final double progress = (total.inMilliseconds > 0)
                                  ? updated.inMilliseconds / total.inMilliseconds
                                  : 0.0;
                              return Stack(
                                children: [
                                  Container(
                                    height: 2.8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 2.8,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(0.86),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.greenAccent,
                            size: 26,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => provider.togglePlayPause(),
                          tooltip: provider.isPlaying ? 'Tạm dừng' : 'Phát',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatTime(current),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}