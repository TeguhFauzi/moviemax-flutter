import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

/// A Firestore document plus its id, decoded into plain Dart values.
class FirestoreDoc {
  final String id;
  final Map<String, dynamic> data;

  FirestoreDoc({required this.id, required this.data});
}

/// Cloud Firestore over the REST API, with anonymous Identity Toolkit auth.
///
/// The web app (`xxx/duals`) talks to the same project through the Firebase JS
/// SDK: `couples/{coupleId}/messages`, `.../status`, `.../calls`, guarded by
/// `firestore.rules` which require `request.auth != null`. Flutter has no
/// firebase_* plugin here, so the same collections are reached over REST and
/// signed with an anonymous id token.
///
/// Realtime Database is NOT used: project `fire-test-f786f` has no RTDB
/// instance provisioned, every `*.firebaseio.com` / `*.firebasedatabase.app`
/// host answers 404.
class FirestoreRestService {
  static final FirestoreRestService _instance = FirestoreRestService._internal();
  factory FirestoreRestService() => _instance;
  FirestoreRestService._internal();

  static const String _refreshTokenKey = 'firebase_anon_refresh_token';
  static const Duration _timeout = Duration(seconds: 8);

  String get _apiKey => EnvConfig.firebaseApiKey;
  String get _documentsUrl => EnvConfig.firestoreDocumentsUrl;
  String get _commitUrl => '${EnvConfig.firestoreDatabaseUrl}/documents:commit';

  String? _idToken;
  DateTime? _tokenExpiry;
  String? _refreshToken;
  Future<String?>? _pendingAuth;

