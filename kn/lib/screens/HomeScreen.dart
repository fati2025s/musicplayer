import 'package:flutter/material.dart';
import '../models/song.dart';
import '../data/mock_songs.dart';
import '../models/song_sort.dart';
import '../screens/RecentlyPlayedScreen.dart';
import '../screens/LikedSongsScreen.dart';
import '../screens/UploadSongScreen.dart';
import '../service/AudioService.dart';
import '../screens/PlayerScreen.dart';
import '../service/localmusic.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  //final LocalMusicService localMusicService = LocalMusicService();
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
      case SongSortType.byPlayCount:
        filteredSongs.sort((a,b) => a.count.compareTo(b.count));
        break;
      case SongSortType.none:
        break;
    }
  }

  void _showSidePanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Side Panel",
      pageBuilder: (_, __, ___) {
        final height = MediaQuery.of(context).size.height;
        final width = MediaQuery.of(context).size.width;

        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: height,
            width: width * 0.75,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: height * 0.25,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage('assets/profile.jpg'), // یا NetworkImage
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text(
                                  "نام کاربر",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.brightness_6, color: Colors.white),
                            onPressed: () {
                              print("تغییر تم");
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text("Account"),
                          onTap: () {
                            //
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text("Setting"),
                          onTap: () {
                            //
                          },
                        ),
                        const Spacer(),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("خروج از حساب", style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
          child: child,
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        //padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: TextField(
                    onChanged: updateSearch,
                    decoration: InputDecoration(
                      labelText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),


                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _showSidePanel(context);
                      },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  children: [
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LikedSongsScreen(allSongs: allSongs),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          //width: 20,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('liked music',
                          style: TextStyle(
                            fontSize: 16,
                            color:Colors.black,
                          ),
                        ),
                      ),
                    ),
                SizedBox(
                  width: 90,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LikedSongsScreen(allSongs: allSongs),// its go to play lists page
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      //width: 20,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('playlists',
                      style: TextStyle(
                        fontSize: 16,
                        color:Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecentlyPlayedScreen(allSongs: allSongs),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('recently music',
                      style: TextStyle(
                        fontSize: 16,
                        color:Colors.white,
                      ),
                    ),
                  ),
                ),
                  ],
                ),
                const SizedBox(width: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        PopupMenuButton<SongSortType>(
                          icon: const Icon(Icons.sort),
                          onSelected: (value) => updateSort(value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: SongSortType.none,
                              child: Text("زمان افزوده شدن"),
                            ),
                            const PopupMenuItem(
                              value: SongSortType.byName,
                              child: Text("بر اساس نام آهنگ"),
                            ),
                            const PopupMenuItem(
                              value: SongSortType.byArtist,
                              child: Text("بر اساس خواننده"),
                            ),
                            PopupMenuItem(
                              value: SongSortType.byPlayCount,
                              child: const Text("تعداد دفعات پخش"),
                            ),
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
          /*Navigator.push(
            context,
            MaterialPageRoute(
              //builder: (context) => UploadSongScreen(
                /*onSongUploaded: (newSong) {
                  setState(() {
                    allSongs.add(newSong);
                    applyFilters();
                  });
                },*/
              ),
            ),
          );*/
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