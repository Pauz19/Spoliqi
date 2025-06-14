import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TrackListTile extends StatelessWidget {
  final dynamic track;
  final VoidCallback? onTap;

  const TrackListTile({super.key, required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = track['title'] ?? 'Không rõ tên';
    final String artist = track['artist']?['name'] ?? 'Không rõ nghệ sĩ';
    final String? coverUrl = track['album']?['cover_big'];

    return Card(
      color: Colors.white12,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: (coverUrl != null && coverUrl.isNotEmpty)
              ? CachedNetworkImage(
            imageUrl: coverUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 60,
              height: 60,
              color: Colors.grey[900],
            ),
            errorWidget: (context, url, error) => const Icon(Icons.music_note, size: 42, color: Colors.white24),
          )
              : Container(
            width: 60,
            height: 60,
            color: Colors.grey[900],
            child: const Icon(Icons.music_note, size: 42, color: Colors.white24),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          artist,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}