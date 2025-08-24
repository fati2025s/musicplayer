import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import 'dart:math';

class UploadSongScreen extends StatefulWidget {
  final Function(Song) onSongUploaded;

  const UploadSongScreen({Key? key, required this.onSongUploaded}) : super(key: key);

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  String? filePath;
  final nameController = TextEditingController();
  final artistController = TextEditingController();

  Future pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        filePath = result.files.single.path!;
      });
    }
  }

  void upload() {
    if (filePath == null || nameController.text.isEmpty || artistController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لطفاً همه‌ی اطلاعات رو کامل کن")),
      );
      return;
    }

    final newSong = Song(
      id: Random().nextInt(100000),
      name: nameController.text,
      artist: artistController.text,
      url: filePath!,
      source: SongSource.uploaded,
    );

    widget.onSongUploaded(newSong);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("آپلود آهنگ 🎵")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("انتخاب فایل mp3"),
            ),
            if (filePath != null) Text("انتخاب شده: ${filePath!.split('/').last}"),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "نام آهنگ"),
            ),
            TextField(
              controller: artistController,
              decoration: const InputDecoration(labelText: "نام خواننده"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: upload,
              child: const Text("آپلود"),
            )
          ],
        ),
      ),
    );
  }
}