import 'package:flutter/material.dart';
import '../models/song.dart';
import '../utils/auto_playlists.dart';

class BlackRecentlyPlayedScreen extends StatelessWidget {
  final List<Song> allSongs;

  const BlackRecentlyPlayedScreen({Key? key, required this.allSongs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recentSongs = getRecentlyPlayed(allSongs);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("🕒 Recently Played")),
      body: recentSongs.isEmpty
          ? const Center(child: Text("هیچ آهنگی اخیراً پخش نشده",
      style: TextStyle(color: Colors.white),))
          : ListView.builder(
        itemCount: recentSongs.length,
        itemBuilder: (context, index) {
          final song = recentSongs[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(song.name),
            subtitle: Text(song.artist),
            trailing: Text(
              song.lastPlayedAt!.toLocal().toString().substring(0, 16),
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}