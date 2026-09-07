import 'dart:async';
import 'firebase_service.dart';
import 'firestore_rest_service.dart';

enum CallType { voice, video }

enum CallStatus { idle, calling, ringing, connected, ended, declined }

CallType callTypeFromString(String? raw) =>
    raw == 'video' ? CallType.video : CallType.voice;

CallStatus callStatusFromString(String? raw) {
  switch (raw) {
    case 'calling':
      return CallStatus.calling;
    case 'ringing':
      return CallStatus.ringing;
    case 'connected':
      return CallStatus.connected;
    case 'ended':
      return CallStatus.ended;
    case 'declined':
      return CallStatus.declined;
    default:
      return CallStatus.idle;
  }
}

/// Deterministic room key for a pair of users, so both devices always
/// resolve to the same conversation id regardless of who calls first.
String callRoomId(String a, String b) {
  final pair = [a.trim().toLowerCase(), b.trim().toLowerCase()]..sort();
  return '${pair[0]}__${pair[1]}';
}

class CallSession {
  final String callId;
  final String caller;
  final String receiver;
  final CallType type;
  final CallStatus status;
  final String roomId;
  final int createdAt;
  final int? connectedAt;
  final int updatedAt;

  CallSession({
    required this.callId,
    required this.caller,
    required this.receiver,
    required this.type,
    required this.status,
    required this.roomId,
    required this.createdAt,
    required this.updatedAt,
    this.connectedAt,
  });

