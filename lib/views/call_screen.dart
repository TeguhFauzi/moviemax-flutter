import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/call_provider.dart';
import '../services/firebase_call_service.dart';

/// Reads all state from [CallProvider], so caller and receiver render the same
/// status, duration, and layout from the shared Firebase session.
class CallScreen extends StatelessWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);

    final currentUser = callProvider.currentUser.isEmpty ? '?' : callProvider.currentUser;
    final targetUser = callProvider.partnerUser.isEmpty ? '?' : callProvider.partnerUser;
    final isConnected = callProvider.isConnected;
    final isVideo = callProvider.callType == CallType.video && callProvider.isCameraOn;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A), // WhatsApp Dark Theme Color
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo && isConnected)
            _buildPartnerVideoView(targetUser)
          else
            _buildVoiceCallWallpaper(),

          // Floating PIP self camera view during an active video call
          if (isVideo && isConnected)
            Positioned(
              top: 50,
              right: 16,
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xFF1F2C34),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF00A884),
                              child: Text(
                                currentUser.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentUser,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(
                            callProvider.isFrontCamera
                                ? Icons.cameraswitch_rounded
                                : Icons.camera_rear_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Header: encryption badge, partner name, shared status/duration
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, color: Color(0xFF00A884), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Terkripsi End-to-End Firebase',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00A884),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      targetUser,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      callProvider.statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isConnected ? const Color(0xFF25D366) : Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center avatar for voice mode / while ringing
          if (!isVideo || !isConnected)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00A884).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFF00A884).withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: const Color(0xFF00A884),
                      child: Text(
                        targetUser.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (callProvider.isOutgoing) ...[
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF00A884)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Bottom control panel
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C34).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: callProvider.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      isActive: callProvider.isMuted,
                      onTap: callProvider.toggleMute,
                    ),
                    _buildControlButton(
                      icon: callProvider.isCameraOn
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      isActive: callProvider.isCameraOn,
                      onTap: callProvider.toggleCamera,
                    ),
                    if (callProvider.isCameraOn)
                      _buildControlButton(
                        icon: Icons.cameraswitch_rounded,
                        isActive: false,
                        onTap: callProvider.switchCamera,
                      ),
                    _buildControlButton(
                      icon: callProvider.isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      isActive: callProvider.isSpeakerOn,
                      onTap: callProvider.toggleSpeaker,
                    ),
                    // Ends the shared session; both devices leave this screen
                    // when the terminal state propagates.
                    FloatingActionButton(
                      heroTag: 'endCallBtn',
                      backgroundColor: const Color(0xFFEA4335),
                      elevation: 4,
                      onPressed: () => callProvider.endCall(),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerVideoView(String partner) {
    return Container(
      color: const Color(0xFF111B21),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F2C34), Color(0xFF0B141A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF00A884),
              child: Text(
                partner.substring(0, 1).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kamera HD Partner ($partner) Aktif',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCallWallpaper() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF111B21),
            Color(0xFF0B141A),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF111B21) : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
