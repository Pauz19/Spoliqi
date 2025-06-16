class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl; // <-- thêm lại trường này!
  final String? coverUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    artist: json['artist'] ?? '',
    audioUrl: json['audioUrl'] ?? '', // <-- lấy từ dữ liệu firebase
    coverUrl: json['coverUrl'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'audioUrl': audioUrl,
    'coverUrl': coverUrl,
  };

  factory Song.fromMap(Map<String, dynamic> map) => Song.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}