import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PlaylistService {
  final _db = FirebaseDatabase.instance;

  // Thêm playlist mới
  Future<void> addPlaylist(String name, List<Map<String, dynamic>> songs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _db.ref('playlists/${user.uid}').push();
    await ref.set({
      'name': name,
      'songs': songs,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Lấy danh sách playlist của user
  Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final ref = _db.ref('playlists/${user.uid}');
    final snapshot = await ref.get();
    if (!snapshot.exists) return [];
    final Map data = snapshot.value as Map;
    return data.entries
        .map<Map<String, dynamic>>(
          (e) => {
        'id': e.key,
        ...Map<String, dynamic>.from(e.value as Map),
      },
    )
        .toList();
  }

  // Xoá playlist
  Future<void> deletePlaylist(String playlistId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.ref('playlists/${user.uid}/$playlistId').remove();
  }

  // Sửa playlist
  Future<void> updatePlaylist(String playlistId, String newName, List<Map<String, dynamic>> newSongs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.ref('playlists/${user.uid}/$playlistId').update({
      'name': newName,
      'songs': newSongs,
    });
  }
}