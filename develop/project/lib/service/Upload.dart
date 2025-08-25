import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SocketService.dart';

class UploadService {
  final SocketService socketService;

  UploadService(this.socketService);

  Future<Map<String, dynamic>?> pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    if (result == null || result.files.isEmpty) return null;

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

    final meta = {"title": title, "artist": artist};

    if (kIsWeb) {
      final base64Data = base64Encode(fileBytes);
      return await socketService.sendAndWait({
        "type": "uploadSongFile",
        "payload": {
          ...(await _authPayload()),
          "fileName": fileName,
          "base64Data": base64Data,
          "meta": meta
        }
      });
    } else {
      return await socketService.uploadSongFile(picked.path!, meta);
    }
  }

  Future<void> downloadSong(int songId, String savePath) async {
    final req = await socketService.sendAndWait({
      "type": "downloadSong",
      "payload": {
        ...(await _authPayload()),
        "songId": songId,
      }
    });

    if (req["status"] != "success") {
      throw Exception("Download request failed: ${req["message"]}");
    }

    final file = File(savePath);
    final sink = file.openWrite();

    StreamSubscription<Map<String, dynamic>>? subscription;
    subscription = socketService.eventsStream.listen((resp) {
      final msg = resp["message"];
      if (msg == "download_chunk") {
        final b64 = resp["data"]["base64"];
        sink.add(base64Decode(b64));
      } else if (msg == "download_complete") {
        sink.close();
        subscription?.cancel();
        print("Download complete: $savePath");
      }
    });
  }

  Stream<List<int>> streamSong(int songId) async* {
    final req = await socketService.sendAndWait({
      "type": "streamSong",
      "payload": {
        ...(await _authPayload()),
        "songId": songId,
      }
    });

    if (req["status"] != "success") {
      throw Exception("Stream request failed: ${req["message"]}");
    }

    final controller = StreamController<List<int>>();

    StreamSubscription<Map<String, dynamic>>? subscription;
    subscription = socketService.eventsStream.listen((resp) {
      final msg = resp["message"];
      if (msg == "stream_chunk") {
        final b64 = resp["data"]["base64"];
        controller.add(base64Decode(b64));
      } else if (msg == "stream_complete") {
        controller.close();
        subscription?.cancel();
        print("🎵 Stream finished");
      }
    });

    yield* controller.stream;
  }

  Future<Map<String, String>> _authPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username") ?? "";
    final password = prefs.getString("password") ?? "";
    return {"username": username, "password": password};
  }
}
