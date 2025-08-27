import 'package:flutter/material.dart';
import '../models/song.dart';
import '../service/SocketService.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({Key? key}) : super(key: key);

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  List<Song> liked = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLiked();
  }

  Future<void> _loadLiked() async {
    setState(() {
      loading = true;
    });

    try {
      final allResp = await SocketService().listSongs();
      if (allResp['status'] != 'success' || allResp['data'] == null) {
        debugPrint('Failed to load all songs: $allResp');
        setState(() => loading = false);
        return;
      }

      final allSongsRaw = allResp['data']['songs'] as List? ?? [];
      final allSongs = allSongsRaw
          .map((e) => Song.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final Map<int, Song> allById = {
        for (var s in allSongs) s.id: s,
      };

      final likedResp = await SocketService().listLikedSongs();
      if (likedResp['status'] != 'success' || likedResp['data'] == null) {
        debugPrint('Failed to load liked ids: $likedResp');
        setState(() => loading = false);
        return;
      }

      final likedRaw = likedResp['data']['songs'] as List? ?? [];

      final likedIds = <int>[];
      for (var v in likedRaw) {
        if (v is int) {
          likedIds.add(v);
        } else if (v is num) {
          likedIds.add(v.toInt());
        } else if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) likedIds.add(parsed);
        }
      }

      final result = <Song>[];
      for (var id in likedIds) {
        final s = allById[id];
        if (s != null) {
          result.add(s);
        } else {
          debugPrint('Liked song id $id not found in all songs');
        }
      }

      setState(() {
        liked = result;
        loading = false;
      });
    } catch (e, st) {
      debugPrint("خطا در گرفتن لایک‌ها: $e\n$st");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liked Songs")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : liked.isEmpty
          ? const Center(child: Text("هنوز هیچ آهنگی لایک نکردی"))
          : ListView.builder(
        itemCount: liked.length,
        itemBuilder: (context, index) {
          final song = liked[index];
          return ListTile(
            title: Text(song.name),
            subtitle: Text(song.artist),
            trailing: Text('${song.likeCount} ❤'),
          );
        },
      ),
    );
  }
}
