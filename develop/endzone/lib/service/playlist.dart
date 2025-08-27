import 'dart:convert';
import '../models/playlist.dart';
import 'SocketService.dart';

class PlaylistService {
  final SocketService socketService;

  PlaylistService(this.socketService);

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

  Future<Playlist?> addPlaylist(String name) async {
    try {
      final response = await socketService.addPlaylist(name);

      if (response["status"] == "success" && response["data"] != null) {
        final data = response["data"];
        return Playlist.fromJson({
          "id": data["id"],
          "name": data["name"] ?? name,
          "songs": data["songs"] ?? [],
        });
      } else {
        print("⚠ Failed to create playlist: ${response["message"]}");
        return null;
      }
    } catch (e) {
      print(" Error in addPlaylist: $e");
      return null;
    }
  }


  Future<bool> sharePlaylist(int playlistId, String targetUsername) async {
    try {
      final response =
      await socketService.sharePlaylist(playlistId, targetUsername);
      if (response["status"] == "success") {
        return true;
      } else {
        print(" Failed to share playlist: ${response["message"]}");
        return false;
      }
    } catch (e) {
      print(" Error in sharePlaylist: $e");
      return false;
    }
  }

  Future<bool> addSongToPlaylist(int playlistId, int songId) async {
    try {
      final response = await socketService.addSongToPlaylist(playlistId, songId);

      if (response["status"] == "success") {
        print("Song $songId added to playlist $playlistId");
        return true;
      } else {
        print("⚠ Failed to add song: ${response["message"]}");
        return false;
      }
    } catch (e) {
      print("Error in addSongToPlaylist: $e");
      return false;
    }
  }


  Future<bool> deletePlaylist(int playlistId) async {
    try {
      final response = await socketService.deletePlaylist(playlistId);
      if (response["status"] == "success") {
        return true;
      } else {
        print("Failed to delete playlist: ${response["message"]}");
        return false;
      }
    } catch (e) {
      print("Error in deletePlaylist: $e");
      return false;
    }
  }

  Future<bool> renamePlaylist(int playlistId, String newName) async {
    try {
      final response = await socketService.renamePlaylist(playlistId, newName);

      if (response["status"] == "success") {
        print("Playlist $playlistId renamed to $newName");
        return true;
      } else {
        print("Failed to rename playlist: ${response["message"]}");
        return false;
      }
    } catch (e) {
      print("Error in renamePlaylist: $e");
      return false;
    }
  }


  Future<List<Playlist>> listPlaylists() async {
    try {
      final response = await socketService.listPlaylists();

      if (response["status"] == "success" && response["data"] != null) {
        final dataList = _normalizeData(response["data"]);
        return dataList.map((e) => Playlist.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error in listPlaylists: $e");
      return [];
    }
  }
}
