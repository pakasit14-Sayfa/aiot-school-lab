import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_academic_calendar_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_attendance_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_dashboard_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_learning_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_schedule_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/widgets/parent_navigation_shell.dart';
import 'package:shared_core/shared_core.dart';

const _students = [
  LinkedStudentItem(
    studentId: 'student-1',
    firstName: 'นักเรียน',
    lastName: 'หนึ่ง',
    schoolId: 'school-1',
    relationship: 'บุตร',
  ),
  LinkedStudentItem(
    studentId: 'student-2',
    firstName: 'นักเรียน',
    lastName: 'สอง',
    schoolId: 'school-2',
    relationship: 'บุตร',
  ),
];

void main() {
  testWidgets(
    'selecting a student in a real page scopes all five real parent pages',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final requestedIds = <String, List<String>>{
        'dashboard': [],
        'learning': [],
        'attendance': [],
        'calendar': [],
        'schedule': [],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ParentNavigationShell(
            pagesBuilder: (selectedStudentId, onStudentSelected) => [
              ParentDashboardPage(
                selectedStudentId: selectedStudentId,
                onStudentSelected: onStudentSelected,
                studentsLoader: () async => _students,
                gradesLoader: (id) async {
                  requestedIds['dashboard']!.add(id);
                  return const [];
                },
                assignmentsLoader: (id) async {
                  requestedIds['dashboard']!.add(id);
                  return const [];
                },
                attendanceLoader: (id) async {
                  requestedIds['dashboard']!.add(id);
                  return const [];
                },
                scheduleLoader: (id) async {
                  requestedIds['dashboard']!.add(id);
                  return const [];
                },
                eventsLoader: (id) async {
                  requestedIds['dashboard']!.add(id);
                  return const [];
                },
                sensorsLoader: () async => const [],
                notificationsLoader: () async => const [],
              ),
              ParentLearningPage(
                selectedStudentId: selectedStudentId,
                onStudentSelected: onStudentSelected,
                studentsLoader: () async => _students,
                gradesLoader: (id) async {
                  requestedIds['learning']!.add(id);
                  return const [];
                },
                attendanceLoader: (id) async {
                  requestedIds['learning']!.add(id);
                  return const [];
                },
                assignmentsLoader: (id) async {
                  requestedIds['learning']!.add(id);
                  return const [];
                },
              ),
              ParentAttendancePage(
                selectedStudentId: selectedStudentId,
                onStudentSelected: onStudentSelected,
                loadStudents: () async => _students,
                loadAttendance: (id) async {
                  requestedIds['attendance']!.add(id);
                  return const [];
                },
              ),
              ParentAcademicCalendarPage(
                selectedStudentId: selectedStudentId,
                onStudentSelected: onStudentSelected,
                studentsLoader: () async => _students,
                eventsLoader: (id) async {
                  requestedIds['calendar']!.add(id);
                  return const [];
                },
              ),
              ParentSchedulePage(
                selectedStudentId: selectedStudentId,
                onStudentSelected: onStudentSelected,
                studentsLoader: () async => _students,
                scheduleLoader: (id) async {
                  requestedIds['schedule']!.add(id);
                  return const [];
                },
                assignmentsLoader: (id) async {
                  requestedIds['schedule']!.add(id);
                  return const [];
                },
              ),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final requests in requestedIds.values) {
        requests.clear();
      }

      await tester.tap(find.byKey(const Key('parent-student-switcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('นักเรียน สอง'));
      await tester.pumpAndSettle();

      expect(requestedIds['dashboard']!.toSet(), {'student-2'});

      for (final destination in const [
        ('การเรียน', 'learning'),
        ('การมาเรียน', 'attendance'),
        ('ปฏิทินวิชาการ', 'calendar'),
        ('ตาราง / การบ้าน', 'schedule'),
      ]) {
        await tester.tap(find.text(destination.$1).first);
        await tester.pumpAndSettle();
        expect(requestedIds[destination.$2]!.toSet(), {
          'student-2',
        }, reason: '${destination.$1} must use the shared student id');
      }
    },
  );
}
