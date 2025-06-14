import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../widgets/lyric_tab.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool isLiked = false;

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        if (provider.currentSong == null) {
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

        final song = provider.currentSong!;

        return GestureDetector(
          onVerticalDragEnd: _handleVerticalDragEnd,
          behavior: HitTestBehavior.translucent,
          child: DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: AppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34, color: Colors.white),
                          tooltip: "Đóng trình phát",
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  bottom: const TabBar(
                    indicatorColor: Color(0xFF1DB954),
                    labelColor: Color(0xFF1DB954),
                    unselectedLabelColor: Colors.white70,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: [
                      Tab(text: "Player"),
                      Tab(text: "Lyric"),
                    ],
                  ),
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
                    handleVerticalDragEnd: _handleVerticalDragEnd,
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
  final void Function(DragEndDetails) handleVerticalDragEnd;

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
    required this.handleVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final Duration safeDuration = duration.inMilliseconds > 0 ? duration : const Duration(seconds: 30);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 18),
                  // Ảnh bìa
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GestureDetector(
                      onVerticalDragEnd: handleVerticalDragEnd,
                      behavior: HitTestBehavior.translucent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
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
                  ),
                  const SizedBox(height: 20),
                  // Tên bài hát & nghệ sĩ
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          songTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.02,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
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
                  const SizedBox(height: 14),
                  // Timeline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  const SizedBox(height: 10),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 10),
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
                        IconButton(
                          icon: Icon(Icons.download_for_offline_outlined,
                              color: Colors.white.withOpacity(0.8), size: 26),
                          tooltip: "Tải về",
                          onPressed: () {},
                        ),
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
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}';
  }
}