import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../models/song.dart';

class LocalMusicService {
  Future<List<Song>> loadLocalSongsFromFolder() async {
    List<Song> songsList = [];

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return [];
    }

    final dir = Directory(selectedDirectory);
    final files = dir.listSync(recursive: true);

    for (var file in files) {
      if (file is File && file.path.toLowerCase().endsWith(".mp3")) {
        try {
          final metadata = await MetadataRetriever.fromFile(file);
          songsList.add(
            Song(
              id: file.hashCode,
              name: metadata.trackName ?? file.uri.pathSegments.last,
              artist: metadata.albumArtistName ?? "Unknown",
              url: file.path,
              source: SongSource.local,
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

  Future<Song?> loadSingleSong() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      final file = File(pickedFile.path!);

      try {
        final metadata = await MetadataRetriever.fromFile(file);
        return Song(
          id: file.hashCode,
          name: metadata.trackName ?? pickedFile.name,
          artist: metadata.albumArtistName ?? "Unknown",
          url: file.path,
          source: SongSource.local,
          isDownloaded: true,
        );
      } catch (e) {
        print("خطا در خواندن اطلاعات فایل: $e");
      }
    }

    return null;
  }
}
