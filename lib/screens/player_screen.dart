import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/liked_songs_provider.dart';
import '../models/song.dart';
import '../widgets/lyric_tab.dart';
import 'queue_screen.dart';

// Hàm format thủ công các biến {0}, %1$s, $args{0}
String manualFormat(String template, List<String> args) {
  var result = template;
  for (var i = 0; i < args.length; i++) {
    result = result.replaceAll('{$i}', args[i]);
    result = result.replaceAll('%${i + 1}\$s', args[i]);
    result = result.replaceAll('\$args{$i}', args[i]);
  }
  return result;
}

class PlayerScreen extends StatefulWidget {
  final List<Song> originalSongs;
  const PlayerScreen({super.key, required this.originalSongs});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Offset? _dragStartDetails;

  void _showAddToPlaylist(BuildContext context, Song song) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.black87 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final playlists = Provider.of<PlaylistProvider>(context, listen: false).playlists;
        final mainTextColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
        if (playlists.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(tr('no_playlists'),
                style: TextStyle(color: mainTextColor, fontSize: 16)),
          );
        }
        return ListView(
          shrinkWrap: true,
          children: playlists.map((pl) => ListTile(
            title: Text(pl.name, style: TextStyle(color: mainTextColor)),
            onTap: () {
              Provider.of<PlaylistProvider>(context, listen: false)
                  .addSongToPlaylist(pl.id, song, context: context); // Truyền context để có notification
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('added_to_playlist', args: [pl.name])),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainTextColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    final subTextColor = theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.black54);
    final iconColor = theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87);

    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 80, color: subTextColor.withOpacity(0.3)),
                  const SizedBox(height: 18),
                  Text(
                    tr('queue_ended'),
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('queue_ended_hint'),
                    style: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh, color: Colors.greenAccent),
                    label: Text(tr('play_again'), style: TextStyle(color: mainTextColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.black87 : Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final original = widget.originalSongs;
                      if (original.isNotEmpty) {
                        Provider.of<PlayerProvider>(context, listen: false).setQueue(original, startIndex: 0);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('no_original_queue'))),
                        );
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
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(54),
              child: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.95),
                elevation: 0,
                toolbarHeight: 34,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: iconColor),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.playlist_add, color: iconColor, size: 20),
                    tooltip: tr('add_to_playlist'),
                    onPressed: () => _showAddToPlaylist(context, song),
                    splashRadius: 18,
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: iconColor, size: 20),
                    onPressed: () {},
                    splashRadius: 18,
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Container(
                    height: 28,
                    alignment: Alignment.center,
                    child: TabBar(
                      indicatorColor: Colors.greenAccent,
                      labelColor: Colors.greenAccent,
                      unselectedLabelColor: subTextColor,
                      tabs: [
                        Tab(icon: Icon(Icons.music_note, size: 18, color: iconColor)),
                        Tab(icon: Icon(Icons.library_music, size: 18, color: iconColor)),
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
                          await likedSongsProvider.unlikeSong(song, context: context); // truyền context để có notification
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('removed_from_liked')),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await likedSongsProvider.likeSong(song, context: context); // truyền context để có notification
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('added_to_liked')),
                              duration: const Duration(seconds: 2),
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
                      mainTextColor: mainTextColor,
                      subTextColor: subTextColor,
                      iconColor: iconColor,
                    ),
                    LyricTab(
                      artist: song.artist,
                      title: song.title,
                    ),
                  ],
                ),
                Positioned(
                  right: 26,
                  bottom: 34,
                  child: FloatingActionButton(
                    backgroundColor: isDark ? Colors.black.withOpacity(0.88) : Colors.white.withOpacity(0.93),
                    elevation: 2,
                    tooltip: tr('see_queue'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QueueScreen()),
                      );
                    },
                    child: Icon(Icons.queue_music_rounded, color: Colors.greenAccent, size: 28),
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
  final Color mainTextColor;
  final Color subTextColor;
  final Color iconColor;

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
    required this.mainTextColor,
    required this.subTextColor,
    required this.iconColor,
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
                              child: Icon(Icons.music_note, size: 88, color: subTextColor.withOpacity(0.5)),
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
                            style: TextStyle(
                              color: mainTextColor,
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
                            style: TextStyle(
                              color: Colors.greenAccent,
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
                              inactiveTrackColor: subTextColor.withOpacity(0.25),
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
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(safeDuration),
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: isShuffling ? Colors.greenAccent : subTextColor,
                            size: 23,
                          ),
                          tooltip: isShuffling
                              ? tr('shuffle_off')
                              : tr('shuffle_on'),
                          onPressed: onShuffle,
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_previous, color: iconColor, size: 30),
                          tooltip: tr('previous_song'),
                          onPressed: onPrev,
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                            color: Colors.greenAccent,
                            size: 50,
                          ),
                          tooltip: isPlaying ? tr('pause') : tr('play'),
                          onPressed: onPlayPause,
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: iconColor, size: 30),
                          tooltip: tr('next_song'),
                          onPressed: onNext,
                        ),
                        IconButton(
                          icon: Icon(
                            repeatMode == RepeatMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            color: repeatMode == RepeatMode.none
                                ? subTextColor
                                : Colors.greenAccent,
                            size: 23,
                          ),
                          tooltip: repeatMode == RepeatMode.none
                              ? tr('repeat_off')
                              : repeatMode == RepeatMode.all
                              ? tr('repeat_all')
                              : tr('repeat_one'),
                          onPressed: onRepeat,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.greenAccent : subTextColor,
                              size: 22,
                            ),
                            tooltip: isLiked ? tr('unlike') : tr('like'),
                            onPressed: onLike,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.download_for_offline_outlined,
                                color: subTextColor, size: 22),
                            tooltip: tr('download'),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.share_outlined,
                                color: subTextColor, size: 22),
                            tooltip: tr('share'),
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