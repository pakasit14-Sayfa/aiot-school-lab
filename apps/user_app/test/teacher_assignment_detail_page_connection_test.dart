import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_detail_page.dart';
import 'package:shared_core/shared_core.dart';

/// หน้าใบงานของครู (2026-09-21): counts are derived from the real roster
/// (list_course_students) and real submissions (list_submissions), and the
/// ⋯ menu's ปิดรับงาน reaches unpublish_assignment.
CourseStudent _stu(String id, String first) => CourseStudent(
  studentId: id,
  firstName: first,
  lastName: 'ทดสอบ',
  email: '$id@aiot-school-lab.local',
  enrolledAt: DateTime(2026, 9, 1),
);

SubmissionRoster _sub(String studentId, String status) => SubmissionRoster(
  submissionId: 'sub-$studentId',
  studentId: studentId,
  studentFirstName: studentId,
  studentLastName: '',
  status: status,
  currentVersion: 1,
  latestContent: 'x',
  submittedAt: DateTime(2026, 9, 20),
);

AssignmentSummary _asg({String status = 'published'}) => AssignmentSummary(
  id: 'a1',
  type: 'worksheet',
  title: 'ใบงานเศษส่วน',
  instructions: 'ทำข้อ 1-10',
  dueAt: DateTime.now().add(const Duration(days: 2)),
  status: status,
);

Future<void> _pump(
  WidgetTester tester, {
  AssignmentSummary? assignment,
  Future<void> Function(String)? unpublish,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherAssignmentDetailPage(
        assignment: assignment ?? _asg(),
        courseId: 'course-1',
        courseName: 'คณิตศาสตร์',
        loadStudents: (_) async => [
          _stu('s1', 'หนึ่ง'),
          _stu('s2', 'สอง'),
          _stu('s3', 'สาม'),
        ],
        loadSubmissions: (_) async => [
          _sub('s1', 'submitted'),
          _sub('s2', 'graded'),
        ],
        loadDetail: (id) async => AssignmentDetail(
          id: id,
          courseId: 'course-1',
          type: 'worksheet',
          title: 'ใบงานเศษส่วน',
          instructions: 'ทำข้อ 1-10',
          dueAt: null,
          status: 'published',
          sensorDatasets: const [
            AssignmentSensorDataset(
              id: 'ds1',
              deviceId: 'dev1',
              metric: 'temperature',
              timeStart: null,
              timeEnd: null,
              label: null,
            ),
          ],
        ),
        unpublish: unpublish ?? (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('counts come from the roster × submissions, each student rowed', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('ใบงานเศษส่วน'), findsOneWidget);
    // เลขสามกล่องถูกรวมเป็นประโยคเดียว + แถบสัดส่วน (redesign 2026-09-21)
    expect(find.text('2'), findsOneWidget); // ส่งแล้ว
    expect(find.text('/ 3 คนส่งแล้ว'), findsOneWidget);
    expect(find.text('มี 1 ชิ้นรอตรวจ · ยังไม่ส่งอีก 1 คน'), findsOneWidget);
    expect(find.text('ทำข้อ 1-10'), findsOneWidget);
    // roster rows
    expect(find.textContaining('หนึ่ง'), findsOneWidget);
    expect(find.textContaining('สาม'), findsOneWidget);
    // 'ยังไม่ส่ง' โผล่ 3 ที่ตามดีไซน์ใหม่: หัวกลุ่ม · ป้ายในแถวของ s3 · คำอธิบาย
    // ใต้แถบสัดส่วน — ที่ต้องยืนยันคือ s3 อยู่ในกลุ่มนั้นจริง
    expect(find.text('ยังไม่ส่ง'), findsNWidgets(3));
    expect(find.text('ตรวจงาน'), findsOneWidget);
    expect(find.text('แก้ไข'), findsOneWidget);
  });

  testWidgets('⋯ → ปิดรับงาน calls unpublish_assignment with the id', (
    tester,
  ) async {
    String? unpublished;
    await _pump(tester, unpublish: (id) async => unpublished = id);
    await tester.tap(find.byTooltip('ตัวเลือก'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปิดรับงาน (กลับเป็นฉบับร่าง)'));
    await tester.pumpAndSettle();
    expect(unpublished, 'a1');
    expect(find.text('ปิดรับงานแล้ว'), findsOneWidget);
  });

  testWidgets('a draft offers เผยแพร่ instead of ปิดรับงาน', (tester) async {
    await _pump(tester, assignment: _asg(status: 'draft'));
    await tester.tap(find.byTooltip('ตัวเลือก'));
    await tester.pumpAndSettle();
    expect(find.text('ปิดรับงาน (กลับเป็นฉบับร่าง)'), findsNothing);
    expect(find.textContaining('เผยแพร่'), findsWidgets);
  });
}
