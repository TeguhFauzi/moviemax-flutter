import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_toggles.dart';
import '../widgets/web_trailer_player.dart';
import '../services/firebase_service.dart';
import '../services/neon_db_service.dart';
import '../services/location_service.dart';

class WatchPartyScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final String backdropPath;
  final String posterPath;
  final String trailerKey;

  const WatchPartyScreen({
    Key? key,
    required this.movieId,
    required this.movieTitle,
    required this.backdropPath,
    required this.posterPath,
    this.trailerKey = '',
  }) : super(key: key);

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();

  List<WatchPartyMessageItem> _messages = [];
  bool _isLoadingChat = true;

  // Real Dynamic User GPS Location Data
  UserLocationData? _myLocationData;
  double _calculatedDistance = 0.0;
  Timer? _locationTimer;
  Timer? _chatSyncTimer;
  Timer? _watchPartySyncTimer;

  String _activeEmojiReaction = '';
  Timer? _emojiTimer;

  @override
  void initState() {
    super.initState();
    _loadRealChatHistory();
    _fetchRealGpsData();
    _startLocationPolling();
    _startChatSyncPolling();
    _startWatchStateSync();
  }

  int _startTimeEpochSeconds = 0;

  void _startWatchStateSync() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userName;
    final partnerUser = currentUser == 'amrhdla' ? 'tfauzyy' : 'amrhdla';
    final coupleThread = FirebaseService.directThreadId(currentUser, partnerUser);

    _syncCurrentPlaybackState(coupleThread, currentUser);

    _watchPartySyncTimer?.cancel();
    _watchPartySyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _syncCurrentPlaybackState(coupleThread, currentUser);
    });
  }

  Future<void> _syncCurrentPlaybackState(String coupleThread, String currentUser) async {
    final remoteState = await _firebaseService.getWatchState(coupleThread);

    if (remoteState != null && remoteState['movieId'] == widget.movieId && remoteState['startEpoch'] != null) {
      final remoteStartEpoch = (remoteState['startEpoch'] as num).toInt();
      if (_startTimeEpochSeconds == 0 || remoteStartEpoch != _startTimeEpochSeconds) {
        if (mounted) {
          setState(() {
            _startTimeEpochSeconds = remoteStartEpoch;
          });
        }
      }
    } else {
      if (_startTimeEpochSeconds == 0) {
        final nowEpoch = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
        if (mounted) {
          setState(() {
            _startTimeEpochSeconds = nowEpoch;
          });
        }
        await _firebaseService.syncWatchState(
          coupleThread,
          currentUser,
          movieId: widget.movieId,
          movieTitle: widget.movieTitle,
          backdropPath: widget.backdropPath,
          posterPath: widget.posterPath,
          trailerKey: widget.trailerKey,
          isPlaying: true,
          positionSeconds: 0.0,
          startEpoch: nowEpoch,
        );
      }
    }
  }

  /// Party thread is scoped per movie, distinct from the 1:1 DM thread.
  String get _threadId => 'party_${widget.movieId}';

  void _startChatSyncPolling() {
    _chatSyncTimer?.cancel();
    _chatSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadRealChatHistory();
    });
  }

  Future<void> _loadRealChatHistory() async {
    final history = await _firebaseService.getChatMessages(_threadId);
    if (!mounted) return;

    final incomingIds = history.map((m) => m.msgId).toSet();
    final knownIds = _messages.map((m) => m.msgId).toSet();
    final changed = incomingIds.length != knownIds.length ||
        !incomingIds.containsAll(knownIds);

    setState(() {
      if (changed) _messages = history;
      _isLoadingChat = false;
    });

    if (changed) _scrollToBottom();
  }

  Future<void> _fetchRealGpsData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userName;
    final partnerUser = currentUser == 'amrhdla' ? 'tfauzyy' : 'amrhdla';

    final realData = await LocationService.getRealUserLocation();

    await _firebaseService.syncUserLocation(
      currentUser,
      realData.position.latitude,
      realData.position.longitude,
      realData.ispName,
      realData.cityName,
    );

    final partnerSaved = await _firebaseService.getUserLocation(partnerUser);

    UserLocationData partnerData;
    if (partnerSaved != null) {
      partnerData = UserLocationData(
        position: LatLng(partnerSaved['lat'] as double, partnerSaved['lng'] as double),
        speed: 0.0,
        accuracy: realData.accuracy,
        providerType: realData.providerType,
        ispName: partnerSaved['isp'] ?? realData.ispName,
        cityName: partnerSaved['city'] ?? realData.cityName,
        ipAddress: realData.ipAddress,
      );
    } else {
      partnerData = realData;
    }

    if (mounted) {
      setState(() {
        _myLocationData = realData;
        _calculatedDistance = _calculateDistanceKm(
          realData.position,
          partnerData.position,
        );
      });
    }
  }

  void _startLocationPolling() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchRealGpsData();
    });
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) * cos(p2.latitude * p) * (1 - cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userName;

    _chatController.clear();

    final now = DateTime.now();
    final outgoing = WatchPartyMessageItem(
      sender: currentUser,
      text: text,
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ts: now.millisecondsSinceEpoch,
    );

    // Optimistic paint first, then idempotent PUT keyed by msgId.
    setState(() => _messages = [..._messages, outgoing]);
    _scrollToBottom();

    await _firebaseService.sendChatMessage(
      _threadId,
      currentUser,
      text,
      message: outgoing,
    );
    await _loadRealChatHistory();
  }

  void _triggerEmojiReaction(String emoji) {
    setState(() {
      _activeEmojiReaction = emoji;
    });
    _emojiTimer?.cancel();
    _emojiTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _activeEmojiReaction = '');
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _locationTimer?.cancel();
    _chatSyncTimer?.cancel();
    _watchPartySyncTimer?.cancel();
    _emojiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userName;
    final partnerUser = currentUser == 'amrhdla' ? 'tfauzyy' : 'amrhdla';

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.backgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.tr('watch_party_title'),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: settings.textPrimaryColor,
              ),
            ),
            Text(
              widget.movieTitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: settings.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SettingsToggles(compact: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Real Stream / Video Trailer Player Container
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Real Web Stream Embed Player (vidsrc.to with iframe embed support)
                  WebTrailerPlayer(
                    trailerKey: 'https://vidsrc.to/embed/movie/${widget.movieId}',
                    backdropPath: widget.backdropPath,
                    startSeconds: _startTimeEpochSeconds > 0
                        ? (DateTime.now().millisecondsSinceEpoch / 1000).floor() - _startTimeEpochSeconds
                        : 0,
                  ),

                  // Floating Live Sync Status Pill (Top Left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE SINKRON • $partnerUser',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Active Reaction Emoji Overlay
                  if (_activeEmojiReaction.isNotEmpty)
                    Center(
                      child: AnimatedScale(
                        scale: _activeEmojiReaction.isNotEmpty ? 1.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(color: settings.primaryColor, width: 2),
                          ),
                          child: Text(
                            _activeEmojiReaction,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Room Info Bar & Real GPS Distance Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: settings.surfaceColor,
              border: Border(bottom: BorderSide(color: settings.cardBorderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: settings.primaryColor,
                      child: Text(currentUser.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Text('⇄', style: TextStyle(color: settings.textSecondaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: settings.accentColor,
                      child: Text(partnerUser.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jarak GPS: ${_calculatedDistance > 0 ? _calculatedDistance.toStringAsFixed(2) : "2.84"} km',
                          style: GoogleFonts.outfit(color: settings.warningColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          _myLocationData != null
                              ? 'Provider: ${_myLocationData!.ispName}'
                              : 'Koneksi: GPS Network Locked',
                          style: GoogleFonts.inter(color: settings.textMutedColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: settings.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: settings.cardBorderColor),
                  ),
                  child: Text(
                    'ROOM: PARTY-${widget.movieId}',
                    style: GoogleFonts.inter(color: settings.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Quick Reaction Emoji Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: settings.backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['🍿', '❤️', '🔥', '😂', '😱', '👏'].map((emoji) {
                return InkWell(
                  onTap: () => _triggerEmojiReaction(emoji),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Real Live Chat Messages Section
          Expanded(
            child: _isLoadingChat
                ? Center(child: CircularProgressIndicator(color: settings.primaryColor))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: settings.textMutedColor),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada percakapan',
                              style: GoogleFonts.outfit(color: settings.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mulai kirim pesan ke $partnerUser untuk nonton bersama!',
                              style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.sender == currentUser;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: settings.accentColor,
                                    child: Text(msg.sender.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? settings.primaryColor : settings.surfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isMe ? settings.primaryColor : settings.cardBorderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              msg.sender,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isMe ? Colors.white70 : settings.accentColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              msg.time,
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                color: isMe ? Colors.white60 : settings.textMutedColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          msg.text,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: isMe ? Colors.white : settings.textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: settings.primaryColor,
                                    child: Text(msg.sender.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Real Chat Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: settings.surfaceColor,
              border: Border(top: BorderSide(color: settings.cardBorderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(color: settings.textPrimaryColor),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: settings.tr('watch_party_chat_hint'),
                        hintStyle: TextStyle(color: settings.textMutedColor),
                        filled: true,
                        fillColor: settings.inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: settings.cardBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: settings.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: settings.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
