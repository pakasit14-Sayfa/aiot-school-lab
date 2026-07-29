import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/grade_model.dart';

void main() {
  group('CourseGrade.fromRow', () {
    test('parses a confirmed grade and computes percent', () {
      final grade = CourseGrade.fromRow({
        'grade_id': 'grade-1',
        'course_id': 'course-1',
        'subject_name': 'Environmental Science',
        'score': 18,
        'max_score': 20,
        'confirmed_at': '2026-07-30T09:00:00Z',
      });

      expect(grade.percent, 90);
      expect(grade.confirmedAt, DateTime.utc(2026, 7, 30, 9, 0, 0));
    });

    test('handles a null confirmed_at', () {
      final grade = CourseGrade.fromRow({
        'grade_id': 'grade-1',
        'course_id': 'course-1',
        'subject_name': 'Math',
        'score': 0,
        'max_score': 100,
        'confirmed_at': null,
      });

      expect(grade.confirmedAt, isNull);
      expect(grade.percent, 0);
    });
  });

  group('GradeRecord.fromRow', () {
    test('combines student name and exposes CoI/status flags', () {
      final record = GradeRecord.fromRow({
        'grade_id': 'grade-1',
        'student_id': 'student-1',
        'student_first_name': 'Student',
        'student_last_name': 'One',
        'score': 15,
        'max_score': 20,
        'status': 'confirmed',
        'coi_flag': true,
        'coi_review_status': 'pending',
        'confirmed_at': '2026-07-30T09:00:00Z',
      });

      expect(record.studentFullName, 'Student One');
      expect(record.isConfirmed, isTrue);
      expect(record.coiFlag, isTrue);
      expect(record.coiReviewStatus, 'pending');
    });

    test('a draft grade is not confirmed', () {
      final record = GradeRecord.fromRow({
        'grade_id': 'grade-1',
        'student_id': 'student-1',
        'student_first_name': 'Student',
        'student_last_name': 'Two',
        'score': 10,
        'max_score': 20,
        'status': 'draft',
        'coi_flag': false,
        'coi_review_status': null,
        'confirmed_at': null,
      });

      expect(record.isConfirmed, isFalse);
      expect(record.coiFlag, isFalse);
    });
  });

  group('PendingCoiGrade.fromRow', () {
    test('parses a list_pending_coi_grades result', () {
      final pending = PendingCoiGrade.fromRow({
        'grade_id': 'grade-1',
        'student_first_name': 'Student',
        'student_last_name': 'Two',
        'course_id': 'course-1',
        'subject_name': 'Math',
        'graded_by': 'teacher-1',
        'score': 10,
        'max_score': 20,
        'status': 'confirmed',
      });

      expect(pending.studentFullName, 'Student Two');
      expect(pending.subjectName, 'Math');
    });
  });
}
