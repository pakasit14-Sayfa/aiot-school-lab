import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/lesson_model.dart';

void main() {
  group('LessonSummary.fromRow', () {
    test('a draft lesson has no published_at', () {
      final lesson = LessonSummary.fromRow({
        'lesson_id': 'lesson-1',
        'title': 'Air Quality 101',
        'status': 'draft',
        'published_at': null,
      });

      expect(lesson.isPublished, isFalse);
      expect(lesson.publishedAt, isNull);
    });

    test('a published lesson parses published_at', () {
      final lesson = LessonSummary.fromRow({
        'lesson_id': 'lesson-1',
        'title': 'Air Quality 101',
        'status': 'published',
        'published_at': '2026-07-24T09:00:00Z',
      });

      expect(lesson.isPublished, isTrue);
      expect(lesson.publishedAt, DateTime.utc(2026, 7, 24, 9, 0, 0));
    });
  });

  group('LessonDetail.fromRow', () {
    test('parses nested materials and sensor_links jsonb arrays', () {
      final lesson = LessonDetail.fromRow({
        'lesson_id': 'lesson-1',
        'course_id': 'course-1',
        'title': 'Air Quality 101',
        'content': {'body': 'intro text'},
        'status': 'published',
        'published_at': '2026-07-24T09:00:00Z',
        'materials': [
          {
            'id': 'material-1',
            'type': 'video',
            'title': 'Intro video',
            'url': 'https://example.test/video.mp4',
            'sort_order': 0,
          },
        ],
        'sensor_links': [
          {
            'id': 'link-1',
            'device_id': 'device-1',
            'metric': 'pm25',
            'time_start': '2026-07-23T00:00:00Z',
            'time_end': '2026-07-24T00:00:00Z',
            'caption': 'ค่าฝุ่นเมื่อวาน',
          },
        ],
        'progress_pct': 40,
        'completed': false,
      });

      expect(lesson.content?['body'], 'intro text');
      expect(lesson.materials, hasLength(1));
      expect(lesson.materials.first.url, 'https://example.test/video.mp4');
      expect(lesson.sensorLinks, hasLength(1));
      expect(lesson.sensorLinks.first.metric, 'pm25');
      expect(lesson.sensorLinks.first.caption, 'ค่าฝุ่นเมื่อวาน');
      expect(lesson.progressPct, 40);
      expect(lesson.completed, isFalse);
    });

    test('handles empty materials/sensor_links arrays and null progress', () {
      final lesson = LessonDetail.fromRow({
        'lesson_id': 'lesson-1',
        'course_id': 'course-1',
        'title': 'Air Quality 101',
        'content': null,
        'status': 'draft',
        'published_at': null,
        'materials': [],
        'sensor_links': [],
        'progress_pct': null,
        'completed': null,
      });

      expect(lesson.materials, isEmpty);
      expect(lesson.sensorLinks, isEmpty);
      expect(lesson.progressPct, isNull);
      expect(lesson.completed, isNull);
    });
  });

  group('DeviceOption.fromRow', () {
    test('parses a list_school_devices result', () {
      final device = DeviceOption.fromRow({
        'device_id': 'device-1',
        'name': 'Classroom PM2.5',
        'type': 'pm25_sensor',
        'location': 'Room 301',
        'status': 'online',
      });

      expect(device.id, 'device-1');
      expect(device.name, 'Classroom PM2.5');
      expect(device.location, 'Room 301');
    });
  });
}
