class AiConversation {
  const AiConversation({
    required this.id,
    required this.title,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
  });

  final String id;
  final String title;
  final String model;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'New Chat',
      model: json['model'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
    );
  }

  AiConversation copyWith({String? title, DateTime? lastMessageAt}) {
    return AiConversation(
      id: id,
      title: title ?? this.title,
      model: model,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
