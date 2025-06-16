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

  Playlist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
    );
  }

  factory Playlist.fromMap(Map<String, dynamic> map, String id) {
    final songsRaw = map['songs'];
    List<Song> songs = [];
    if (songsRaw is List) {
      songs = songsRaw
          .where((e) => e is Map || e is Map<String, dynamic>)
          .map((songMap) => Song.fromMap(Map<String, dynamic>.from(songMap)))
          .toList();
    }
    return Playlist(
      id: id,
      name: map['name'] ?? '',
      songs: songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'songs': songs.map((s) => s.toMap()).toList(),
    };
  }
}