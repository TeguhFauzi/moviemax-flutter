import 'package:flutter/foundation.dart';
import '../models/movie_model.dart';
import '../models/watchlist_model.dart';
import '../services/tmdb_service.dart';
import '../services/neon_db_service.dart';

class MovieProvider extends ChangeNotifier {
  final TmdbService _tmdbService = TmdbService();
  final NeonDbService _neonDbService = NeonDbService();

  List<Movie> _trendingMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _koreanDramas = [];
  List<Movie> _searchResults = [];
  List<Genre> _genres = [];
  List<WatchlistItem> _watchlist = [];

  bool _isLoading = false;
  bool _isSearching = false;
  int _selectedGenreId = 0;
  String _searchQuery = '';

  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get koreanDramas => _koreanDramas;
  List<Movie> get searchResults => _searchResults;
  List<Genre> get genres => _genres;
  List<WatchlistItem> get watchlist => _watchlist;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  int get selectedGenreId => _selectedGenreId;
  String get searchQuery => _searchQuery;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final trending = await _tmdbService.getTrendingMovies();
      final popular = await _tmdbService.getPopularMovies();
      final topRated = await _tmdbService.getTopRatedMovies();
      final korean = await _tmdbService.getKoreanDramas();
      final genreList = await _tmdbService.getGenres();
      final userWatchlist = await _neonDbService.getWatchlist();

      _trendingMovies = trending;
      _popularMovies = popular;
      _topRatedMovies = topRated;
      _koreanDramas = korean;
      _genres = genreList;
      _watchlist = userWatchlist;
    } catch (e) {
      print('Error in MovieProvider.fetchHomeData: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _tmdbService.searchMovies(query);
    } catch (e) {
      print('Error searching in provider: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void selectGenre(int genreId) {
    _selectedGenreId = genreId;
    notifyListeners();
  }

  List<Movie> get filteredPopularMovies {
    if (_selectedGenreId == 0) return _popularMovies;
    return _popularMovies.where((m) => m.genreIds.contains(_selectedGenreId)).toList();
  }

  Future<void> toggleWatchlist(Movie movie) async {
    final exists = _watchlist.any((item) => item.movieId == movie.id);
    if (exists) {
      await _neonDbService.removeFromWatchlist(movie.id);
    } else {
      await _neonDbService.addToWatchlist(movie);
    }
    _watchlist = await _neonDbService.getWatchlist();
    notifyListeners();
  }

  bool isWatchlisted(int movieId) {
    return _watchlist.any((item) => item.movieId == movieId);
  }
}
