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

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void clearPlaylists() {
    _playlists.clear();
    _currentUid = null;
    notifyListeners();
  }

  Future<void> loadPlaylists() async {
    final uid = _uid;
    if (uid == null) {
      isLoading = false;
      clearPlaylists();
      return;
    }
    if (_currentUid != uid) {
      clearPlaylists();
      _currentUid = uid;
    }
    isLoading = true;
    notifyListeners();

    try {
      final ref = FirebaseDatabase.instance.ref('playlists/$uid');
      final snapshot = await ref.get();

      debugPrint('Firebase snapshot: ${snapshot.value}');

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
      debugPrint('Error loading playlist: $e');
      debugPrint(stack.toString());
    }
    isLoading = false;
    notifyListeners();
  }

  // Thêm playlist mới (trả về bool, kiểm tra trùng tên). KHÔNG sử dụng context ở đây!
  Future<bool> addPlaylist(String name) async {
    if (_uid == null) {
      debugPrint('addPlaylist: user not logged in!');
      return false;
    }
    if (_playlists.any((pl) => pl.name.trim().toLowerCase() == name.trim().toLowerCase())) {
      debugPrint('addPlaylist: playlist name already exists!');
      return false;
    }
    try {
      final ref = FirebaseDatabase.instance.ref('playlists/$_uid').push();
      await ref.set({
        'name': name,
        'songs': <dynamic>[],
        'createdAt': DateTime.now().toIso8601String(),
      });
      await loadPlaylists();
      debugPrint('addPlaylist: Playlist created successfully!');
      return true;
    } catch (e) {
      debugPrint('addPlaylist: error $e');
      return false;
    }
  }

  // Các hàm bên dưới vẫn có thể nhận context nếu thực sự cần thông báo tức thời (không bị async/delay dispose như addPlaylist).

  Future<void> addSongToPlaylist(String playlistId, Song song, {BuildContext? context}) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final playlist = _playlists[idx];
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);

      final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/songs');
      await ref.set(playlist.songs.map((s) => s.toMap()).toList());
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song, {BuildContext? context}) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final playlist = _playlists[idx];
    playlist.songs.removeWhere((s) => s.id == song.id);

    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/songs');
    await ref.set(playlist.songs.map((s) => s.toMap()).toList());
    notifyListeners();
  }

  Future<void> removePlaylist(String playlistId, {BuildContext? context}) async {
    if (_uid == null) return;
    final pl = _playlists.firstWhere((pl) => pl.id == playlistId, orElse: () => Playlist(id: '', name: '', songs: []));
    _playlists.removeWhere((pl) => pl.id == playlistId);
    await FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId').remove();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylistById(String playlistId, String songId, {BuildContext? context}) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final playlist = _playlists[idx];
    final oldSong = playlist.songs.firstWhere((s) => s.id == songId, orElse: () => Song(id: '', title: '', artist: '', audioUrl: '', coverUrl: ''));
    playlist.songs.removeWhere((s) => s.id == songId);

    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/songs');
    await ref.set(playlist.songs.map((s) => s.toMap()).toList());
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName, {BuildContext? context}) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final oldName = _playlists[idx].name;
    _playlists[idx] = _playlists[idx].copyWith(name: newName);
    notifyListeners();

    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/name');
    await ref.set(newName);
  }
}