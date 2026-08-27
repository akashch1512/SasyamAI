class ChatMessageModel {
  final String id;
  final String sessionId;
  final String role; // 'user' | 'assistant'
  final String content;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      metadata: json['metadata_json'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'image_url': imageUrl,
      'metadata_json': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatSessionModel {
  final String id;
  final int userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final List<ChatMessageModel> messages;

  ChatSessionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.messages = const [],
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    var rawMessages = json['messages'] as List<dynamic>? ?? [];
    List<ChatMessageModel> parsedMessages = rawMessages
        .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return ChatSessionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as int? ?? 0,
      title: json['title'] as String? ?? 'New Conversation',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messageCount: json['message_count'] as int? ?? parsedMessages.length,
      messages: parsedMessages,
    );
  }
}
