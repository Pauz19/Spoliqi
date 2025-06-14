import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

String formatTime(Duration duration) {
  final twoDigits = (int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }
        final Duration current = provider.position;
        final Duration total = provider.duration;
        final double sliderValue = current.inSeconds.clamp(0, total.inSeconds > 0 ? total.inSeconds : 30).toDouble();

        return Dismissible(
          key: const ValueKey('miniplayer'),
          direction: DismissDirection.up,
          onDismissed: (_) {
            provider.clearQueue();
          },
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlayerScreen(),
                ),
              );
            },
            child: Container(
              height: 74,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Info row
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          provider.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.greenAccent,
                          size: 28,
                        ),
                        onPressed: () => provider.togglePlayPause(),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  // Timeline row (dưới cùng)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 2, bottom: 0),
                    child: Row(
                      children: [
                        Text(
                          formatTime(current),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              trackHeight: 2.5,
                              overlayShape: SliderComponentShape.noOverlay,
                              thumbColor: Colors.greenAccent,
                              activeTrackColor: Colors.greenAccent,
                              inactiveTrackColor: Colors.white24,
                            ),
                            child: Slider(
                              min: 0,
                              max: total.inSeconds > 0 ? total.inSeconds.toDouble() : 30,
                              value: sliderValue,
                              onChanged: (value) {
                                provider.seek(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                        ),
                        Text(
                          formatTime(total),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
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
      },
    );
  }
}