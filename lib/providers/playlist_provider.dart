import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart'; // Thêm nếu chưa có
import '../models/playlist.dart';
import '../models/song.dart';
import 'notification_provider.dart'; // Thêm dòng này

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

      debugPrint('Firebase snapshot: ${snapshot.value}'); // DEBUG: Xem dữ liệu lấy về

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

  // Thêm playlist mới
  Future<void> addPlaylist(String name, {BuildContext? context}) async {
    if (_uid == null) {
      debugPrint('addPlaylist: user not logged in!');
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
      debugPrint('addPlaylist: Playlist created successfully!');
      // Thêm notification
      if (context != null) {
        context.read<NotificationProvider>().addNotificationKey('Tạo playlist "$name" thành công');
      }
    } catch (e) {
      debugPrint('addPlaylist: error $e');
    }
  }

  // Thêm bài hát vào playlist
  Future<void> addSongToPlaylist(String playlistId, Song song, {BuildContext? context}) async {
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
      // Thêm notification
      if (context != null) {
        context.read<NotificationProvider>().addNotificationKey('Đã thêm "${song.title}" vào playlist "${playlist.name}"');
      }
    }
  }

  // Xoá bài hát khỏi playlist
  Future<void> removeSongFromPlaylist(String playlistId, Song song, {BuildContext? context}) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final playlist = _playlists[idx];
    playlist.songs.removeWhere((s) => s.id == song.id);

    // Cập nhật trên database
    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/songs');
    await ref.set(playlist.songs.map((s) => s.toMap()).toList());
    notifyListeners();
    // Thêm notification
    if (context != null) {
      context.read<NotificationProvider>().addNotificationKey('Đã xoá "${song.title}" khỏi playlist "${playlist.name}"');
    }
  }

  // Xoá playlist
  Future<void> removePlaylist(String playlistId, {BuildContext? context}) async {
    if (_uid == null) return;
    final pl = _playlists.firstWhere((pl) => pl.id == playlistId, orElse: () => Playlist(id: '', name: '', songs: []));
    _playlists.removeWhere((pl) => pl.id == playlistId);
    await FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId').remove();
    notifyListeners();
    // Thêm notification
    if (context != null && pl.id.isNotEmpty) {
      context.read<NotificationProvider>().addNotificationKey('Đã xoá playlist "${pl.name}"');
    }
  }

  // Xoá bài hát khỏi playlist bằng songId
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
    // Thêm notification
    if (context != null && oldSong.id.isNotEmpty) {
      context.read<NotificationProvider>().addNotificationKey('Đã xoá "${oldSong.title}" khỏi playlist "${playlist.name}"');
    }
  }

  // ĐỔI TÊN PLAYLIST
  Future<void> renamePlaylist(String playlistId, String newName, {BuildContext? context}) async {
    if (_uid == null) return;
    final idx = _playlists.indexWhere((pl) => pl.id == playlistId);
    if (idx == -1) return;

    final oldName = _playlists[idx].name;
    // Tạo object mới với tên mới, giữ nguyên các field khác
    _playlists[idx] = _playlists[idx].copyWith(name: newName);
    notifyListeners();

    // Cập nhật trên Realtime Database
    final ref = FirebaseDatabase.instance.ref('playlists/$_uid/$playlistId/name');
    await ref.set(newName);

    // Thêm notification
    if (context != null) {
      context.read<NotificationProvider>().addNotificationKey('Đã đổi tên playlist "$oldName" thành "$newName"');
    }
  }
}