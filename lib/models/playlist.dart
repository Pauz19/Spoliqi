import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
  });
}