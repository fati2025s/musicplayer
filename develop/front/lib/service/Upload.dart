// lib/services/upload_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../models/song.dart';
import 'SocketService.dart';

class UploadService {
  final SocketService socketService;

  UploadService(this.socketService);

  Future<void> pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    String fileName;
    Uint8List fileBytes;
    String title = "";
    String artist = "";

    if (kIsWeb) {
      fileName = picked.name;
      fileBytes = picked.bytes!;
      title = fileName;
      artist = "Unknown";
    } else {
      final file = File(picked.path!);
      fileName = file.uri.pathSegments.last;

      try {
        final metadata = await MetadataRetriever.fromFile(file);
        title = metadata.trackName ?? fileName;
        artist = metadata.albumArtistName ??
            (metadata.trackArtistNames?.join(', ') ?? 'Unknown');
      } catch (_) {
        title = fileName;
        artist = "Unknown";
      }

      fileBytes = await file.readAsBytes();
    }

    final base64Data = base64Encode(fileBytes);

    final payload = {
      "fileName": fileName,
      "base64Data": base64Data,
      "meta": {"title": title, "artist": artist}
    };

    final request = {"type": "uploadSongFile", "payload": payload};
    socketService.send(request);
  }
}
