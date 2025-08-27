import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'SocketService.dart';

class SongService extends ChangeNotifier {
  static final SongService _instance = SongService._internal();
  factory SongService() => _instance;
  SongService._internal();

  final SocketService _socket = SocketService();

  final List<Song> _likedSongs = [];

  List<Song> get likedSongs => List.unmodifiable(_likedSongs);

  void _applyLikeChange(Song song, bool liked) {
    song.isLiked = liked;
    if (liked) {
      song.likeCount++;
      if (!_likedSongs.any((s) => s.id == song.id)) {
        _likedSongs.add(song);
      }
    } else {
      if (song.likeCount > 0) song.likeCount--;
      _likedSongs.removeWhere((s) => s.id == song.id);
    }
  }

  Future<void> toggleLike(Song song) async {
    _applyLikeChange(song, !song.isLiked);
    notifyListeners();

    final resp = await _socket.toggleLikeSong(song.id);

    if (resp['status'] != 'success') {
      _applyLikeChange(song, !song.isLiked); // undo
      notifyListeners();
    }
  }
}
