import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_timetable_controller.dart';
import 'package:my_first_app/pages/school_admin/school_timetable_page.dart';
import 'package:shared_core/shared_core.dart';

/// D6 timetable v2 — overview → room → day. Every seam is asserted to be
/// called with the real ids/values the RPCs need; nothing renders from a
/// local fallback.
void main() {
  const term = Term(termId: 't1', termName: '1', academicYearName: '2569');
  const periods = [
    SchoolPeriod(periodNo: 1, startTime: '08:30:00', endTime: '09:20:00'),
    SchoolPeriod(
      periodNo: 2,
      startTime: '09:20:00',
      endTime: '10:10:00',
      kind: 'break',
      label: 'พักกลางวัน',
    ),
    SchoolPeriod(periodNo: 3, startTime: '10:10:00', endTime: '11:00:00'),
  ];
  const m11 = TimetableRoomOverview(
    gradeLevel: 'ม.1',
    room: '1',
    roomKey: 'ม.1/1',
    studentCount: 3,
    filledSlots: 1,
    lessonSlots: 10,
  );
  const m41 = TimetableRoomOverview(
    gradeLevel: 'ม.4',
    room: '1',
    roomKey: 'ม.4/1',
    studentCount: 2,
    filledSlots: 10,
    lessonSlots: 10,
  );
  final staff = [
    StaffDirectoryEntry(
      userId: 't1',
      fullName: 'ครูสมปอง',
      email: 'e',
      status: 'a',
      positionTitle: 'p',
      phone: '1',
      roles: const ['teacher'],
      administrativeDepartments: const [],
      subjectGroups: const [],
      headsDepartments: const [],
    ),
    StaffDirectoryEntry(
      userId: 'a1',
      fullName: 'แอดมิน',
      email: 'e',
      status: 'a',
      positionTitle: 'p',
      phone: '1',
      roles: const ['school_admin'],
      administrativeDepartments: const [],
      subjectGroups: const [],
      headsDepartments: const [],
    ),
  ];

  SchoolTimetableController make({
    List<SchoolPeriod> periodsOverride = periods,
    List<ClassSchedule> Function()? schedules,
    List<TeacherConflict> conflicts = const [],
    Future<void> Function({
      required String termId,
      required String gradeLevel,
      required String room,
      required String subjectName,
      required String? teacherId,
      required int periodNo,
      required int dayOfWeek,
    })?
    setSlot,
    Future<void> Function(List<SchoolPeriod>)? savePeriods,
    Future<int> Function({
      required String fromTermId,
      required String fromGradeLevel,
      required String fromRoom,
      required String toTermId,
      required String toGradeLevel,
      required String toRoom,
    })?
    copyRoom,
    Future<List<TeacherWeekSlot>> Function(String, String)? teacherWeek,
    Future<List<Term>> Function()? loadTerms,
  }) {
    return SchoolTimetableController(
      loadTerms: loadTerms ?? () async => const [term],
      loadPeriods: () async => periodsOverride,
      loadOverview: (_) async => const [m11, m41],
      loadSchedules: (a, b, c) async => schedules?.call() ?? const [],
      loadTeacherSubjects: () async => const [
        TeacherSubject(
          teacherId: 't1',
          subjectName: 'คณิต',
          fullName: 'ครูสมปอง',
        ),
      ],
      loadStaff: () async => staff,
      loadTeacherWeek: teacherWeek ?? (_, _) async => const [],
      loadConflicts: (_) async => conflicts,
      setSlot:
          setSlot ??
          ({
            required termId,
            required gradeLevel,
            required room,
            required subjectName,
            required teacherId,
            required periodNo,
            required dayOfWeek,
          }) async {},
      clearSlot:
          ({
            required termId,
            required gradeLevel,
            required room,
            required periodNo,
            required dayOfWeek,
          }) async {},
      savePeriods: savePeriods ?? (_) async {},
      copyRoom:
          copyRoom ??
          ({
            required fromTermId,
            required fromGradeLevel,
            required fromRoom,
            required toTermId,
            required toGradeLevel,
            required toRoom,
          }) async => 0,
      clearRoom:
          ({required termId, required gradeLevel, required room}) async => 0,
    );
  }

  Future<void> pump(WidgetTester tester, SchoolTimetableController c) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SchoolTimetablePage(controller: c)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('overview groups rooms by level and shows fill ratio', (
    tester,
  ) async {
    await pump(tester, make());
    expect(find.text('มัธยมต้น'), findsOneWidget);
    expect(find.text('มัธยมปลาย'), findsOneWidget);
    expect(find.text('ม.1/1'), findsOneWidget);
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('10/10'), findsOneWidget);
    expect(find.textContaining('จัดแล้ว 1 จาก 2 ห้อง'), findsOneWidget);
  });

  testWidgets('conflicts tile opens the clash list', (tester) async {
    await pump(
      tester,
      make(
        conflicts: const [
          TeacherConflict(
            teacherId: 't1',
            teacherName: 'ครูสมปอง',
            dayOfWeek: 1,
            periodNo: 1,
            rooms: ['ม.1/1', 'ม.1/2'],
          ),
        ],
      ),
    );
    await tester.tap(find.text('ครูชนกัน'));
    await tester.pumpAndSettle();
    expect(find.text('ครูถูกจัดชนกัน'), findsOneWidget);
    expect(find.textContaining('ม.1/1 และ ม.1/2'), findsOneWidget);
  });

  testWidgets(
    'room → day view: break is a band, empty lesson is tappable, save reaches setSlot with real ids',
    (tester) async {
      String? gotSubject;
      String? gotTeacher;
      int? gotDay;
      int? gotPeriod;
      String? gotRoom;
      final c = make(
        setSlot:
            ({
              required termId,
              required gradeLevel,
              required room,
              required subjectName,
              required teacherId,
              required periodNo,
              required dayOfWeek,
            }) async {
              gotSubject = subjectName;
              gotTeacher = teacherId;
              gotDay = dayOfWeek;
              gotPeriod = periodNo;
              gotRoom = '$gradeLevel|$room|$termId';
            },
      );
      await pump(tester, c);
      await tester.tap(find.text('ม.1/1'));
      await tester.pumpAndSettle();

      expect(find.text('ตารางเรียน ม.1/1'), findsOneWidget);
      // week grid: the break is one band across the week, lessons are 5 cells
      expect(find.textContaining('พักกลางวัน'), findsOneWidget);
      expect(find.byKey(const ValueKey('slot-1-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot-5-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot-1-2')), findsNothing);

      // Wednesday, period 1
      await tester.tap(find.byKey(const ValueKey('slot-3-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('วันพุธ · คาบ 1'), findsOneWidget);

      // no subjects yet → the sheet offers "first subject"
      await tester.tap(find.text('ใส่วิชาแรกของห้องนี้'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'คณิต');
      await tester.pumpAndSettle();
      // save disabled until a teacher is chosen
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'บันทึก'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      // only the teacher-role account is offered, never the admin
      expect(find.text('แอดมิน'), findsNothing);
      await tester.tap(find.text('ครูสมปอง').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(gotSubject, 'คณิต');
      expect(gotTeacher, 't1');
      expect(gotDay, 3);
      expect(gotPeriod, 1);
      expect(gotRoom, 'ม.1|1|t1');
    },
  );

  testWidgets('clash warning appears when the teacher is booked elsewhere', (
    tester,
  ) async {
    final c = make(
      teacherWeek: (_, _) async => const [
        TeacherWeekSlot(
          dayOfWeek: 1,
          periodNo: 1,
          gradeLevel: 'ม.1',
          roomKey: 'ม.1/2',
          subjectName: 'คณิต',
        ),
      ],
    );
    await pump(tester, c);
    await tester.tap(find.text('ม.1/1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slot-1-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ใส่วิชาแรกของห้องนี้'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'คณิต');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ครูสมปอง').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('สอน ม.1/2 (คณิต) อยู่แล้วในคาบนี้'),
      findsOneWidget,
    );
  });

  testWidgets('existing subjects of the room are one-tap picks', (
    tester,
  ) async {
    final c = make(
      schedules: () => const [
        ClassSchedule(
          courseId: 'c1',
          dayOfWeek: 1,
          periodNo: 1,
          startTime: '08:30:00',
          endTime: '09:20:00',
          subjectName: 'คณิต',
          teacherId: 't1',
          teacherName: 'ครูสมปอง',
        ),
      ],
    );
    await pump(tester, c);
    await tester.tap(find.text('ม.1/1'));
    await tester.pumpAndSettle();
    // the Monday block renders with its subject; Tuesday period 1 is empty
    expect(find.text('คณิต'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('slot-2-1')));
    await tester.pumpAndSettle();
    expect(find.text('วิชาที่ห้องนี้เรียนอยู่'), findsOneWidget);
    expect(find.textContaining('ครูสมปอง · 1 คาบ/สัปดาห์'), findsOneWidget);
    await tester.tap(find.text('คณิต').last);
    await tester.pumpAndSettle();
    // subject + teacher prefilled → save enabled immediately
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'บันทึก'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'no periods yet → in-page sheet with a lunch break; saved set reaches savePeriods',
    (tester) async {
      List<SchoolPeriod> saved = const [];
      final c = make(
        periodsOverride: const [],
        savePeriods: (p) async => saved = p,
      );
      await pump(tester, c);
      expect(find.text('ยังไม่ได้ตั้งค่าคาบเวลาเรียน'), findsOneWidget);
      await tester.tap(find.text('ตั้งค่าคาบเวลา'));
      await tester.pumpAndSettle();
      expect(find.text('พัก'), findsOneWidget); // default lunch row
      await tester.tap(find.text('บันทึกคาบเวลา'));
      await tester.pumpAndSettle();
      expect(saved.length, 9);
      expect(saved.where((p) => p.isBreak).length, 1);
      expect(saved.first.startTime, '08:30');
    },
  );

  testWidgets('backend error is shown in Thai with a retry, never raw', (
    tester,
  ) async {
    final c = make(loadTerms: () async => throw Exception('forbidden'));
    await pump(tester, c);
    expect(find.text('บัญชีนี้ไม่มีสิทธิ์จัดตารางเรียน'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.text('ลองใหม่'), findsOneWidget);
  });
}
