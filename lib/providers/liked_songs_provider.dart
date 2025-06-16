import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/song.dart';

class LikedSongsProvider extends ChangeNotifier {
  final List<Song> _likedSongs = [];
  List<Song> get likedSongs => List.unmodifiable(_likedSongs);

  String? _currentUid;

  // Xóa danh sách nhạc đã thích trong bộ nhớ (RAM)
  void clearLikedSongs() {
    _likedSongs.clear();
    _currentUid = null;
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Load danh sách nhạc đã thích từ Realtime Database
  Future<void> loadLikedSongs() async {
    final uid = _uid;
    if (uid == null) {
      clearLikedSongs();
      return;
    }
    if (_currentUid != uid) {
      clearLikedSongs();
      _currentUid = uid;
    }
    final ref = FirebaseDatabase.instance.ref('users/$uid/liked_songs');
    final snapshot = await ref.get();
    _likedSongs.clear();
    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((id, value) {
        _likedSongs.add(Song.fromMap(Map<String, dynamic>.from(value)));
      });
    }
    notifyListeners();
  }

  // Thích một bài hát
  Future<void> likeSong(Song song) async {
    final uid = _uid;
    if (uid == null) return;
    if (_likedSongs.any((s) => s.id == song.id)) return;

    _likedSongs.add(song);
    await FirebaseDatabase.instance
        .ref('users/$uid/liked_songs/${song.id}')
        .set(song.toMap());
    notifyListeners();
  }

  // Bỏ thích một bài hát
  Future<void> unlikeSong(Song song) async {
    final uid = _uid;
    if (uid == null) return;
    _likedSongs.removeWhere((s) => s.id == song.id);
    await FirebaseDatabase.instance
        .ref('users/$uid/liked_songs/${song.id}')
        .remove();
    notifyListeners();
  }

  // Kiểm tra bài hát đã thích chưa
  bool isLiked(Song song) {
    return _likedSongs.any((s) => s.id == song.id);
  }
}