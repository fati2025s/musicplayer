import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled/screens/singelton.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../service/SocketService.dart';
import '../screens/player.dart';
import '../service/audio.dart';
import '../service/playlist.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailsScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  final AudioService audioService = AudioService();
  final SocketService socketService = SocketService();
  late PlaylistService playlistService;
  String message = "";

  @override
  void initState() {
    super.initState();
    if (!socketService.isConnected) {
      socketService.connect("10.208.175.99", 8080);
    }
    playlistService = PlaylistService(socketService);
  }

  void removeSong(Song song) async {
    await socketService.send({
      "type": "removeSongFromPlaylist",
      "payload": {
        "playlistId": widget.playlist.id,
        "songId": song.id,
      }
    });

    setState(() {
      widget.playlist.music.remove(song);
    });
  }

  void addSong(Song song) async {
    await socketService.send({
      "type": "addSongToPlaylist",
      "payload": {
        "playlistId": widget.playlist.id,
        "song": song.toJson(),
      }
    });

    setState(() {
      widget.playlist.music.add(song);
    });
  }

  void showAddSongDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("افزودن آهنگ به پلی‌لیست"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "نام آهنگ"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("انصراف"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newSong = Song(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  artist: "Unknown",
                  url: "",
                  source: SongSource.uploaded,
                  isDownloaded: false,
                );
                addSong(newSong);
              }
              Navigator.pop(ctx);
            },
            child: const Text("افزودن"),
          ),
        ],
      ),
    );
  }




  void showShareDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("اشتراک‌گذاری پلی‌لیست"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "نام کاربری مقصد"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("انصراف"),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetUsername = controller.text.trim();
              if (targetUsername.isNotEmpty) {
                final ok = await playlistService.sharePlaylist(
                  widget.playlist.id,
                  targetUsername,
                );
                if (ok) {
                  Fluttertoast.showToast(
                    msg: "با موفقیت اشتراک‌گذاری شد!",
                    backgroundColor: Colors.green,
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: "خطا در اشتراک‌گذاری پلی‌لیست",
                    backgroundColor: Colors.red,
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text("اشتراک‌گذاری"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: showShareDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddSongDialog,
          ),
        ],
      ),
      body: playlist.music.isEmpty
          ? const Center(child: Text("هیچ آهنگی در این پلی‌لیست نیست"))
          : ListView.builder(
        itemCount: playlist.music.length,
        itemBuilder: (context, index) {
          final song = playlist.music[index];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(song.name),
            subtitle: Text(song.artist),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => removeSong(song),
            ),
            onTap: () {
              audioService.setPlaylist(playlist.music, startIndex: index);
              audioService.play();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(audioService: audioService),
                ),
              );
            },
          );
        },
      ),
    );
  }
}