import 'dart:convert';
import 'dart:math';

import '../models/playlist.dart';
import '../models/song.dart';
import 'SocketService.dart';

class PlaylistService {
  final SocketService socketService;

  PlaylistService(this.socketService);

  Future<bool> addPlaylist(String name, List<Song> songs) async {
    final playlist = Playlist(
      id: Random().nextInt(100000),
      name: name,
      likeplaylist: false,
      music: songs,
    );

    final request = {
      "type": "addPlaylist",
      "payload": playlist.toJson(),
    };

    final response = await socketService.sendAndWait(request);
    return response["success"] == "success";
  }

  Future<bool> sharePlaylist(int playlistId, String targetUsername) async {
    final request = {
      "type": "sharePlaylist",
      "payload": {
        "playlistId": playlistId,
        "targetUsername": targetUsername,
      }
    };

    final response = await socketService.sendAndWait(request);
    return response["success"] == "success";
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    final request = {
      "type": "deletePlaylist",
      "payload": {"id": playlist.id},
    };

    final response = await socketService.sendAndWait(request);
    return response["success"] == "success";
  }

  Future<List<Playlist>> getPlaylists() async {
    final request = {
      "type": "getplaylists",
      "payload": {},
    };

    final response = await socketService.sendAndWait(request);

    if (response["success"] == "success" && response["data"] != null) {
      if (response["data"] is List) {
        final List<dynamic> dataList = response["data"];
        return dataList.map((e) => Playlist.fromJson(e)).toList();
      }

      if (response["data"] is String) {
        try {
          final List<dynamic> dataList = jsonDecode(response["data"]);
          return dataList.map((e) => Playlist.fromJson(e)).toList();
        } catch (e) {
          print("خطا در parse کردن پلی‌لیست‌ها: $e");
        }
      }
    }



    return [];
  }
}