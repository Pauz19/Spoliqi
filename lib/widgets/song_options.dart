import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';

void showSongOptions(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.queue_music, color: Colors.white),
            title: const Text('Thêm vào danh sách chờ', style: TextStyle(color: Colors.white)),
            onTap: () {
              Provider.of<PlayerProvider>(context, listen: false).addToQueue(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm vào danh sách chờ')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: const Text('Thêm vào playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylist(context, song);
            },
          ),
        ],
      );
    },
  );
}

void _showAddToPlaylist(BuildContext context, Song song) {
  final playlists = Provider.of<PlaylistProvider>(context, listen: false).playlists;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) {
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