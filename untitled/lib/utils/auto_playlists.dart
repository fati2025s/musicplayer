import '../models/song.dart';

List<Song> getLikedSongs(List<Song> allSongs) {
  return allSongs.where((s) => s.isLiked && s.source != SongSource.local).toList();
}

List<Song> getRecentlyPlayed(List<Song> allSongs) {
  final recent = allSongs.where((s) => s.lastPlayedAt != null).toList();
  recent.sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!)); // جدیدترین بالا
  return recent;
}