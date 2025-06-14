import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/lyric_tab.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool isLiked = false;

  void _showAddToPlaylist(BuildContext context, dynamic song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final playlists = Provider.of<PlaylistProvider>(context, listen: false).playlists;
        if (playlists.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Bạn chưa có playlist nào.',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
          );
        }
        return ListView(
          shrinkWrap: true,
          children: playlists.map((pl) => ListTile(
            title: Text(pl.name, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Provider.of<PlaylistProvider>(context, listen: false)
                  .addSongToPlaylist(pl.id, song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm vào "${pl.name}"'),
                  backgroundColor: Colors.green[600],
                ),
              );
            },
          )).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: Text(
                "Chưa có bài hát nào đang phát.",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black.withOpacity(0.95),
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.white),
                    tooltip: "Thêm vào playlist",
                    onPressed: () => _showAddToPlaylist(context, song),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
                bottom: const TabBar(
                  indicatorColor: Color(0xFF1DB954),
                  labelColor: Color(0xFF1DB954),
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(icon: Icon(Icons.music_note)),
                    Tab(icon: Icon(Icons.library_music)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _PlayerTab(
                    songTitle: song.title,
                    artistName: song.artist,
                    coverUrl: song.coverUrl ?? "",
                    isShuffling: provider.isShuffling,
                    repeatMode: provider.repeatMode,
                    isLiked: isLiked,
                    onShuffle: provider.toggleShuffle,
                    onRepeat: provider.cycleRepeatMode,
                    onLike: () => setState(() => isLiked = !isLiked),
                    onNext: provider.next,
                    onPrev: provider.previous,
                    isPlaying: provider.isPlaying,
                    onPlayPause: provider.togglePlayPause,
                    position: provider.position,
                    duration: provider.duration,
                  ),
                  LyricTab(
                    artist: song.artist,
                    title: song.title,
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

class _PlayerTab extends StatelessWidget {
  final String songTitle;
  final String artistName;
  final String coverUrl;
  final bool isShuffling;
  final RepeatMode repeatMode;
  final bool isLiked;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final VoidCallback onLike;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final Duration position;
  final Duration duration;

  const _PlayerTab({
    required this.songTitle,
    required this.artistName,
    required this.coverUrl,
    required this.isShuffling,
    required this.repeatMode,
    required this.isLiked,
    required this.onShuffle,
    required this.onRepeat,
    required this.onLike,
    required this.onNext,
    required this.onPrev,
    required this.isPlaying,
    required this.onPlayPause,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final safeDuration = duration.inMilliseconds > 0 ? duration : const Duration(seconds: 30);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Hero(
              tag: coverUrl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  width: 280,
                  height: 280,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.black26,
                    width: 280,
                    height: 280,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black26,
                    width: 280,
                    height: 280,
                    child: const Icon(Icons.music_note, size: 110, color: Colors.white38),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    songTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.02,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artistName,
                    style: const TextStyle(
                      color: Color(0xFF1DB954),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Slider tiến trình
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      activeTrackColor: Colors.greenAccent,
                      thumbColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.white24,
                    ),
                    child: Slider(
                      min: 0,
                      max: safeDuration.inMilliseconds.toDouble(),
                      value: position.inMilliseconds.clamp(0, safeDuration.inMilliseconds).toDouble(),
                      onChanged: (value) {
                        Provider.of<PlayerProvider>(context, listen: false)
                            .seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        _formatDuration(safeDuration),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Nút điều khiển nhạc chính
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: isShuffling ? const Color(0xFF1DB954) : Colors.white38,
                    size: 28,
                  ),
                  tooltip: isShuffling ? "Tắt phát ngẫu nhiên" : "Phát ngẫu nhiên",
                  onPressed: onShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                  tooltip: "Bài trước",
                  onPressed: onPrev,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.greenAccent,
                    size: 62,
                  ),
                  tooltip: isPlaying ? "Tạm dừng" : "Phát",
                  onPressed: onPlayPause,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                  tooltip: "Bài tiếp theo",
                  onPressed: onNext,
                ),
                IconButton(
                  icon: Icon(
                    repeatMode == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: repeatMode == RepeatMode.none
                        ? Colors.white38
                        : const Color(0xFF1DB954),
                    size: 28,
                  ),
                  tooltip: repeatMode == RepeatMode.none
                      ? "Lặp lại: Tắt"
                      : repeatMode == RepeatMode.all
                      ? "Lặp lại tất cả"
                      : "Lặp lại một bài",
                  onPressed: onRepeat,
                ),
              ],
            ),
            // Nút phụ: like, tải, share
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? const Color(0xFF1DB954) : Colors.white.withOpacity(0.8),
                      size: 26,
                    ),
                    tooltip: isLiked ? "Bỏ thích" : "Thích",
                    onPressed: onLike,
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.download_for_offline_outlined,
                        color: Colors.white.withOpacity(0.8), size: 26),
                    tooltip: "Tải về",
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.share_outlined,
                        color: Colors.white.withOpacity(0.8), size: 26),
                    tooltip: "Chia sẻ",
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}';
  }
}