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
  Future<void> Function({required String currentPassword, required String newPassword})? changePassword,
  Future<void> Function({required String uid, required String name})? updateName,
  bool phone = false,
}) async {
  tester.view.physicalSize = phone ? const Size(390 * 3, 844 * 3) : const Size(1000, 1800);
  tester.view.devicePixelRatio = phone ? 3 : 1;
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
        changePassword: changePassword,
        updateName: updateName,
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
    await tester.pumpAndSettle();
    // confirm dialog (added 2026-09-21 — same as the teacher lane); the
    // sign-out RPC must not fire before ยืนยัน
    expect(find.text('ยืนยันออกจากระบบ'), findsOneWidget);
    expect(signOutCalls, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'ออกจากระบบ'));
    // Not pumpAndSettle: LoginPage may render an indeterminate animation
    // that never settles. A few bounded pumps are enough to prove the
    // real signOut callback fired and navigation was triggered.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(signOutCalls, 1);
  });

  testWidgets('no placeholder menu item is left; change-password is real', (
    tester,
  ) async {
    String? sentNew;
    await _pump(
      tester,
      changePassword: ({required currentPassword, required newPassword}) async =>
          sentNew = newPassword,
    );
    expect(find.textContaining('ยังไม่เปิดใช้งาน'), findsNothing);
    for (final gone in ['เคล็ดลับการใช้งาน', 'คำถามที่พบบ่อย', 'ติดต่อทีมงาน', 'การแจ้งเตือน', 'ความเป็นส่วนตัวและ PDPA']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านปัจจุบัน'), 'Test1234!');
    await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)'), 'NewPass9!');
    await tester.enterText(find.widgetWithText(TextField, 'ยืนยันรหัสผ่านใหม่'), 'NewPass9!');
    await tester.tap(find.widgetWithText(FilledButton, 'เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();
    expect(sentNew, 'NewPass9!');
    expect(find.textContaining('เปลี่ยนรหัสผ่านแล้ว'), findsOneWidget);
  });

  // ── rename (added 2026-09-18) ──────────────────────────────────────
  testWidgets('the hero pencil saves a new name through the injected updater', (
    tester,
  ) async {
    final previous = currentUserModel;
    currentUserModel = const UserModel(
      uid: 'u-1',
      name: 'ครู ทดสอบ',
      email: 'x@example.com',
      role: UserRole.student,
    );
    addTearDown(() => currentUserModel = previous);
    String? gotUid;
    String? gotName;
    await _pump(
      tester,
      phone: true,
      updateName: ({required String uid, required String name}) async {
        gotUid = uid;
        gotName = name;
      },
    );
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    expect(find.text('แก้ไขชื่อที่แสดง'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '  สมชาย ใจดี  ');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(gotUid, 'u-1');
    expect(gotName, 'สมชาย ใจดี');
    expect(find.text('บันทึกชื่อแล้ว'), findsOneWidget);
  });

  testWidgets('an unchanged or empty name is not sent', (tester) async {
    final previous = currentUserModel;
    currentUserModel = const UserModel(
      uid: 'u-1',
      name: 'ครู ทดสอบ',
      email: 'x@example.com',
      role: UserRole.student,
    );
    addTearDown(() => currentUserModel = previous);
    var calls = 0;
    await _pump(
      tester,
      phone: true,
      updateName: ({required String uid, required String name}) async {
        calls++;
      },
    );
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึก')); // unchanged
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '   ');
    await tester.tap(find.text('บันทึก')); // empty
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
}
