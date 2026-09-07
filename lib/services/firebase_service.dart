import '../config/env_config.dart';
import 'firestore_rest_service.dart';
import 'neon_db_service.dart';

/// Chat + presence transport shared with the `xxx/duals` web app.
///
/// Both apps live in Firebase project `fire-test-f786f` but only **Cloud
/// Firestore** is provisioned there; the Realtime Database has no instance, so
/// every `*.firebaseio.com` / `*.firebasedatabase.app` host answers 404. Writing
/// chat to RTDB is why messages never crossed between the two browsers: each
/// side silently fell back to its own SharedPreferences mirror.
///
/// Collections mirror `../duals/firestore.rules` exactly:
///   couples/{threadId}/messages/{msgId}  -> senderId, content, type, createdAt
///   couples/{threadId}/status/{userId}   -> userId, lat, lng, isp, city, updatedAt
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirestoreRestService _firestore = FirestoreRestService();

  /// duals caps `content` at 2000 chars in its security rules; a longer write is
  /// rejected with PERMISSION_DENIED, so clamp before sending.
  static const int maxContentLength = 2000;

  /// Deterministic 1:1 thread id so both users read/write the same documents
  /// regardless of who opens the conversation first. Used as the `{coupleId}`
  /// path segment, which the rules accept as a wildcard.
  static String directThreadId(String a, String b) {
    final pair = [a.trim().toLowerCase(), b.trim().toLowerCase()]..sort();
    return 'dm_${pair[0]}__${pair[1]}';
  }

  static String messagesParent(String threadId) => 'couples/$threadId';

  /// True once the Firebase web API key is present; without it no REST call can
  /// be signed and the app runs local-only.
  bool get isConfigured => EnvConfig.firebaseApiKey.isNotEmpty;

  /// Confirms an anonymous session exists. Used by the UI to show a real
  /// connection state instead of a hardcoded label.
  Future<bool> ensureConnected() async => (await _firestore.ensureAuth()) != null;

  // --- Chat -----------------------------------------------------------------

  Future<List<WatchPartyMessageItem>> getChatMessages(String threadId) async {
    final docs = await _firestore.queryCollection(
      parentPath: messagesParent(threadId),
      collectionId: 'messages',
      orderByField: 'createdAt',
      limit: 300,
    );

    if (docs.isNotEmpty) {
      final messages = docs
          .map(_messageFromDoc)
          .whereType<WatchPartyMessageItem>()
          .toList()
        ..sort((a, b) => a.ts.compareTo(b.ts));

      if (messages.isNotEmpty) {
        // Mirror remote history locally so offline reads stay consistent.
        await NeonDbService().replaceWatchPartyMessages(threadId, messages);
        return messages;
      }
    }

    // Empty remote thread or a failed request: serve the local mirror.
    return await NeonDbService().getWatchPartyMessagesByThread(threadId);
  }

  Future<bool> sendChatMessage(
    String threadId,
    String sender,
    String text, {
    WatchPartyMessageItem? message,
  }) async {
    final msg = message ??
        WatchPartyMessageItem(
          sender: sender,
          text: text,
          time: DateTime.now().toString().substring(11, 16),
        );

    // Save locally first so the bubble survives a dropped request.
    await NeonDbService().appendWatchPartyMessage(threadId, msg);

    // Document id == msgId, and `currentDocument.exists=false` inside
    // createDocument, so a retry can never duplicate a message.
    return await _firestore.createDocument(
      path: '${messagesParent(threadId)}/messages/${msg.msgId}',
      fields: {
        'senderId': msg.sender,
        'content': msg.text.length > maxContentLength
            ? msg.text.substring(0, maxContentLength)
            : msg.text,
        'type': 'text',
        'deleted': false,
        // Local clock, kept so ordering survives before createdAt resolves.
        'clientTs': msg.ts,
      },
      // Rules demand `createdAt == request.time`, which only a server
      // transform can satisfy.
      serverTimestampFields: const ['createdAt'],
    );
  }

  /// Soft delete, matching duals' "hapus untuk semua": the tombstone stays so
  /// both clients agree the message existed.
  Future<bool> deleteChatMessage(String threadId, String msgId) async {
    return await _firestore.updateDocument(
      path: '${messagesParent(threadId)}/messages/$msgId',
      fields: {
        'deleted': true,
        'content': '',
      },
    );
  }

  WatchPartyMessageItem? _messageFromDoc(FirestoreDoc doc) {
    final data = doc.data;
    final sender = (data['senderId'] ?? '').toString();
    if (sender.isEmpty) return null;

    final deleted = data['deleted'] == true;
    final content = (data['content'] ?? '').toString();

    // createdAt is a server timestamp; clientTs covers the brief window before
    // the write lands, and the msgId suffix is the last resort.
    final createdAt = data['createdAt'];
    final int ts;
    if (createdAt is DateTime) {
      ts = createdAt.millisecondsSinceEpoch;
    } else if (data['clientTs'] is int) {
      ts = data['clientTs'] as int;
    } else {
      ts = int.tryParse(doc.id.split('_').last) ??
          DateTime.now().millisecondsSinceEpoch;
    }

    final stamp = DateTime.fromMillisecondsSinceEpoch(ts);
    final time =
        '${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}';

    return WatchPartyMessageItem(
      sender: sender,
      text: deleted ? 'Pesan telah dihapus' : content,
      time: time,
      msgId: doc.id,
      ts: ts,
    );
  }

  // --- Presence / location --------------------------------------------------

  Future<void> syncUserLocation(
    String username,
    double lat,
    double lng,
    String isp,
    String city,
  ) async {
    await NeonDbService().saveUserLocation(username, lat, lng, isp, city);

    final userKey = _statusKey(username);
    await _firestore.setDocument(
      // Presence is shared per user, so it hangs off a stable per-user thread
      // rather than one conversation.
      path: 'couples/${_presenceThread(username)}/status/$userKey',
      fields: {
        // Required by the rules: `request.resource.data.userId is string`.
        'userId': userKey,
        'lat': lat,
        'lng': lng,
        'isp': isp,
        'city': city,
      },
      serverTimestampFields: const ['updatedAt'],
    );
  }

  // --- Watch Party State Sync ------------------------------------------------

  Future<void> syncWatchState(
    String threadId,
    String username, {
    required int movieId,
    required String movieTitle,
    required String backdropPath,
    required String posterPath,
    required String trailerKey,
    required bool isPlaying,
    required double positionSeconds,
    int? startEpoch,
  }) async {
    await _firestore.setDocument(
      path: 'couples/$threadId/status/watch_party_state',
      fields: {
        'userId': username,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'backdropPath': backdropPath,
        'posterPath': posterPath,
        'trailerKey': trailerKey,
        'isPlaying': isPlaying,
        'positionSeconds': positionSeconds,
        if (startEpoch != null) 'startEpoch': startEpoch,
      },
      serverTimestampFields: const ['updatedAt'],
    );
  }

  Future<Map<String, dynamic>?> getWatchState(String threadId) async {
    final doc = await _firestore.getDocument('couples/$threadId/status/watch_party_state');
    return doc?.data;
  }

  Future<Map<String, dynamic>?> getUserLocation(String username) async {
    final userKey = _statusKey(username);
    final doc = await _firestore
        .getDocument('couples/${_presenceThread(username)}/status/$userKey');

    if (doc != null && doc.data['lat'] != null && doc.data['lng'] != null) {
      final updatedAt = doc.data['updatedAt'];
      return {
        'lat': _asDouble(doc.data['lat']),
        'lng': _asDouble(doc.data['lng']),
        'isp': (doc.data['isp'] ?? '').toString(),
        'city': (doc.data['city'] ?? '').toString(),
        'updated_at': updatedAt is DateTime
            ? updatedAt.toIso8601String()
            : updatedAt?.toString() ?? '',
      };
    }

    return await NeonDbService().getUserLocation(username);
  }

  /// Presence lives under the pair thread so a partner can read it with the
  /// same wildcard rule that guards chat.
  static String _presenceThread(String username) {
    final me = username.trim().toLowerCase();
    final partner = me == 'amrhdla' ? 'tfauzyy' : 'amrhdla';
    return directThreadId(me, partner);
  }

  static String _statusKey(String username) => username.trim().toLowerCase();

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
