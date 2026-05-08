enum AiChatRole { user, assistant }

enum AiChatStatus { sending, sent, failed }

class AiChatMessage {
  final String id;
  final AiChatRole role;
  final String text;
  final DateTime createdAt;
  final AiChatStatus status;

  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = AiChatStatus.sent,
  });

  bool get isUser => role == AiChatRole.user;

  AiChatMessage copyWith({
    String? id,
    AiChatRole? role,
    String? text,
    DateTime? createdAt,
    AiChatStatus? status,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toApiJson() => {
    'role': isUser ? 'user' : 'assistant',
    'content': text,
  };
}
