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
  final String? coverUrl;
  final SongSource source;
  bool isLiked;
  bool isDownloaded;
  DateTime? lastPlayedAt;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.url,
    this.coverUrl,
    this.source = SongSource.server,
    this.isLiked = false,
    this.isDownloaded = false,
    this.lastPlayedAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      url: json['url'],
      coverUrl: json['coverUrl'],
      source: SongSource.values.firstWhere(
            (e) => e.name == json['source'],
        orElse: () => SongSource.server,
      ),
      isLiked: json['isLiked'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'url': url,
      'coverUrl': coverUrl,
      'source': source.name,
      'isLiked': isLiked,
      'isDownloaded': isDownloaded,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }

  Song copyWith({
    int? id,
    String? name,
    String? artist,
    String? url,
    String? coverUrl,
    SongSource? source,
    bool? isLiked,
    bool? isDownloaded,
    DateTime? lastPlayedAt,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      url: url ?? this.url,
      coverUrl: coverUrl ?? this.coverUrl,
      source: source ?? this.source,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}