  factory CallSession.create({
    required String caller,
    required String receiver,
    required CallType type,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return CallSession(
      callId: 'call_$now',
      caller: caller,
      receiver: receiver,
      type: type,
      status: CallStatus.calling,
      roomId: callRoomId(caller, receiver),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CallSession.fromJson(Map<String, dynamic> json) {
    final caller = (json['caller'] ?? '').toString();
    final receiver = (json['receiver'] ?? '').toString();
    final created = _asInt(json['createdAt']) ?? DateTime.now().millisecondsSinceEpoch;
    return CallSession(
      callId: (json['callId'] ?? 'call_$created').toString(),
      caller: caller,
      receiver: receiver,
      type: callTypeFromString(json['type']?.toString()),
      status: callStatusFromString(json['status']?.toString()),
      roomId: (json['roomId'] ?? callRoomId(caller, receiver)).toString(),
      createdAt: created,
      connectedAt: _asInt(json['connectedAt']),
      updatedAt: _asInt(json['updatedAt']) ?? created,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'caller': caller,
        'receiver': receiver,
        'type': type.name,
        'status': status.name,
        'roomId': roomId,
        'createdAt': createdAt,
        'connectedAt': connectedAt,
        'updatedAt': updatedAt,
      };

  CallSession copyWith({
    CallStatus? status,
    int? connectedAt,
    int? updatedAt,
  }) {
    return CallSession(
      callId: callId,
      caller: caller,
      receiver: receiver,
      type: type,
      status: status ?? this.status,
      roomId: roomId,
      createdAt: createdAt,
      connectedAt: connectedAt ?? this.connectedAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool involves(String user) {
    final u = user.trim().toLowerCase();
    return caller.trim().toLowerCase() == u || receiver.trim().toLowerCase() == u;
  }

  bool isCaller(String user) => caller.trim().toLowerCase() == user.trim().toLowerCase();

  bool isReceiver(String user) => receiver.trim().toLowerCase() == user.trim().toLowerCase();

  String partnerOf(String user) => isCaller(user) ? receiver : caller;

  bool get isActive => status == CallStatus.calling ||
      status == CallStatus.ringing ||
      status == CallStatus.connected;

  bool get isTerminated => status == CallStatus.ended || status == CallStatus.declined;

  /// Identity used to detect real changes and avoid redundant notifications.
  String get fingerprint => '$callId|${status.name}|$connectedAt';
}

/// Shared call signaling over Cloud Firestore REST.
///
/// Uses the same collection the `xxx/duals` web app signals through,
/// `couples/{coupleId}/calls/{callId}` (see `../duals/firestore.rules`). The
/// Realtime Database is not an option: project `fire-test-f786f` has no RTDB
/// instance, so every `*.firebaseio.com` host answers 404.
///
/// A session is mirrored to the caller's and the receiver's own doc so each
/// device only polls one document yet both observe identical state.
class FirebaseCallService {
  static final FirebaseCallService _instance = FirebaseCallService._internal();
  factory FirebaseCallService() => _instance;
  FirebaseCallService._internal();

  static const Duration pollInterval = Duration(milliseconds: 1200);
  static const Duration ringTimeout = Duration(seconds: 45);

  final StreamController<CallSession?> _callStreamController =
      StreamController<CallSession?>.broadcast();
  Stream<CallSession?> get callStream => _callStreamController.stream;

  final FirestoreRestService _firestore = FirestoreRestService();

  Timer? _pollTimer;
  Timer? _cleanupTimer;
  String? _currentUser;
  CallSession? _activeCall;
  String? _lastFingerprint;
  bool _polling = false;

  /// Consecutive empty polls. One failed request must not tear down a live
  /// call, so a session is only dropped after a couple of misses in a row.
  int _missStreak = 0;
  static const int _missTolerance = 2;

  CallSession? get activeCall => _activeCall;
  String? get currentUser => _currentUser;

  String _key(String user) => user.trim().toLowerCase();

  /// Signaling docs hang off the pair thread, matching the `{coupleId}`
  /// wildcard the rules use for chat.
  String _callPath(String user) {
    final me = _key(user);
    final partner = me == 'amrhdla' ? 'tfauzyy' : 'amrhdla';
    return 'couples/${FirebaseService.directThreadId(me, partner)}/calls/$me';
  }

  /// Binds the service to the signed-in user and starts listening for signals.
  void bind(String username) {
    final normalized = username.trim();
    if (normalized.isEmpty) return;
    if (_currentUser == normalized && _pollTimer != null && _pollTimer!.isActive) {
      return;
    }
    _currentUser = normalized;
    _activeCall = null;
    _lastFingerprint = null;
    _missStreak = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
    _poll();
  }

  void unbind() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _currentUser = null;
    _activeCall = null;
    _lastFingerprint = null;
  }

  Future<void> _poll() async {
    final user = _currentUser;
    if (user == null || _polling) return;
    _polling = true;
    try {
      final data = await _get(_callPath(user));
      if (data == null) {
        _missStreak++;
        if (_activeCall == null || _missStreak >= _missTolerance) _emit(null);
        return;
      }
      _missStreak = 0;

      final session = CallSession.fromJson(data);
      if (!session.involves(user)) {
        _emit(null);
        return;
      }

      // Drop abandoned invitations so a dead signal never blocks new calls.
      if (session.status == CallStatus.calling &&
          DateTime.now().millisecondsSinceEpoch - session.createdAt >
              ringTimeout.inMilliseconds) {
        await _delete(session);
        _emit(null);
        return;
      }

      _emit(session);
    } finally {
      _polling = false;
    }
  }

  void _emit(CallSession? session) {
    final fingerprint = session?.fingerprint;
    if (fingerprint == _lastFingerprint) return;
    _lastFingerprint = fingerprint;
    _activeCall = session != null && session.isActive ? session : null;
    _callStreamController.add(session);
  }

  Future<CallSession> initiateCall({
    required String caller,
    required String receiver,
    required CallType type,
  }) async {
    final session = CallSession.create(
      caller: caller,
      receiver: receiver,
      type: type,
    );
    _emit(session);
    await _publish(session);
    return session;
  }

  Future<CallSession?> acceptCall([CallSession? incoming]) async {
    final base = incoming ?? _activeCall;
    if (base == null) return null;
    final accepted = base.copyWith(
      status: CallStatus.connected,
      connectedAt: base.connectedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    _emit(accepted);
    await _publish(accepted);
    return accepted;
  }

  Future<void> declineCall([CallSession? incoming]) async {
    final base = incoming ?? _activeCall;
    if (base == null) return;
    final declined = base.copyWith(status: CallStatus.declined);
    _emit(declined);
    await _publish(declined);
    _scheduleCleanup(declined);
  }

  Future<void> endCall([CallSession? current]) async {
    final base = current ?? _activeCall;
    if (base == null) return;
    final ended = base.copyWith(status: CallStatus.ended);
    _emit(ended);
    await _publish(ended);
    _scheduleCleanup(ended);
  }

  /// Keeps the terminal state visible long enough for the peer to observe it,
  /// then removes both mirrors so the next call starts clean.
  void _scheduleCleanup(CallSession session) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(const Duration(seconds: 4), () async {
      await _delete(session);
      _emit(null);
    });
  }

  Future<void> _publish(CallSession session) async {
    final fields = session.toJson();
    await Future.wait([
      _put(_callPath(session.caller), fields),
      _put(_callPath(session.receiver), fields),
    ]);
  }

  Future<void> _delete(CallSession session) async {
    await Future.wait([
      _deletePath(_callPath(session.caller)),
      _deletePath(_callPath(session.receiver)),
    ]);
  }

  Future<Map<String, dynamic>?> _get(String path) async {
    final doc = await _firestore.getDocument(path);
    if (doc == null) return null;
    if (doc.data.isEmpty) return null;
    return doc.data;
  }

  Future<void> _put(String path, Map<String, dynamic> fields) async {
    // Create-or-replace: a session doc is fully rewritten on every state change.
    await _firestore.setDocument(path: path, fields: fields);
  }

  Future<void> _deletePath(String path) async {
    // Ignore failures: a stale signal is also cleared by the ring timeout guard.
    await _firestore.deleteDocument(path);
  }

  void dispose() {
    unbind();
    _callStreamController.close();
  }
}
