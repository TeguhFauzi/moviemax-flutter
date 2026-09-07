import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watchlist_model.dart';
import '../models/movie_model.dart';

class WatchPartyMessageItem {
  final String sender;
  final String text;
  final String time;

  /// Stable client-generated id, used to de-duplicate optimistic messages
  /// against the copy that comes back from Firebase.
  final String msgId;

  /// Epoch millis used for deterministic ordering across both devices.
  final int ts;

  WatchPartyMessageItem({
    required this.sender,
    required this.text,
    required this.time,
    String? msgId,
    int? ts,
  })  : msgId = msgId ?? '${sender}_${ts ?? DateTime.now().millisecondsSinceEpoch}',
        ts = ts ?? DateTime.now().millisecondsSinceEpoch;

  factory WatchPartyMessageItem.fromJson(Map<String, dynamic> json) {
    final rawTs = json['ts'];
    int? parsedTs;
    if (rawTs is int) {
      parsedTs = rawTs;
    } else if (rawTs is double) {
      parsedTs = rawTs.toInt();
    } else if (rawTs != null) {
      parsedTs = int.tryParse(rawTs.toString());
    }

    return WatchPartyMessageItem(
      sender: json['sender'] ?? '',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
      msgId: json['msgId']?.toString(),
      ts: parsedTs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'time': time,
      'msgId': msgId,
      'ts': ts,
    };
  }
}

class NeonDbService {
  static const String _watchlistKey = 'user_watchlist_neon_sync';
  static const String _chatPrefix = 'watch_party_chat_neon_';
  static const String _userLocationPrefix = 'user_location_neon_';

  Future<List<WatchlistItem>> getWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_watchlistKey);
      if (jsonStr != null) {
        final List decoded = json.decode(jsonStr);
        return decoded.map((item) => WatchlistItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading watchlist: $e');
    }
    return [];
  }

  Future<bool> addToWatchlist(Movie movie) async {
    try {
      final items = await getWatchlist();
      if (items.any((item) => item.movieId == movie.id)) {
        return true;
      }

      final newItem = WatchlistItem(
        movieId: movie.id,
        title: movie.title,
        posterPath: movie.posterPath,
        voteAverage: movie.voteAverage,
        addedAt: DateTime.now().toIso8601String(),
      );

      items.add(newItem);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_watchlistKey, json.encode(items.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      print('Error adding to watchlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWatchlist(int movieId) async {
    try {
      final items = await getWatchlist();
      items.removeWhere((item) => item.movieId == movieId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_watchlistKey, json.encode(items.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      print('Error removing from watchlist: $e');
      return false;
    }
  }

  Future<bool> isWatchlisted(int movieId) async {
    final items = await getWatchlist();
    return items.any((item) => item.movieId == movieId);
  }

  // Real Chat Persistence for Watch Party Rooms
  Future<List<WatchPartyMessageItem>> getWatchPartyMessages(int movieId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('$_chatPrefix$movieId');
      if (jsonStr != null) {
        final List decoded = json.decode(jsonStr);
        final items = decoded.map((item) => WatchPartyMessageItem.fromJson(item)).toList();
        items.sort((a, b) => a.ts.compareTo(b.ts));
        return items;
      }
    } catch (e) {
      print('Error loading watch party chat ($movieId): $e');
    }
    return [];
  }

  Future<bool> sendWatchPartyMessage(
    int movieId,
    String sender,
    String text, {
    WatchPartyMessageItem? message,
  }) async {
    final newMsg = message ??
        WatchPartyMessageItem(
          sender: sender,
          text: text,
          time: DateTime.now().toString().substring(11, 16),
        );
    return appendWatchPartyMessage(movieId.toString(), newMsg);
  }

  // --- Thread-keyed chat cache (supports both movie rooms and 1:1 DM ids) ---
  Future<List<WatchPartyMessageItem>> getWatchPartyMessagesByThread(String threadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('$_chatPrefix$threadId');
      if (jsonStr != null) {
        final List decoded = json.decode(jsonStr);
        final items = decoded.map((item) => WatchPartyMessageItem.fromJson(item)).toList();
        items.sort((a, b) => a.ts.compareTo(b.ts));
        return items;
      }
    } catch (e) {
      print('Error loading chat thread ($threadId): $e');
    }
    return [];
  }

  Future<bool> appendWatchPartyMessage(String threadId, WatchPartyMessageItem message) async {
    try {
      final messages = await getWatchPartyMessagesByThread(threadId);
      if (messages.any((m) => m.msgId == message.msgId)) return true;
      messages.add(message);
      messages.sort((a, b) => a.ts.compareTo(b.ts));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_chatPrefix$threadId',
        json.encode(messages.map((e) => e.toJson()).toList()),
      );
      return true;
    } catch (e) {
      print('Error appending chat message ($threadId): $e');
      return false;
    }
  }

  /// Overwrites the local cache with authoritative remote history.
  Future<bool> replaceWatchPartyMessages(
    String threadId,
    List<WatchPartyMessageItem> messages,
  ) async {
    try {
      final sorted = [...messages]..sort((a, b) => a.ts.compareTo(b.ts));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_chatPrefix$threadId',
        json.encode(sorted.map((e) => e.toJson()).toList()),
      );
      return true;
    } catch (e) {
      print('Error replacing chat thread ($threadId): $e');
      return false;
    }
  }

  // Real User GPS & Location Persistence / Sync between amrhdla & tfauzyy
  Future<bool> saveUserLocation(String username, double lat, double lng, String isp, String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'lat': lat,
        'lng': lng,
        'isp': isp,
        'city': city,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('$_userLocationPrefix$username', json.encode(data));
      return true;
    } catch (e) {
      print('Error saving user location: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserLocation(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('$_userLocationPrefix$username');
      if (jsonStr != null) {
        return json.decode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
    return null;
  }
}
