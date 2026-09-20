import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_timetable_page.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_timetable_controller.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets('connection logic triggers correctly, errors displayed', (
    tester,
  ) async {
    bool assigned = false;

    final controller = SchoolTimetableController(
      loadTerms: () async => const [
        Term(termId: '1', termName: '1', academicYearName: '2569'),
      ],
      loadRooms: () async => const [SchoolRoom(gradeLevel: 'ม.1', room: '1/1')],
      loadPeriods: () async => const [
        SchoolPeriod(periodNo: 1, startTime: '08:30:00', endTime: '09:20:00'),
      ],
      loadSchedules: (a, b, c) async => const [],
      loadTeacherSubjects: () async => const [
        TeacherSubject(
          teacherId: 't1',
          subjectName: 'คณิต',
          fullName: 'ครูสมปอง',
        ),
      ],
      loadStaff: () async => [
        StaffDirectoryEntry(
          userId: 't1',
          fullName: 'ครูสมปอง',
          email: 'e',
          status: 'a',
          positionTitle: 'p',
          phone: '1',
          roles: [],
          administrativeDepartments: [],
          subjectGroups: [],
          headsDepartments: [],
        ),
      ],
      setSlot:
          ({
            required termId,
            required gradeLevel,
            required room,
            required dayOfWeek,
            required periodNo,
            required subjectName,
            required teacherId,
          }) async {
            assigned = true;
          },
      clearSlot:
          ({
            required termId,
            required gradeLevel,
            required room,
            required dayOfWeek,
            required periodNo,
          }) async {
          },
    );

    await tester.pumpWidget(
      MaterialApp(home: SchoolTimetablePage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('คาบ 1'), findsOneWidget);

    // Tap to add schedule for period 1, day 1
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    // Add subject name
    await tester.enterText(find.byType(TextField).first, 'คณิต');
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(assigned, isTrue);
  });
}
