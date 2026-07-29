import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/course_file_model.dart';

void main() {
  group('CourseFile.fromRow', () {
    test('combines uploader name and formats a small size in KB', () {
      final file = CourseFile.fromRow({
        'file_id': 'file-1',
        'storage_path': 'course-1/lab-manual.pdf',
        'file_name': 'lab-manual.pdf',
        'size_bytes': 204800,
        'uploaded_by': 'teacher-1',
        'uploader_first_name': 'Teacher',
        'uploader_last_name': 'A',
        'created_at': '2026-07-31T09:00:00Z',
      });

      expect(file.uploaderFullName, 'Teacher A');
      expect(file.formattedSize, '200.0 KB');
    });

    test('formats a large size in MB', () {
      final file = CourseFile.fromRow({
        'file_id': 'file-1',
        'storage_path': 'course-1/slides.pptx',
        'file_name': 'slides.pptx',
        'size_bytes': 6 * 1024 * 1024,
        'uploaded_by': 'teacher-1',
        'uploader_first_name': 'Teacher',
        'uploader_last_name': 'A',
        'created_at': '2026-07-31T09:00:00Z',
      });

      expect(file.formattedSize, '6.0 MB');
    });

    test('formats a tiny size in bytes', () {
      final file = CourseFile.fromRow({
        'file_id': 'file-1',
        'storage_path': 'course-1/tiny.txt',
        'file_name': 'tiny.txt',
        'size_bytes': 42,
        'uploaded_by': 'teacher-1',
        'uploader_first_name': 'Teacher',
        'uploader_last_name': 'A',
        'created_at': '2026-07-31T09:00:00Z',
      });

      expect(file.formattedSize, '42 B');
    });
  });
}
