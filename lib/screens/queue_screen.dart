import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    final queue = provider.queue;
    final currentSong = provider.currentSong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách chờ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: queue.isEmpty
          ? const Center(
        child: Text(
          'Danh sách chờ trống',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      )
          : ReorderableListView.builder(
        itemCount: queue.length,
        onReorder: (oldIndex, newIndex) {
          // Khi kéo thả reorder
          // Nếu kéo xuống dưới cùng, Flutter trả về newIndex = length + 1, phải giảm 1
          if (newIndex > oldIndex) newIndex -= 1;
          Provider.of<PlayerProvider>(context, listen: false)
              .moveSongInQueue(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final song = queue[index];
          final isCurrent = currentSong?.id == song.id;
          return ListTile(
            key: ValueKey(song.id),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: (song.coverUrl != null && song.coverUrl!.isNotEmpty)
                  ? Image.network(
                song.coverUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: Colors.black26,
                  child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
                ),
              )
                  : Container(
                width: 44,
                height: 44,
                color: Colors.black26,
                child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
              ),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: isCurrent ? Colors.greenAccent : Colors.white,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              onPressed: () {
                Provider.of<PlayerProvider>(context, listen: false).removeFromQueue(song);
              },
              tooltip: 'Xóa khỏi danh sách chờ',
            ),
            selected: isCurrent,
            onTap: () {
              provider.playFromQueue(index);
              Navigator.pop(context); // Đóng queue và chuyển phát bài này
            },
            tileColor: isCurrent ? Colors.white10 : Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          );
        },
      ),
    );
  }
}