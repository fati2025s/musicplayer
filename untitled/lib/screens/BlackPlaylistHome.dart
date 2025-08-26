import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/playlist.dart';
import 'package:untitled/screens/blackplaylistdetail.dart';
import 'package:untitled/screens/singelton.dart';

class BlackPlaylistsHome extends StatefulWidget {
  final List<Playlist> allplaylists;

  const BlackPlaylistsHome({Key? key, required this.allplaylists}) : super(key: key);

  @override
  State<BlackPlaylistsHome> createState() => _PlaylistsHomeState();
}

class _PlaylistsHomeState extends State<BlackPlaylistsHome> {
  late List<Playlist> playlists;
  String message = "";
  final TextEditingController _controllername = TextEditingController();

  @override
  void initState() {
    super.initState();
    playlists = widget.allplaylists;
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
        await socketService.connect("10.208.175.99", 8080);
      }

      final responseJson = await socketService.sendAndReceive(requestBody);

      if (responseJson["status"] == "success") {
        setState(() {
          /*playlists.add(
            Playlist(
              id: DateTime.now().millisecondsSinceEpoch,
              name: name,
              songs: [],
            ),
          );*/
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlackPlaylistsHome(allplaylists: playlists),
          ),
        );
      } else {
        setState(() => message = responseJson["message"] ?? "Add playlist failed.");
      }
    } catch (e) {
      setState(() => message = "Connection failed: $e");
    }
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
              if (name.isNotEmpty) {
                setState(() {
                  playlists.add(
                    Playlist(
                      id: DateTime.now().millisecondsSinceEpoch,
                      name: name,
                      likeplaylist: false,
                      music: [],
                    ),
                  );
                });
              }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                    builder: (_) => BlackPlaylistDetailsScreen(playlist: playlists[index]),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF8A0000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    playlists[index].name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
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