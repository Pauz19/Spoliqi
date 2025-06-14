import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistProvider extends ChangeNotifier {
  final List<Playlist> _playlists = [];

  List<Playlist> get playlists => List.unmodifiable(_playlists);

  void addPlaylist(String name) {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: [],
    );
    _playlists.add(playlist);
    notifyListeners();
  }

  void addSongToPlaylist(String playlistId, Song song) {
    final playlist = _playlists.firstWhere((pl) => pl.id == playlistId, orElse: () => throw Exception('Playlist not found'));
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(String playlistId, Song song) {
    final playlist = _playlists.firstWhere((pl) => pl.id == playlistId, orElse: () => throw Exception('Playlist not found'));
    playlist.songs.removeWhere((s) => s.id == song.id);
    notifyListeners();
  }

  void removePlaylist(String playlistId) {
    _playlists.removeWhere((pl) => pl.id == playlistId);
    notifyListeners();
  }

  // Nếu muốn hỗ trợ xoá bằng songId (String) cho tiện lợi từ giao diện:
  void removeSongFromPlaylistById(String playlistId, String songId) {
    final playlist = _playlists.firstWhere((pl) => pl.id == playlistId, orElse: () => throw Exception('Playlist not found'));
    playlist.songs.removeWhere((s) => s.id == songId);
    notifyListeners();
  }
}