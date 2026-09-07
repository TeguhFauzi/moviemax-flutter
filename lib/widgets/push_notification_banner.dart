import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/call_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_call_service.dart';
import '../views/call_screen.dart';

/// Navigator key so the overlay can drive call routes from above the Navigator.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Route name used for the single, shared call screen instance.
const String callRouteName = '/active-call';

/// Hosts the chat push banner, the incoming-call banner, and the automatic
/// call-screen routing that keeps caller and receiver on the same screen.
class GlobalNotificationOverlay extends StatefulWidget {
  final Widget child;

  const GlobalNotificationOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<GlobalNotificationOverlay> createState() => _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState extends State<GlobalNotificationOverlay> {
  CallProvider? _callProvider;
  bool _callRouteOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<CallProvider>(context, listen: false);
    if (provider != _callProvider) {
      _callProvider?.removeListener(_handleCallState);
      _callProvider = provider;
      _callProvider!.addListener(_handleCallState);
    }
  }

  @override
  void dispose() {
    _callProvider?.removeListener(_handleCallState);
    super.dispose();
  }

  /// Opens the call screen once a call is live on this device and closes it
  /// as soon as the shared session terminates on either side.
  void _handleCallState() {
    final provider = _callProvider;
    if (provider == null) return;

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final shouldShowCallScreen = provider.isOutgoing || provider.isConnected;

    if (shouldShowCallScreen && !_callRouteOpen) {
      _callRouteOpen = true;
      navigator
          .push(
            MaterialPageRoute(
              settings: const RouteSettings(name: callRouteName),
              builder: (_) => const CallScreen(),
            ),
          )
          .then((_) => _callRouteOpen = false);
      return;
    }

    if (!provider.hasActiveCall && _callRouteOpen) {
      _callRouteOpen = false;
      navigator.popUntil((route) => route.settings.name != callRouteName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: _NotificationBannerContent(),
          ),
        ),
      ],
    );
  }
}

class _NotificationBannerContent extends StatelessWidget {
  const _NotificationBannerContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final callProvider = Provider.of<CallProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    // Incoming call outranks chat notifications.
    if (callProvider.isIncoming) {
      return _IncomingCallBanner(callProvider: callProvider);
    }

    final notif = chatProvider.activePushNotification;
    if (notif == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: settings.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF10B981),
              child: Text(
                notif.sender.isEmpty ? '?' : notif.sender.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '💬 ${notif.sender}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: settings.textPrimaryColor,
                        ),
                      ),
                      Text(
                        notif.time,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: settings.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: settings.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: settings.textMutedColor,
              onPressed: () => chatProvider.dismissNotification(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingCallBanner extends StatelessWidget {
  final CallProvider callProvider;

  const _IncomingCallBanner({Key? key, required this.callProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final caller = callProvider.partnerUser.isEmpty ? 'Seseorang' : callProvider.partnerUser;
    final isVideo = callProvider.callType == CallType.video;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                color: const Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Panggilan Masuk',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caller,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isVideo ? 'Panggilan Video Firebase...' : 'Panggilan Suara Firebase...',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Reject
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.call_end, color: Colors.white, size: 20),
              onPressed: () => callProvider.declineCall(),
            ),
            const SizedBox(width: 8),
            // Accept — routing to the call screen is handled by the overlay
            // once the shared session flips to `connected`.
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.call, color: Colors.white, size: 20),
              onPressed: () => callProvider.acceptCall(),
            ),
          ],
        ),
      ),
    );
  }
}
