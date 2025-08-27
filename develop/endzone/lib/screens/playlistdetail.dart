import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../service/SocketService.dart';
import '../service/Song.dart';
import '../service/playlist.dart';
import '../service/audio.dart';
import '../screens/player.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailsScreen({Key? key, required this.playlist})
      : super(key: key);

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  final SocketService _socketService = SocketService();
  late final PlaylistService _playlistService;
  final SongService _songService = SongService();


  @override
  void initState() {
    super.initState();
    _playlistService = PlaylistService(_socketService);
    _ensureSocketConnected();
  }

  // اتصال سوکت
  Future<void> _ensureSocketConnected() async {
    try {
      if (!_socketService.isConnected) {
        await _socketService.connect("172.20.195.170", 8080);
      }
    } catch (e) {
      debugPrint("Socket connect failed: $e");
    }
  }

  // ---------- حذف آهنگ ----------
  Future<void> _removeSong(Song song) async {
    try {
      final resp = await _playlistService.socketService.sendAndWait({
        "type": "removeSongFromPlaylist",
        "payload": {
          "playlistId": widget.playlist.id,
          "songId": song.id,
        }
      });

      if (resp['status'] == 'success') {
        setState(() {
          if (_hasMusicField(widget.playlist)) {
            (widget.playlist as dynamic).music.removeWhere((s) => s.id == song.id);
          } else {
            (widget.playlist as dynamic).songs.removeWhere((s) => s.id == song.id);
          }
        });
        Fluttertoast.showToast(msg: "آهنگ حذف شد", backgroundColor: Colors.green);
      } else {
        Fluttertoast.showToast(
          msg: "خطا در حذف: ${resp['message'] ?? 'نامشخص'}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "خطای شبکه هنگام حذف آهنگ", backgroundColor: Colors.red);
    }
  }

  // ---------- افزودن آهنگ به پلی‌لیست ----------
  Future<void> _addSongToPlaylist(Song song) async {
    try {
      final resp = await _playlistService.socketService.sendAndWait({
        "type": "addSongToPlaylist",
        "payload": {
          "playlistId": widget.playlist.id,
          "song": song.toJson(),
        }
      });

      if (resp['status'] == 'success') {
        setState(() {
          if (_hasMusicField(widget.playlist)) {
            (widget.playlist as dynamic).music.add(song);
          } else {
            (widget.playlist as dynamic).songs.add(song);
          }
        });
        Fluttertoast.showToast(msg: "آهنگ اضافه شد", backgroundColor: Colors.green);
      } else {
        Fluttertoast.showToast(
          msg: "خطا در افزودن: ${resp['message'] ?? 'نامشخص'}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "خطای شبکه", backgroundColor: Colors.red);
    }
  }

  // ---------- نمایش لیست آهنگ‌ها برای انتخاب ----------
  void _showSongPickerDialog() async {
    try {
      final songs = await _songService.fetchLikedSongs();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("انتخاب آهنگ"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: songs.isEmpty
                ? const Center(child: Text("هیچ آهنگی موجود نیست"))
                : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song.name),
                  subtitle: Text(song.artist ?? "Unknown"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addSongToPlaylist(song);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "خطا در دریافت لیست آهنگ‌ها", backgroundColor: Colors.red);
    }
  }

  // ---------- اشتراک گذاری ----------
  void _showShareDialog() {
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
          ElevatedButton(
            onPressed: () {
              final username = controller.text.trim();
              Navigator.pop(ctx);
              if (username.isNotEmpty) {
                _sharePlaylistWith(username);
              }
            },
            child: const Text("اشتراک‌گذاری"),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePlaylistWith(String targetUsername) async {
    try {
      final ok = await _playlistService.sharePlaylist(widget.playlist.id, targetUsername.trim());
      if (ok) {
        Fluttertoast.showToast(msg: "پلی‌لیست به $targetUsername ارسال شد", backgroundColor: Colors.green);
      } else {
        Fluttertoast.showToast(msg: "خطا در اشتراک‌گذاری", backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "خطای شبکه هنگام اشتراک‌گذاری", backgroundColor: Colors.red);
    }
  }

  // ---------- Helpers ----------
  bool _hasMusicField(Playlist p) {
    try {
      final dyn = p as dynamic;
      final val = dyn.music;
      return val != null;
    } catch (_) {
      return false;
    }
  }

  List<Song> _getSongList() {
    try {
      final dyn = widget.playlist as dynamic;
      if (_hasMusicField(widget.playlist)) {
        return List<Song>.from(dyn.music ?? []);
      } else {
        return List<Song>.from(dyn.songs ?? []);
      }
    } catch (_) {
      return [];
    }
  }

  // ---------- UI ----------
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.queue_music, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text("هنوز آهنگی در این پلی‌لیست نیست", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = _getSongList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _showShareDialog),
          IconButton(icon: const Icon(Icons.add), onPressed: _showSongPickerDialog), // تغییر اصلی
        ],
      ),
      body: songs.isEmpty
          ? _emptyState()
          : ListView.separated(
        itemCount: songs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(song.name),
            subtitle: Text(song.artist ?? "Unknown"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmRemoveSong(song),
            ),
            onTap: () async {
              await _audioService.setPlaylist(songs, startIndex: index);
              await _audioService.play();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(audioService: _audioService),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRemoveSong(Song song) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف آهنگ'),
        content: Text('آیا از حذف "${song.name}" مطمئنی؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );

    if (ok == true) {
      await _removeSong(song);
    }
  }
}
