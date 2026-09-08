import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_learning_page.dart';
import 'package:shared_core/shared_core.dart';

const _student = LinkedStudentItem(
  studentId: 'student-1',
  firstName: 'นักเรียน',
  lastName: 'ทดสอบ',
  schoolId: 'school-1',
);

Widget _app({
  required ParentLearningStudentsLoader studentsLoader,
  required ParentGradesLoader gradesLoader,
  required ParentLearningAttendanceLoader attendanceLoader,
  required ParentLearningAssignmentsLoader assignmentsLoader,
}) {
  return MaterialApp(
    home: ParentLearningPage(
      studentsLoader: studentsLoader,
      gradesLoader: gradesLoader,
      attendanceLoader: attendanceLoader,
      assignmentsLoader: assignmentsLoader,
      now: () => DateTime(2026, 9, 3, 10),
    ),
  );
}

void main() {
  testWidgets('shows a loading state while learning data is pending', (
    tester,
  ) async {
    final students = Completer<List<LinkedStudentItem>>();
    await tester.pumpWidget(
      _app(
        studentsLoader: () => students.future,
        gradesLoader: (_) async => const [],
        attendanceLoader: (_) async => const [],
        assignmentsLoader: (_) async => const [],
      ),
    );
    await tester.pump();

    expect(find.text('กำลังโหลดข้อมูล'), findsOneWidget);

    students.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('shows honest empty state without prototype metrics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(
      _app(
        studentsLoader: () async => const [_student],
        gradesLoader: (_) async => const [],
        attendanceLoader: (_) async => const [],
        assignmentsLoader: (_) async => const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('นักเรียน ทดสอบ'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('96%'), findsNothing);
    expect(find.text('86.8'), findsNothing);
    expect(find.text('3.62'), findsNothing);
    expect(find.text('น้องมะลิ · ม.2/1'), findsNothing);
  });

  testWidgets('keeps failures distinct from empty data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      _app(
        studentsLoader: () async => throw Exception('network_error'),
        gradesLoader: (_) async => const [],
        attendanceLoader: (_) async => const [],
        assignmentsLoader: (_) async => const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('derives metrics from grades attendance and assignments', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 3, 10);
    await tester.binding.setSurfaceSize(const Size(1200, 2000));
    await tester.pumpWidget(
      _app(
        studentsLoader: () async => const [_student],
        gradesLoader: (_) async => [
          StudentGradeItem(
            gradeId: 'grade-1',
            courseId: 'course-1',
            subjectName: 'วิทยาศาสตร์',
            score: 18,
            maxScore: 20,
            confirmedAt: now,
          ),
        ],
        attendanceLoader: (_) async => [
          StudentAttendanceItem(
            recordId: 'record-1',
            courseId: 'course-1',
            courseName: 'วิทยาศาสตร์',
            courseCode: 'SCI',
            classDate: now,
            status: 'present',
            markedAt: now,
          ),
          StudentAttendanceItem(
            recordId: 'record-2',
            courseId: 'course-1',
            courseName: 'วิทยาศาสตร์',
            courseCode: 'SCI',
            classDate: now,
            status: 'absent',
            markedAt: now,
          ),
        ],
        assignmentsLoader: (_) async => [
          StudentAssignmentItem(
            assignmentId: 'assignment-1',
            courseName: 'วิทยาศาสตร์',
            title: 'รายงานการทดลอง',
            dueAt: now.add(const Duration(days: 1)),
            status: 'pending',
          ),
          StudentAssignmentItem(
            assignmentId: 'assignment-2',
            courseName: 'วิทยาศาสตร์',
            title: 'ใบงานแรง',
            dueAt: now,
            status: 'submitted',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('90%'), findsWidgets);
    expect(find.text('50%'), findsWidgets);
    expect(find.text('รายงานการทดลอง'), findsOneWidget);
    expect(find.text('ใบงานแรง'), findsOneWidget);
    expect(find.text('1 งานรอดำเนินการ'), findsWidgets);
  });

  testWidgets('shows unknown attendance without lowering the known rate', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 3, 10);
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(
      _app(
        studentsLoader: () async => const [_student],
        gradesLoader: (_) async => const [],
        attendanceLoader: (_) async => [
          StudentAttendanceItem(
            recordId: 'present',
            courseId: 'course-1',
            courseName: 'วิทยาศาสตร์',
            courseCode: 'SCI',
            classDate: now,
            status: 'present',
            markedAt: now,
          ),
          StudentAttendanceItem(
            recordId: 'unknown',
            courseId: 'course-1',
            courseName: 'วิทยาศาสตร์',
            courseCode: 'SCI',
            classDate: now,
            status: 'unknown',
            markedAt: now,
          ),
        ],
        assignmentsLoader: (_) async => const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่ทราบสถานะ'), findsOneWidget);
    expect(find.text('unknown'), findsNothing);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('50%'), findsNothing);
  });
}
