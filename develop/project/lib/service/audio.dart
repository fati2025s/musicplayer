import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'SocketService.dart';
import 'Upload.dart';


class SongStreamAudioSource extends StreamAudioSource {
  final Stream<List<int>> byteStream;

  SongStreamAudioSource(this.byteStream);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final controller = StreamController<List<int>>();
    byteStream.listen(
          (chunk) => controller.add(Uint8List.fromList(chunk)),
      onDone: () => controller.close(),
      onError: (e, st) {
        controller.addError(e, st);
        controller.close();
      },
      cancelOnError: true,
    );

    return StreamAudioResponse(
      sourceLength: null,
      contentLength: null,
      offset: start ?? 0,
      stream: controller.stream,
      contentType: 'audio/mpeg',
    );
  }
}

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  late final UploadService uploadService;

  List<Song> _playlist = [];
  int _currentIndex = 0;

  AudioService({UploadService? upload}) {
    uploadService = upload ?? UploadService(SocketService());
    _player.currentIndexStream.listen((index) {
      if (index != null) _currentIndex = index;
    });
  }

  Song? get currentSong =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Stream<Song?> get currentSongStream =>
      _player.currentIndexStream.map((index) {
        if (index != null && index >= 0 && index < _playlist.length) {
          return _playlist[index];
        }
        return null;
      });

  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    _playlist = songs;
    _currentIndex = startIndex;

    final sources = songs
        .map((song) => SongStreamAudioSource(
      uploadService.streamSong(song.id),
    ))
        .toList();

    final playlistSource = ConcatenatingAudioSource(children: sources);

    try {
      await _player.setAudioSource(
        playlistSource,
        initialIndex: startIndex,
      );
    } catch (e) {
      print("Error setting playlist: $e");
    }
  }

  Future<void> play() async {
    if (_player.audioSource != null) {
      await _player.play();
      currentSong?.lastPlayedAt = DateTime.now();
    }
  }

  Future<void> pause() async => _player.pause();
  Future<void> seekTo(Duration position) async => _player.seek(position);
  Future<void> setShuffle(bool enabled) async =>
      _player.setShuffleModeEnabled(enabled);
  Future<void> next() async => _player.seekToNext();
  Future<void> previous() async => _player.seekToPrevious();
  bool get isPlaying => _player.playing;

  void dispose() {
    _player.dispose();
  }
}
