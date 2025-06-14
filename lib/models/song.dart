class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? coverUrl; // có thể null nếu không có ảnh

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl,
  });

  // Nếu muốn parse từ JSON (ví dụ lấy từ API hoặc local file)
  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    artist: json['artist'] ?? '',
    audioUrl: json['audioUrl'] ?? '',
    coverUrl: json['coverUrl'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'audioUrl': audioUrl,
    'coverUrl': coverUrl,
  };
}