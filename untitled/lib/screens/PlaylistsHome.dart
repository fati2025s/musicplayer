import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/playlist.dart';
import 'package:untitled/screens/blackplaylistdetail.dart';
import 'package:untitled/screens/playlistdetail.dart';

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

  Future<void> _addplaylist() async {
    print("hi");
    final name = _controllername.text;
    if (name.isEmpty) {
      setState(() => message = "name is invalid");
      return;
    }

    final requestBody = {
      "type": "addPlaylist",
      "payload": {
        "id": Random().nextInt(100000),
        "name": name,
      }
    };
    final jsonString = json.encode(requestBody) + '\n';

    try {
      var socket = await Socket.connect("172.20.98.97", 8080);
      StringBuffer responseText = StringBuffer();
      final completer = Completer<String>();

      socket.write(jsonString);
      await socket.flush();

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((data) {
        responseText.write(data);
        if (data.contains("end")) {
          socket.close();
          completer.complete(responseText.toString());
        }
      }, onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      }, onDone: () {
        if (!completer.isCompleted) {
          completer.complete(responseText.toString());
        }
      }, cancelOnError: true);

      final result = await completer.future;
      final Map<String, dynamic> responseJson =
      json.decode(result.replaceAll("end", ""));

      if (responseJson["success"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("addplaylistStatus", true);
        await prefs.setString("Name", name);
      } else {
        setState(() {
          message = responseJson["message"] ?? "add playlist failed.";
        });
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
                      songs: [],
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

