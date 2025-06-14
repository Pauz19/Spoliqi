import 'dart:convert';
import 'package:http/http.dart' as http;

/// DeezerService helper for fetching tracks and playlists.
class DeezerService {
  // Lấy các track top (ví dụ dùng cho recommended section)
  Future<List<dynamic>> fetchTopTracks() async {
    final response = await http.get(Uri.parse('https://api.deezer.com/chart/0/tracks'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as List<dynamic>;
    }
    throw Exception('Không thể tải top tracks');
  }

  // Tìm kiếm bài hát theo từ khóa
  Future<List<dynamic>> searchTracks(String keyword) async {
    final response = await http.get(Uri.parse('https://api.deezer.com/search?q=${Uri.encodeComponent(keyword)}'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as List<dynamic>;
    }
    throw Exception('Không thể tìm kiếm bài hát');
  }

  // Lấy danh sách bài hát trong một playlist (dùng để lấy nhạc trẻ Việt Nam)
  Future<List<dynamic>> fetchPlaylistTracks(String playlistId) async {
    final response = await http.get(Uri.parse('https://api.deezer.com/playlist/$playlistId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tracks']['data'] as List<dynamic>;
    }
    throw Exception('Không thể tải playlist');
  }
}