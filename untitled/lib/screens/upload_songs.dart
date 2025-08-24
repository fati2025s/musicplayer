import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../models/song.dart';
import 'dart:math';

class UploadSongScreen extends StatefulWidget {
  final Function(List<Song>) onSongsUploaded; // تغییر: لیست آهنگ‌ها می‌فرستیم

  const UploadSongScreen({Key? key, required this.onSongsUploaded}) : super(key: key);

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  bool isLoading = false;
  Future pickFolderAndUploadSongs() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      setState(() => isLoading = true);

      try {
        final dir = Directory(directoryPath);
        final files = dir.listSync(recursive: true);

        List<Song> songs = [];

        for (var file in files) {
          if (file is File && file.path.toLowerCase().endsWith(".mp3")) {
            try {
              final metadata = await MetadataRetriever.fromFile(file);
              songs.add(
                Song(
                  id: Random().nextInt(100000),
                  name: metadata.trackName ?? file.uri.pathSegments.last,
                  artist: metadata.albumArtistName ?? "Unknown",
                  url: file.path,
                  source: SongSource.local,
                ),
              );
            } catch (e) {
              debugPrint("خطا در خواندن فایل ${file.path}: $e");
            }
          }
        }

        if (songs.isNotEmpty) {
          widget.onSongsUploaded(songs);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("هیچ فایل MP3 یافت نشد")),
          );
        }
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future uploadFromServer() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("آپلود از سرور هنوز پیاده‌سازی نشده")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("افزودن آهنگ 🎵")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickFolderAndUploadSongs,
              child: const Text("📁 انتخاب فولدر لوکال"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadFromServer,
              child: const Text("🌐 آپلود به سرور"),
            ),
          ],
        ),
      ),
    );
  }
}
