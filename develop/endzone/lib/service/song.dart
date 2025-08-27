// ===================== lib/service/SongService.dart =====================
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'SocketService.dart';

class SongService extends ChangeNotifier {
  static final SongService _instance = SongService._internal();
  factory SongService() => _instance;
  SongService._internal();

  final SocketService _socket = SocketService();

  // لیست‌های خاص
  final List<Song> _likedSongs = [];
  final List<Song> _recentlyPlayed = [];
  final List<Song> _songsAddedByMe = [];

  static const int _recentLimit = 20;

  // === Getters برای دسترسی در UI
  List<Song> get likedSongs => List.unmodifiable(_likedSongs);
  List<Song> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  List<Song> get songsAddedByMe => List.unmodifiable(_songsAddedByMe);

  // ------------------ Private Helper ------------------
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
  // ------------------ دریافت همه آهنگ‌ها از سرور ------------------

  Future<List<Song>> fetchAllSongs() async {
    try {
      final resp = await _socket.sendAndWait({
        "type": "listSongs",
      });

      if (resp['status'] == 'success' && resp['data'] != null) {
        return (resp['data'] as List)
            .map((e) => Song.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("خطا در fetchAllSongs: $e");
    }
    return [];
  }


  // ------------------ لایک / آنلایک (toggle) ------------------
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
