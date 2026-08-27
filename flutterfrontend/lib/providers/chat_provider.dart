import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_constants.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<ChatSessionModel> _sessions = [];
  String? _activeSessionId;
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  List<String> _suggestedActions = [
    "Recommend crops for my farm",
    "How to manage yellow leaf disease?",
    "Check mandi price of wheat",
    "Government subsidies for drip irrigation",
  ];

  List<ChatSessionModel> get sessions => _sessions;
  String? get activeSessionId => _activeSessionId;
  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  List<String> get suggestedActions => _suggestedActions;

  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().get(ApiConstants.chatSessionsEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _sessions = data.map((s) => ChatSessionModel.fromJson(s as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectSession(String sessionId) async {
    _activeSessionId = sessionId;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().get('${ApiConstants.chatSessionsEndpoint}/$sessionId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final session = ChatSessionModel.fromJson(data);
        _messages = session.messages;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void startNewChat() {
    _activeSessionId = null;
    _messages = [
      ChatMessageModel(
        id: 'welcome',
        sessionId: '',
        role: 'assistant',
        content: 'Namaste! 🙏 I am SasyamAI, your dedicated agricultural assistant.\n\nHow can I help you with your farm today? You can ask about crop recommendations, upload leaf photos for disease diagnosis, or inquire about farm management practices.',
        createdAt: DateTime.now(),
      ),
    ];
    _suggestedActions = [
      "Recommend crops for my farm",
      "How to manage yellow leaf disease?",
      "Check mandi price of wheat",
      "Government subsidies for drip irrigation",
    ];
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String text,
    String? imageUrl,
    String? audioTranscription,
  }) async {
    if (text.trim().isEmpty && imageUrl == null) return false;

    // Append optimistic user message
    final optimisticUserMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _activeSessionId ?? '',
      role: 'user',
      content: text,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    _messages.add(optimisticUserMsg);
    _isSending = true;
    notifyListeners();

    try {
      final payload = {
        'session_id': _activeSessionId,
        'content': text,
        'image_url': imageUrl,
        'audio_transcription': audioTranscription,
      };

      final response = await ApiService().post(
        ApiConstants.chatMessageEndpoint,
        body: payload,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _activeSessionId = data['session_id'] as String?;

        final assistantMsg = ChatMessageModel.fromJson(data['assistant_message'] as Map<String, dynamic>);
        _messages.add(assistantMsg);

        final rawActions = data['suggested_actions'] as List<dynamic>?;
        if (rawActions != null && rawActions.isNotEmpty) {
          _suggestedActions = rawActions.map((e) => e.toString()).toList();
        }

        // Refresh session list
        fetchSessions();

        _isSending = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Append fallback error response
      _messages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: _activeSessionId ?? '',
          role: 'assistant',
          content: 'I apologize, but I encountered an error connecting to the agricultural server. Please check your network connection and try again.',
          createdAt: DateTime.now(),
        ),
      );
    }

    _isSending = false;
    notifyListeners();
    return false;
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await ApiService().delete('${ApiConstants.chatSessionsEndpoint}/$sessionId');
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_activeSessionId == sessionId) {
        startNewChat();
      } else {
        notifyListeners();
      }
    } catch (_) {}
  }
}
