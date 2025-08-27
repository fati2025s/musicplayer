enum SongSource {
  local,
  uploaded,
  server,
}class Song {
  final int id;
  final String name;         // از "title" پر میشه
  final String artist;
  final String url;          // اجباری نباشه چون JSON نداره
  final String? coverUrl;
  final SongSource source;
  bool isLiked;
  bool isDownloaded;
  int likeCount;
  DateTime? lastPlayedAt;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    this.url = "",                 // 👈 دیگه required نیست
    this.coverUrl,
    this.source = SongSource.server,
    this.isLiked = false,
    this.isDownloaded = false,
    this.likeCount = 0,
    this.lastPlayedAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? 0,
      name: json['title'] ?? "",                   // 👈 با title هماهنگ شد
      artist: json['artist'] ?? "Unknown",
      url: json['url'] ?? "",                      // 👈 safe برای null
      coverUrl: json['coverUrl'],
      source: SongSource.values.firstWhere(
            (e) => e.name == (json['source'] ?? "server"),
        orElse: () => SongSource.server,
      ),
      isLiked: json['isLiked'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
      likeCount: json['likeCount'] ?? 0,           // 👈 اضافه شد
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,             // 👈 برای سرور هم title برمی‌گردونیم
      'artist': artist,
      'url': url,
      'coverUrl': coverUrl,
      'source': source.name,
      'isLiked': isLiked,
      'isDownloaded': isDownloaded,
      'likeCount': likeCount,
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
    int? likeCount,
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
      likeCount: likeCount ?? this.likeCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}
