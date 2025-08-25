import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/screens/playlistdetail.dart';
import 'package:project/screens/userprofile.dart';

import '../models/song.dart';
import '../models/song_sort.dart';
import '../models/playlist.dart';
import '../screens/likedsongs.dart';
import '../screens/player.dart';
import '../screens/recentlyplayed.dart';
import '../service/audio.dart';
import '../service/localmusic.dart';
import '../service/SocketService.dart';
import '../service/playlist.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService audioService = AudioService();
  final LocalMusicService localMusicService = LocalMusicService();
  final SocketService socketService = SocketService();
  late PlaylistService playlistService;

  SongSortType sortType = SongSortType.none;
  List<Song> allSongs = [];
  List<Song> filteredSongs = [];
  List<Playlist> playlists = [];
  String searchQuery = "";
  bool isLoading = false;

  final Set<int> _downloadingSongIds = {};
  final Set<int> _likingSongIds = {};

  @override
  void initState() {
    super.initState();
    playlistService = PlaylistService(socketService);
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final serverPlaylists = await playlistService.listPlaylists();

      final songsResp = await socketService.listSongs();
      List<Song> serverSongs = [];
      if (songsResp["status"] == "success" && songsResp["data"] is List) {
        serverSongs = (songsResp["data"] as List)
            .map((e) => Song.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        playlists = serverPlaylists;
        allSongs = serverSongs;
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("⚠ خطا در loadData: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در بارگذاری داده‌ها: $e")),
      );
    }
  }

  Future<void> uploadSong(File file, Song song) async {
    if (!socketService.isConnected) {
      print("Not connected to server");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ارتباط با سرور برقرار نیست")),
      );
      return;
    }

    try {
      final base64File = base64Encode(await file.readAsBytes());

      final resp = await socketService.sendAndWait({
        "type": "uploadSongFile",
        "payload": {
          "fileName": file.uri.pathSegments.last,
          "base64Data": base64File,
          "meta": {
            "title": song.name,
            "artist": song.artist,
          }
        }
      });

      if (resp["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("آپلود با موفقیت انجام شد")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا در آپلود: ${resp["message"] ?? "نامشخص"}")),
        );
      }
    } catch (e) {
      debugPrint("خطا در uploadSong: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در آپلود: $e")),
      );
    }
  }

  Future<void> pickSingleSongAndAdd() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => isLoading = true);

      try {
        final pickedFile = result.files.first;
        Song? newSong;

        if (kIsWeb) {
          newSong = Song(
            id: Random().nextInt(100000),
            name: pickedFile.name,
            artist: "Unknown",
            url: pickedFile.name,
            source: SongSource.local,
            isDownloaded: true,
          );
        } else {
          final file = File(pickedFile.path!);
          final metadata = await MetadataRetriever.fromFile(file);

          final appDir = await getApplicationDocumentsDirectory();
          final localFilePath = '${appDir.path}/${pickedFile.name}';
          final localFile = await file.copy(localFilePath);

          newSong = Song(
            id: Random().nextInt(100000),
            name: metadata.trackName ?? pickedFile.name,
            artist: metadata.albumArtistName ?? "Unknown",
            url: localFile.path,
            source: SongSource.local,
            isDownloaded: true,
          );

          await uploadSong(file, newSong);
        }

        if (!mounted) return;
        setState(() {
          if (newSong != null) {
            allSongs.add(newSong);
            applyFilters();
          }
          isLoading = false;
        });
      } catch (e) {
        debugPrint("خطا در آپلود یا ذخیره فایل: $e");
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا در آپلود یا ذخیره فایل: $e")),
        );
      }
    }
  }

  Future<void> pickFolderAndAdd() async {
    setState(() => isLoading = true);
    try {
      final songs = await localMusicService.loadLocalSongsFromFolder();

      for (var song in songs) {
        final file = File(song.url);
        await uploadSong(file, song);
      }

      if (!mounted) return;
      setState(() {
        allSongs.addAll(songs);
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("خطا در افزودن پوشه: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در افزودن پوشه: $e")),
      );
    }
  }

  Future<void> _sendLikeRequest(int songId, bool like) async {
    final type = like ? "likeSong" : "unlikeSong";
    await socketService.sendAndWait({
      "type": type,
      "payload": {"songId": songId}
    });
  }

  void toggleLike(Song song) async {
    if (song.source == SongSource.local) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("این آهنگ محلی است و قابل لایک سروری نیست.")),
      );
      return;
    }
    if (_likingSongIds.contains(song.id)) return;

    setState(() {
      _likingSongIds.add(song.id);
    });

    final wantToLike = !song.isLiked;
    try {
      final resp = await socketService.sendAndWait({
        "type": wantToLike ? "likeSong" : "unlikeSong",
        "payload": {"songId": song.id}
      });

      if (resp["status"] == "success") {
        if (!mounted) return;
        setState(() {
          song.isLiked = wantToLike;
        });
      } else {
        final msg = resp["message"] ?? "خطای نامشخص";
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطا: $msg")));
      }
    } catch (e) {
      debugPrint("⚠ Error toggling like: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا در عملیات لایک: $e")),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _likingSongIds.remove(song.id);
      });
    }
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      applyFilters();
    });
  }

  void updateSort(SongSortType type) {
    setState(() {
      sortType = type;
      applyFilters();
    });
  }

  void applyFilters() {
    filteredSongs = allSongs.where((song) {
      final name = song.name.toLowerCase();
      final artist = song.artist.toLowerCase();
      final q = searchQuery.toLowerCase();
      return name.contains(q) || artist.contains(q);
    }).toList();

    switch (sortType) {
      case SongSortType.byName:
        filteredSongs.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SongSortType.byArtist:
        filteredSongs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SongSortType.none:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("افزودن آهنگ تکی"),
            onTap: () {
              Navigator.pop(ctx);
              pickSingleSongAndAdd();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text("افزودن پوشه آهنگ‌ها"),
            onTap: () {
              Navigator.pop(ctx);
              pickFolderAndAdd();
            },
          ),
        ],
      ),
    );
  }

  void showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ساخت پلی‌لیست جدید"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "نام پلی‌لیست"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("انصراف"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newPlaylist = await playlistService.addPlaylist(name);
                if (newPlaylist != null) {
                  if (!mounted) return;
                  setState(() {
                    playlists.add(newPlaylist); // مستقیماً اضافه به لیست
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("پلی‌لیست ساخته شد")),
                  );
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("خطا در ساخت پلی‌لیست")),
                    );
                  }
                }
              }
              if (mounted) Navigator.pop(ctx);
            },

            child: const Text("ساخت"),
          ),
        ],
      ),
    );
  }

  Future<void> downloadSongToLocal(Song song) async {
    if (_downloadingSongIds.contains(song.id)) return;
    if (!socketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ارتباط با سرور برقرار نیست")),
      );
      return;
    }

    setState(() {
      _downloadingSongIds.add(song.id);
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      // امن‌سازی نام فایل
      final fileName = song.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') + '.mp3';
      final savePath = "${dir.path}/$fileName";

      await socketService.downloadSong(song.id, savePath);

      if (!mounted) return;
      setState(() {
        song.isDownloaded = true;
        final idx = allSongs.indexWhere((s) => s.id == song.id);
        if (idx != -1) {
          allSongs[idx] = allSongs[idx].copyWith(url: savePath, source: SongSource.local, isDownloaded: true);
        }
        applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("دانلود تکمیل شد: ${fileName}")),
      );
    } catch (e) {
      debugPrint(" Download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا در دانلود: $e")),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _downloadingSongIds.remove(song.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MC20 🎵"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    onToggleTheme: () {
                      setState(() {});
                    },
                    socketService: socketService,
                  ),
                ),
              );
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedSongsScreen(allSongs: allSongs),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecentlyPlayedScreen(allSongs: allSongs),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("منوی اصلی", style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text("ساخت پلی‌لیست"),
              onTap: showCreatePlaylistDialog,
            ),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text("افزودن آهنگ"),
              onTap: showAddOptions,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                onChanged: updateSearch,
                decoration: InputDecoration(
                  hintText: "جست‌وجو بر اساس نام یا خواننده",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("پلی‌لیست‌ها", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: showCreatePlaylistDialog,
                  ),
                ],
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailsScreen(playlist: playlist),
                          ),
                        );
                        await loadData();
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.playlist_play, size: 40, color: Colors.blue),
                            const SizedBox(height: 5),
                            Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredSongs.isEmpty
                    ? const Center(child: Text("آهنگی یافت نشد"))
                    : ListView.builder(
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    final isDownloading = _downloadingSongIds.contains(song.id);
                    final isLiking = _likingSongIds.contains(song.id);

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(song.name),
                        subtitle: Text(song.artist),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              song.isDownloaded ? Icons.download_done : Icons.download,
                              color: song.isDownloaded ? Colors.green : null,
                            ),
                            IconButton(
                              icon: isDownloading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(song.isDownloaded ? Icons.check_circle : Icons.download),
                              onPressed: song.isDownloaded ? null : () => downloadSongToLocal(song),
                            ),
                            IconButton(
                              icon: isLiking
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(
                                song.isLiked ? Icons.favorite : Icons.favorite_border,
                                color: song.isLiked ? Colors.red : null,
                              ),
                              onPressed: () => toggleLike(song),
                            ),
                          ],
                        ),
                        onTap: () {
                          audioService.setPlaylist(filteredSongs, startIndex: index);
                          audioService.play();
                          setState(() {});
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(audioService: audioService),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: audioService.currentSong == null
          ? null
          : Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(audioService: audioService),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.music_note),
              const SizedBox(width: 8),
              Expanded(
                child: Text(audioService.currentSong!.name, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: Icon(audioService.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (audioService.isPlaying) {
                    audioService.pause();
                  } else {
                    audioService.play();
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
