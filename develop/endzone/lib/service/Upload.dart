// ===================== lib/service/MusicService.dart =====================
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../models/song.dart';
import 'SocketService.dart';

class MusicService {
  final SocketService socketService;

  MusicService(this.socketService);

  /// انتخاب یک آهنگ و آپلود به سرور
  Future<Song?> pickAndUploadSong() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.first;
    final file = File(pickedFile.path!);

    try {
      final metadata = await MetadataRetriever.fromFile(file);

      // ارسال فایل به سرور
      final response = await socketService.uploadSongFile(file.path, {
        "title": metadata.trackName ?? pickedFile.name,
        "artist": metadata.albumArtistName ??
            (metadata.trackArtistNames?.join(', ') ?? "Unknown"),
      });

      if (response["status"] == "success" && response["data"] != null) {
        // سرور باید id واقعی رو بده
        return Song.fromJson(response["data"]);
      } else {
        print("⚠ خطا در آپلود آهنگ: ${response["message"]}");
        return null;
      }
    } catch (e) {
      print("خطا در خواندن اطلاعات فایل یا آپلود: $e");
      return null;
    }
  }

  /// انتخاب پوشه و آپلود همه آهنگ‌ها (آپلود موازی)
  Future<List<Song>> pickFolderAndUploadSongs() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return [];

    final dir = Directory(selectedDirectory);
    final files = dir.listSync(recursive: true);

    // فقط فایل‌های mp3
    final mp3Files = files
        .where((f) => f is File && f.path.toLowerCase().endsWith(".mp3"))
        .cast<File>();

    // آپلود موازی همه فایل‌ها
    final futures = mp3Files.map((file) async {
      try {
        final metadata = await MetadataRetriever.fromFile(file);

        final response = await socketService.uploadSongFile(file.path, {
          "title": metadata.trackName ?? file.uri.pathSegments.last,
          "artist": metadata.albumArtistName ??
              (metadata.trackArtistNames?.join(', ') ?? "Unknown"),
        });

        if (response["status"] == "success" && response["data"] != null) {
          return Song.fromJson(response["data"]);
        } else {
          print("⚠ خطا در آپلود ${file.path}: ${response["message"]}");
          return null;
        }
      } catch (e) {
        print("خطا در خواندن/آپلود فایل ${file.path}: $e");
        return null;
      }
    });

    final results = await Future.wait(futures);
    return results.whereType<Song>().toList();
  }
}
