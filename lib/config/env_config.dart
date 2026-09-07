import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print("Warning: Could not load .env file: $e");
    }
  }

  // TMDB API Config
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '0c6d15fc91ca67462804a7fde7d3bf4c';
  static String get tmdbAccessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
  static String get tmdbImageBaseUrl => 'https://image.tmdb.org/t/p/w500';
  static String get tmdbBackdropBaseUrl => 'https://image.tmdb.org/t/p/w1280';

  // Cloudinary Config
  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'kh8tka7v';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '891772412685687';
  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? 'WBJbYSS57FHMHr0AcPeqGO7sdaE';

  // Database (Neon PostgreSQL)
  static String get databaseUrl => dotenv.env['DATABASE_URL'] ?? '';

  // Firebase Config
  static String get firebaseApiKey => dotenv.env['NEXT_PUBLIC_FIREBASE_API_KEY'] ?? '';
  static String get firebaseAuthDomain => dotenv.env['NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseProjectId => dotenv.env['NEXT_PUBLIC_FIREBASE_PROJECT_ID'] ?? '';

  /// Effective Firebase project id, falling back to the shared project used by
  /// the `xxx/duals` web app so both clients hit the same data.
  static String get resolvedFirebaseProjectId =>
      firebaseProjectId.isNotEmpty ? firebaseProjectId : 'fire-test-f786f';

  /// Realtime Database endpoint. Set NEXT_PUBLIC_FIREBASE_DATABASE_URL when the
  /// RTDB instance lives outside us-central1 (e.g. asia-southeast1), otherwise
  /// the default `<projectId>-default-rtdb.firebaseio.com` host is used.
  ///
  /// NOTE: project `fire-test-f786f` has no RTDB instance provisioned (every
  /// host answers 404). Live chat/calls/location use Firestore instead, see
  /// [firestoreDocumentsUrl].
  static String get firebaseDatabaseUrl {
    final explicit = dotenv.env['NEXT_PUBLIC_FIREBASE_DATABASE_URL'] ?? '';
    if (explicit.isNotEmpty) {
      return explicit.endsWith('/') ? explicit.substring(0, explicit.length - 1) : explicit;
    }
    return 'https://$resolvedFirebaseProjectId-default-rtdb.firebaseio.com';
  }

  /// Firestore REST database resource, e.g.
  /// `https://firestore.googleapis.com/v1/projects/<id>/databases/(default)`.
  /// This is the same database the `xxx/duals` web app writes to through the
  /// Firebase JS SDK.
  static String get firestoreDatabaseUrl {
    final explicit = dotenv.env['NEXT_PUBLIC_FIRESTORE_DATABASE_URL'] ?? '';
    if (explicit.isNotEmpty) {
      return explicit.endsWith('/') ? explicit.substring(0, explicit.length - 1) : explicit;
    }
    final dbId = dotenv.env['NEXT_PUBLIC_FIRESTORE_DATABASE_ID'] ?? '(default)';
    return 'https://firestore.googleapis.com/v1/projects/$resolvedFirebaseProjectId/databases/$dbId';
  }

  /// Root of the Firestore document tree: `<firestoreDatabaseUrl>/documents`.
  static String get firestoreDocumentsUrl => '$firestoreDatabaseUrl/documents';
  static String get firebaseStorageBucket => dotenv.env['NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['NEXT_PUBLIC_FIREBASE_APP_ID'] ?? '';

  // Wyzie API
  static String get wyzieApiKey => dotenv.env['WYZIE_API_KEY'] ?? '';

  // Subtitle API Keys (OpenSubtitles.com / SubDL)
  static String get openSubtitlesApiKey => dotenv.env['OPENSUBTITLES_API_KEY'] ?? '';
  static String get subdlApiKey => dotenv.env['SUBDL_API_KEY'] ?? '';
}
