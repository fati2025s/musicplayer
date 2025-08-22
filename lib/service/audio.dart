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

  void setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    _playlist = songs;
    _currentIndex = startIndex;

    final sources = songs.map((song) {
      String path = song.url;
      if (song.source == SongSource.local && !path.startsWith("file://")) {
        path = "file://$path";
      }
      return AudioSource.uri(Uri.parse(path));
    }).toList();

    final playlistSource = ConcatenatingAudioSource(children: sources);

    try {
      await _player.setAudioSource(
        playlistSource,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );
    } catch (e) {
      print("Error setting playlist: $e");
    }
  }

  Future<void> play() async {
    await _player.play();
    if (currentSong != null) {
      currentSong!.lastPlayedAt = DateTime.now();
    }
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
    await _player.seekToNext();
  }

  Future<void> previous() async {
    await _player.seekToPrevious();
  }

  void dispose() {
    _player.dispose();
  }
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  AudioService() {
    _player.currentIndexStream.listen((index) {
      if (index != null) {
        _currentIndex = index;
      }
    });
  }

  bool get isPlaying => _player.playing;

}
