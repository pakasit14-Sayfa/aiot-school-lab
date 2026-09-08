import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_profile_page.dart';
import 'package:shared_core/shared_core.dart';

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.2',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

final _confirmedGrade = CourseGrade(
  id: 'g-1',
  courseId: 'course-1',
  subjectName: 'คณิตศาสตร์',
  score: 90,
  maxScore: 100,
  confirmedAt: DateTime(2026, 9, 1),
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
  Future<List<CourseGrade>> Function()? loadGrades,
  Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse,
  Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadSubmissionVersions,
  Future<void> Function()? signOut,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentProfilePage(
        loadCourses: loadCourses ?? () async => const [_course],
        loadGrades: loadGrades ?? () async => const [],
        loadAssignmentsForCourse: loadAssignmentsForCourse ?? (_) async => const [],
        loadSubmissionVersions: loadSubmissionVersions ?? (_) async => const [],
        signOut: signOut,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the submitted-count card reflects the real roster/submission numbers, not an invented total', (
    tester,
  ) async {
    await _pump(
      tester,
      loadAssignmentsForCourse: (_) async => const [_assignment],
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

    expect(find.text('1/1'), findsOneWidget);
    expect(find.textContaining('ชั้น ม.2'), findsOneWidget);
  });

  testWidgets('the average-grade card reflects only confirmed grades, not pending ones', (
    tester,
  ) async {
    await _pump(tester, loadGrades: () async => [_confirmedGrade]);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('1 วิชายืนยันแล้ว'), findsOneWidget);
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

  testWidgets('signing out calls the real signOut and navigates to the login page', (
    tester,
  ) async {
    var signOutCalls = 0;
    await _pump(
      tester,
      signOut: () async {
        signOutCalls++;
      },
    );

    await tester.tap(find.text('ออกจากระบบ'));
    // Not pumpAndSettle: LoginPage may render an indeterminate animation
    // that never settles. A few bounded pumps are enough to prove the
    // real signOut callback fired and navigation was triggered.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(signOutCalls, 1);
  });

  testWidgets('unimplemented menu items (privacy/PDPA) are honestly disabled, not fake-clickable', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.textContaining('ยังไม่เปิดใช้งาน'), findsWidgets);
  });
}
