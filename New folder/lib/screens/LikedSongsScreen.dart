import 'package:flutter/material.dart';
import '../models/song.dart';
import '../utils/auto_playlists.dart';

class LikedSongsScreen extends StatelessWidget {
  final List<Song> allSongs;

  const LikedSongsScreen({Key? key, required this.allSongs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final liked = getLikedSongs(allSongs);

    return Scaffold(
      appBar: AppBar(title: const Text("❤️ Liked Songs")),
      body: ListView.builder(
        itemCount: liked.length,
        itemBuilder: (context, index) {
          final song = liked[index];
          return ListTile(
            title: Text(song.name),
            subtitle: Text(song.artist),
          );
        },
      ),
    );
  }
}
