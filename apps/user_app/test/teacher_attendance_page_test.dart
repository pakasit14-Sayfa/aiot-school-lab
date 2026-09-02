import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_attendance_page.dart';

void main() {
  testWidgets('TeacherAttendancePage renders header, mode selector, KPI cards, and roster', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockHomeroom = const HomeroomAssignment(
      assignmentId: 'h1',
      gradeLevel: '2',
      room: '1',
      studentCount: 3,
    );

    final mockRoster = [
      AttendanceStudentRow(
        studentId: 's1',
        studentName: 'สมชาย สายเสมอ',
        studentCode: 'STU001',
        status: 'present',
      ),
      AttendanceStudentRow(
        studentId: 's2',
        studentName: 'สมหญิง จริงใจ',
        studentCode: 'STU002',
        status: 'late',
      ),
      AttendanceStudentRow(
        studentId: 's3',
        studentName: 'สมศักดิ์ ขยันดี',
        studentCode: 'STU003',
        status: 'absent',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendancePage(
          initialHomerooms: [mockHomeroom],
          initialRoster: mockRoster,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text('เช็คชื่อนักเรียน'), findsWidgets);
    expect(find.textContaining('นักเรียนประจำชั้น'), findsWidgets);
    expect(find.textContaining('รายวิชาที่สอน'), findsWidgets);

    // Verify 4 KPI cards
    expect(find.text('มาเรียน'), findsWidgets);
    expect(find.text('มาสาย'), findsWidgets);
    expect(find.text('ลากิจ / ลาป่วย'), findsWidgets);
    expect(find.text('ขาดเรียน'), findsWidgets);

    // Verify Roster & Students
    expect(find.text('สมชาย สายเสมอ'), findsOneWidget);
    expect(find.text('สมหญิง จริงใจ'), findsOneWidget);
    expect(find.text('สมศักดิ์ ขยันดี'), findsOneWidget);

    // Verify "เช็คมาทุกคน" Button
    expect(find.text('เช็คมาทุกคน'), findsOneWidget);
    await tester.tap(find.text('เช็คมาทุกคน'));
    await tester.pumpAndSettle();

    // After mark all present, all 3 students have status 'present'
    expect(mockRoster.every((r) => r.status == 'present'), isTrue);

    // Test clicking on status badge to change status via PopupMenu
    final student3Picker = find.byType(PopupMenuButton<String>).at(2);
    await tester.tap(student3Picker);
    await tester.pumpAndSettle();

    // Tap 'ขาดเรียน' in the opened popup menu
    expect(find.text('ขาดเรียน'), findsWidgets);
    await tester.tap(find.text('ขาดเรียน').last);
    await tester.pumpAndSettle();

    // Student 3 is now set to 'absent'
    expect(mockRoster[2].status, 'absent');
  });
}
