import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/parent_portal_model.dart';

void main() {
  test('attendance without a status remains unknown', () {
    final item = StudentAttendanceItem.fromRow({
      'record_id': 'attendance-1',
      'course_id': 'course-1',
      'course_name': 'คณิตศาสตร์',
      'course_code': 'MATH101',
      'class_date': '2026-09-08',
      'marked_at': '2026-09-08T08:00:00Z',
    });

    expect(item.status, 'unknown');
    expect(item.isPresent, isFalse);
  });
}
