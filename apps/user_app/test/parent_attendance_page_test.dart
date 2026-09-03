import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_attendance_page.dart';
import 'package:shared_core/shared_core.dart';

const _student = LinkedStudentItem(
  studentId: 'student-1',
  firstName: 'นักเรียน',
  lastName: 'ทดสอบ',
  schoolId: 'school-1',
  relationship: 'บุตร',
);

Widget _app({
  required ParentStudentsLoader loadStudents,
  required ParentAttendanceLoader loadAttendance,
}) {
  return MaterialApp(
    home: ParentAttendancePage(
      loadStudents: loadStudents,
      loadAttendance: loadAttendance,
    ),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows honest empty cards without fabricated percentages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    await tester.pumpWidget(
      _app(
        loadStudents: () async => const [_student],
        loadAttendance: (_) async => const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('นักเรียน ทดสอบ (บุตร)'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('100%'), findsNothing);
    expect(find.text('96%'), findsNothing);
    expect(find.text('98%'), findsNothing);
    expect(find.text('น้องมะลิ'), findsNothing);
  });

  testWidgets('keeps load failures distinct from empty data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      _app(
        loadStudents: () async => throw Exception('network_error'),
        loadAttendance: (_) async => const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
  });

  testWidgets('derives attendance percentages from real records', (
    tester,
  ) async {
    final now = DateTime.now();
    final records = [
      StudentAttendanceItem(
        recordId: 'record-1',
        courseId: 'course-1',
        courseName: 'วิทยาศาสตร์',
        courseCode: 'SCI-1',
        classDate: now,
        status: 'present',
        markedAt: now,
      ),
      StudentAttendanceItem(
        recordId: 'record-2',
        courseId: 'course-2',
        courseName: 'คณิตศาสตร์',
        courseCode: 'MATH-1',
        classDate: now,
        status: 'absent',
        markedAt: now,
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    await tester.pumpWidget(
      _app(
        loadStudents: () async => const [_student],
        loadAttendance: (_) async => records,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsWidgets);
    expect(find.textContaining('มาเรียนหรือมาสาย 1 จาก 2 คาบ'), findsOneWidget);
    expect(find.text('น้องมะลิ'), findsNothing);
  });
}
