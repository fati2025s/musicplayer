import 'package:untitled/models/playlist.dart';
import 'package:untitled/models/song.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final List<String> profilePictures;
  final List<Song> likedSongs;
  final List<Song> downloadedSongs;
  final List<Playlist> playlists;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    List<String>? profilePictures,
    List<Song>? likedSongs,
    List<Song>? downloadedSongs,
    List<Playlist>? playlists,
  })  : profilePictures = profilePictures ?? [],
        likedSongs = likedSongs ?? [],
        downloadedSongs = downloadedSongs ?? [],
        playlists = playlists ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '0',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      profilePictures: json['profilePicturePath'] != null
          ? List<String>.from(json['profilePicturePath'])
          : [],
      likedSongs: (json['likedSongs'] as List<dynamic>? ?? [])
          .map((s) => Song.fromJson(s))
          .toList(),
      downloadedSongs: (json['songs'] as List<dynamic>? ?? [])
          .map((s) => Song.fromJson(s))
          .toList(),
      playlists: (json['playlists'] as List<dynamic>? ?? [])
          .map((p) => Playlist.fromJson(p))
          .toList(),
    );
  }

}
