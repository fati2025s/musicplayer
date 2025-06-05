import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = 0;

  Song? get currentSong =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _playlist = songs;
    _currentIndex = startIndex;
  }

  Future<void> play() async {
  final song = currentSong;
  if (song == null) return;

  String path = song.url;

  if (song.source == SongSource.local && !path.startsWith("file://")) {
    path = "file://$path";
  }

  await _player.setUrl(path);
  await _player.play();
  song.lastPlayedAt = DateTime.now();
}


  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setShuffle(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> next() async {
    if (_currentIndex + 1 < _playlist.length) {
      _currentIndex++;
      await play();
    }
  }

  Future<void> previous() async {
    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
      await play();
    }
  }

  void dispose() {
    _player.dispose();
  }
}
