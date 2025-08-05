enum SongSource {
  local,
  uploaded,
  server,
}

class Song {
  final int id;
  final String name;
  final String artist;
  final String url;
  final int count;
  final String? coverUrl;
  final SongSource source;
  bool isLiked;
  DateTime? lastPlayedAt;



  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.url,
    required this.count,
    this.coverUrl,
    this.source = SongSource.server,
    this.isLiked = false,
    this.lastPlayedAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      url: json['url'],
      count: json['count'],
      coverUrl: json['coverUrl'],
      source: SongSource.values.firstWhere(
            (e) => e.name == json['source'],
        orElse: () => SongSource.server,
      ),
      isLiked: json['isLiked'] ?? false,
    )
      ..lastPlayedAt = json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'])
          : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'url': url,
      'count' : count,
      'coverUrl': coverUrl,
      'source': source.name,
      'isLiked': isLiked,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }
//song.lastPlayedAt = DateTime.now();
}
