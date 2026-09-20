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
    String? assignedTeacher;

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
            assignedTeacher = teacherId;
          },
      clearSlot:
          ({
            required termId,
            required gradeLevel,
            required room,
            required dayOfWeek,
            required periodNo,
          }) async {},
      savePeriods: (_) async {},
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

    // Teacher is mandatory (D6: a slot is room × subject × teacher) — the
    // save button stays disabled until one is picked.
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'บันทึก'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ครูสมปอง').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(assigned, isTrue);
    expect(assignedTeacher, 't1');
  });

  testWidgets(
    'no periods yet → in-page sheet, saved set reaches savePeriods and is reloaded',
    (tester) async {
      List<SchoolPeriod> saved = const [];
      var periods = const <SchoolPeriod>[];
      final controller = SchoolTimetableController(
        loadTerms: () async => const [
          Term(termId: '1', termName: '1', academicYearName: '2569'),
        ],
        loadRooms: () async => const [SchoolRoom(gradeLevel: 'ม.1', room: '1')],
        loadPeriods: () async => periods,
        loadSchedules: (a, b, c) async => const [],
        loadTeacherSubjects: () async => const [],
        loadStaff: () async => const [],
        setSlot:
            ({
              required termId,
              required gradeLevel,
              required room,
              required dayOfWeek,
              required periodNo,
              required subjectName,
              required teacherId,
            }) async {},
        clearSlot:
            ({
              required termId,
              required gradeLevel,
              required room,
              required dayOfWeek,
              required periodNo,
            }) async {},
        savePeriods: (p) async {
          saved = p;
          periods = p; // the backend now has them; reload must pick them up
        },
      );

      await tester.pumpWidget(
        MaterialApp(home: SchoolTimetablePage(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่ได้ตั้งค่าคาบเวลาเรียน'), findsOneWidget);
      await tester.tap(find.text('ตั้งค่าคาบเวลา'));
      await tester.pumpAndSettle();

      // 8 default rows offered, nothing written until saved
      expect(find.text('คาบ 8'), findsOneWidget);
      expect(saved, isEmpty);

      await tester.tap(find.text('บันทึกคาบเวลา'));
      await tester.pumpAndSettle();

      expect(saved.length, 8);
      expect(saved.first.startTime, '08:30');
      expect(saved.first.endTime, '09:20');
      expect(saved.last.periodNo, 8);
      // grid now renders from the reloaded periods
      expect(find.text('ยังไม่ได้ตั้งค่าคาบเวลาเรียน'), findsNothing);
      expect(find.text('คาบ 1'), findsOneWidget);
    },
  );

  testWidgets(
    'error from the backend is shown in Thai with a retry, never raw',
    (tester) async {
      final controller = SchoolTimetableController(
        loadTerms: () async => throw Exception('forbidden'),
        loadRooms: () async => const [],
        loadPeriods: () async => const [],
        loadSchedules: (a, b, c) async => const [],
        loadTeacherSubjects: () async => const [],
        loadStaff: () async => const [],
        setSlot:
            ({
              required termId,
              required gradeLevel,
              required room,
              required dayOfWeek,
              required periodNo,
              required subjectName,
              required teacherId,
            }) async {},
        clearSlot:
            ({
              required termId,
              required gradeLevel,
              required room,
              required dayOfWeek,
              required periodNo,
            }) async {},
        savePeriods: (_) async {},
      );
      await tester.pumpWidget(
        MaterialApp(home: SchoolTimetablePage(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('บัญชีนี้ไม่มีสิทธิ์จัดตารางเรียน'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.text('ลองใหม่'), findsOneWidget);
    },
  );
}
