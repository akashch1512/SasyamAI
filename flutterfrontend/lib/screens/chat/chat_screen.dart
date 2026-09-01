import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/tts_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/assistant_avatar.dart';
import '../../widgets/chat_bottom_bar.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/feature_showcase.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'components/chat_history_sheet.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  int _navIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.fetchSessions();
      if (chat.messages.isEmpty && chat.activeSessionId == null) {
        chat.startNewChat();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSendMessage(String text, String? imageUrl) async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _scrollToBottom();
    final ok = await chat.sendMessage(text: text, imageUrl: imageUrl);
    _scrollToBottom();
    if (!ok || !mounted) return;

    final reply = chat.messages.lastWhere(
      (m) => !m.isUser,
      orElse: () => chat.messages.last,
    );
    if (!reply.isUser) {
      await TtsService.instance.speak(
        text: reply.content,
        languageCode: auth.currentUser?.preferredLanguage ?? 'hi-IN',
        messageId: reply.id,
      );
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final showFeatures = !chat.hasStartedChat && !chat.isSending;

    return Scaffold(
      backgroundColor: AppTheme.warmSand,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppLogo(size: 30, fontSize: 18),
        actions: [
          if (user?.isAdmin ?? false)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.shield_rounded,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
              label: const Text(
                'Admin',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.paleGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: chat.isLoading
                  ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : showFeatures
                  ? FeatureShowcase(
                      key: const ValueKey('features'),
                      farmerName: user?.fullName.split(' ').first ?? '',
                      onFeatureSelected: (prompt) =>
                          _onSendMessage(prompt, null),
                    )
                  : ListView.builder(
                      key: const ValueKey('messages'),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount:
                          chat.messages.length + (chat.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chat.messages.length && chat.isSending) {
                          return _buildThinkingIndicator();
                        }
                        final message = chat.messages[index];
                        return ChatBubble(
                          key: ValueKey(message.id),
                          message: message,
                          onTypingProgress: _scrollToBottom,
                          onActionSelected: (action) =>
                              _onSendMessage(action, null),
                          isSpeaking:
                              TtsService.instance.speakingMessageId ==
                              message.id,
                          onSpeak: message.isUser
                              ? null
                              : () async {
                                  await TtsService.instance.toggle(
                                    text: message.content,
                                    languageCode:
                                        user?.preferredLanguage ?? 'hi-IN',
                                    messageId: message.id,
                                  );
                                  if (mounted) setState(() {});
                                },
                        );
                      },
                    ),
            ),
          ),
          if (chat.suggestedActions.isNotEmpty &&
              !chat.isSending &&
              chat.hasStartedChat)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: chat.suggestedActions.length,
                itemBuilder: (context, index) {
                  final action = chat.suggestedActions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(
                        action,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textDark,
                        ),
                      ),
                      backgroundColor: AppTheme.surfaceWhite,
                      side: const BorderSide(color: AppTheme.borderGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () => _onSendMessage(action, null),
                    ),
                  );
                },
              ),
            ),
          ChatInputBar(
            onSendMessage: _onSendMessage,
            isSending: chat.isSending,
            preferredLanguage: user?.preferredLanguage ?? 'hi-IN',
          ),
        ],
      ),
      bottomNavigationBar: ChatBottomBar(
        currentIndex: _navIndex,
        profileImageUrl: user?.profileImageUrl,
        onHistory: () {
          setState(() => _navIndex = 0);
          showChatHistorySheet(context);
        },
        onNewChat: () {
          setState(() => _navIndex = 1);
          chat.startNewChat();
        },
        onProfile: () {
          setState(() => _navIndex = 2);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssistantAvatar(size: 30),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'SasyamAI is analyzing farm data...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
