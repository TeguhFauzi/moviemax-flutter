class WatchlistItem {
  final int movieId;
  final String title;
  final String posterPath;
  final double voteAverage;
  final String addedAt;

  WatchlistItem({
    required this.movieId,
    required this.title,
    required this.posterPath,
    required this.voteAverage,
    required this.addedAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      movieId: json['movie_id'] ?? json['movieId'] ?? 0,
      title: json['title'] ?? '',
      posterPath: json['poster_path'] ?? json['posterPath'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      addedAt: json['added_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movie_id': movieId,
      'title': title,
      'poster_path': posterPath,
      'vote_average': voteAverage,
      'added_at': addedAt,
    };
  }
}
