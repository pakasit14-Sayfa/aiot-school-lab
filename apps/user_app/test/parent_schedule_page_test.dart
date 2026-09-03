import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_schedule_page.dart';
import 'package:shared_core/shared_core.dart';

const _student = LinkedStudentItem(
  studentId: 'student-1',
  firstName: 'นักเรียน',
  lastName: 'ทดสอบ',
  schoolId: 'school-1',
);

Widget _app({
  required ParentScheduleStudentsLoader studentsLoader,
  required ParentScheduleLoader scheduleLoader,
  required ParentAssignmentsLoader assignmentsLoader,
}) {
  return MaterialApp(
    home: ParentSchedulePage(
      studentsLoader: studentsLoader,
      scheduleLoader: scheduleLoader,
      assignmentsLoader: assignmentsLoader,
      now: () => DateTime(2026, 9, 3, 10),
    ),
  );
}

void main() {
  testWidgets(
    'shows explicit empty cards without sample schedule or homework',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      await tester.pumpWidget(
        _app(
          studentsLoader: () async => const [_student],
          scheduleLoader: (_) async => const [],
          assignmentsLoader: (_) async => const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('นักเรียน ทดสอบ'), findsOneWidget);
      expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
      expect(find.text('วิทยาศาสตร์'), findsNothing);
      expect(find.textContaining('แบบฝึกหัดบทที่ 5'), findsNothing);
    },
  );

  testWidgets('keeps load failures distinct from empty data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      _app(
        studentsLoader: () async => throw Exception('network_error'),
        scheduleLoader: (_) async => const [],
        assignmentsLoader: (_) async => const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('shows unauthenticated state without empty data cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(const MaterialApp(home: ParentSchedulePage()));
    await tester.pumpAndSettle();

    expect(find.text('กรุณาเข้าสู่ระบบอีกครั้ง'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('derives schedule and assignment summaries from loader data', (
    tester,
  ) async {
    final schedule = [
      const StudentScheduleItem(
        scheduleId: 'schedule-1',
        courseId: 'course-1',
        subjectName: 'วิทยาศาสตร์',
        dayOfWeek: DateTime.thursday,
        startTime: '10:30',
        endTime: '11:20',
        room: 'Lab 2',
      ),
    ];
    final assignments = [
      StudentAssignmentItem(
        assignmentId: 'assignment-1',
        courseName: 'วิทยาศาสตร์',
        title: 'รายงานการทดลอง',
        dueAt: DateTime(2026, 9, 4, 16),
        status: 'pending',
      ),
      StudentAssignmentItem(
        assignmentId: 'assignment-2',
        courseName: 'ภาษาไทย',
        title: 'สรุปบทอ่าน',
        dueAt: DateTime(2026, 9, 5, 16),
        status: 'submitted',
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(
      _app(
        studentsLoader: () async => const [_student],
        scheduleLoader: (_) async => schedule,
        assignmentsLoader: (_) async => assignments,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('วิทยาศาสตร์'), findsWidgets);
    expect(find.text('รายงานการทดลอง'), findsOneWidget);
    expect(find.text('สรุปบทอ่าน'), findsOneWidget);
    expect(find.text('1 งานใกล้ครบกำหนด'), findsWidgets);
    expect(find.text('1 งานส่งแล้ว'), findsOneWidget);
    expect(find.text('70%'), findsNothing);
  });
}
