import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class SubtitleTrack {
  final String id;
  final String language;
  final String displayLanguage;
  final String url;
  final String format; // vtt, srt, zip, etc.

  SubtitleTrack({
    required this.id,
    required this.language,
    required this.displayLanguage,
    required this.url,
    this.format = 'vtt',
  });

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      id: json['id']?.toString() ?? json['url'] ?? '',
      language: json['iso_639_1'] ?? json['language'] ?? json['lang'] ?? 'en',
      displayLanguage: json['display_name'] ?? json['language_name'] ?? json['language'] ?? 'English',
      url: json['url'] ?? json['link'] ?? json['file'] ?? '',
      format: json['format'] ?? json['extension'] ?? 'vtt',
    );
  }
}

class WyzieSubtitleService {
  static const String _baseUrl = 'https://api.wyzie.ru/v1';

  /// Fetch subtitles from all available free engines simultaneously
  static Future<List<SubtitleTrack>> fetchSubtitles({
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
    String? language,
  }) async {
    final Map<String, SubtitleTrack> uniqueSubs = {};

    // Parallel fetch from all providers
    final results = await Future.wait([
      _fetchOpenSubtitlesCom(imdbId: imdbId, tmdbId: tmdbId, season: season, episode: episode),
      _fetchWyzie(imdbId: imdbId, tmdbId: tmdbId, season: season, episode: episode),
      _fetchStremioOpenSubtitles(imdbId: imdbId, tmdbId: tmdbId, season: season, episode: episode),
      _fetchStremioSubscene(imdbId: imdbId, tmdbId: tmdbId, season: season, episode: episode),
      _fetchSubDL(imdbId: imdbId, season: season, episode: episode),
      _fetchYifySubtitles(imdbId: imdbId),
      _fetchFallbackMultiSources(imdbId: imdbId, tmdbId: tmdbId, season: season, episode: episode),
    ]);

    for (final list in results) {
      for (final sub in list) {
        if (sub.url.isNotEmpty && !uniqueSubs.containsKey(sub.url)) {
          uniqueSubs[sub.url] = sub;
        }
      }
    }

    List<SubtitleTrack> subtitles = uniqueSubs.values.toList();

    // Filter by language if requested
    if (language != null && language.isNotEmpty && subtitles.isNotEmpty) {
      final langCodes = _getLanguageAliases(language);
      final filtered = subtitles.where((s) {
        final l = s.language.toLowerCase();
        final dl = s.displayLanguage.toLowerCase();
        return langCodes.any((code) => l.contains(code) || dl.contains(code));
      }).toList();

      if (filtered.isNotEmpty) {
        return filtered;
      }
    }

    return subtitles;
  }

