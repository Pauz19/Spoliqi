import 'dart:convert';
import 'package:http/http.dart' as http;

class LyricService {
  static Future<String?> fetchLyric({required String artist, required String title}) async {
    try {
      final url = Uri.parse('https://api.lyrics.ovh/v1/$artist/$title');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final lyrics = body['lyrics'];
        if (lyrics is String && lyrics.trim().isNotEmpty) {
          return lyrics.trim();
        }
      }
    } catch (e) {
      // Bạn có thể log lỗi ra debug console nếu muốn
    }
    return null;
  }
}