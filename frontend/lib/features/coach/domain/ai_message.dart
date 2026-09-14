enum AiMessageRole { user, assistant }

enum AiMessageStatus { pending, completed, failed, cancelled }

class AiMessage {
  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final AiMessageRole role;
  final String content;
  final AiMessageStatus status;
  final DateTime createdAt;

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'] as String,
      role: json['role'] == 'assistant' ? AiMessageRole.assistant : AiMessageRole.user,
      content: json['content'] as String? ?? '',
      status: _statusFromString(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static AiMessageStatus _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return AiMessageStatus.pending;
      case 'failed':
        return AiMessageStatus.failed;
      case 'cancelled':
        return AiMessageStatus.cancelled;
      default:
        return AiMessageStatus.completed;
    }
  }

  AiMessage copyWith({String? content, AiMessageStatus? status}) {
    return AiMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
