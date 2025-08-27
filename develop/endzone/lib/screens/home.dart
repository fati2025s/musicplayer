import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/screens/playlistscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../models/song_sort.dart';
import '../models/playlist.dart';
import '../screens/playlistdetail.dart';
import '../screens/userprofile.dart';
import '../screens/likedsongs.dart';
import '../screens/player.dart';

import '../service/audio.dart';
import '../service/SocketService.dart';
import '../service/Playlist.dart';
import '../service/Upload.dart';
import '../widget/profileimageslider.dart';


class HomeScreen extends StatefulWidget {
  final String? username;

  const HomeScreen({Key? key, this.username}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService socketService = SocketService();

  late final AudioService audioService;
  late final PlaylistService playlistService;
  late final MusicService musicService;

  SongSortType sortType = SongSortType.none;
  List<Song> allSongs = [];
  List<Song> filteredSongs = [];
  List<Playlist> playlists = [];
  String searchQuery = "";
  bool isLoading = false;

  final Set<int> _downloadingSongIds = {};
  final Set<int> _likingSongIds = {};

  final ImagePicker _picker = ImagePicker();
  List<String> profileImages = [];
  int currentProfileIndex = 0;
  String? currentProfilePath;

  @override
  void initState() {
    super.initState();

    audioService = AudioService(socket: socketService);
    playlistService = PlaylistService(socketService);
    musicService = MusicService(socketService);

    loadData();
    _loadProfileImages();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final serverPlaylists = await playlistService.listPlaylists();
      final songsResp = await socketService.listSongs();

      List<Song> serverSongs = [];
      if (songsResp["status"] == "success" &&
          songsResp["data"] is Map &&
          songsResp["data"]["songs"] is List) {
        serverSongs = (songsResp["data"]["songs"] as List)
            .map((e) => Song.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        debugPrint("⚠ ساختار لیست آهنگ‌ها نامعتبر: \$songsResp");
      }

      if (!mounted) return;
      setState(() {
        playlists = serverPlaylists;
        allSongs = serverSongs;
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("⚠ خطا در loadData: \$e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در بارگذاری داده‌ها: \$e")),
      );
    }
  }

  Future<void> pickSingleSongAndAdd() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("آپلود در وب پشتیبانی نشده است.")),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final song = await musicService.pickAndUploadSong();
      if (!mounted) return;
      setState(() {
        if (song != null) {
          allSongs.add(song);
          applyFilters();
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint("خطا در آپلود یا ذخیره فایل: \$e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در آپلود یا ذخیره فایل: \$e")),
      );
    }
  }

  Future<void> pickFolderAndAdd() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("آپلود پوشه در وب پشتیبانی نشده است.")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final songs = await musicService.pickFolderAndUploadSongs();

      if (!mounted) return;
      setState(() {
        allSongs.addAll(songs);
        applyFilters();
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${songs.length} آهنگ آپلود شد")),
      );
    } catch (e) {
      debugPrint("خطا در افزودن پوشه: \$e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در افزودن پوشه: \$e")),
      );
    }
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
      final safeName =
          song.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') + '.mp3';
      final savePath = "\${dir.path}/\$safeName";

      await socketService.downloadSong(song.id, savePath);

      if (!mounted) return;
      setState(() {
        song.isDownloaded = true;
        final idx = allSongs.indexWhere((s) => s.id == song.id);
        if (idx != -1) {
          allSongs[idx] = allSongs[idx].copyWith(
            url: savePath,
            source: SongSource.local,
            isDownloaded: true,
          );
        }
        applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("دانلود تکمیل شد: \$safeName")),
      );
    } catch (e) {
      debugPrint("Download error: \$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا در دانلود: \$e")),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _downloadingSongIds.remove(song.id);
      });
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
    if (_likingSongIds.contains(song.id)) return;

    setState(() {
      _likingSongIds.add(song.id);
      // optimistic UI
      song.isLiked = !song.isLiked;
      song.likeCount += song.isLiked ? 1 : -1;
    });

    try {
      final resp = await socketService.toggleLikeSong(song.id);

      if (resp["status"] != "success") {
        final msg = resp["message"] ?? "خطای نامشخص";
        if (!mounted) return;
        setState(() {
          // rollback
          song.isLiked = !song.isLiked;
          song.likeCount += song.isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا: \$msg")),
        );
      }
    } catch (e) {
      debugPrint("⚠ Error toggling like: \$e");
      if (!mounted) return;
      setState(() {
        // rollback
        song.isLiked = !song.isLiked;
        song.likeCount += song.isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در عملیات لایک: \$e")),
      );
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
    final q = searchQuery.toLowerCase();
    filteredSongs = allSongs.where((song) {
      final name = song.name.toLowerCase();
      final artist = song.artist.toLowerCase();
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

  @override
  void dispose() {
    audioService.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImages() async {
    final prefs = await SharedPreferences.getInstance();
    profileImages = prefs.getStringList("profileImages") ?? [];
    currentProfileIndex = prefs.getInt("currentProfileIndex") ?? 0;

    if (profileImages.isNotEmpty &&
        currentProfileIndex >= 0 &&
        currentProfileIndex < profileImages.length) {
      currentProfilePath = profileImages[currentProfileIndex];
    } else {
      currentProfilePath = null;
    }

    if (mounted) setState(() {});
  }

  void openProfileSlider() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileImageSlider(
          initialBase64: profileImages,
          initialIndex: currentProfileIndex,
        ),
      ),
    ).then((_) => _loadProfileImages());
  }

  Future<void> pickProfileImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final base64Image = base64Encode(await file.readAsBytes());

    profileImages.add(base64Image);
    currentProfileIndex = profileImages.length - 1;
    currentProfilePath = base64Image;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("profileImages", profileImages);
    await prefs.setInt("currentProfileIndex", currentProfileIndex);

    if (mounted) setState(() {});
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
            child: const Text("لغو"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await playlistService.addPlaylist(name);
                await loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطا در ایجاد پلی‌لیست: \$e")));
              }
            },
            child: const Text("ایجاد"),
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
          child: SafeArea(
            child: Container(
              width: width * 0.75,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                color: Colors.white,
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
                                backgroundImage: currentProfilePath != null
                                    ? NetworkImage(currentProfilePath!)
                                    : AssetImage("assets/default_profile.png") as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                widget.username ?? "کاربر",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.sunny, color: Colors.white),
                              onPressed: () {
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
                              onPressed: pickProfileImage,
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
                                MaterialPageRoute(builder: (context) => UserProfileScreen(socketService: SocketService())),
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
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست حذف حساب ارسال شد')));
                            },
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
      backgroundColor: const Color(0xFFEDEDED),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
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
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 10,
                children: [
                  SizedBox(
                    width: 110,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LikedSongsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('liked music',
                        style: TextStyle(fontSize: 16, color: Colors.black),
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
                      child: const Text('playlists', style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                PopupMenuButton<SongSortType>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) => updateSort(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: SongSortType.none, child: Text("زمان افزوده شدن")),
                    const PopupMenuItem(value: SongSortType.byName, child: Text("بر اساس نام آهنگ")),
                    const PopupMenuItem(value: SongSortType.byArtist, child: Text("بر اساس خواننده")),
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
                  final isDownloading = _downloadingSongIds.contains(song.id);
                  final isLiking = _likingSongIds.contains(song.id);

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
                          isDownloading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                            icon: Icon(song.isDownloaded ? Icons.check_circle : Icons.download, color: song.isDownloaded ? Colors.green : null),
                            onPressed: song.isDownloaded ? null : () => downloadSongToLocal(song),
                          ),

                          isLiking
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                            icon: Icon(song.isLiked ? Icons.favorite : Icons.favorite_border, color: song.isLiked ? Colors.red : null),
                            onPressed: () => toggleLike(song),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await audioService.setPlaylist(filteredSongs, startIndex: index);
                        await audioService.play();
                        if (!mounted) return;
                        setState(() {});
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(audioService: audioService)));
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(audioService: audioService)));
          },
          child: Row(
            children: [
              const Icon(Icons.music_note),
              const SizedBox(width: 8),
              Expanded(child: Text(audioService.currentSong!.name, overflow: TextOverflow.ellipsis)),
              IconButton(
                icon: Icon(audioService.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () async {
                  if (audioService.isPlaying) {
                    await audioService.pause();
                  } else {
                    await audioService.play();
                  }
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _delete(Song song) async {
    final requestBody = {
      "type": "deletesong",
      "payload": {"name": song.name, "artist": song.artist}
    };

    try {
      final resp = await socketService.sendAndWait(requestBody);
      if (resp["status"] == "success") {
        if (!mounted) return;
        setState(() {
          allSongs.removeWhere((s) => s.name == song.name && s.artist == song.artist);
          filteredSongs.removeWhere((s) => s.name == song.name && s.artist == song.artist);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('آهنگ حذف شد')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حذف ناموفق: \${resp["message"]}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در حذف: \$e')));
    }
  }
}
