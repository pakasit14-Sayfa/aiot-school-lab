class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      body: row['body'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] != null ? DateTime.parse(row['read_at'] as String) : null,
    );
  }

  bool get isUnread => readAt == null;
}
