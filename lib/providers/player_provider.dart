import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'dart:math';

enum RepeatMode { none, one, all }

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _isShuffling = false;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 30);

  String? _lastPlayedSongId;

  PlayerProvider() {
    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        next();
      }
    });
  }

  // Getter cho MiniPlayer, PlayerScreen
  Song? get currentSong =>
      (_queue.isNotEmpty && _currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;
  bool get isShuffling => _isShuffling;
  RepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  String? get lastPlayedSongId => _lastPlayedSongId;

  // Set một queue mới (và phát bài tương ứng)
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List<Song>.from(songs);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    await _loadAndPlayCurrent();
    if (_queue.isNotEmpty) {
      _lastPlayedSongId = _queue[_currentIndex].id;
    }
    notifyListeners();
  }

  Future<void> playFromList(List<Song> songs, int index) async {
    if (songs.isEmpty || index < 0 || index >= songs.length) return;
    _queue = List<Song>.from(songs);
    _currentIndex = index;
    await _loadAndPlayCurrent();
    if (_queue.isNotEmpty) {
      _lastPlayedSongId = _queue[_currentIndex].id;
    }
    notifyListeners();
  }

  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _loadAndPlayCurrent();
    if (_queue.isNotEmpty) {
      _lastPlayedSongId = _queue[_currentIndex].id;
    }
    notifyListeners();
  }

  Future<void> clearQueue() async {
    await _audioPlayer.stop();
    _queue.clear();
    _currentIndex = 0;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = const Duration(seconds: 30);
    notifyListeners();
  }

  Future<void> clear() async {
    await _audioPlayer.stop();
    _queue.clear();
    _currentIndex = 0;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = const Duration(seconds: 30);
    _isShuffling = false;
    _repeatMode = RepeatMode.none;
    _lastPlayedSongId = null;
    notifyListeners();
  }

  Future<void> _loadAndPlayCurrent() async {
    final song = currentSong;
    if (song != null && song.audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(song.audioUrl);
        await _audioPlayer.play();
        _isPlaying = true;
        _lastPlayedSongId = song.id;
      } catch (e) {
        print('Lỗi khi phát nhạc: $e');
        _isPlaying = false;
      }
    } else {
      _isPlaying = false;
    }
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void seek(Duration newPosition) {
    _audioPlayer.seek(newPosition);
    _position = newPosition;
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == RepeatMode.one) {
      await _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
      return;
    }
    if (_isShuffling) {
      _currentIndex = _getRandomIndex();
    } else if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
      } else {
        // Khi đã ở cuối và không lặp lại, clear queue để currentSong == null
        await clearQueue();
        notifyListeners();
        return;
      }
    }
    await _loadAndPlayCurrent();
    if (_queue.isNotEmpty) {
      _lastPlayedSongId = _queue[_currentIndex].id;
    }
    notifyListeners();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == RepeatMode.one) {
      await _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
      return;
    }
    if (_isShuffling) {
      _currentIndex = _getRandomIndex();
    } else if (_currentIndex > 0) {
      _currentIndex--;
    } else {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = _queue.length - 1;
      }
    }
    await _loadAndPlayCurrent();
    if (_queue.isNotEmpty) {
      _lastPlayedSongId = _queue[_currentIndex].id;
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
    notifyListeners();
  }

  int _getRandomIndex() {
    if (_queue.length <= 1) return _currentIndex;
    int newIndex = _currentIndex;
    final rand = Random();
    while (newIndex == _currentIndex) {
      newIndex = rand.nextInt(_queue.length);
    }
    return newIndex;
  }

  Future<void> addToQueue(Song song) async {
    if (_queue.any((s) => s.id == song.id)) return;
    _queue.add(song);
    notifyListeners();
  }

  Future<void> removeFromQueue(Song song) async {
    _queue.removeWhere((s) => s.id == song.id);
    if (_currentIndex >= _queue.length) {
      _currentIndex = _queue.isEmpty ? 0 : _queue.length - 1;
    }
    notifyListeners();
  }

  void moveSongInQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length ||
        newIndex < 0 || newIndex >= _queue.length) return;
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }

  // ĐÃ LOẠI BỎ HOÀN TOÀN TÍNH NĂNG PHÁT BÀI HÁT TƯƠNG TỰ (RADIO/SIMILAR SONGS).

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}