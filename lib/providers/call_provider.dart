import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firebase_call_service.dart';

/// Single source of truth for call state on both devices.
///
/// All transitions go through [FirebaseCallService], so caller and receiver
/// observe the same session document and stay in sync.
class CallProvider extends ChangeNotifier {
  final FirebaseCallService _callService = FirebaseCallService();

  CallSession? _currentCall;
  String _currentUser = '';
  bool _isMuted = false;
  bool _isCameraOn = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  StreamSubscription<CallSession?>? _callSub;

  /// Set when a terminal state arrives so open call UI can dismiss itself.
  CallStatus? _lastTerminalStatus;

  CallSession? get currentCall => _currentCall;
  String get currentUser => _currentUser;
  bool get isMuted => _isMuted;
  bool get isCameraOn => _isCameraOn;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  int get callDurationSeconds => _callDurationSeconds;
  CallStatus? get lastTerminalStatus => _lastTerminalStatus;

  CallStatus get status => _currentCall?.status ?? CallStatus.idle;
  bool get isConnected => status == CallStatus.connected;
  bool get isRinging => status == CallStatus.calling;
  bool get hasActiveCall => _currentCall?.isActive ?? false;

  /// True when this device is the one being called and has not answered yet.
  bool get isIncoming {
    final call = _currentCall;
    if (call == null || _currentUser.isEmpty) return false;
    return call.status == CallStatus.calling && call.isReceiver(_currentUser);
  }

  /// True when this device started the call and is waiting for an answer.
  bool get isOutgoing {
    final call = _currentCall;
    if (call == null || _currentUser.isEmpty) return false;
    return call.status == CallStatus.calling && call.isCaller(_currentUser);
  }

  String get partnerUser {
    final call = _currentCall;
    if (call == null || _currentUser.isEmpty) return '';
    return call.partnerOf(_currentUser);
  }

  CallType get callType => _currentCall?.type ?? CallType.voice;

  String get formattedDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get statusLabel {
    switch (status) {
      case CallStatus.calling:
        return isIncoming ? 'Panggilan masuk...' : 'Memanggil...';
      case CallStatus.ringing:
        return 'Berdering...';
      case CallStatus.connected:
        return formattedDuration;
      case CallStatus.declined:
        return 'Panggilan ditolak';
      case CallStatus.ended:
        return 'Panggilan berakhir';
      case CallStatus.idle:
        return 'Tidak ada panggilan';
    }
  }

  /// Binds signaling to the signed-in user. Safe to call repeatedly.
  void bind(String username) {
    final normalized = username.trim();
    if (normalized.isEmpty) return;
    if (_currentUser == normalized && _callSub != null) return;

    _currentUser = normalized;
    _callSub?.cancel();
    _callSub = _callService.callStream.listen(_onSessionChanged);
    _callService.bind(normalized);
  }

  void _onSessionChanged(CallSession? session) {
    final previous = _currentCall;
    _currentCall = session;

    if (session == null) {
      _stopDurationTimer();
      if (previous != null && previous.isActive) {
        _lastTerminalStatus = CallStatus.ended;
      }
      notifyListeners();
      return;
    }

    if (session.status == CallStatus.connected) {
      _lastTerminalStatus = null;
      // Camera defaults to the negotiated call type on first connect.
      if (previous?.callId != session.callId || previous?.status != CallStatus.connected) {
        _isCameraOn = session.type == CallType.video;
      }
      _startDurationTimer(session);
    } else if (session.isTerminated) {
      _lastTerminalStatus = session.status;
      _stopDurationTimer();
    } else {
      _lastTerminalStatus = null;
      _stopDurationTimer();
    }

    notifyListeners();
  }

  Future<void> startCall({
    required String caller,
    required String receiver,
    required CallType type,
  }) async {
    bind(caller);
    _isMuted = false;
    _isCameraOn = type == CallType.video;
    _isSpeakerOn = true;
    _isFrontCamera = true;
    _callDurationSeconds = 0;
    _lastTerminalStatus = null;
    notifyListeners();

    await _callService.initiateCall(
      caller: caller,
      receiver: receiver,
      type: type,
    );
  }

  Future<void> acceptCall() async {
    final call = _currentCall;
    if (call == null) return;
    _isCameraOn = call.type == CallType.video;
    await _callService.acceptCall(call);
  }

  Future<void> declineCall() async {
    await _callService.declineCall(_currentCall);
  }

  Future<void> endCall() async {
    await _callService.endCall(_currentCall);
  }

  /// Clears the terminal marker after the UI has reacted to it.
  void consumeTerminalStatus() {
    _lastTerminalStatus = null;
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleCamera() {
    _isCameraOn = !_isCameraOn;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void switchCamera() {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  /// Duration is derived from the shared `connectedAt` timestamp so both
  /// participants display the same elapsed time.
  void _startDurationTimer(CallSession session) {
    _callDurationSeconds = _elapsedFor(session);
    if (_durationTimer != null && _durationTimer!.isActive) return;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final call = _currentCall;
      if (call == null || call.status != CallStatus.connected) {
        _stopDurationTimer();
        notifyListeners();
        return;
      }
      _callDurationSeconds = _elapsedFor(call);
      notifyListeners();
    });
  }

  int _elapsedFor(CallSession session) {
    final start = session.connectedAt;
    if (start == null) return 0;
    final diff = DateTime.now().millisecondsSinceEpoch - start;
    return diff <= 0 ? 0 : diff ~/ 1000;
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callDurationSeconds = 0;
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _durationTimer?.cancel();
    _callService.unbind();
    super.dispose();
  }
}