  static Future<List<SubtitleTrack>> _fetchWyzie({
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
  }) async {
    final apiKey = EnvConfig.wyzieApiKey;
    try {
      final queryParams = <String, String>{};
      if (imdbId != null && imdbId.isNotEmpty) queryParams['imdb_id'] = imdbId;
      if (tmdbId != null) queryParams['tmdb_id'] = tmdbId.toString();
      if (season != null) queryParams['season'] = season.toString();
      if (episode != null) queryParams['episode'] = episode.toString();

      final uri = Uri.parse('$_baseUrl/subtitles').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey('subtitles')) {
          list = data['subtitles'];
        }
        return list.map((item) => SubtitleTrack.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SubtitleTrack>> _fetchStremioOpenSubtitles({
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
  }) async {
    try {
      String id = imdbId ?? '';
      if (id.isEmpty && tmdbId != null) id = 'tmdb:$tmdbId';
      if (id.isEmpty) return [];

      final type = season != null ? 'series' : 'movie';
      final mediaId = season != null ? '$id:$season:$episode' : id;
      final urls = [
        'https://opensubtitles-v3.strem.io/subtitles/$type/$mediaId.json',
        'https://opensubtitles.strem.io/subtitles/$type/$mediaId.json',
        'https://opensubtitles.stremio.be/subtitles/$type/$mediaId.json',
      ];

      for (final url in urls) {
        try {
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            if (data['subtitles'] is List && (data['subtitles'] as List).isNotEmpty) {
              final List subs = data['subtitles'];
              return subs.map((s) => SubtitleTrack(
                id: s['url'] ?? s['id'] ?? '',
                language: s['lang'] ?? 'ind',
                displayLanguage: s['lang'] ?? 'Indonesian',
                url: s['url'] ?? '',
                format: 'vtt',
              )).toList();
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SubtitleTrack>> _fetchStremioSubscene({
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
  }) async {
    try {
      final id = imdbId ?? (tmdbId != null ? 'tmdb:$tmdbId' : '');
      if (id.isEmpty) return [];

      final type = season != null ? 'series' : 'movie';
      final mediaId = season != null ? '$id:$season:$episode' : id;
      
      // Multiple Stremio Subscene / Subtitles proxy addon mirrors
      final endpoints = [
        'https://subscene-addon.strem.fun/subtitles/$type/$mediaId.json',
        'https://subtitles.strem.fun/subtitles/$type/$mediaId.json',
        'https://cinemeta-live.strem.fun/subtitles/$type/$mediaId.json',
      ];

      for (final endpoint in endpoints) {
        try {
          final res = await http.get(
            Uri.parse(endpoint),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            if (data['subtitles'] is List && (data['subtitles'] as List).isNotEmpty) {
              final List subs = data['subtitles'];
              return subs.map((s) => SubtitleTrack(
                id: s['url'] ?? s['id'] ?? '',
                language: s['lang'] ?? 'ind',
                displayLanguage: s['lang'] ?? 'Indonesian',
                url: s['url'] ?? '',
                format: 'srt',
              )).toList();
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SubtitleTrack>> _fetchSubDL({
    String? imdbId,
    int? season,
    int? episode,
  }) async {
    try {
      final cleanImdb = imdbId?.replaceAll('tt', '');
      if (cleanImdb == null || cleanImdb.isEmpty) return [];

      final apiKey = EnvConfig.subdlApiKey.isNotEmpty ? EnvConfig.subdlApiKey : 'public';
      final url = 'https://api.subdl.com/api/v1/subtitles?api_key=$apiKey&imdb_id=$cleanImdb${season != null ? '&season_number=$season' : ''}${episode != null ? '&episode_number=$episode' : ''}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['subtitles'] != null) {
          final List subs = data['subtitles'];
          return subs.map((s) => SubtitleTrack(
            id: s['url'] ?? '',
            language: s['lang'] ?? 'en',
            displayLanguage: s['language'] ?? s['lang'] ?? 'Unknown',
            url: s['url']?.startsWith('http') == true ? s['url'] : 'https://dl.subdl.com${s['url']}',
            format: 'srt',
          )).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Official OpenSubtitles REST API v1 (requires OPENSUBTITLES_API_KEY in .env)
  static Future<List<SubtitleTrack>> _fetchOpenSubtitlesCom({
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
  }) async {
    final apiKey = EnvConfig.openSubtitlesApiKey;
    if (apiKey.isEmpty) return [];

    try {
      final queryParams = <String, String>{};
      if (imdbId != null && imdbId.isNotEmpty) {
        queryParams['imdb_id'] = imdbId.replaceAll('tt', '');
      } else if (tmdbId != null) {
        queryParams['tmdb_id'] = tmdbId.toString();
      }
      if (season != null) queryParams['season_number'] = season.toString();
      if (episode != null) queryParams['episode_number'] = episode.toString();

      final uri = Uri.parse('https://api.opensubtitles.com/api/v1/subtitles').replace(queryParameters: queryParams);
      final res = await http.get(
        uri,
        headers: {
          'Api-Key': apiKey,
          'User-Agent': 'MoviemaxApp v1.0.0',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['data'] is List) {
          final List items = data['data'];
          final List<SubtitleTrack> tracks = [];
          for (final item in items) {
            final attr = item['attributes'];
            if (attr == null) continue;
            final files = attr['files'] as List?;
            final fileId = files != null && files.isNotEmpty ? files[0]['file_id'] : null;
            final lang = attr['language'] ?? 'en';

            tracks.add(SubtitleTrack(
              id: item['id']?.toString() ?? '',
              language: lang,
              displayLanguage: attr['language_name'] ?? lang,
              url: fileId != null ? 'https://api.opensubtitles.com/api/v1/download/$fileId' : '',
              format: 'srt',
            ));
          }
          return tracks;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SubtitleTrack>> _fetchYifySubtitles({String? imdbId}) async {
    try {
      if (imdbId == null || imdbId.isEmpty) return [];
      final url = 'https://yifysubtitles.org/api/v1/movie/$imdbId';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['subtitles'] is Map) {
          final Map map = data['subtitles'];
          final List<SubtitleTrack> list = [];
          map.forEach((lang, items) {
            if (items is List) {
              for (final item in items) {
                list.add(SubtitleTrack(
                  id: item['url'] ?? item['id']?.toString() ?? '',
                  language: lang,
                  displayLanguage: lang,
                  url: item['url']?.startsWith('http') == true
                      ? item['url']
                      : 'https://yifysubtitles.org${item['url']}',
                  format: 'zip',
                ));
              }
            }
          });
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  static List<String> _getLanguageAliases(String? lang) {
    if (lang == null) return [];
    final l = lang.toLowerCase();
    if (l == 'id' || l == 'ind' || l.contains('indonesia')) {
      return ['id', 'ind', 'indonesian', 'bahasa'];
    }
    return [l];
  }

  static Future<List<SubtitleTrack>> _fetchFallbackMultiSources({
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
  }) async {
    List<SubtitleTrack> list = [];
    final cleanImdb = imdbId?.replaceAll('tt', '');

    // Backup source: OpenSubtitles mirror via Stremio active addon
    try {
      final targetId = imdbId ?? (tmdbId != null ? 'tmdb:$tmdbId' : '');
      if (targetId.isNotEmpty) {
        final url = 'https://opensubtitles.stremio.be/subtitles/movie/$targetId.json';
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['subtitles'] is List) {
            final List subs = data['subtitles'];
            list.addAll(subs.map((s) => SubtitleTrack(
              id: s['url'] ?? s['id'] ?? '',
              language: s['lang'] ?? s['id'] ?? 'ind',
              displayLanguage: s['lang'] ?? 'Indonesian',
              url: s['url'] ?? '',
              format: 'vtt',
            )));
          }
        }
      }
    } catch (_) {}

    if (list.isNotEmpty) return list;

    // Backup source: SubDL API
    if (cleanImdb != null && cleanImdb.isNotEmpty) {
      list = await _fetchFallbackOpenSubtitles(imdbId: imdbId, tmdbId: tmdbId, season: season, episode: episode);
    }

    return list;
  }

  /// Backup subtitle fetcher (SubDL / OpenSubtitles mirror)
  static Future<List<SubtitleTrack>> _fetchFallbackOpenSubtitles({
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
  }) async {
    try {
      final cleanImdb = imdbId?.replaceAll('tt', '');
      final url = 'https://api.subdl.com/api/v1/subtitles?api_key=public&imdb_id=$cleanImdb${season != null ? '&season_number=$season' : ''}${episode != null ? '&episode_number=$episode' : ''}';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['subtitles'] != null) {
          final List subs = data['subtitles'];
          return subs.map((s) => SubtitleTrack(
            id: s['url'] ?? '',
            language: s['lang'] ?? 'en',
            displayLanguage: s['language'] ?? s['lang'] ?? 'Unknown',
            url: s['url'] ?? '',
            format: 'srt',
          )).toList();
        }
      }
    } catch (e) {
      print('Fallback subtitle error: $e');
    }
    return [];
  }

  /// Download subtitle content from URL.
  /// Unzip/gunzip automatically if response or URL is archive (zip/gz).
  /// Convert SRT to VTT string ready to attach directly to video player.
  static Future<String?> downloadAndProcessSubtitle(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final bytes = response.bodyBytes;
      String rawContent = '';

      // Check if file is ZIP archive or GZIP based on magic bytes or URL
      final isZip = (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) ||
          url.toLowerCase().endsWith('.zip');
      final isGzip = (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) ||
          url.toLowerCase().endsWith('.gz');

      if (isZip) {
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          if (file.isFile) {
            final fileName = file.name.toLowerCase();
            if (fileName.endsWith('.srt') || fileName.endsWith('.vtt')) {
              final contentBytes = file.content as List<int>;
              rawContent = utf8.decode(contentBytes, allowMalformed: true);
              break;
            }
          }
        }
      } else if (isGzip) {
        final decompressed = GZipDecoder().decodeBytes(bytes);
        rawContent = utf8.decode(decompressed, allowMalformed: true);
      } else {
        rawContent = utf8.decode(bytes, allowMalformed: true);
      }

      if (rawContent.trim().isEmpty) return null;

      // Convert SRT to WebVTT format for video player compatibility
      return convertSrtToVtt(rawContent);
    } catch (e) {
      print('Download/Process subtitle error: $e');
      return null;
    }
  }

  /// Convert raw SRT subtitle content into valid WebVTT string format
  static String convertSrtToVtt(String srtContent) {
    if (srtContent.trim().startsWith('WEBVTT')) {
      return srtContent;
    }

    String vtt = 'WEBVTT\n\n';
    String normalized = srtContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Replace comma in timestamp with dot (00:00:00,000 -> 00:00:00.000)
    final timeRegExp = RegExp(r'(\d{2}:\d{2}:\d{2}),(\d{3})');
    normalized = normalized.replaceAllMapped(timeRegExp, (match) => '${match[1]}.${match[2]}');

    vtt += normalized;
    return vtt;
  }
}
