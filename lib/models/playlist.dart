import '../models/song.dart';

class Playlist {
  final int id;
  String name;
  List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      songs: (json['songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((s) => s.toJson()).toList(),
    };
  }
}
