import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/liked_songs_provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  // Hàm lấy lại previewUrl mới nhất từ Deezer API
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

  // Phát một bài hát với previewUrl mới nhất
  Future<void> playSongWithFreshPreview(
      Song song, List<Song> queue, int idx, BuildContext context) async {
    final previewUrl = await fetchPreviewUrl(song.id);
    if (previewUrl != null && previewUrl.isNotEmpty) {
      final freshSong = song.copyWith(audioUrl: previewUrl);
      final newQueue = List<Song>.from(queue);
      newQueue[idx] = freshSong;
      Provider.of<PlayerProvider>(context, listen: false)
          .setQueue(newQueue, startIndex: idx);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(originalSongs: newQueue),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('preview_not_supported'))),
      );
    }
  }

  // Phát tất cả bài hát với previewUrl mới nhất
  Future<void> playAllWithFreshPreview(List<Song> songs, BuildContext context) async {
    final newQueue = <Song>[];
    for (final song in songs) {
      final previewUrl = await fetchPreviewUrl(song.id);
      if (previewUrl != null && previewUrl.isNotEmpty) {
        newQueue.add(song.copyWith(audioUrl: previewUrl));
      }
    }
    if (newQueue.isNotEmpty) {
      Provider.of<PlayerProvider>(context, listen: false)
          .setQueue(newQueue, startIndex: 0);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(originalSongs: newQueue),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('no_preview_supported'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final likedSongs = context.watch<LikedSongsProvider>().likedSongs;

    if (likedSongs.isEmpty) {
      // Giao diện tối ưu: icon, text lớn, màu sắc nổi bật, mô tả phụ
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('liked_songs'.tr()),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 80, color: Colors.white24),
              const SizedBox(height: 22),
              Text(
                tr('no_liked_songs'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                tr('like_instruction'),
                style: const TextStyle(color: Colors.white38, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Color(0xFF1DB954), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    tr('like_instruction_2'),
                    style: const TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('liked_songs'.tr()),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF1DB954), size: 33),
            tooltip: tr('play_all'),
            onPressed: likedSongs.isEmpty
                ? null
                : () => playAllWithFreshPreview(likedSongs, context),
          ),
        ],
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
              tooltip: tr('unlike'),
              onPressed: () async {
                await context.read<LikedSongsProvider>().unlikeSong(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('removed_from_liked')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            onTap: () {
              playSongWithFreshPreview(song, likedSongs, idx, context);
            },
          );
        },
      ),
    );
  }
}