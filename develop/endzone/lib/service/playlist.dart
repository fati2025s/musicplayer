// ===================== lib/service/PlaylistService.dart =====================
import 'dart:convert';
import '../models/playlist.dart';
import 'SocketService.dart';

class PlaylistService {
  final SocketService socketService;

  PlaylistService(this.socketService);

  // --- Helper برای نرمال‌سازی داده ---
  List<dynamic> _normalizeData(dynamic rawData) {
    if (rawData == null) return [];
    if (rawData is List) return rawData;
    if (rawData is String) {
      try {
        return jsonDecode(rawData);
      } catch (e) {
        print("⚠ JSON parse error: $e");
        return [];
      }
    }
    return [];
  }

  // --- ایجاد پلی‌لیست ---
  Future<Playlist?> addPlaylist(String name) async {
    try {
      final response = await socketService.addPlaylist(name);

      if (response["status"] == "success" && response["data"] != null) {
        print("✅ Playlist created: $name");
        return Playlist.fromJson(response["data"]);
      } else {
        print("⚠ Failed to create playlist: ${response["message"]}");
        return null;
      }
    } catch (e) {
      print("❌ Error in addPlaylist: $e");
      return null;
    }
  }

  // --- اشتراک‌گذاری پلی‌لیست ---
  Future<bool> sharePlaylist(int playlistId, String targetUsername) async {
    try {
      final response =
      await socketService.sharePlaylist(playlistId, targetUsername);
      if (response["status"] == "success") {
        return true;
      } else {
        print("⚠ Failed to share playlist: ${response["message"]}");
        return false;
      }
    } catch (e) {
      print("❌ Error in sharePlaylist: $e");
      return false;
    }
  }

  // --- حذف پلی‌لیست ---
  Future<bool> deletePlaylist(int playlistId) async {
    try {
      final response = await socketService.deletePlaylist(playlistId);
      if (response["status"] == "success") {
        return true;
      } else {
        print("⚠ Failed to delete playlist: ${response["message"]}");
        return false;
      }
    } catch (e) {
      print("❌ Error in deletePlaylist: $e");
      return false;
    }
  }

  // --- گرفتن لیست پلی‌لیست‌ها ---
  Future<List<Playlist>> listPlaylists() async {
    try {
      final response = await socketService.listPlaylists();

      if (response["status"] == "success" && response["data"] != null) {
        final dataList = _normalizeData(response["data"]);
        return dataList.map((e) => Playlist.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error in listPlaylists: $e");
      return [];
    }
  }
}
