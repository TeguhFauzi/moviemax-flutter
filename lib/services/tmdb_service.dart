import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/movie_model.dart';

class TmdbService {
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json;charset=utf-8',
        if (EnvConfig.tmdbAccessToken.isNotEmpty)
          'Authorization': 'Bearer ${EnvConfig.tmdbAccessToken}',
      };

  String _buildUrl(String path, [Map<String, String>? queryParams]) {
    final params = queryParams ?? {};
    if (EnvConfig.tmdbAccessToken.isEmpty) {
      params['api_key'] = EnvConfig.tmdbApiKey;
    }
    final queryString = Uri(queryParameters: params).query;
    return '$_baseUrl$path?$queryString';
  }

  Future<List<Movie>> getTrendingMovies() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/trending/movie/week')),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) => Movie.fromJson(m)).toList();
      }
    } catch (e) {
      print('Error fetching trending movies: $e');
    }
    return [];
  }

  Future<List<Movie>> getPopularMovies() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/movie/popular')),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) => Movie.fromJson(m)).toList();
      }
    } catch (e) {
      print('Error fetching popular movies: $e');
    }
    return [];
  }

  Future<List<Movie>> getTopRatedMovies() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/movie/top_rated')),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) => Movie.fromJson(m)).toList();
      }
    } catch (e) {
      print('Error fetching top rated movies: $e');
    }
    return [];
  }

  Future<List<Movie>> getKoreanDramas() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/discover/movie', {
          'with_original_language': 'ko',
          'sort_by': 'popularity.desc',
        })),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) => Movie.fromJson(m)).toList();
      }
    } catch (e) {
      print('Error fetching Korean dramas: $e');
    }
    return [];
  }

  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/search/movie', {'query': query})),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) => Movie.fromJson(m)).toList();
      }
    } catch (e) {
      print('Error searching movies: $e');
    }
    return [];
  }

  Future<List<Genre>> getGenres() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/genre/movie/list')),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List genres = data['genres'] ?? [];
        return genres.map((g) => Genre.fromJson(g)).toList();
      }
    } catch (e) {
      print('Error fetching genres: $e');
    }
    return [];
  }

  Future<MovieDetail?> getMovieDetails(int movieId) async {
    try {
      final detailResp = await http.get(
        Uri.parse(_buildUrl('/movie/$movieId')),
        headers: _headers,
      );
      final creditsResp = await http.get(
        Uri.parse(_buildUrl('/movie/$movieId/credits')),
        headers: _headers,
      );
      final videosResp = await http.get(
        Uri.parse(_buildUrl('/movie/$movieId/videos')),
        headers: _headers,
      );

      if (detailResp.statusCode == 200) {
        final detailData = json.decode(detailResp.body);

        List<CastMember> castList = [];
        if (creditsResp.statusCode == 200) {
          final creditsData = json.decode(creditsResp.body);
          final List castJson = creditsData['cast'] ?? [];
          castList = castJson.take(10).map((c) => CastMember.fromJson(c)).toList();
        }

        String trailerKey = '';
        if (videosResp.statusCode == 200) {
          final videosData = json.decode(videosResp.body);
          final List videos = videosData['results'] ?? [];
          final trailer = videos.firstWhere(
            (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
            orElse: () => videos.isNotEmpty ? videos.first : null,
          );
          if (trailer != null) {
            trailerKey = trailer['key'] ?? '';
          }
        }

        return MovieDetail.fromJson(
          detailData,
          castList: castList,
          youtubeTrailer: trailerKey,
        );
      }
    } catch (e) {
      print('Error fetching movie detail ($movieId): $e');
    }
    return null;
  }
}
