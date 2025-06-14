import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

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
  Song? get currentSong => _queue.isNotEmpty ? _queue[_currentIndex] : null;
  bool get isShuffling => _isShuffling;
  RepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  // Set một queue mới (và phát bài tương ứng)
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List<Song>.from(songs);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    await _loadAndPlayCurrent();
    notifyListeners();
  }

  // Xóa queue, dừng nhạc (ẩn MiniPlayer)
  Future<void> clearQueue() async {
    await _audioPlayer.stop();
    _queue.clear();
    _currentIndex = 0;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = const Duration(seconds: 30);
    notifyListeners();
  }

  Future<void> _loadAndPlayCurrent() async {
    final song = currentSong;
    if (song != null && song.audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(song.audioUrl);
        _audioPlayer.play();
        _isPlaying = true;
      } catch (_) {
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

  void next() async {
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
        await clearQueue();
        return;
      }
    }
    await _loadAndPlayCurrent();
    notifyListeners();
  }

  void previous() async {
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
    while (newIndex == _currentIndex) {
      newIndex = (DateTime.now().millisecondsSinceEpoch % _queue.length);
    }
    return newIndex;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}