// ===================== lib/service/AudioService.dart =====================
import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import 'SocketService.dart';
import 'Song.dart';

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

  /// آهنگ فعلی
  Song? get currentSong =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

  // === استریم‌ها برای UI
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

  /// دانلود آهنگ و ذخیره در temp
  Future<File> _downloadSongToFile(Song song) async {
    // استفاده از Documents Directory به‌جای Temp
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/song_${song.id}.mp3");

    if (!await file.exists()) {
      try {
        print("⬇ شروع دانلود آهنگ: ${song.name}");
        await socketService.downloadSong(song.id, file.path);

        if (await file.exists()) {
          print("✅ دانلود کامل شد: ${file.path}");
          print("📏 حجم فایل: ${await file.length()} بایت");
        } else {
          print("❌ فایل دانلود نشد: ${file.path}");
        }
      } catch (e) {
        print("⚠ خطا در دانلود آهنگ ${song.name}: $e");
        rethrow;
      }
    } else {
      print("📂 فایل از قبل وجود داشت: ${file.path}");
      print("📏 حجم فایل موجود: ${await file.length()} بایت");
    }

    return file;
  }



  /// آماده کردن پلی‌لیست
  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    _playlist = songs;
    _currentIndex = startIndex;

    final sources = <AudioSource>[];

    for (var song in songs) {
      try {
        final file = await _downloadSongToFile(song);
        final cleanPath = file.path.replaceAll(".mp3.mp3", ".mp3");
        sources.add(AudioSource.file(file.path));
      } catch (e) {
        print("⚠ خطا در آماده‌سازی آهنگ ${song.name}: $e");
      }
    }

    if (sources.isEmpty) {
      print("❌ هیچ آهنگی قابل پخش نشد!");
      return;
    }

    final playlistSource = ConcatenatingAudioSource(children: sources);

    try {
      await _player.setAudioSource(
        playlistSource,
        initialIndex: startIndex < sources.length ? startIndex : 0,
      );
    } catch (e) {
      print("Error setting playlist: $e");
    }
  }

  /// پخش آهنگ
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
