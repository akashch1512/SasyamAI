import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/assistant_avatar.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input_bar.dart';
import '../admin/admin_dashboard_screen.dart';
import 'components/chat_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.fetchSessions();
      if (chat.messages.isEmpty) {
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

  void _onSendMessage(String text, String? imageUrl) async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    _scrollToBottom();
    await chat.sendMessage(text: text, imageUrl: imageUrl);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.warmSand,
      drawer: const ChatDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_open_rounded, color: AppTheme.textDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const AppLogo(size: 30, fontSize: 18),
        actions: [
          // Switch to Admin Dashboard button (visible for Admin)
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
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
            tooltip: 'New Conversation',
            onPressed: () {
              chat.startNewChat();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: chat.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : chat.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: chat.messages.length + (chat.isSending ? 1 : 0),
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
                      );
                    },
                  ),
          ),

          // Suggested Action Chips (if applicable)
          if (chat.suggestedActions.isNotEmpty && !chat.isSending)
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

          // Bottom Chat Input Bar
          ChatInputBar(
            onSendMessage: _onSendMessage,
            isSending: chat.isSending,
            preferredLanguage: user?.preferredLanguage ?? 'hi-IN',
          ),
        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.paleGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: AppTheme.primaryGreen,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your farm companion is ready',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ask about crops, prices, weather, or share a leaf photo for a quick diagnosis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
