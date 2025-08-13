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
import '../screens/playlistdetail.dart';
import '../service/audio.dart';
import '../service/localmusic.dart';
import '../service/SocketService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService audioService = AudioService();
  final LocalMusicService localMusicService = LocalMusicService();
  final SocketService socketService = SocketService();

  SongSortType sortType = SongSortType.none;
  List<Song> allSongs = [];
  List<Song> filteredSongs = [];
  List<Playlist> playlists = [];
  String searchQuery = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    socketService.connect("192.168.1.101", 8080);
  }

  Future<void> uploadSong(File file, Song song) async {
    if (!socketService.isConnected) {
      print("Not connected to server");
      return;
    }

    final base64File = base64Encode(await file.readAsBytes());
    await socketService.send({
      "type": "uploadSongFile",
      "payload": {
        "fileName": file.uri.pathSegments.last,
        "base64Data": base64File
      }
    });

    await socketService.send({
      "type": "addsong",
      "payload": {
        "name": song.name,
        "artist": song.artist,
        "url": file.uri.pathSegments.last
      }
    });
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

        setState(() {
          allSongs.add(newSong!);
          applyFilters();
          isLoading = false;
        });
      } catch (e) {
        debugPrint("خطا در آپلود یا ذخیره فایل: $e");
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> pickFolderAndAdd() async {
    setState(() => isLoading = true);
    final songs = await localMusicService.loadLocalSongsFromFolder();

    for (var song in songs) {
      final file = File(song.url);
      await uploadSong(file, song);
    }

    setState(() {
      allSongs.addAll(songs);
      applyFilters();
      isLoading = false;
    });
  }

  void toggleLike(Song song) {
    if (song.source == SongSource.local) return;
    setState(() {
      song.isLiked = !song.isLiked;
    });
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
    socketService.close();
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
            onPressed: () {
              final name = controller.text.trim();
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
            },
            child: const Text("ساخت"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text("MC20 🎵"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
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
                  builder: (context) =>
                      RecentlyPlayedScreen(allSongs: allSongs),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: updateSearch,
              decoration: InputDecoration(
                labelText: "جست‌وجو بر اساس نام آهنگ یا خواننده",
                prefixIcon: const Icon(Icons.search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // بخش پلی‌لیست‌ها
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "پلی‌لیست‌ها",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailsScreen(playlist: playlist),
                        ),
                      );
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
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.playlist_play, size: 40, color: Colors.blue),
                          const SizedBox(height: 5),
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song.name),
                      subtitle: Text(song.artist),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (song.isDownloaded)
                            const Icon(Icons.download_done,
                                color: Colors.green),
                          if (song.source != SongSource.local)
                            IconButton(
                              icon: Icon(
                                song.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: song.isLiked
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () => toggleLike(song),
                            ),
                        ],
                      ),
                      onTap: () {
                        audioService.setPlaylist(filteredSongs,
                            startIndex: index);
                        audioService.play();
                        setState(() {});

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlayerScreen(audioService: audioService),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddOptions,
        icon: const Icon(Icons.upload),
        label: const Text("افزودن آهنگ"),
      ),
      bottomNavigationBar: audioService.currentSong == null
          ? null
          : Container(
        color: Colors.white,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlayerScreen(audioService: audioService),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.music_note),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  audioService.currentSong!.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(audioService.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow),
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
