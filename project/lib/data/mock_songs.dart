import '../models/song.dart';

final List<Song> mockSongs = [
  Song(
    id: 1,
    name: "Tanha",
    artist: "Mohsen",
    url: "https://example.com/tanha.mp3",
    source: SongSource.server,
  ),
  Song(
    id: 2,
    name: "Mano Bebakhsh",
    artist: "Ali",
    url: "https://example.com/ali.mp3",
    source: SongSource.uploaded,
  ),
  Song(
    id: 3,
    name: "Yadegari",
    artist: "Reza",
    url: "/storage/emulated/0/Music/yadegari.mp3",
    source: SongSource.local,
  ),
];
