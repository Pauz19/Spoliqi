import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/liked_songs_provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final likedSongs = context.watch<LikedSongsProvider>().likedSongs;

    if (likedSongs.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có bài hát nào đã thích',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Nhạc đã thích'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: likedSongs.length,
        itemBuilder: (context, idx) {
          final song = likedSongs[idx];
          return ListTile(
            leading: song.coverUrl != null && song.coverUrl!.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                song.coverUrl!,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 46,
                  height: 46,
                  color: Colors.black12,
                  child: const Icon(Icons.music_note, color: Colors.white38),
                ),
              ),
            )
                : Container(
              width: 46,
              height: 46,
              color: Colors.black12,
              child: const Icon(Icons.music_note, color: Colors.white38),
            ),
            title: Text(song.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54)),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Color(0xFF1DB954)),
              tooltip: "Bỏ thích",
              onPressed: () async {
                await context.read<LikedSongsProvider>().unlikeSong(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa khỏi Nhạc đã thích'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            onTap: () {
              // Đặt bài hát hiện tại và mở PlayerScreen
              context.read<PlayerProvider>().playFromList(likedSongs, idx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            },
          );
        },
      ),
    );
  }
}