class ChatMessage {
  final int? id;
  final String role; // 'user' atau 'ai'
  final String text;
  final String? createdAt;

  ChatMessage({
    this.id,
    required this.role,
    required this.text,
    this.createdAt,
  });

  // Dari Map (hasil query SQLite) ke Object
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      role: map['role'] ?? 'user',
      text: map['text'] ?? '',
      createdAt: map['created_at'],
    );
  }

  // Dari Object ke Map (buat insert/update ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'role': role,
      'text': text,
    };
  }

  // Convert to Map untuk display di UI (sesuai format yang dipakai chat_screen)
  Map<String, String> toUIMap() {
    return {
      'role': role,
      'text': text,
    };
  }
}
