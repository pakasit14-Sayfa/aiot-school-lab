import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/course_model.dart';

void main() {
  group('CourseSummary.fromRow', () {
    test('parses required and nullable fields from an RPC row', () {
      final course = CourseSummary.fromRow({
        'course_id': 'course-1',
        'subject_name': 'Environmental Science',
        'grade_level': 'M.3',
        'room': '301',
        'status': 'active',
        'term_id': 'term-1',
      });

      expect(course.id, 'course-1');
      expect(course.subjectName, 'Environmental Science');
      expect(course.gradeLevel, 'M.3');
      expect(course.room, '301');
      expect(course.isActive, isTrue);
    });

    test('a closed course is not active', () {
      final course = CourseSummary.fromRow({
        'course_id': 'course-1',
        'subject_name': 'Math',
        'grade_level': null,
        'room': null,
        'status': 'closed',
        'term_id': 'term-1',
      });

      expect(course.isActive, isFalse);
      expect(course.gradeLevel, isNull);
    });
  });

  group('CourseStudent.fromRow', () {
    test('combines first and last name and parses the timestamp', () {
      final student = CourseStudent.fromRow({
        'student_id': 'student-1',
        'first_name': 'Student',
        'last_name': 'One',
        'email': 'student1@school.test',
        'enrolled_at': '2026-07-20T10:00:00Z',
      });

      expect(student.fullName, 'Student One');
      expect(student.enrolledAt, DateTime.utc(2026, 7, 20, 10, 0, 0));
    });
  });

  group('StudentLookup.fromRow', () {
    test('parses a find_student_by_email result', () {
      final student = StudentLookup.fromRow({
        'student_id': 'student-1',
        'first_name': 'Student',
        'last_name': 'Two',
        'email': 'student2@school.test',
      });

      expect(student.fullName, 'Student Two');
      expect(student.email, 'student2@school.test');
    });
  });

  group('TermOption.fromRow', () {
    test('parses a list_terms result', () {
      final term = TermOption.fromRow({
        'term_id': 'term-1',
        'term_name': 'Term 1/2026',
        'academic_year_name': '2026',
      });

      expect(term.id, 'term-1');
      expect(term.name, 'Term 1/2026');
      expect(term.academicYearName, '2026');
    });
  });
}
