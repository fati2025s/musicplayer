import 'package:flutter/material.dart';
import '../models/song.dart';
import '../data/mock_songs.dart';
import '../models/song_sort.dart';
import '../screens/recentlyplayed.dart';
import '../screens/likedsongs.dart';
import '../screens/upload_songs.dart';
import '../service/audio.dart';
import '../screens/player.dart';
import '../service/localmusic.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  final LocalMusicService localMusicService = LocalMusicService();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService audioService = AudioService();
  SongSortType sortType = SongSortType.none;

  List<Song> allSongs = mockSongs;
  List<Song> filteredSongs = mockSongs;
  String searchQuery = "";

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
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    appBar: AppBar(
      title: const Text("Novak 🎵"),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: [
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
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: updateSearch,
            decoration: InputDecoration(
              labelText: "جست‌وجو بر اساس نام آهنگ یا خواننده",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("مرتب‌سازی: "),
              const SizedBox(width: 8),
              DropdownButton<SongSortType>(
                value: sortType,
                onChanged: (value) {
                  if (value != null) updateSort(value);
                },
                borderRadius: BorderRadius.circular(10),
                items: const [
                  DropdownMenuItem(value: SongSortType.none, child: Text("بدون")),
                  DropdownMenuItem(value: SongSortType.byName, child: Text("بر اساس نام آهنگ")),
                  DropdownMenuItem(value: SongSortType.byArtist, child: Text("بر اساس خواننده")),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                final song = filteredSongs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(song.name),
                    subtitle: Text(song.artist),
                    trailing: song.source == SongSource.local
                        ? null
                        : IconButton(
                            icon: Icon(
                              song.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: song.isLiked ? Colors.red : null,
                            ),
                            onPressed: () => toggleLike(song),
                          ),
                    onTap: () {
                      audioService.setPlaylist(filteredSongs, startIndex: index);
                      audioService.play();
                      setState(() {}); // برای نمایش mini-player

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
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadSongScreen(
              onSongUploaded: (newSong) {
                setState(() {
                  allSongs.add(newSong);
                  applyFilters();
                });
              },
            ),
          ),
        );
      },
      icon: const Icon(Icons.upload),
      label: const Text("آپلود"),
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
                  Expanded(
                    child: Text(
                      "${audioService.currentSong!.name} - ${audioService.currentSong!.artist}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () => audioService.previous(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => audioService.play(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => audioService.next(),
                  ),
                ],
              ),
            ),
          ),
  );
}
}