import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_course_catalog_minimal_page.dart';
import 'package:shared_core/shared_core.dart';

/// This is the *live* course catalog variant (the other,
/// student_course_catalog_page.dart, is only reachable through the
/// compile-time-disabled /prototype/* route table, per the 2026-09-07
/// audit). Used directly by the real student navigation shell.

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'วิทยาศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

const _detail = CourseDetail(
  id: 'course-1',
  subjectName: 'วิทยาศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  description: null,
  status: 'active',
  termId: 'term-1',
  teacherNames: 'ครูสมศรี',
);

const _lesson = LessonSummary(
  id: 'lesson-1',
  title: 'บทที่ 1',
  status: 'published',
  publishedAt: null,
);

const _assignment = AssignmentSummary(
  id: 'asg-1',
  type: 'homework',
  title: 'แบบฝึกหัด',
  dueAt: null,
  status: 'published',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<CourseDetail> Function(String courseId)? getCourse,
  Future<List<LessonSummary>> Function(String courseId)? listLessons,
  Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse,
  Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadSubmissionVersions,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentCourseCatalogMinimalPage(
        loadCourses: loadCourses ?? () async => const [_course],
        getCourse: getCourse ?? (_) async => _detail,
        listLessons: listLessons ?? (_) async => const [_lesson],
        loadAssignmentsForCourse:
            loadAssignmentsForCourse ?? (_) async => const [_assignment],
        loadSubmissionVersions: loadSubmissionVersions ?? (_) async => const [],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a real course shows the real teacher name and lesson/assignment counts, not fabricated data', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('วิทยาศาสตร์'), findsWidgets);
    expect(find.textContaining('ครูสมศรี'), findsOneWidget);
    expect(find.text('1 วิชา'), findsOneWidget);
  });

  testWidgets('submission progress reflects the real submission count, not an invented total', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSubmissionVersions: (assignmentId) async {
        expect(assignmentId, 'asg-1');
        return [
          SubmissionVersion(
            version: 1,
            content: 'ทำแล้ว',
            submittedAt: DateTime(2026, 9, 1),
            submissionVersionId: 'sv-1',
          ),
        ];
      },
    );
    expect(find.text('100%'), findsOneWidget);
    expect(find.textContaining('ส่งครบแล้ว'), findsOneWidget);
  });

  testWidgets('zero real courses shows an honest empty state, not fabricated ones', (
    tester,
  ) async {
    await _pump(tester, loadCourses: () async => const []);
    expect(find.text('0 วิชา'), findsOneWidget);
  });

  testWidgets('a real load failure shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      loadCourses: () async =>
          throw StateError('backend detail that must stay internal'),
    );
    expect(find.textContaining('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });
}
