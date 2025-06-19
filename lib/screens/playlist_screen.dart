import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../providers/liked_songs_provider.dart';
import '../providers/notification_provider.dart';
import '../models/song.dart';
import '../widgets/song_options.dart';
import '../screens/liked_songs_screen.dart';

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

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaylistProvider>(context, listen: false).loadPlaylists();
    });
  }

  void _showCreatePlaylistDialog(BuildContext rootContext) {
    final controller = TextEditingController();
    // Lấy Provider ngoài dialog, trước khi showDialog
    final playlistProvider = Provider.of<PlaylistProvider>(rootContext, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(rootContext, listen: false);

    showDialog(
      context: rootContext,
      builder: (dialogContext) {
        final isDark = Theme.of(rootContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
          title: Text(tr('create_playlist')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: tr('new_playlist_name_hint'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                debugPrint('Bấm nút tạo: $name');
                if (name.isNotEmpty) {
                  final result = await playlistProvider.addPlaylist(name);
                  debugPrint('Kết quả tạo: $result');
                  if (!mounted) return;
                  if (result) {
                    notificationProvider.addNotificationKey('created_playlist', args: [name]);
                    Navigator.of(dialogContext).pop();
                  } else {
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(content: Text(tr('create_playlist_failed'))),
                    );
                  }
                }
              },
              child: Text(tr('create')),
            ),
          ],
        );
      },
    );
  }

  Future<String?> fetchPreviewUrl(String trackId) async {
    try {
      final resp = await http.get(Uri.parse('https://api.deezer.com/track/$trackId'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['preview'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> playSongWithFreshPreview(Song song, List<Song> queue, int idx, BuildContext context) async {
    final previewUrl = await fetchPreviewUrl(song.id);
    if (previewUrl != null && previewUrl.isNotEmpty) {
      final freshSong = song.copyWith(audioUrl: previewUrl);
      final newQueue = List<Song>.from(queue);
      newQueue[idx] = freshSong;
      Provider.of<PlayerProvider>(context, listen: false)
          .setQueue(newQueue, startIndex: idx);
      if (Navigator.canPop(context)) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('preview_not_supported'))),
      );
    }
  }

  Future<void> playAllWithFreshPreview(List<Song> songs, BuildContext context) async {
    final newQueue = <Song>[];
    for (final song in songs) {
      final previewUrl = await fetchPreviewUrl(song.id);
      newQueue.add(song.copyWith(audioUrl: previewUrl ?? ''));
    }
    final playableQueue = newQueue.where((s) => s.audioUrl.isNotEmpty).toList();
    if (playableQueue.isNotEmpty) {
      Provider.of<PlayerProvider>(context, listen: false)
          .setQueue(playableQueue, startIndex: 0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('no_preview_supported'))),
      );
    }
  }

  Future<void> playAllLikedSongs(BuildContext context, List<Song> likedSongs) async {
    final newQueue = <Song>[];
    for (final song in likedSongs) {
      final previewUrl = await fetchPreviewUrl(song.id);
      if (previewUrl != null && previewUrl.isNotEmpty) {
        newQueue.add(song.copyWith(audioUrl: previewUrl));
      }
    }
    if (newQueue.isNotEmpty) {
      Provider.of<PlayerProvider>(context, listen: false).setQueue(newQueue, startIndex: 0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('no_preview_supported'))),
      );
    }
  }

  void _showRenamePlaylistDialog(BuildContext rootContext, dynamic playlist) {
    final controller = TextEditingController(text: playlist.name);
    // Lấy Provider ngoài dialog
    final playlistProvider = Provider.of<PlaylistProvider>(rootContext, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(rootContext, listen: false);

    showDialog(
      context: rootContext,
      builder: (dialogContext) {
        final isDark = Theme.of(rootContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
          title: Text(tr('rename_playlist'), style: TextStyle(color: Theme.of(rootContext).textTheme.bodyLarge?.color)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: Theme.of(rootContext).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: tr('new_playlist_name_hint'),
              hintStyle: TextStyle(color: Theme.of(rootContext).textTheme.bodySmall?.color),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                final oldName = playlist.name;
                if (newName.isNotEmpty) {
                  await playlistProvider.renamePlaylist(playlist.id, newName, context: rootContext);

                  // Thông báo khi đổi tên thành công, truyền cả tên cũ và tên mới
                  notificationProvider.addNotificationKey('playlist_renamed', args: [oldName, newName]);

                  if (rootContext.mounted) Navigator.of(dialogContext).pop();
                }
              },
              child: Text(tr('save')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final mainTextColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    final subTextColor = theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.black54);
    final iconColor = theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer2<PlaylistProvider, LikedSongsProvider>(
        builder: (context, playlistProvider, likedSongsProvider, _) {
          final playlists = playlistProvider.playlists;
          final likedSongs = likedSongsProvider.likedSongs;

          return playlistProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: playlists.length + 2, // +1 cho "Nhạc đã thích", +1 cho "Tạo playlist mới"
            separatorBuilder: (context, idx) => const SizedBox(height: 30),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Nút tạo playlist mới ở đầu danh sách
                return Material(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    leading: Icon(Icons.add, color: Colors.greenAccent, size: 33),
                    title: Text(tr('create_playlist'),
                        style: TextStyle(fontWeight: FontWeight.bold, color: mainTextColor)),
                    onTap: () => _showCreatePlaylistDialog(context),
                  ),
                );
              }
              if (index == 1) {
                // Playlist Nhạc đã thích ghim cố định đầu danh sách
                return Material(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1DB954), Color(0xFF191414)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(Icons.favorite, color: mainTextColor, size: 33),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('liked_songs'),
                                  style: TextStyle(
                                    color: mainTextColor,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('all_liked_songs'),
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 36),
                            tooltip: tr('play_all'),
                            onPressed: likedSongs.isEmpty
                                ? null
                                : () => playAllLikedSongs(context, likedSongs),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              // Các playlist tự tạo
              final playlist = playlists[index - 2];
              final songCount = playlist.songs.length;
              return Material(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(22),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: backgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      builder: (_) => _PlaylistDetailSheet(
                        playlistId: playlist.id,
                        fetchPreviewUrl: fetchPreviewUrl,
                        playSongWithFreshPreview: playSongWithFreshPreview,
                        playAllWithFreshPreview: playAllWithFreshPreview,
                        mainTextColor: mainTextColor,
                        subTextColor: subTextColor,
                        iconColor: iconColor,
                        isDark: isDark,
                      ),
                    );
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      builder: (_) => _PlaylistOptionsMenu(
                        playlist: playlist,
                        onRename: () => _showRenamePlaylistDialog(context, playlist),
                        iconColor: iconColor,
                        mainTextColor: mainTextColor,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: playlist.songs.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: playlist.songs.first.coverUrl ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.black26,
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.black26,
                              child: Icon(Icons.music_note, color: subTextColor),
                            ),
                          )
                              : Container(
                            width: 60,
                            height: 60,
                            color: Colors.black26,
                            child: Icon(Icons.queue_music, color: subTextColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.name,
                                style: TextStyle(
                                  color: mainTextColor,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                manualFormat(tr('song_count'), ['$songCount']),
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 36),
                          tooltip: tr('play_all'),
                          onPressed: playlist.songs.isEmpty
                              ? null
                              : () => playAllWithFreshPreview(playlist.songs, context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlaylistDetailSheet extends StatelessWidget {
  final String playlistId;
  final Future<String?> Function(String) fetchPreviewUrl;
  final Future<void> Function(Song, List<Song>, int, BuildContext) playSongWithFreshPreview;
  final Future<void> Function(List<Song>, BuildContext) playAllWithFreshPreview;
  final Color mainTextColor;
  final Color subTextColor;
  final Color iconColor;
  final bool isDark;

  const _PlaylistDetailSheet({
    required this.playlistId,
    required this.fetchPreviewUrl,
    required this.playSongWithFreshPreview,
    required this.playAllWithFreshPreview,
    required this.mainTextColor,
    required this.subTextColor,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final playlist = Provider.of<PlaylistProvider>(context, listen: false)
        .playlists
        .firstWhere((pl) => pl.id == playlistId);
    final songCount = playlist.songs.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: playlist.songs.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: playlist.songs.first.coverUrl ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.black26,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.black26,
                      child: Icon(Icons.music_note, color: subTextColor),
                    ),
                  )
                      : Container(
                    width: 70,
                    height: 70,
                    color: Colors.black26,
                    child: Icon(Icons.queue_music, color: subTextColor),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: TextStyle(
                            color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        manualFormat(tr('song_count'), ['$songCount']),
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 38),
                  tooltip: tr('play_all'),
                  onPressed: playlist.songs.isEmpty
                      ? null
                      : () => playAllWithFreshPreview(playlist.songs, context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (playlist.songs.isEmpty)
              Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.music_off, size: 54, color: subTextColor.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  Text(
                    tr('playlist_empty'),
                    style: TextStyle(color: subTextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                ],
              )
            else
              SizedBox(
                height: 350,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: playlist.songs.length,
                  separatorBuilder: (context, idx) => Divider(color: subTextColor.withOpacity(0.18), height: 1),
                  itemBuilder: (context, idx) {
                    final song = playlist.songs[idx];
                    return Dismissible(
                      key: ValueKey(song.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await Provider.of<PlaylistProvider>(context, listen: false)
                            .removeSongFromPlaylist(playlist.id, song, context: context);
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          showSongOptions(context, song);
                        },
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: CachedNetworkImage(
                              imageUrl: song.coverUrl ?? '',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.black26,
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.black26,
                                child: Icon(Icons.music_note, color: subTextColor),
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.artist,
                                style: TextStyle(color: subTextColor, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (song.album != null && song.album!.isNotEmpty)
                                Text(
                                  '${tr('album')}: ${song.album}',
                                  style: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (song.duration != null)
                                Text(
                                  '${tr('duration')}: ${song.duration}',
                                  style: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (song.releaseDate != null && song.releaseDate!.isNotEmpty)
                                Text(
                                  '${tr('release_date')}: ${song.releaseDate}',
                                  style: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                            onSelected: (value) async {
                              if (value == 'remove') {
                                await Provider.of<PlaylistProvider>(context, listen: false)
                                    .removeSongFromPlaylist(playlist.id, song, context: context);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    const SizedBox(width: 10),
                                    Text(tr('remove_from_playlist'), style: TextStyle(color: mainTextColor)),
                                  ],
                                ),
                              ),
                            ],
                            child: Icon(Icons.more_vert, color: subTextColor),
                          ),
                          onTap: () =>
                              playSongWithFreshPreview(song, playlist.songs, idx, context),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistOptionsMenu extends StatelessWidget {
  final dynamic playlist;
  final VoidCallback? onRename;
  final Color iconColor;
  final Color mainTextColor;
  const _PlaylistOptionsMenu({
    required this.playlist,
    this.onRename,
    required this.iconColor,
    required this.mainTextColor,
  });
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: iconColor),
            title: Text(tr('rename_playlist'), style: TextStyle(color: mainTextColor)),
            onTap: () {
              Navigator.pop(context);
              if (onRename != null) onRename!();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(tr('delete_playlist'), style: const TextStyle(color: Colors.red)),
            onTap: () async {
              await Provider.of<PlaylistProvider>(context, listen: false)
                  .removePlaylist(playlist.id, context: context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}