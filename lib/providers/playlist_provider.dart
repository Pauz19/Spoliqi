import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistProvider extends ChangeNotifier {
  final List<Playlist> _playlists = [];
  bool isLoading = false;
  String? _currentUid;

  List<Playlist> get playlists => List.unmodifiable(_playlists);

  // Lấy UID hiện tại
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Xoá toàn bộ playlists trong bộ nhớ (dùng khi đổi user)
  void clearPlaylists() {
    _playlists.clear();
    _currentUid = null;
    notifyListeners();
  }

  // Load playlists của user từ Realtime Database, tự động clear khi đổi user
  Future<void> loadPlaylists() async {
    final uid = _uid;
    if (uid == null) {
      isLoading = false;
      clearPlaylists();
      return;
    }
    // Nếu đổi user thì reset playlists
    if (_currentUid != uid) {
      clearPlaylists();
      _currentUid = uid;
    }
    isLoading = true;
    notifyListeners();

    try {
      final ref = FirebaseDatabase.instance.ref('playlists/$uid');
      final snapshot = await ref.get();

      print('Firebase snapshot: ${snapshot.value}'); // DEBUG: Xem dữ liệu lấy về

      _playlists.clear();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in data.entries) {
          final playlistData = Map<String, dynamic>.from(entry.value);
          final songsRaw = playlistData['songs'];
          List<Song> songs = [];
          if (songsRaw is List) {
            songs = songsRaw
                .where((e) => e is Map || e is Map<String, dynamic>)
                .map((songMap) => Song.fromMap(Map<String, dynamic>.from(songMap)))
                .toList();
          }
          _playlists.add(
            Playlist(
              id: entry.key,
              name: playlistData['name'] ?? '',
              songs: songs,
            ),
          );
        }
      }
    } catch (e, stack) {
      print('LỖI khi load playlist: $e');
      print(stack);
    }
    isLoading = false;
    notifyListeners();
  }

  // Thêm playlist mới
  Future<void> addPlaylist(String name) async {
    if (_uid == null) {
      print('addPlaylist: user not logged in!');
      return;
    }
    try {
      final ref = FirebaseDatabase.instance.ref('playlists/$_uid').push();
      await ref.set({
        'name': name,
        'songs': <dynamic>[],
        'createdAt': DateTime.now().toIso8601String(),
      });
      await loadPlaylists();
      print('addPlaylist: tạo playlist thành công!');
    } catch (e) {
      print('addPlaylist: lỗi $e');
    }
  }

  // Thêm bài hát vào playlist
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final playlist = _playlists[idx];
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);

      // Cập nhật trên database
      final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/songs');
      await ref.set(playlist.songs.map((s) => s.toMap()).toList());
      notifyListeners();
    }
  }

  // Xoá bài hát khỏi playlist
  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final playlist = _playlists[idx];
    playlist.songs.removeWhere((s) => s.id == song.id);

    // Cập nhật trên database
    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/songs');
    await ref.set(playlist.songs.map((s) => s.toMap()).toList());
    notifyListeners();
  }

  // Xoá playlist
  Future<void> removePlaylist(String playlistId) async {
    if (_uid == null) return;
    _playlists.removeWhere((pl) => pl.id == playlistId);
    await FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId').remove();
    notifyListeners();
  }

  // Xoá bài hát khỏi playlist bằng songId
  Future<void> removeSongFromPlaylistById(String playlistId, String songId) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final playlist = _playlists[idx];
    playlist.songs.removeWhere((s) => s.id == songId);

    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/songs');
    await ref.set(playlist.songs.map((s) => s.toMap()).toList());
    notifyListeners();
  }

  // ĐỔI TÊN PLAYLIST
  Future<void> renamePlaylist(String playlistId, String newName) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    // Tạo object mới với tên mới, giữ nguyên các field khác
    _playlists[idx] = _playlists[idx].copyWith(name: newName);
    notifyListeners();

    // Cập nhật trên Realtime Database
    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/name');
    await ref.set(newName);
  }
}