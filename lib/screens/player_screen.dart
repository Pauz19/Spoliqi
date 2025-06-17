import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/liked_songs_provider.dart'; // Thêm provider này
import '../models/song.dart';
import '../widgets/lyric_tab.dart';
import 'queue_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Offset? _dragStartDetails;

  void _showAddToPlaylist(BuildContext context, Song song) {
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
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          )).toList(),
        );
      },
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragStartDetails = details.globalPosition;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_dragStartDetails != null && details.globalPosition.dy - _dragStartDetails!.dy > 85) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      _dragStartDetails = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        // Cập nhật UI đẹp khi không có bài hát nào đang phát
        if (song == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 80, color: Colors.white24),
                  const SizedBox(height: 18),
                  const Text(
                    'Bạn đã nghe hết danh sách nhạc!',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy chọn một bài hát khác hoặc phát lại playlist.',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                    label: const Text('Phát lại từ đầu', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final queue = provider.queue;
                      if (queue.isNotEmpty) {
                        provider.setQueue(queue, startIndex: 0);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        final likedSongsProvider = Provider.of<LikedSongsProvider>(context);
        final isLiked = likedSongsProvider.isLiked(song);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(54),
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.95),
                elevation: 0,
                toolbarHeight: 34,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.white, size: 20),
                    tooltip: "Thêm vào playlist",
                    onPressed: () => _showAddToPlaylist(context, song),
                    splashRadius: 18,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    onPressed: () {},
                    splashRadius: 18,
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Container(
                    height: 28,
                    alignment: Alignment.center,
                    child: const TabBar(
                      indicatorColor: Color(0xFF1DB954),
                      labelColor: Color(0xFF1DB954),
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(icon: Icon(Icons.music_note, size: 18)),
                        Tab(icon: Icon(Icons.library_music, size: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                TabBarView(
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
                      onLike: () async {
                        if (isLiked) {
                          await likedSongsProvider.unlikeSong(song);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa khỏi Nhạc đã thích'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await likedSongsProvider.likeSong(song);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã thêm vào Nhạc đã thích'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      onNext: provider.next,
                      onPrev: provider.previous,
                      isPlaying: provider.isPlaying,
                      onPlayPause: provider.togglePlayPause,
                      position: provider.position,
                      duration: provider.duration,
                      onCoverVerticalDragStart: _onVerticalDragStart,
                      onCoverVerticalDragUpdate: _onVerticalDragUpdate,
                    ),
                    LyricTab(
                      artist: song.artist,
                      title: song.title,
                    ),
                  ],
                ),
                // Nút queue kiểu floating ở góc dưới bên phải
                Positioned(
                  right: 26,
                  bottom: 34,
                  child: FloatingActionButton(
                    backgroundColor: Colors.black.withOpacity(0.88),
                    elevation: 2,
                    tooltip: "Xem danh sách chờ",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QueueScreen()),
                      );
                    },
                    child: const Icon(Icons.queue_music_rounded, color: Color(0xFF1DB954), size: 28),
                  ),
                ),
              ],
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
  final GestureDragStartCallback? onCoverVerticalDragStart;
  final GestureDragUpdateCallback? onCoverVerticalDragUpdate;

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
    this.onCoverVerticalDragStart,
    this.onCoverVerticalDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final safeDuration = duration.inMilliseconds > 0 ? duration : const Duration(seconds: 30);
    final media = MediaQuery.of(context);
    final double coverSize = media.size.width < 350 ? 200 : 250;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    GestureDetector(
                      onVerticalDragStart: onCoverVerticalDragStart,
                      onVerticalDragUpdate: onCoverVerticalDragUpdate,
                      child: Hero(
                        tag: coverUrl,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: CachedNetworkImage(
                            imageUrl: coverUrl,
                            width: coverSize,
                            height: coverSize,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.black26,
                              width: coverSize,
                              height: coverSize,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.black26,
                              width: coverSize,
                              height: coverSize,
                              child: const Icon(Icons.music_note, size: 88, color: Colors.white38),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Text(
                            songTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.02,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            artistName,
                            style: const TextStyle(
                              color: Color(0xFF1DB954),
                              fontSize: 15,
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
                    const SizedBox(height: 13),
                    // Slider tiến trình
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
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
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(safeDuration),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nút điều khiển nhạc chính
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: isShuffling ? const Color(0xFF1DB954) : Colors.white38,
                            size: 23,
                          ),
                          tooltip: isShuffling ? "Tắt phát ngẫu nhiên" : "Phát ngẫu nhiên",
                          onPressed: onShuffle,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 30),
                          tooltip: "Bài trước",
                          onPressed: onPrev,
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                            color: Colors.greenAccent,
                            size: 50,
                          ),
                          tooltip: isPlaying ? "Tạm dừng" : "Phát",
                          onPressed: onPlayPause,
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 30),
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
                            size: 23,
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
                      padding: const EdgeInsets.only(top: 4.0, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? const Color(0xFF1DB954) : Colors.white.withOpacity(0.8),
                              size: 22,
                            ),
                            tooltip: isLiked ? "Bỏ thích" : "Thích",
                            onPressed: onLike,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.download_for_offline_outlined,
                                color: Colors.white.withOpacity(0.8), size: 22),
                            tooltip: "Tải về",
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.share_outlined,
                                color: Colors.white.withOpacity(0.8), size: 22),
                            tooltip: "Chia sẻ",
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}';
  }
}