import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:untitled/screens/BlackHomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/screens/PlaylistsHome.dart';
import 'package:untitled/screens/singelton.dart';
import 'package:untitled/screens/userprofile.dart';
import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../models/song_sort.dart';
import '../models/user.dart';
import '../screens/RecentlyPlayedScreen.dart';
import '../screens/LikedSongsScreen.dart';
import 'package:path_provider/path_provider.dart';
import '../service/AudioService.dart';
import '../screens/PlayerScreen.dart';
import '../service/SocketService.dart';
import '../service/localmusic.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../screens/ProfilePicture.dart';
import '../screens/Signup.dart';
import 'dart:io';
class HomeScreen extends StatefulWidget {
  final User currentu;

  HomeScreen({Key? key,required this.currentu}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
//final LocalMusicService localMusicService = LocalMusicService();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService audioService = AudioService();
  final LocalMusicService localMusicService = LocalMusicService();
  final singelton socketService = singelton();
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _controllername = TextEditingController();
  //StreamSubscription? _profileSubscription;
  SongSortType sortType = SongSortType.none;
  List<Song> allSongs = [];
  List<Song> filteredSongs = [];
  List<Song> likedSongs = [];
  List<Playlist> playlists = [];
  String searchQuery = "";
  bool isLoading = false;

  List<String> images=[];
  List<String> profileimage = [];
  int currentindex = 0;
  String message = "";
  String? currentPath;
  String? _image;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData(widget.currentu);
    loadUserProfile();
  }

  void loadUserProfile() async {
    final response = await socketService.sendAndReceive({"type": "getProfileImages"});
    if (!mounted) return;

    if (response["status"] == "success") {
      setState(() {
        profileimage = List<String>.from(response["images"]);
        currentindex = response["currentIndex"] ?? 0;
      });
    }
  }