  bool get _tokenIsFresh =>
      _idToken != null &&
      _tokenExpiry != null &&
      DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 2)));

  // --- Auth -----------------------------------------------------------------

  /// Returns a valid id token, signing in anonymously when needed.
  /// Concurrent callers share one in-flight sign-in.
  Future<String?> ensureAuth() {
    if (_tokenIsFresh) return Future.value(_idToken);
    return _pendingAuth ??= _authenticate().whenComplete(() {
      _pendingAuth = null;
    });
  }

  Future<String?> _authenticate() async {
    if (_apiKey.isEmpty) {
      print('Firestore auth skipped: NEXT_PUBLIC_FIREBASE_API_KEY is empty');
      return null;
    }

    // Reuse the stored refresh token so a reinstall-free relaunch keeps the
    // same anonymous uid instead of creating a new user every start.
    _refreshToken ??= await _loadRefreshToken();
    if (_refreshToken != null && await _refreshIdToken()) return _idToken;

    return await _signUpAnonymously() ? _idToken : null;
  }

  Future<bool> _signUpAnonymously() async {
    try {
      final response = await http
          .post(
            Uri.parse(
                'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'returnSecureToken': true}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        print('Anonymous sign-in failed: ${response.statusCode} ${response.body}');
        return false;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      _applyToken(
        idToken: body['idToken']?.toString(),
        refreshToken: body['refreshToken']?.toString(),
        expiresInSec: int.tryParse(body['expiresIn']?.toString() ?? '') ?? 3600,
      );
      await _saveRefreshToken(_refreshToken);
      return _idToken != null;
    } catch (e) {
      print('Anonymous sign-in error: $e');
      return false;
    }
  }

  Future<bool> _refreshIdToken() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse('https://securetoken.googleapis.com/v1/token?key=$_apiKey'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'grant_type=refresh_token&refresh_token=$refresh',
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        // Refresh token revoked/invalid: fall back to a fresh anonymous user.
        _refreshToken = null;
        await _saveRefreshToken(null);
        return false;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      _applyToken(
        idToken: body['id_token']?.toString(),
        refreshToken: body['refresh_token']?.toString() ?? refresh,
        expiresInSec: int.tryParse(body['expires_in']?.toString() ?? '') ?? 3600,
      );
      await _saveRefreshToken(_refreshToken);
      return _idToken != null;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  void _applyToken({String? idToken, String? refreshToken, required int expiresInSec}) {
    if (idToken == null || idToken.isEmpty) return;
    _idToken = idToken;
    _refreshToken = refreshToken;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSec));
  }

  Future<String?> _loadRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveRefreshToken(String? token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null || token.isEmpty) {
        await prefs.remove(_refreshTokenKey);
      } else {
        await prefs.setString(_refreshTokenKey, token);
      }
    } catch (e) {
      // Cache miss only costs one extra anonymous sign-in.
    }
  }

  /// Drops the cached session (used on 401 so the next call re-authenticates).
  void _invalidateToken() {
    _idToken = null;
    _tokenExpiry = null;
  }

  // --- Requests -------------------------------------------------------------

  Future<http.Response?> _send(
    String method,
    Uri url, {
    String? body,
    bool retryOnUnauthorized = true,
  }) async {
    final token = await ensureAuth();
    if (token == null) return null;

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    try {
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: body).timeout(_timeout);
          break;
        case 'PATCH':
          response = await http.patch(url, headers: headers, body: body).timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers).timeout(_timeout);
          break;
        default:
          return null;
      }

      if (response.statusCode == 401 && retryOnUnauthorized) {
        _invalidateToken();
        return await _send(method, url, body: body, retryOnUnauthorized: false);
      }
      return response;
    } catch (e) {
      print('Firestore $method ${url.path} error: $e');
      return null;
    }
  }

  /// Reads a collection ordered by [orderByField].
  ///
  /// [parentPath] is relative to `.../documents`, e.g. `couples/dm_a__b`.
  Future<List<FirestoreDoc>> queryCollection({
    required String parentPath,
    required String collectionId,
    String? orderByField,
    bool descending = false,
    int limit = 200,
  }) async {
    final query = <String, dynamic>{
      'from': [
        {'collectionId': collectionId}
      ],
      'limit': limit,
      if (orderByField != null)
        'orderBy': [
          {
            'field': {'fieldPath': orderByField},
            'direction': descending ? 'DESCENDING' : 'ASCENDING',
          }
        ],
    };

    final response = await _send(
      'POST',
      Uri.parse('$_documentsUrl/$parentPath:runQuery'),
      body: json.encode({'structuredQuery': query}),
    );

    if (response == null || response.statusCode != 200) {
      if (response != null) {
        print('Firestore runQuery $parentPath/$collectionId -> ${response.statusCode}');
      }
      return [];
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return [];

    final docs = <FirestoreDoc>[];
    for (final row in decoded) {
      if (row is! Map<String, dynamic>) continue;
      final doc = row['document'];
      if (doc is! Map<String, dynamic>) continue;
      docs.add(_toDoc(doc));
    }
    return docs;
  }

  Future<FirestoreDoc?> getDocument(String path) async {
    final response = await _send('GET', Uri.parse('$_documentsUrl/$path'));
    if (response == null || response.statusCode != 200) return null;
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return _toDoc(decoded);
  }

  /// Creates a document at [path].
  ///
  /// [serverTimestampFields] are written with `REQUEST_TIME`, which
  /// `firestore.rules` demands for message `createdAt`
  /// (`request.resource.data.createdAt == request.time`).
  ///
  /// With [failIfExists] a duplicate write returns HTTP 409, which is treated
  /// as success so retries of the same msgId never duplicate a message.
  Future<bool> createDocument({
    required String path,
    required Map<String, dynamic> fields,
    List<String> serverTimestampFields = const [],
    bool failIfExists = true,
  }) async {
    final write = <String, dynamic>{
      'update': {
        'name': '${_documentsPrefix()}/$path',
        'fields': encodeFields(fields),
      },
      if (serverTimestampFields.isNotEmpty)
        'updateTransforms': serverTimestampFields
            .map((f) => {'fieldPath': f, 'setToServerValue': 'REQUEST_TIME'})
            .toList(),
      if (failIfExists) 'currentDocument': {'exists': false},
    };

    final response = await _send(
      'POST',
      Uri.parse(_commitUrl),
      body: json.encode({'writes': [write]}),
    );

    if (response == null) return false;
    if (response.statusCode == 200) return true;
    // ALREADY_EXISTS: the message is already stored, nothing to retry.
    if (response.statusCode == 409 && failIfExists) return true;
    print('Firestore create $path -> ${response.statusCode} ${response.body}');
    return false;
  }

  /// Overwrites a document (create-or-replace, like `setDoc` without merge).
  Future<bool> setDocument({
    required String path,
    required Map<String, dynamic> fields,
    List<String> serverTimestampFields = const [],
  }) =>
      createDocument(
        path: path,
        fields: fields,
        serverTimestampFields: serverTimestampFields,
        failIfExists: false,
      );

  /// Patches only the listed [fields], leaving every other field untouched
  /// (`updateDoc` semantics). Needed where `firestore.rules` require existing
  /// fields to stay intact, e.g. messages keep their `senderId`/`createdAt`.
  Future<bool> updateDocument({
    required String path,
    required Map<String, dynamic> fields,
  }) async {
    final maskQuery = fields.keys
        .map((f) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(f)}')
        .join('&');

    final response = await _send(
      'PATCH',
      Uri.parse('$_documentsUrl/$path?$maskQuery'),
      body: json.encode({'fields': encodeFields(fields)}),
    );

    if (response == null) return false;
    if (response.statusCode == 200) return true;
    print('Firestore update $path -> ${response.statusCode} ${response.body}');
    return false;
  }

  Future<bool> deleteDocument(String path) async {
    final response = await _send('DELETE', Uri.parse('$_documentsUrl/$path'));
    return response != null && response.statusCode == 200;
  }

  String _documentsPrefix() {
    // `https://firestore.googleapis.com/v1/<resource>/documents` -> `<resource>/documents`
    const marker = '/v1/';
    final index = _documentsUrl.indexOf(marker);
    return index == -1 ? _documentsUrl : _documentsUrl.substring(index + marker.length);
  }

  FirestoreDoc _toDoc(Map<String, dynamic> doc) {
    final name = doc['name']?.toString() ?? '';
    final id = name.isEmpty ? '' : name.split('/').last;
    final rawFields = doc['fields'];
    return FirestoreDoc(
      id: id,
      data: rawFields is Map<String, dynamic> ? decodeFields(rawFields) : <String, dynamic>{},
    );
  }

  // --- Value codec ----------------------------------------------------------

  static Map<String, dynamic> encodeFields(Map<String, dynamic> fields) =>
      {for (final entry in fields.entries) entry.key: encodeValue(entry.value)};

  static Map<String, dynamic> encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is DateTime) return {'timestampValue': value.toUtc().toIso8601String()};
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(encodeValue).toList()}
      };
    }
    if (value is Map) {
      return {
        'mapValue': {
          'fields': {
            for (final entry in value.entries) entry.key.toString(): encodeValue(entry.value)
          }
        }
      };
    }
    return {'stringValue': value.toString()};
  }

  static Map<String, dynamic> decodeFields(Map<String, dynamic> fields) =>
      {for (final entry in fields.entries) entry.key: decodeValue(entry.value)};

  static dynamic decodeValue(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('booleanValue')) return value['booleanValue'] == true;
    if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue'].toString());
    }
    if (value.containsKey('doubleValue')) {
      final raw = value['doubleValue'];
      return raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    }
    if (value.containsKey('stringValue')) return value['stringValue']?.toString();
    if (value.containsKey('timestampValue')) {
      return DateTime.tryParse(value['timestampValue'].toString())?.toLocal();
    }
    if (value.containsKey('arrayValue')) {
      final values = (value['arrayValue'] as Map<String, dynamic>?)?['values'];
      if (values is List) return values.map(decodeValue).toList();
      return <dynamic>[];
    }
    if (value.containsKey('mapValue')) {
      final nested = (value['mapValue'] as Map<String, dynamic>?)?['fields'];
      if (nested is Map<String, dynamic>) return decodeFields(nested);
      return <String, dynamic>{};
    }
    return null;
  }
}
