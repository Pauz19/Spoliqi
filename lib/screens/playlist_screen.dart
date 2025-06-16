import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../widgets/song_options.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  void initState() {
    super.initState();
    // Tự động load playlist từ Firebase khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaylistProvider>(context, listen: false).loadPlaylists();
    });
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Tạo playlist mới', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên playlist...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Tạo', style: TextStyle(color: Colors.greenAccent)),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await Provider.of<PlaylistProvider>(context, listen: false).addPlaylist(name);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final playlists = playlistProvider.playlists;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'Playlist của bạn',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Tạo playlist mới',
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            ],
          ),
          body: playlistProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : playlists.isEmpty
              ? const _EmptyPlaylistWidget()
              : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: playlists.length,
            separatorBuilder: (context, idx) => const SizedBox(height: 30),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final songCount = playlist.songs.length;
              return Material(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(22),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      builder: (_) => _PlaylistDetailSheet(playlistId: playlist.id),
                    );
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.grey[900],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      builder: (_) => _PlaylistOptionsMenu(playlist: playlist),
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
                              child: const Icon(Icons.music_note, color: Colors.white54),
                            ),
                          )
                              : Container(
                            width: 60,
                            height: 60,
                            color: Colors.black26,
                            child: const Icon(Icons.queue_music, color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$songCount bài hát',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 36),
                          tooltip: "Phát tất cả",
                          onPressed: playlist.songs.isEmpty
                              ? null
                              : () {
                            Provider.of<PlayerProvider>(context, listen: false)
                                .setQueue(playlist.songs, startIndex: 0);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyPlaylistWidget extends StatelessWidget {
  const _EmptyPlaylistWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music_rounded, size: 66, color: Colors.white24),
          const SizedBox(height: 18),
          const Text(
            'Chưa có playlist nào',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo playlist mới để lưu các bài hát yêu thích!',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _PlaylistDetailSheet extends StatelessWidget {
  final String playlistId;
  const _PlaylistDetailSheet({required this.playlistId});

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
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  )
                      : Container(
                    width: 70,
                    height: 70,
                    color: Colors.black26,
                    child: const Icon(Icons.queue_music, color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$songCount bài hát',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 38),
                  tooltip: "Phát tất cả",
                  onPressed: playlist.songs.isEmpty
                      ? null
                      : () {
                    Provider.of<PlayerProvider>(context, listen: false)
                        .setQueue(playlist.songs, startIndex: 0);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Danh sách bài hát
            if (playlist.songs.isEmpty)
              Column(
                children: const [
                  SizedBox(height: 32),
                  Icon(Icons.music_off, size: 54, color: Colors.white24),
                  SizedBox(height: 10),
                  Text(
                    'Playlist rỗng',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                ],
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: playlist.songs.length,
                  separatorBuilder: (context, idx) => const Divider(color: Colors.white12, height: 1),
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
                            .removeSongFromPlaylist(playlist.id, song);
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
                                child: const Icon(Icons.music_note, color: Colors.white54),
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            color: Colors.grey[900],
                            onSelected: (value) async {
                              if (value == 'remove') {
                                await Provider.of<PlaylistProvider>(context, listen: false)
                                    .removeSongFromPlaylist(playlist.id, song);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    SizedBox(width: 10),
                                    Text('Xoá khỏi playlist'),
                                  ],
                                ),
                              ),
                            ],
                            child: const Icon(Icons.more_vert, color: Colors.white70),
                          ),
                          onTap: () {
                            Provider.of<PlayerProvider>(context, listen: false)
                                .setQueue(playlist.songs, startIndex: idx);
                            Navigator.pop(context);
                          },
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
  final playlist;
  const _PlaylistOptionsMenu({required this.playlist});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: const Text('Đổi tên playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              // TODO: Hiện dialog đổi tên playlist nếu muốn
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Xoá playlist', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Provider.of<PlaylistProvider>(context, listen: false)
                  .removePlaylist(playlist.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}