import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../models/song.dart';
import 'SocketService.dart';

class MusicService {
  final SocketService socketService;

  MusicService(this.socketService);

  Future<Song?> pickAndUploadSong() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    if (picked.path == null) return null;
    final file = File(picked.path!);

    try {
      final metadata = await MetadataRetriever.fromFile(file);

      final meta = {
        "title": metadata.trackName ?? picked.name,
        "artist": metadata.albumArtistName ??
            (metadata.trackArtistNames?.join(', ') ?? "Unknown")
      };

      final resp = await socketService.uploadSongFile(file.path, meta);

      final song = Song(
        id: resp['songId'],
        name: metadata.trackName ?? picked.name,
        artist: metadata.albumArtistName ??
            (metadata.trackArtistNames?.join(', ') ?? "Unknown"),
        url: file.path,
        source: SongSource.server,
        isDownloaded: true,
      );

      return song;
    } catch (e) {
      print("خطا در خواندن اطلاعات فایل یا آپلود: $e");
      return null;
    }
  }

  Future<List<Song>> pickFolderAndUploadSongs() async {
    List<Song> songsList = [];

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return [];

    final dir = Directory(selectedDirectory);
    final files = dir.listSync(recursive: true);

    for (var entry in files) {
      if (entry is File && entry.path.toLowerCase().endsWith(".mp3")) {
        final file = entry;
        try {
          final metadata = await MetadataRetriever.fromFile(file);

          final meta = {
            "title": metadata.trackName ?? file.uri.pathSegments.last,
            "artist": metadata.albumArtistName ?? "Unknown",
          };

          final resp = await socketService.uploadSongFile(file.path, meta);

          songsList.add(
            Song(
              id: resp['songId'],
              name: metadata.trackName ?? file.uri.pathSegments.last,
              artist: metadata.albumArtistName ?? "Unknown",
              url: file.path,
              source: SongSource.server,
              isDownloaded: true,
            ),
          );
        } catch (e) {
          print("خطا در خواندن/آپلود فایل ${file.path}: $e");
        }
      }
    }

    return songsList;
  }

  Future<List<Song>> loadFolderAsServerSongs({String? directoryPath}) async {
    List<Song> songsList = [];

    String? selectedDirectory = directoryPath;
    if (selectedDirectory == null) {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return [];
    }

    final dir = Directory(selectedDirectory);
    final files = dir.listSync(recursive: true);

    for (var entry in files) {
      if (entry is File && entry.path.toLowerCase().endsWith(".mp3")) {
        final file = entry;
        try {
          final metadata = await MetadataRetriever.fromFile(file);

          songsList.add(
            Song(
              id: file.hashCode,
              name: metadata.trackName ?? file.uri.pathSegments.last,
              artist: metadata.albumArtistName ?? "Unknown",
              url: file.path,
              source: SongSource.server,
              isDownloaded: true,
            ),
          );
        } catch (e) {
          print("خطا در خواندن اطلاعات فایل ${file.path}: $e");
        }
      }
    }

    return songsList;
  }
}
