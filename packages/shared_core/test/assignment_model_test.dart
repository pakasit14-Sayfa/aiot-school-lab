import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/assignment_model.dart';

void main() {
  group('AssignmentSummary.fromRow', () {
    test('parses a published assignment', () {
      final summary = AssignmentSummary.fromRow({
        'assignment_id': 'assign-1',
        'type': 'homework',
        'title': 'สำรวจคุณภาพอากาศ',
        'due_at': '2026-08-01T09:00:00Z',
        'status': 'published',
      });

      expect(summary.isPublished, isTrue);
      expect(summary.dueAt, DateTime.utc(2026, 8, 1, 9, 0, 0));
    });

    test('handles a null due_at', () {
      final summary = AssignmentSummary.fromRow({
        'assignment_id': 'assign-1',
        'type': 'project',
        'title': 'โครงงาน',
        'due_at': null,
        'status': 'draft',
      });

      expect(summary.isPublished, isFalse);
      expect(summary.dueAt, isNull);
    });
  });

  group('AssignmentDetail.fromRow', () {
    test('parses nested sensor_datasets jsonb array', () {
      final detail = AssignmentDetail.fromRow({
        'assignment_id': 'assign-1',
        'course_id': 'course-1',
        'type': 'homework',
        'title': 'สำรวจคุณภาพอากาศ',
        'instructions': 'บันทึกค่าฝุ่น PM2.5',
        'due_at': '2026-08-01T09:00:00Z',
        'status': 'published',
        'sensor_datasets': [
          {
            'id': 'dataset-1',
            'device_id': 'device-1',
            'metric': 'pm25',
            'time_start': '2026-07-25T00:00:00Z',
            'time_end': '2026-08-01T00:00:00Z',
            'label': 'ค่าฝุ่นสัปดาห์นี้',
          },
        ],
      });

      expect(detail.sensorDatasets, hasLength(1));
      expect(detail.sensorDatasets.first.metric, 'pm25');
      expect(detail.isPublished, isTrue);
    });

    test('handles an empty sensor_datasets array', () {
      final detail = AssignmentDetail.fromRow({
        'assignment_id': 'assign-1',
        'course_id': 'course-1',
        'type': 'worksheet',
        'title': 'ใบงาน',
        'instructions': null,
        'due_at': null,
        'status': 'draft',
        'sensor_datasets': [],
      });

      expect(detail.sensorDatasets, isEmpty);
      expect(detail.isPublished, isFalse);
    });
  });

  group('SubmissionVersion.fromRow', () {
    test('parses a submitted version', () {
      final version = SubmissionVersion.fromRow({
        'version': 2,
        'content': 'แก้ไข: ค่าเฉลี่ย PM2.5 คือ 30',
        'submitted_at': '2026-08-01T10:00:00Z',
      });

      expect(version.version, 2);
      expect(version.content, 'แก้ไข: ค่าเฉลี่ย PM2.5 คือ 30');
    });
  });

  group('SubmissionRoster.fromRow', () {
    test('combines student name and exposes latest content', () {
      final roster = SubmissionRoster.fromRow({
        'submission_id': 'sub-1',
        'student_id': 'student-1',
        'student_first_name': 'Student',
        'student_last_name': 'One',
        'status': 'submitted',
        'current_version': 2,
        'latest_content': 'แก้ไข: ค่าเฉลี่ย PM2.5 คือ 30',
        'submitted_at': '2026-08-01T10:00:00Z',
      });

      expect(roster.studentFullName, 'Student One');
      expect(roster.currentVersion, 2);
    });
  });

  group('AssignmentFeedback.fromRow', () {
    test('combines author name', () {
      final feedback = AssignmentFeedback.fromRow({
        'feedback_id': 'feedback-1',
        'author_first_name': 'Teacher',
        'author_last_name': 'A',
        'body': 'ทำได้ดีมาก',
        'created_at': '2026-08-01T11:00:00Z',
      });

      expect(feedback.authorFullName, 'Teacher A');
      expect(feedback.body, 'ทำได้ดีมาก');
    });
  });
}
