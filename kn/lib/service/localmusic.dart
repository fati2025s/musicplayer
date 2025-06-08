/*import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

class LocalMusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<List<Song>> loadLocalSongs() async {
    // درخواست دسترسی
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    // گرفتن آهنگ‌ها
    final songs = await _audioQuery.querySongs();

    // تبدیل به Song پروژه‌ی تو
    return songs.map((s) {
      return Song(
        id: s.id,
        name: s.title,
        artist: s.artist ?? "Unknown",
        url: s.uri ?? "", // یا data
        source: SongSource.local,
      );
    }).toList();
  }
}*/
