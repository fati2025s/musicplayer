import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import 'SocketService.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final SocketService socketService;

  List<Song> _playlist = [];
  int _currentIndex = 0;
  StreamSubscription<int?>? _indexSub;

  AudioService({SocketService? socket})
      : socketService = socket ?? SocketService() {
    _indexSub = _player.currentIndexStream.listen((index) {
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

  Future<File> _downloadSongToFile(Song song) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/song_${song.id}.mp3");

    if (!await file.exists()) {
      try {
        if (kDebugMode) print("⬇ شروع دانلود: ${song.name}");
        final downloadedFile = await socketService.downloadSong(song.id, file.path);
        if (kDebugMode) print("✅ دانلود کامل شد: ${downloadedFile.path}");
        return downloadedFile;
      } catch (e) {
        if (kDebugMode) print("⚠ خطا در دانلود ${song.name}: $e");
        rethrow;
      }
    }
    return file;
  }


  Future<void> playDownloadedSong(Song song) async {
    try {
      final file = await _downloadSongToFile(song);

      await _player.stop();
      await _player.setFilePath(file.path); // اینجا مطمئن میشی فایل کامل هست
      _playlist = [song.copyWith(url: file.path, isDownloaded: true)];
      _currentIndex = 0;

      await _player.play();
      print(" در حال پخش: ${song.name}");
    } catch (e) {
      if (kDebugMode) print(" خطا در پخش ${song.name}: $e");
    }
  }


  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    _playlist = songs;
    _currentIndex = startIndex;

    final sources = <AudioSource>[];

    for (var i = 0; i < songs.length; i++) {
      final song = songs[i];
      try {
        final f = await _downloadSongToFile(song);
        sources.add(AudioSource.file(f.path));
      } catch (e) {
        if (song.url.isNotEmpty) {
          sources.add(AudioSource.uri(Uri.parse(song.url)));
        } else {
          if (kDebugMode) print("️ آهنگ ${song.name} نه دانلود شد نه URL داشت");
        }
      }
    }


    final playlistSource = ConcatenatingAudioSource(children: sources);

    try {
      await _player.setAudioSource(
        playlistSource,
        initialIndex: startIndex < sources.length ? startIndex : 0,
      );
    } catch (e) {
      if (kDebugMode) print("Error setting playlist: $e");
    }
  }

  Future<void> play() async {
    if (_player.audioSource != null) {
      await _player.play();
      if (currentSong != null) {
        currentSong!.lastPlayedAt = DateTime.now();
      }
    }
  }

  Future<void> pause() async => _player.pause();
  Future<void> seekTo(Duration position) async => _player.seek(position);
  Future<void> setShuffle(bool enabled) async =>
      _player.setShuffleModeEnabled(enabled);
  Future<void> next() async => _player.seekToNext();
  Future<void> previous() async => _player.seekToPrevious();

  bool get isPlaying => _player.playing;
  bool get isShuffling => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;

  Future<void> setLoop(LoopMode mode) async => _player.setLoopMode(mode);

  void dispose() {
    _indexSub?.cancel();
    _player.dispose();
  }
}
