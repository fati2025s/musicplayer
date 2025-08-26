import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../models/song_sort.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../service/AudioService.dart';
import '../service/SocketService.dart';
import '../service/localmusic.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'BlackLikedSongsScreen.dart';
import 'BlackPlayerScreen.dart';
import 'BlackPlaylistHome.dart';
import 'BlackProfilePicture.dart';
import 'BlackRecentlyPlayedScreen.dart';
import 'HomeScreen.dart';
import 'Signup.dart';
import 'blackuserprofile.dart';
class BlackHomeScreen extends StatefulWidget {
  final User currentuser;
  BlackHomeScreen({Key? key,required this.currentuser}) : super(key: key);

  @override
  State<BlackHomeScreen> createState() => _HomeScreenState();
//final LocalMusicService localMusicService = LocalMusicService();
}

class _HomeScreenState extends State<BlackHomeScreen> {
  final AudioService audioService = AudioService();
  final LocalMusicService localMusicService = LocalMusicService();
  final SocketService socketService = SocketService();
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _controllername = TextEditingController();

  SongSortType sortType = SongSortType.none;
  List<Song> allSongs = [];
  List<Song> filteredSongs = [];
  List<Playlist> playlists = [];
  String searchQuery = "";
  bool isLoading = false;

  List<File> images=[];
  String message = "";
  File? _image;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData(widget.currentuser);
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
  }

  void toggleLike(Song song) {
    if (song.source == SongSource.local) return;
    setState(() {
      song.isLiked = !song.isLiked;
    });
    _toggleLikeOnServer(song);
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

  Future<void> deleteaccount() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("userName");
    final password = prefs.getString("userPassword");

    if (username == null || password == null) {
      print("❗ نام کاربری یا رمز عبور پیدا نشد.");
      return;
    }

    final requestBody = {
      "type": "deleteaccount",
      "payload": {
        "username": username,
        "password": password,
      }
    };

    final jsonString = json.encode(requestBody) + '\n';

    try {
      var socket = await Socket.connect("10.208.175.99", 8080);
      StringBuffer responseText = StringBuffer();
      final completer = Completer<String>();

      socket.write(jsonString);
      await socket.flush();

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (data) {
          print("📥 دریافت شد: $data");
          responseText.write(data);
          if (data.contains("end")) {
            socket.close();
            completer.complete(responseText.toString());
          }
        },
        onError: (error) {
          print("❌ خطا: $error");
          if (!completer.isCompleted) completer.completeError(error);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(responseText.toString());
          }
        },
        cancelOnError: true,
      );

      final result = await completer.future;
      final Map<String, dynamic> responseJson =
      json.decode(result.replaceAll("end", ""));

      if (responseJson["success"] == "success") {
        print("✅ اکانت حذف شد");
        await prefs.clear();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Signup()),
        );
      } else {
        print("❌ حذف نشد: ${responseJson["message"]}");
      }
    } catch (e) {
      print("Connection failed: $e");
    }
  }


  Future<void> _toggleLikeOnServer(Song song) async {
    final requestBody = {
      "type": song.isLiked ? "addlikesong" : "deletlikesong",
      "payload": {
        "name": song.name,
        "artist": song.artist,
        "liked": song.isLiked
      }
    };

    final jsonString = json.encode(requestBody) + '\n';

    try {
      var socket = await Socket.connect("10.208.175.99", 8080); // IP و پورت بک
      StringBuffer responseText = StringBuffer();
      final completer = Completer<String>();

      socket.write(jsonString);
      await socket.flush();

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (data) {
          print("📥 دریافت شد: $data");
          responseText.write(data);

          if (data.contains("end")) {
            socket.close();
            completer.complete(responseText.toString());
          }
        },
        onError: (error) {
          print("❌ خطا: $error");
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          print("📴 اتصال بسته شد");
          if (!completer.isCompleted) {
            completer.complete(responseText.toString());
          }
        },
        cancelOnError: true,
      );

      final result = await completer.future;
      print("result:$result");

      final Map<String, dynamic> responseJson =
      json.decode(result.replaceAll("end", ""));

      if (responseJson["success"] != "success") {
        print("❌ لایک ثبت نشد");
      }
    } catch (e) {
      print("Connection failed: $e");
    }
  }


  Future<void> _delete(Song song) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final requestBody = {
      "type": "deletesong",
      "payload": {
        "name": song.name,
        "artist": song.artist,
      }
    };

    final jsonString = json.encode(requestBody) + '\n';

    try {
      var socket = await Socket.connect("10.208.175.99", 8080);
      StringBuffer responseText = StringBuffer();
      final completer = Completer<String>();

      socket.write(jsonString);
      await socket.flush();

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (data) {
          print("📥 دریافت شد: $data");
          responseText.write(data);

          if (data.contains("end")) {
            socket.close();
            completer.complete(responseText.toString());
          }
        },
        onError: (error) {
          print("❌ خطا: $error");
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          print("📴 اتصال بسته شد");
          if (!completer.isCompleted) {
            completer.complete(responseText.toString());
          }
        },
        cancelOnError: true,
      );

      final result = await completer.future;
      print("result:$result");
      final Map<String, dynamic> responseJson =
      json.decode(result.replaceAll("end", ""));

      setState(() {
        message = responseJson["message"] ?? "Unknown response";
      });

      if (responseJson["success"] == "success") {
        final prefs = await SharedPreferences.getInstance();
      }
      else{
        print("Faild");
        setState(() {
          message = responseJson["message"] ?? "delete music faild.";
        });
      }
    }  catch (e) {
      setState(() {
        message = "Connection failed: $e";
      });
    }

  }

  Future<void> _addplaylist() async {
    final name = _controllername.text;
    if (name.isEmpty) {
      setState(() => message = "name is invalid");
      return;
    }

    final requestBody = {
      "type": "addPlaylist",
      "payload": {
        "id": Random().nextInt(100000),
        "name": name,
      }
    };
    final jsonString = json.encode(requestBody) + '\n';

    try {
      var socket = await Socket.connect("10.208.175.99", 8080);
      StringBuffer responseText = StringBuffer();
      final completer = Completer<String>();

      socket.write(jsonString);
      await socket.flush();

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((data) {
        responseText.write(data);
        if (data.contains("end")) {
          socket.close();
          completer.complete(responseText.toString());
        }
      }, onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      }, onDone: () {
        if (!completer.isCompleted) {
          completer.complete(responseText.toString());
        }
      }, cancelOnError: true);

      final result = await completer.future;
      final Map<String, dynamic> responseJson =
      json.decode(result.replaceAll("end", ""));

      if (responseJson["success"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("addplaylistStatus", true);
        await prefs.setString("Name", name);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlackPlaylistsHome(allplaylists: playlists)),
        );
      } else {
        setState(() {
          message = responseJson["message"] ?? "add playlist failed.";
        });
      }
    } catch (e) {
      setState(() => message = "Connection failed: $e");
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

  void showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Create new playlist",style: TextStyle(color: Colors.white),),
        content: TextField(
          controller: _controllername,
          decoration: const InputDecoration(labelText: "name",
            labelStyle: const TextStyle(color: Colors.white),),

        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("cancel",style: TextStyle(color: Colors.white),),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _controllername.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  playlists.add(
                    Playlist(
                      id: DateTime.now().millisecondsSinceEpoch,
                      name: name,
                      likeplaylist: false,
                      music: [],
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
              await _addplaylist();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Text("create"),
          ),
        ],
      ),
    );
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
                              onTap: () async {
                                final updatedImages = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>BlackProfileImageSlider(initialImages: images),
                                  ),
                                );
                                if (updatedImages != null) {
                                  setState(() {
                                    images = List<File>.from(updatedImages);
                                    _image =
                                    images.isNotEmpty ? images.last : null;
                                  });
                                }
                              },
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: images.isNotEmpty
                                    ? FileImage(_image!) as ImageProvider
                                    : const AssetImage('assets/profile.jpg'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                                widget.currentuser.username,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 60),
                            IconButton(
                              icon: const Icon(Icons.nightlight, color: Colors.white),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HomeScreen(currentu: widget.currentuser)),
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
                                setState(() {
                                  _image = File(pickedFile.path);
                                });
                                print("عکس انتخاب شد: ${pickedFile.path}");
                                images.add(_image!);
                              } else {
                                print("هیچ عکسی انتخاب نشد.");
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Material(
                    color: Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.white,),
                          title: const Text("Account",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BlackUserProfileScreen()),
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
                          onTap: () async {
                            await deleteaccount();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const Signup()),
                            );
                          },
                        ),

                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("خروج از حساب", style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Signup()), //go to welcome page
                            );
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
      backgroundColor: Color(0xFF3B3B3B),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              spacing: 10,
              children: [
                //const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    onChanged: updateSearch,
                    decoration: InputDecoration(
                      labelText: "Search",
                      prefixIcon: const Icon(Icons.search,color: Colors.white,),
                      filled: true,
                      fillColor: Colors.black38,
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
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu,color: Colors.white,),
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
                          builder: (context) => BlackLikedSongsScreen(allSongs: allSongs),
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
                          builder: (context) => BlackPlaylistsHome(allplaylists: playlists),
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
                          builder: (context) => BlackRecentlyPlayedScreen(allSongs: allSongs),
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
                  icon: const Icon(Icons.sort,color: Colors.white,),
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
                  ? const Center(
                child: Text("آهنگی یافت نشد",
                  style: TextStyle(color: Colors.white),),
              )
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
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white,),
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
                                BlackPlayerScreen(audioService: audioService),
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
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlackPlayerScreen(audioService: audioService),
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