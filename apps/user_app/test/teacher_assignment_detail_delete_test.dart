import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_detail_page.dart';
import 'package:shared_core/shared_core.dart';

/// ลบใบงาน (2026-09-23)
///
/// ระบบนี้ลบใบงานไม่ได้เลยมาตลอด — สร้างผิดแล้วค้างถาวร เจอกับตัวในวันเดียวกัน
/// (ใบงานทดสอบ 2 ใบค้างบน prod ต้องไปลบด้วย SQL ตรง ๆ)
///
/// สิ่งที่เทสต์ชุดนี้ตรึง: ใบที่มีนักเรียนส่งงานแล้วต้องลบไม่ได้ ทั้งที่หน้าจอ
/// และเมื่อหลังบ้านปฏิเสธ — เพราะลบไปคืองานและคะแนนของเด็กหายด้วย
void main() {
  const assignment = AssignmentSummary(
    id: 'asg-9',
    type: 'worksheet',
    title: 'ใบงานที่จะลบ',
    dueAt: null,
    status: 'draft',
  );

  CourseStudent student(String id) => CourseStudent(
    studentId: id,
    firstName: 'นักเรียน',
    lastName: id,
    email: '$id@test',
    enrolledAt: DateTime(2026, 1, 1),
  );

  SubmissionRoster submission(String studentId) => SubmissionRoster(
    submissionId: 'sub-$studentId',
    studentId: studentId,
    studentFirstName: 'นักเรียน',
    studentLastName: studentId,
    status: 'submitted',
    currentVersion: 1,
    latestContent: 'ส่งแล้ว',
    submittedAt: DateTime(2026, 9, 1),
    latestAttachments: const [],
  );

  Future<void> pump(
    WidgetTester tester, {
    List<SubmissionRoster> submissions = const [],
    Future<void> Function(String)? deleteAssignment,
  }) async {
    tester.view.physicalSize = const Size(402, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAssignmentDetailPage(
          assignment: assignment,
          courseId: 'c1',
          courseName: 'คณิตศาสตร์',
          loadStudents: (_) async => [student('a'), student('b')],
          loadSubmissions: (_) async => submissions,
          loadDetail: (id) async => AssignmentDetail(
            id: id,
            courseId: 'c1',
            type: 'worksheet',
            title: assignment.title,
            instructions: null,
            dueAt: null,
            status: 'draft',
            sensorDatasets: const [],
          ),
          deleteAssignment: deleteAssignment,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
  }

  testWidgets('ยังไม่มีใครส่ง — ลบได้ และส่ง id จริงไปหลังบ้าน', (tester) async {
    String? deleted;
    await pump(tester, deleteAssignment: (id) async => deleted = id);

    await openMenu(tester);
    await tester.tap(find.text('ลบใบงาน'));
    await tester.pumpAndSettle();

    // ต้องถามยืนยันก่อน และบอกว่าไฟล์ในคลังไม่หายไปด้วย
    expect(find.text('ลบใบงานนี้?'), findsOneWidget);
    expect(find.textContaining('ยังอยู่ในคลังความรู้'), findsOneWidget);

    await tester.tap(find.text('ลบใบงาน').last);
    await tester.pumpAndSettle();

    expect(deleted, 'asg-9');
  });

  testWidgets('กดยกเลิกในกล่องยืนยัน ต้องไม่ลบ', (tester) async {
    var called = false;
    await pump(tester, deleteAssignment: (_) async => called = true);

    await openMenu(tester);
    await tester.tap(find.text('ลบใบงาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });

  testWidgets('มีนักเรียนส่งแล้ว — ปุ่มลบถูกปิด พร้อมบอกให้ใช้ปิดรับงานแทน', (
    tester,
  ) async {
    var called = false;
    await pump(
      tester,
      submissions: [submission('a')],
      deleteAssignment: (_) async => called = true,
    );

    await openMenu(tester);
    expect(find.textContaining('มีนักเรียนส่งแล้ว 1 คน'), findsOneWidget);
    expect(find.textContaining('ใช้ปิดรับงานแทน'), findsOneWidget);

    // กดแล้วต้องไม่เกิดอะไรขึ้นเลย
    await tester.tap(find.text('ลบใบงาน'));
    await tester.pumpAndSettle();
    expect(find.text('ลบใบงานนี้?'), findsNothing);
    expect(called, isFalse);
  });

  testWidgets('หลังบ้านปฏิเสธ ต้องแปลงเป็นข้อความที่บอกทางออก ไม่ใช่ error ดิบ', (
    tester,
  ) async {
    // จำนวนที่ส่งอาจเปลี่ยนระหว่างเปิดหน้าค้างไว้ — ปุ่มที่เปิดอยู่จึงไม่ใช่
    // ด่านจริง หลังบ้านต่างหากที่เป็น
    await pump(
      tester,
      deleteAssignment: (_) async =>
          throw StateError('assignment_has_2 submissions'),
    );

    await openMenu(tester);
    await tester.tap(find.text('ลบใบงาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบใบงาน').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('มีนักเรียนส่งแล้ว 2 คน'), findsOneWidget);
    expect(find.textContaining('assignment_has_2'), findsNothing);
  });
}
