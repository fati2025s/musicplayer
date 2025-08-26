import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/playlist.dart';
import 'package:untitled/screens/blackplaylistdetail.dart';
import 'package:untitled/screens/playlistdetail.dart';
import 'package:untitled/screens/singelton.dart';

class PlaylistsHome extends StatefulWidget {
  final List<Playlist> allplaylists;

  const PlaylistsHome({Key? key, required this.allplaylists}) : super(key: key);

  @override
  State<PlaylistsHome> createState() => _PlaylistsHomeState();
}

class _PlaylistsHomeState extends State<PlaylistsHome> {
  late List<Playlist> playlists;
  String message = "";
  final TextEditingController _controllername = TextEditingController();

  @override
  void initState() {
    super.initState();
    playlists = widget.allplaylists;
  }

  void showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create new playlist"),
        content: TextField(
          controller: _controllername,
          decoration: const InputDecoration(labelText: "name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("cancel"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _controllername.text.trim();
              if (name.isEmpty) return;

              /*setState(() {
                playlists.add(
                  Playlist(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: name,
                    songs: [],
                  ),
                );
              });*/

              Navigator.pop(ctx);
              await _addplaylist();
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Text("create"),
          ),
        ],
      ),
    );
  }

  Future<void> _addplaylist() async {
    final name = _controllername.text.trim();
    if (name.isEmpty) {
      setState(() => message = "Name is invalid");
      return;
    }

    final requestBody = {
      "type": "addPlaylist",
      "payload": {
        "id": Random().nextInt(100000),
        "name": name,
      }
    };

    try {
      final socketService = singelton();

      if (!socketService.isConnected) {
        await socketService.connect("172.20.195.170", 8080);
      }

      final responseJson = await socketService.sendAndReceive(requestBody);

      if (responseJson["status"] == "success") {
        final newPlaylist = Playlist.fromJson(responseJson["data"]);
        setState(() {
          playlists.add(newPlaylist);
        });
      } else {
        setState(() => message = responseJson["message"] ?? "Add playlist failed.");
      }
    } catch (e) {
      setState(() => message = "Connection failed: $e");
    }
  }

  Future<void> _deletePlaylist(int playlistId) async {
    final requestBody = {
      "type": "deletePlaylist",
      "payload": {
        "playlistId": playlistId,
        //"userId": widget.playlist.user.id
      }
    };

    try {
      final socketService = singelton();
      await socketService.connect("172.20.195.170", 8080);

      socketService.listen((responseJson) {
        setState(() {
          message = responseJson["message"] ?? "Unknown response";
        });

        if (responseJson["status"] == "success") {
          setState(() {
            playlists.removeWhere((playlist) => playlist.id == playlistId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Playlist deleted successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete playlist: ${responseJson["message"]}")),
          );
        }
      });

      socketService.send(requestBody);
    } catch (e) {
      setState(() {
        message = "Connection failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: playlists.isEmpty
          ? const Center(
        child: Text(
          'هیچ پلی‌لیستی وجود ندارد',
          style: TextStyle(fontSize: 18),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: List.generate(playlists.length, (index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailsScreen(playlist: playlists[index]),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        playlists[index].name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${playlists[index].music.length} آهنگ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await _deletePlaylist(playlists[index].id);
                        },
                        child: const Icon(
                          Icons.delete,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreatePlaylistDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}

