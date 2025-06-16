class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? coverUrl;
  final String? album;
  final int? duration; // đơn vị: giây
  final String? releaseDate;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl,
    this.album,
    this.duration,
    this.releaseDate,
  });

  // Sử dụng khi lấy dữ liệu từ Firebase hoặc Deezer API
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      coverUrl: map['coverUrl'],
      album: map['album'],
      duration: map['duration'] is int
          ? map['duration']
          : int.tryParse('${map['duration'] ?? ''}'),
      releaseDate: map['releaseDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'album': album,
      'duration': duration,
      'releaseDate': releaseDate,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? coverUrl,
    String? album,
    int? duration,
    String? releaseDate,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }
}