  void openProfileSlider() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileImageSlider(
          initialImages: profileimage,
          initialIndex: currentindex,
          onDelete: (index) async{
            socketService.send({
              "type": "removeProfileImage",
              "payload": {"index": index}
            });
          },
          onSetCurrent: (index) async{
            socketService.send({
              "type": "setCurrentProfileImage",
              "payload": {"index": index}
            });
          },
        ),
      ),
    ).then((_) {
      loadUserProfile();
    });
  }

  void _loadUserData(User user) {
    setState(() {
      playlists = user.playlists;
      allSongs = [
        ...user.likedSongs,
        ...user.downloadedSongs,
      ];
      applyFilters();
    });
    print(widget.currentu);
  }


  Future<void> uploadSong(File file, Song song) async {
    if (!socketService.isConnected) {
      print("Not connected to server");
      return;
    }

    final base64File = base64Encode(await file.readAsBytes());
    socketService.send({
      "type": "uploadSongFile",
      "payload": {
        "fileName": file.uri.pathSegments.last,
        "base64Data": base64File
      }
    });

    socketService.send({
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

  Future<void> deleteaccount() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("userName");
    final password = prefs.getString("userPassword");

    if (username == null || password == null) return;

    final socketService = singelton();
    if (!socketService.isConnected) {
      await socketService.connect("10.208.175.99", 8080);
    }

    final requestBody = {
      "type": "deleteaccount",
      "payload": {"username": username, "password": password}
    };

    socketService.listen((responseJson) async {
      if (responseJson["type"] != "deleteaccount") return;

      if (responseJson["status"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Signup()),
              (route) => false,
        );
      } else {
        print("❌ حذف نشد: ${responseJson["message"]}");
      }
    });


    socketService.send(requestBody);
  }


  void logoutUser() async {
    try {
      final socketService = singelton();

      if (!socketService.isConnected) {
        await socketService.connect("10.208.175.99", 8080);
      }

      final requestBody = {
        "type": "logout",
        "payload": {}
      };

      socketService.listen((responseJson) async {

        if (responseJson["status"] == "success") {

          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Signup()),
                (route) => false,
          );
        }
      });

      socketService.send(requestBody);
    } catch (e) {
      print("❌ خطا در لاگ‌اوت: $e");
    }
  }

  Future<void> _toggleLike(int musicId) async {
    final requestBody = {
      "type": "toggleLikeMusic",
      "payload": {
        "musicId": musicId,
      }
    };

    try {
      final socketService = singelton();

      if (!socketService.isConnected) {
        await socketService.connect("10.244.67.99", 8080);
      }

      final responseJson = await socketService.sendAndReceive(requestBody);

      if (responseJson["status"] == "success") {
        setState(() {
          likedSongs = (responseJson["data"]["likedSongs"]);
        });
      }
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  void _delete(Song song) async {
    final requestBody = {
      "type": "deletesong",
      "payload": {
        "name": song.name,
        "artist": song.artist,
      }
    };

    try {
      final socketService = singelton();
      if (!socketService.isConnected) {
        await socketService.connect("10.208.175.99", 8080);
      }

      socketService.listen((responseJson) {
        setState(() {
          message = responseJson["message"] ?? "Unknown response";
        });

        if (responseJson["status"] == "success") {
          setState(() {
            allSongs.removeWhere((s) => s.name == song.name && s.artist == song.artist);
            filteredSongs.removeWhere((s) => s.name == song.name && s.artist == song.artist);
          });
          print("✅ آهنگ حذف شد: ${song.name}");
        } else {
          print("❌ حذف نشد: ${responseJson["message"]}");
        }
      });

      socketService.send(requestBody);
    } catch (e) {
      setState(() {
        message = "Connection failed: $e";
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
      default:
        break;
    }
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

  ImageProvider getProfileImage(String? base64) {
    if (base64 == null || base64.isEmpty) {
      return AssetImage("assets/default_profile.png");
    }
    return MemoryImage(base64Decode(base64));
  }

  void pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final base64Image = base64Encode(await file.readAsBytes());

    final response = await socketService.sendAndReceive({
      "type": "uploadProfileImage",
      "payload": {
        "fileName": file.uri.pathSegments.last,
        "base64Data": base64Image,
      }
    });

    if (!mounted) return;
    if (response["status"] == "success") {
      setState(() {
        profileimage.add(response["data"]["base64"]); // فرض بر اینه سرور base64 برمیگردونه
        currentindex = profileimage.length - 1;
      });
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
          child: SafeArea(
            child:Container(
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
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  height: height * 0.2,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            GestureDetector(
                              onTap: openProfileSlider,
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: currentPath != null
                                    ? NetworkImage(currentPath!)
                                    : AssetImage("assets/default_profile.png") as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.currentu.username,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 60),
                            IconButton(
                              icon: const Icon(Icons.sunny, color: Colors.white),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BlackHomeScreen(currentuser: widget.currentu)),
                                );
                              },
                            ),
                          ]
                      ),
                      //const SizedBox(height: 5),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
                            onPressed: () async {
                              final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                final base64Image = base64Encode(await File(pickedFile.path).readAsBytes());

                                if (!mounted) return;
                                setState(() {
                                  _image = base64Image;
                                  images.add(base64Image);
                                });

                                final response = await socketService.sendAndReceive({
                                  "type": "uploadProfileImage",
                                  "payload": {
                                    "fileName": pickedFile.name,
                                    "base64Data": base64Image,
                                  }
                                });

                                print("Response from server: $response");
                                final data = response["data"] as Map<String, dynamic>?;
                                final path = data?["path"] as String?;
                                if (path != null) {
                                  final addProfileResponse = await socketService.sendAndReceive({
                                    "type": "addProfileImage",
                                    "payload": {"path": path}
                                  });
                                  if (addProfileResponse["status"] == "success") {
                                    final set = await socketService.sendAndReceive({
                                      "type": "setCurrentProfileImage",
                                      "payload": {
                                        "currentProfileIndex": images.length - 1,
                                      }
                                    });

                                    if(set["status"] == "success"){
                                      if (!mounted) return;
                                      setState(() {
                                        _image = addProfileResponse["data"]["profileImages"][addProfileResponse["data"]["currentProfileIndex"]];
                                        images = List<String>.from(addProfileResponse["data"]["profileImages"]);
                                      });
                                      print("load successful");
                                    } else {
                                      print("error in load");
                                    }
                                  } else {
                                    print("Failed to add profile path: ${addProfileResponse["message"]}");
                                  }
                                } else {
                                  print("Upload failed: ${response["message"]}");
                                }
                              } else {
                                print("هیچ عکسی انتخاب نشد.");
                              }
                            },
                          )
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
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                            );
                            setState(() {});
                          },
                        ),
                        const Spacer(),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text(
                            "حذف حساب کاربری",
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: deleteaccount,
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("خروج از حساب", style: TextStyle(color: Colors.red)),
                          onTap: logoutUser,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
      backgroundColor: Color(0xFFEDEDED),
      body: SafeArea(
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
                          builder: (context) => PlaylistsHome(allplaylists: playlists),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
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
                      /*IconButton(
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
                    ),*/
                      //این کد یه جورایی میاد اینجا
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
                          //if (song.source != SongSource.local)
                          IconButton(
                              icon: Icon(
                                song.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: song.isLiked
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () => _toggleLike(song.id),
                            ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'share':
                                  print('اشتراک‌گذاری آهنگ');
                                  break;
                                case 'delete':
                                  setState(() {
                                    allSongs.remove(song);
                                    filteredSongs.removeAt(index);
                                  });
                                  _delete(song);
                                  print('حذف آهنگ');
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'share',
                                child: Text('اشتراک‌گذاری'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                            ],
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
            /*Expanded(
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (song.source != SongSource.local)
                              IconButton(
                                icon: Icon(
                                  song.isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: song.isLiked ? Colors.red : null,
                                ),
                                onPressed: () => toggleLike(song),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                switch (value) {
                                  case 'share':
                                    print('اشتراک‌گذاری آهنگ');
                                    break;
                                  case 'delete':
                                    setState(() {
                                      allSongs.remove(song);
                                      filteredSongs.removeAt(index);
                                    });
                                    _delete(song);
                                    print('حذف آهنگ');
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Text('اشتراک‌گذاری'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'),
                                ),
                              ],
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
                      )

                  );
                },
              ),
            ),*/
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddOptions,
        icon: const Icon(Icons.upload),
        label: const Text("آپلود"),
        backgroundColor: Colors.red,
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
  @override
  void dispose() {
    _controllername.dispose();
    super.dispose();
  }
}