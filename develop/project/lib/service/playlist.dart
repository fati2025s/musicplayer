import 'dart:convert';
import '../models/playlist.dart';
import '../models/song.dart';
import 'SocketService.dart';

class PlaylistService {
  final SocketService socketService;

  PlaylistService(this.socketService);

  Future<Playlist?> addPlaylist(String name) async {
    try {
      final response = await socketService.addPlaylist(name);

      if (response["status"] == "success" && response["data"] != null) {
        print("Playlist created: $name");
        return Playlist.fromJson(response["data"]);
      } else {
        print("⚠ Failed to create playlist: ${response["message"]}");
        return null;
      }
    } catch (e) {
      print("Error in addPlaylist: $e");
      return null;
    }
  }


  Future<bool> sharePlaylist(int playlistId, String targetUsername) async {
    try {
      final response =
      await socketService.sharePlaylist(playlistId, targetUsername);
      return response["status"] == "success";
    } catch (e) {
      print("Error in sharePlaylist: $e");
      return false;
    }
  }

  Future<bool> deletePlaylist(int playlistId) async {
    try {
      final response = await socketService.deletePlaylist(playlistId);
      return response["status"] == "success";
    } catch (e) {
      print("Error in deletePlaylist: $e");
      return false;
    }
  }

  Future<List<Playlist>> listPlaylists() async {
    try {
      final response = await socketService.listPlaylists();

      if (response["status"] == "success" && response["data"] != null) {
        if (response["data"] is List) {
          return (response["data"] as List)
              .map((e) => Playlist.fromJson(e))
              .toList();
        }

        if (response["data"] is String) {
          try {
            final List<dynamic> dataList = jsonDecode(response["data"]);
            return dataList.map((e) => Playlist.fromJson(e)).toList();
          } catch (e) {
            print("Parse error in listPlaylists: $e");
          }
        }
      }
      return [];
    } catch (e) {
      print("Error in listPlaylists: $e");
      return [];
    }
  }
}
