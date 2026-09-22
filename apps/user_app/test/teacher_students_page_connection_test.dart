import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_students_page.dart';
import 'package:shared_core/shared_core.dart';

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

final _student = CourseStudent(
  studentId: 's-1',
  firstName: 'สมชาย',
  lastName: 'ใจดี',
  email: 'somchai@test.local',
  enrolledAt: DateTime(2026, 5, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<CourseStudent>> Function(String courseId)? loadCourseStudents,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherStudentsPage(
        loadCourses: loadCourses ?? () async => const [_course],
        loadCourseStudents: loadCourseStudents ?? (_) async => [_student],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a real roster shows the real student name/email/room, not fabricated data',
    (tester) async {
      await _pump(tester);
      expect(find.text('สมชาย ใจดี'), findsOneWidget);
      expect(find.textContaining('somchai@test.local'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // total students + room count
    },
  );

  testWidgets('zero real students shows an honest empty state', (tester) async {
    await _pump(tester, loadCourseStudents: (_) async => const []);
    expect(find.text('ไม่พบนักเรียนในห้องที่เลือก'), findsOneWidget);
  });

  testWidgets(
    'a real load failure shows an honest error, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        loadCourses: () async =>
            throw StateError('backend detail that must stay internal'),
      );
      expect(find.text('โหลดรายชื่อนักเรียนไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );
}
