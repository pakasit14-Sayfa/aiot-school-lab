import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/post_model.dart';

void main() {
  group('CoursePost.fromRow', () {
    test('parses nested replies jsonb array', () {
      final post = CoursePost.fromRow({
        'post_id': 'post-1',
        'author_id': 'teacher-1',
        'author_first_name': 'Teacher',
        'author_last_name': 'A',
        'body': '[ประกาศ] เตรียมรายงานผลค่าฝุ่น PM2.5',
        'is_pinned': true,
        'created_at': '2026-07-30T09:00:00Z',
        'replies': [
          {
            'id': 'reply-1',
            'author_id': 'student-1',
            'author_first_name': 'Student',
            'author_last_name': 'One',
            'body': 'รับทราบครับ',
            'created_at': '2026-07-30T10:00:00Z',
          },
        ],
      });

      expect(post.authorFullName, 'Teacher A');
      expect(post.isPinned, isTrue);
      expect(post.replies, hasLength(1));
      expect(post.replies.first.authorFullName, 'Student One');
    });

    test('handles an empty replies array', () {
      final post = CoursePost.fromRow({
        'post_id': 'post-1',
        'author_id': 'student-1',
        'author_first_name': 'Student',
        'author_last_name': 'One',
        'body': 'สอบถามครับ',
        'is_pinned': false,
        'created_at': '2026-07-30T09:00:00Z',
        'replies': [],
      });

      expect(post.replies, isEmpty);
      expect(post.isPinned, isFalse);
    });
  });
}
