class NotificationCategory {
  NotificationCategory.fromRow(Map<String, dynamic> r)
    : category = r['category'] as String,
      total = (r['total'] as num).toInt(),
      unread = (r['unread'] as num).toInt();
  final String category;
  final int total, unread;
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? category;
  final Map<String, dynamic> payload;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.createdAt,
    this.readAt,
    this.category,
    this.payload = const {},
  });

  factory AppNotification.fromRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      body: row['body'] as String?,
      category: row['category'] as String?,
      payload: row['payload'] is Map
          ? Map<String, dynamic>.from(row['payload'] as Map)
          : const {},
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] != null
          ? DateTime.parse(row['read_at'] as String)
          : null,
    );
  }

  bool get isUnread => readAt == null;
}
