import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../services/firebase_call_service.dart';
import '../widgets/settings_toggles.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ChatProvider>(context, listen: false).setThreadOpen(true);
      _scrollToBottom();
    });
  }

  void _startCall(CallType type) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final currentUser = authProvider.userName;
    final partnerUser = ChatProvider.resolvePartner(currentUser);
    if (currentUser.isEmpty || (chatProvider.threadId ?? '').isEmpty) return;

    callProvider.startCall(
      caller: currentUser,
      receiver: partnerUser,
      type: type,
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
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

    _chatController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  void dispose() {
    Provider.of<ChatProvider>(context, listen: false).setThreadOpen(false);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    final currentUser = authProvider.userName;
    final partnerUser = ChatProvider.resolvePartner(currentUser);

    final messages = chatProvider.messages;
    final isLoading = chatProvider.isLoading;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.surfaceColor,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: settings.primaryColor,
              child: Text(
                partnerUser.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerUser,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: settings.textPrimaryColor,
                  ),
                ),
                // Reflects the real Firestore session instead of a fixed label.
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: chatProvider.isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatProvider.isConnected
                          ? 'Online • Firestore Sync'
                          : 'Menyambungkan…',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: chatProvider.isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // WhatsApp Voice Call Icon Button
          IconButton(
            icon: Icon(Icons.call_rounded, color: settings.accentColor, size: 22),
            tooltip: 'Voice Call',
            onPressed: () => _startCall(CallType.voice),
          ),

          // WhatsApp Video Call Icon Button
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: settings.primaryColor, size: 24),
            tooltip: 'Video Call',
            onPressed: () => _startCall(CallType.video),
          ),

          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SettingsToggles(compact: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: settings.primaryColor))
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_rounded, size: 64, color: settings.textMutedColor),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada percakapan dengan $partnerUser',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: settings.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ketik pesan di bawah untuk memulai obrolan Firebase!',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: settings.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
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
                                    child: Text(
                                      msg.sender.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
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
                                    child: Text(
                                      msg.sender.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Input Field Bar
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
                        hintText: 'Ketik pesan ke $partnerUser...',
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

