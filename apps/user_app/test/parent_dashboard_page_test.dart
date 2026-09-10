import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_dashboard_page.dart';
import 'package:shared_core/shared_core.dart';

const _student = LinkedStudentItem(
  studentId: 'student-1',
  firstName: 'นักเรียน',
  lastName: 'ทดสอบ',
  schoolId: 'school-1',
);

Widget _app({
  required ParentDashboardStudentsLoader students,
  ParentDashboardGradesLoader? grades,
  ParentDashboardAssignmentsLoader? assignments,
  ParentDashboardAttendanceLoader? attendance,
  ParentDashboardScheduleLoader? schedule,
  ParentDashboardSensorsLoader? sensors,
  ParentDashboardNotificationsLoader? notifications,
  ParentDashboardEventsLoader? events,
}) => MaterialApp(
  home: ParentDashboardPage(
    studentsLoader: students,
    gradesLoader: grades ?? (_) async => const [],
    assignmentsLoader: assignments ?? (_) async => const [],
    attendanceLoader: attendance ?? (_) async => const [],
    scheduleLoader: schedule ?? (_) async => const [],
    sensorsLoader: sensors ?? () async => const [],
    eventsLoader: events ?? (_) async => const [],
    notificationsLoader: notifications ?? () async => const [],
    now: () => DateTime(2026, 9, 3, 10),
  ),
);

void main() {
  testWidgets('shows a loading state while dashboard data is pending', (
    tester,
  ) async {
    final students = Completer<List<LinkedStudentItem>>();
    await tester.pumpWidget(_app(students: () => students.future));
    await tester.pump();

    expect(find.text('กำลังโหลดข้อมูล'), findsOneWidget);

    students.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('shows honest empty cards without dashboard samples', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    await tester.pumpWidget(_app(students: () async => const [_student]));
    await tester.pumpAndSettle();

    expect(find.text('นักเรียน ทดสอบ'), findsWidgets);
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('ครูประจำชั้น'), findsNothing);
    expect(find.text('ปกติ'), findsNothing);
    expect(find.text('น้องมะลิ'), findsNothing);
  });

  testWidgets('keeps load failures distinct from empty data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      _app(students: () async => throw Exception('network_error')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('renders core metrics from service data', (tester) async {
    final now = DateTime(2026, 9, 3, 10);
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    await tester.pumpWidget(
      _app(
        students: () async => const [_student],
        grades: (_) async => [
          StudentGradeItem(
            gradeId: 'g1',
            courseId: 'c1',
            subjectName: 'วิทยาศาสตร์',
            score: 18,
            maxScore: 20,
            confirmedAt: now,
          ),
        ],
        assignments: (_) async => [
          StudentAssignmentItem(
            assignmentId: 'a1',
            courseName: 'วิทยาศาสตร์',
            title: 'รายงานการทดลอง',
            dueAt: now.add(const Duration(days: 1)),
            status: 'pending',
          ),
        ],
        attendance: (_) async => [
          StudentAttendanceItem(
            recordId: 'r1',
            courseId: 'c1',
            courseName: 'วิทยาศาสตร์',
            courseCode: 'SCI',
            classDate: now,
            status: 'present',
            markedAt: DateTime(2026, 9, 3, 8),
          ),
        ],
        schedule: (_) async => const [
          StudentScheduleItem(
            scheduleId: 's1',
            courseId: 'c1',
            subjectName: 'วิทยาศาสตร์',
            dayOfWeek: DateTime.thursday,
            startTime: '09:30',
            endTime: '10:30',
            room: 'Lab 2',
          ),
        ],
        sensors: () async => [
          {'metric': 'temperature', 'value': 27.5},
        ],
        events: (_) async => [
          SchoolEventItem(
            eventId: 'e1',
            title: 'วันวิทยาศาสตร์',
            location: 'หอประชุม',
            startDate: DateTime(2026, 9, 5),
          ),
        ],
        notifications: () async => [
          AppNotification(
            id: 'n1',
            type: 'announcement',
            title: 'ประกาศประชุมผู้ปกครอง',
            body: 'วันศุกร์ เวลา 15:00 น.',
            createdAt: now,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('กำลังเรียน วิทยาศาสตร์'), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('90%'), findsWidgets);
    expect(find.text('รายงานการทดลอง'), findsOneWidget);
    expect(find.text('27.5 °C'), findsOneWidget);
    expect(find.text('วันวิทยาศาสตร์'), findsOneWidget);
    expect(find.text('ประกาศประชุมผู้ปกครอง'), findsOneWidget);
  });

  testWidgets('shows unknown attendance without lowering the known rate', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 3, 10);
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(
      _app(
        students: () async => const [_student],
        attendance: (_) async => [
          StudentAttendanceItem(
            recordId: 'present',
            courseId: 'course-1',
            courseName: 'วิทยาศาสตร์',
            courseCode: 'SCI',
            classDate: now,
            status: 'present',
            markedAt: DateTime(2026, 9, 3, 8),
          ),
          StudentAttendanceItem(
            recordId: 'unknown',
            courseId: 'course-2',
            courseName: 'คณิตศาสตร์',
            courseCode: 'MATH',
            classDate: now,
            status: 'unknown',
            markedAt: DateTime(2026, 9, 3, 9),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่ทราบสถานะ'), findsWidgets);
    expect(find.text('unknown'), findsNothing);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('50%'), findsNothing);
  });

  testWidgets('does not present unknown-only attendance as zero percent', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 3, 10);
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(
      _app(
        students: () async => const [_student],
        attendance: (_) async => [
          StudentAttendanceItem(
            recordId: 'unknown',
            courseId: 'course-1',
            courseName: 'วิทยาศาสตร์',
            courseCode: 'SCI',
            classDate: now,
            status: 'unknown',
            markedAt: DateTime(2026, 9, 3, 8),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่ทราบสถานะ'), findsWidgets);
    expect(find.text('0%'), findsNothing);
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
  });
}
