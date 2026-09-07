import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../services/neon_db_service.dart';

class PushNotificationEvent {
  final String sender;
  final String text;
  final String time;
  final String threadId;

  PushNotificationEvent({
    required this.sender,
    required this.text,
    required this.time,
    required this.threadId,
  });
}

/// Owns the 1:1 chat thread only. Call signaling lives in CallProvider so the
/// two features never fight over the same Firebase node.
class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  static const Duration syncInterval = Duration(milliseconds: 1500);

  List<WatchPartyMessageItem> _messages = [];
  bool _isLoading = true;
  Timer? _syncTimer;
  bool _syncing = false;

  String? _currentUser;
  String? _partnerUser;
  String? _threadId;

  /// msgIds already surfaced, so a banner never fires twice for one message.
  final Set<String> _seenMessageIds = {};

  PushNotificationEvent? _activePushNotification;

  /// Suppresses banners while the user is already reading the thread.
  bool _isThreadOpen = false;

  /// Real Firestore connection state, so the UI stops claiming "Online" when
  /// nothing is actually syncing.
  bool _isConnected = false;

  List<WatchPartyMessageItem> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  PushNotificationEvent? get activePushNotification => _activePushNotification;
  String? get threadId => _threadId;
  String? get currentUser => _currentUser;
  String? get partnerUser => _partnerUser;

  static String resolvePartner(String username) =>
      username.trim().toLowerCase() == 'amrhdla' ? 'tfauzyy' : 'amrhdla';

  void init(String username) {
    final normalized = username.trim();
    if (normalized.isEmpty) return;
    if (_currentUser == normalized && _syncTimer != null && _syncTimer!.isActive) {
      return;
    }

    _currentUser = normalized;
    _partnerUser = resolvePartner(normalized);
    _threadId = FirebaseService.directThreadId(normalized, _partnerUser!);
    _messages = [];
    _seenMessageIds.clear();
    _isLoading = true;
    notifyListeners();

    _checkConnection();
    _fetchMessages(markAllSeen: true);
    _startPeriodicSync();
  }

  Future<void> _checkConnection() async {
    final connected = await _firebaseService.ensureConnected();
    if (connected == _isConnected) return;
    _isConnected = connected;
    notifyListeners();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncInterval, (_) => _syncMessages());
  }

  /// Marks the thread as visible; incoming messages then update the list
  /// without raising a push banner.
  void setThreadOpen(bool isOpen) {
    if (_isThreadOpen == isOpen) return;
    _isThreadOpen = isOpen;
    if (isOpen && _activePushNotification != null) {
      _activePushNotification = null;
      notifyListeners();
    }
  }

  Future<void> _fetchMessages({bool markAllSeen = false}) async {
    final thread = _threadId;
    if (thread == null) return;

    final fetched = await _firebaseService.getChatMessages(thread);
    _messages = fetched;
    if (markAllSeen) {
      _seenMessageIds
        ..clear()
        ..addAll(fetched.map((m) => m.msgId));
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _syncMessages() async {
    final thread = _threadId;
    final user = _currentUser;
    final partner = _partnerUser;
    if (thread == null || user == null || partner == null || _syncing) return;

    _syncing = true;
    try {
      final fetched = await _firebaseService.getChatMessages(thread);

      final newIncoming = fetched
          .where((m) => !_seenMessageIds.contains(m.msgId))
          .toList();

      final changed = newIncoming.isNotEmpty || fetched.length != _messages.length;
      if (!changed) return;

      _messages = fetched;
      _seenMessageIds.addAll(fetched.map((m) => m.msgId));
      _isLoading = false;

      // Banner only for partner messages while the thread is not on screen.
      if (!_isThreadOpen) {
        final fromPartner = newIncoming
            .where((m) => m.sender.trim().toLowerCase() == partner.toLowerCase())
            .toList();
        if (fromPartner.isNotEmpty) {
          final latest = fromPartner.last;
          _activePushNotification = PushNotificationEvent(
            sender: latest.sender,
            text: latest.text,
            time: latest.time,
            threadId: thread,
          );
        }
      }

      notifyListeners();
    } finally {
      _syncing = false;
    }
  }

  Future<void> sendMessage(String text) async {
    final user = _currentUser;
    final thread = _threadId;
    if (user == null || thread == null || text.trim().isEmpty) return;

    final msg = WatchPartyMessageItem(
      sender: user,
      text: text.trim(),
      time: DateTime.now().toString().substring(11, 16),
    );

    // Optimistic insert; msgId keeps the echo from Firebase from duplicating it.
    _messages = [..._messages, msg]..sort((a, b) => a.ts.compareTo(b.ts));
    _seenMessageIds.add(msg.msgId);
    notifyListeners();

    final sent =
        await _firebaseService.sendChatMessage(thread, user, msg.text, message: msg);
    if (sent != _isConnected) {
      _isConnected = sent;
      notifyListeners();
    }
    await _syncMessages();
  }

  void dismissNotification() {
    if (_activePushNotification == null) return;
    _activePushNotification = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
