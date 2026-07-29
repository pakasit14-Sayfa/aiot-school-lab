class PostReply {
  final String id;
  final String authorId;
  final String authorFirstName;
  final String authorLastName;
  final String body;
  final DateTime createdAt;

  const PostReply({
    required this.id,
    required this.authorId,
    required this.authorFirstName,
    required this.authorLastName,
    required this.body,
    required this.createdAt,
  });

  factory PostReply.fromJson(Map<String, dynamic> json) => PostReply(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    authorFirstName: json['author_first_name'] as String,
    authorLastName: json['author_last_name'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );

  String get authorFullName => '$authorFirstName $authorLastName';
}

class CoursePost {
  final String id;
  final String authorId;
  final String authorFirstName;
  final String authorLastName;
  final String body;
  final bool isPinned;
  final DateTime createdAt;
  final List<PostReply> replies;

  const CoursePost({
    required this.id,
    required this.authorId,
    required this.authorFirstName,
    required this.authorLastName,
    required this.body,
    required this.isPinned,
    required this.createdAt,
    required this.replies,
  });

  factory CoursePost.fromRow(Map<String, dynamic> row) {
    final replies = (row['replies'] as List? ?? [])
        .map((item) => PostReply.fromJson(item as Map<String, dynamic>))
        .toList();

    return CoursePost(
      id: row['post_id'] as String,
      authorId: row['author_id'] as String,
      authorFirstName: row['author_first_name'] as String,
      authorLastName: row['author_last_name'] as String,
      body: row['body'] as String,
      isPinned: row['is_pinned'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      replies: replies,
    );
  }

  String get authorFullName => '$authorFirstName $authorLastName';
}
