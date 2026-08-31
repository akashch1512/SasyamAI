import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../config/theme.dart';
import '../models/chat_model.dart';
import 'assistant_avatar.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessageModel message;
  final Function(String)? onActionSelected;
  final VoidCallback? onTypingProgress;

  const ChatBubble({
    super.key,
    required this.message,
    this.onActionSelected,
    this.onTypingProgress,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  Timer? _typingTimer;
  late String _visibleContent;
  List<String> _words = const [];
  int _wordIndex = 0;

  bool get _isTyping => _wordIndex < _words.length;

  @override
  void initState() {
    super.initState();
    _visibleContent = widget.message.content;
    final isFreshReply =
        DateTime.now().difference(widget.message.createdAt).inSeconds < 15;
    if (!widget.message.isUser &&
        isFreshReply &&
        widget.message.content.isNotEmpty) {
      // Keep the whitespace with each word. String.split would discard it,
      // causing text to run together while the answer is revealed.
      _words = RegExp(r'\S+\s*')
          .allMatches(widget.message.content)
          .map((match) => match.group(0)!)
          .toList();
      _visibleContent = _words.first;
      _wordIndex = 1;
      _typingTimer = Timer.periodic(const Duration(milliseconds: 24), (timer) {
        if (!mounted || _wordIndex >= _words.length) {
          timer.cancel();
          return;
        }
        // Small batches keep longer answers natural without making them feel slow.
        final batchSize = _words.length > 240
            ? 3
            : _words.length > 120
            ? 2
            : 1;
        setState(() {
          final end = (_wordIndex + batchSize).clamp(0, _words.length) as int;
          _visibleContent += _words.sublist(_wordIndex, end).join();
          _wordIndex = end;
        });
        widget.onTypingProgress?.call();
        if (_wordIndex >= _words.length) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isUser) {
      return _buildUserBubble(context);
    }
    return _buildAssistantBubble(context);
  }

  Widget _buildUserBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.userBubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.message.imageUrl!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 200,
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    widget.message.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryGreen,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssistantAvatar(size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppTheme.borderGrey, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isTyping)
                    Text(
                      _visibleContent,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: AppTheme.textDark,
                        height: 1.5,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: _visibleContent,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14.5,
                          color: AppTheme.textDark,
                          height: 1.5,
                        ),
                        h1: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        h3: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                        h4: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        listBullet: const TextStyle(
                          color: AppTheme.primaryGreen,
                        ),
                        blockquote: const TextStyle(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: AppTheme.paleGreen,
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(
                              color: AppTheme.primaryGreen,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isTyping)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 5,
                        height: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: AppTheme.lightGreen),
                        ),
                      ),
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
