import '../models/song.dart';

class Playlist {
  final int id;
  final String name;
  final bool likeplaylist;
  List<Song> music;

  Playlist({
    required this.id,
    required this.name,
    required this.likeplaylist,
    required this.music,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      likeplaylist: json['likeplaylist'] ?? false,
      music: (json['music'] as List<dynamic>? ?? [])
          .map((s) => Song.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'music': music.map((s) => s.toJson()).toList(),
    };
  }
}
