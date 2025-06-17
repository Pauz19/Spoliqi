class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? coverUrl;
  final String? album;
  final int? duration; // đơn vị: giây
  final String? releaseDate;
  final int? genreId; // Thể loại Deezer
  final String? genreName; // Tên thể loại Deezer
  final String? artistId; // Deezer artist id

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl,
    this.album,
    this.duration,
    this.releaseDate,
    this.genreId,
    this.genreName,
    this.artistId,
  });

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
      genreId: map['genreId'] is int
          ? map['genreId']
          : int.tryParse('${map['genreId'] ?? ''}'),
      genreName: map['genreName'],
      artistId: map['artistId'],
    );
  }

  factory Song.fromDeezerJson(Map<String, dynamic> json) {
    int? genreId;
    String? genreName;
    String? artistId;

    // Deezer trả về genre_id trực tiếp hoặc nằm trong genres['data']
    if (json['genre_id'] != null) {
      genreId = json['genre_id'] is int
          ? json['genre_id']
          : int.tryParse('${json['genre_id']}');
    } else if (json['genres'] != null &&
        json['genres']['data'] is List &&
        (json['genres']['data'] as List).isNotEmpty) {
      final genre = json['genres']['data'][0];
      genreId = genre['id'] is int
          ? genre['id']
          : int.tryParse('${genre['id']}');
      genreName = genre['name'];
    }

    if (json['artist'] != null) {
      artistId = json['artist']['id']?.toString();
    }

    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      artist: json['artist']?['name'] ?? '',
      audioUrl: json['preview'] ?? '',
      coverUrl: json['album']?['cover_big'] ?? json['album']?['cover'] ?? null,
      album: json['album']?['title'],
      duration: json['duration'] is int
          ? json['duration']
          : int.tryParse('${json['duration'] ?? ''}'),
      releaseDate: json['release_date'],
      genreId: genreId,
      genreName: genreName,
      artistId: artistId,
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
      'genreId': genreId,
      'genreName': genreName,
      'artistId': artistId,
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
    int? genreId,
    String? genreName,
    String? artistId,
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
      genreId: genreId ?? this.genreId,
      genreName: genreName ?? this.genreName,
      artistId: artistId ?? this.artistId,
    );
  }
}