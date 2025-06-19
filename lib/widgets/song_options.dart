import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
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
            title: Text('add_to_queue'.tr(), style: const TextStyle(color: Colors.white)),
            onTap: () {
              Provider.of<PlayerProvider>(context, listen: false).addToQueue(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('added_to_queue'.tr()),
                      duration: const Duration(seconds: 2)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: Text('add_to_playlist'.tr(), style: const TextStyle(color: Colors.white)),
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
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('no_playlist'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                content: Text(tr('added_to_playlist', args: [pl.name])),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green[600],
              ),
            );
          },
        )).toList(),
      );
    },
  );
}