import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_academic_calendar_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_attendance_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_dashboard_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_learning_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_schedule_page.dart';
import 'package:shared_core/shared_core.dart';

const _students = [
  LinkedStudentItem(
    studentId: 'student-1',
    firstName: 'นักเรียน',
    lastName: 'หนึ่ง',
    schoolId: 'school-1',
  ),
  LinkedStudentItem(
    studentId: 'student-2',
    firstName: 'นักเรียน',
    lastName: 'สอง',
    schoolId: 'school-2',
  ),
];

void main() {
  testWidgets('all student-scoped parent pages honor the shared student id', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    final requestedIds = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ParentDashboardPage(
          selectedStudentId: 'student-2',
          studentsLoader: () async => _students,
          gradesLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          assignmentsLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          attendanceLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          scheduleLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          eventsLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          sensorsLoader: () async => const [],
          notificationsLoader: () async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: ParentLearningPage(
          selectedStudentId: 'student-2',
          studentsLoader: () async => _students,
          gradesLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          attendanceLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          assignmentsLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: ParentAttendancePage(
          selectedStudentId: 'student-2',
          loadStudents: () async => _students,
          loadAttendance: (id) async {
            requestedIds.add(id);
            return const [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: ParentSchedulePage(
          selectedStudentId: 'student-2',
          studentsLoader: () async => _students,
          scheduleLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
          assignmentsLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: ParentAcademicCalendarPage(
          selectedStudentId: 'student-2',
          studentsLoader: () async => _students,
          eventsLoader: (id) async {
            requestedIds.add(id);
            return const [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedIds, isNotEmpty);
    expect(requestedIds.toSet(), {'student-2'});
  });
}
