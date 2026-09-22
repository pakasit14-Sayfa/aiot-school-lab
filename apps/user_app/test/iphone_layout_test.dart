import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/student_safety_page.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_calendar_page.dart';
import 'package:my_first_app/pages/school_admin/school_timetable_page.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_timetable_controller.dart';

import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_variant_school_home.dart';
import 'package:my_first_app/widgets/sensor_card.dart';
import 'package:shared_core/shared_core.dart';

/// The app was only ever run in a desktop Chrome window until 2026-09-17.
/// The first run on an iPhone 17 Pro simulator (390pt wide) showed two
/// layouts that had silently relied on the wide window:
///   - every SensorCard on the AIoT dashboard overflowed its bottom by
///     36–150px and its label broke one character per line;
///   - the safety-history row overflowed 43px on the right when the
///     category was "ขอความช่วยเหลือด่วน (SOS)" with a severity badge.
/// Every other test in this suite pumps at 900px wide, which is why neither
/// ever failed. These pump at phone size; a RenderFlex overflow is thrown
/// as a FlutterError and fails the test on its own.
/// Widths covered: 360 (common Android), 375 (iPhone SE/8), 390 (iPhone
/// 14–16). Each test pumps at all three; a RenderFlex overflow at any of
/// them fails the test.
const _phoneSizes = [Size(360, 640), Size(375, 667), Size(390, 844)];

Future<void> _phone(WidgetTester tester, Widget home) async {
  for (final size in _phoneSizes) {
    await _phoneAt(tester, home, size);
  }
}

Future<void> _phoneAt(WidgetTester tester, Widget home, Size size) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(key: ValueKey(size), home: home));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AIoT sensor grid fits a 390pt phone with offline badges', (
    tester,
  ) async {
    final stale = DateTime(2026, 9, 1);
    await _phone(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SensorGrid(
            sensor: SensorModel(
              pm25: 39.8,
              co2: 448,
              tvoc: 46,
              temperature: 30.5,
              humidity: 41,
              lux: 56,
              updatedAt: stale,
              metricUpdatedAt: {
                'pm25': stale,
                'co2': stale,
                'tvoc': stale,
                'temperature': stale,
                'humidity': stale,
                'light_lux': stale,
              },
            ),
            aqiReading: (value: 1, ts: stale),
            gasReading: (value: 9, ts: stale),
          ),
        ),
      ),
    );
    expect(find.text('PM2.5'), findsOneWidget);
    expect(find.text('เซนเซอร์ไม่ทำงาน'), findsWidgets);
  });

  testWidgets(
    'safety history row keeps the SOS title, badge and status on a phone',
    (tester) async {
      await _phone(
        tester,
        StudentSafetyPage(
          loadRoom: () async =>
              const MyStudentRoom(room: 'ม.1/1', gradeLevel: 'ม.1'),
          loadIncidents: () async => [
            MyIncidentReport(
              id: 'inc-1',
              category: IncidentCategory.sos,
              room: null,
              status: 'closed',
              createdAt: DateTime(2026, 9, 17, 15, 18),
              acknowledgedAt: null,
              closedAt: DateTime(2026, 9, 17, 16),
              severity: 'high',
              reason: 'เจ็บป่วย / ไม่สบายด่วน',
            ),
          ],
          watchIncidents: () => const Stream.empty(),
        ),
      );
      expect(find.text('🔴 เหตุใหญ่'), findsOneWidget);
    },
  );

  testWidgets('student home hero fits a 390pt phone with no data', (
    tester,
  ) async {
    await _phone(
      tester,
      Scaffold(
        body: StudentVariantSchoolHome(
          loadCourses: () async => const [],
          loadGrades: () async => const [],
          loadNotifications: () async => const [],
          loadLessons: (_) async => const [],
          loadAssignments: (_) async => const [],
          loadSubmissionVersions: (_) async => const [],
          sensorStreamOverride: const Stream.empty(),
          rawReadingsStreamOverride: const Stream.empty(),
          now: () => DateTime(2026, 9, 18, 22),
        ),
      ),
    );
    expect(find.text('สวัสดีตอนเย็น 👋'), findsOneWidget);
    expect(find.text('ความคืบหน้าการเรียน'), findsOneWidget);
    expect(find.text('0 บทเรียน'), findsOneWidget);
    expect(find.text('ส่งแล้ว 0/0'), findsOneWidget);
  });

  testWidgets('student calendar fits a 390pt phone with no events', (
    tester,
  ) async {
    await _phone(
      tester,
      StudentCalendarPage(
        loadCourses: () async => const [],
        loadSchedule: () async => const [],
        loadTasks: () async => const [],
        loadAssignmentsForCourse: (_) async => const [],
      ),
    );
    expect(find.text('รายการวันนี้'), findsOneWidget);
    expect(find.text('ไม่มีรายการในวันนี้'), findsOneWidget);
  });

  testWidgets(
    'school_timetable_page (overview + room day view) does not overflow on phones',
    (tester) async {
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
      final controller = SchoolTimetableController(
        loadTerms: () async => const [
          Term(
            termId: '1',
            termName: 'ภาคเรียนที่ 1',
            academicYearName: '2569',
          ),
        ],
        loadPeriods: () async => periods,
        loadOverview: (_) async => const [
          TimetableRoomOverview(
            gradeLevel: 'ม.1',
            room: '1',
            roomKey: 'ม.1/1',
            studentCount: 32,
            filledSlots: 4,
            lessonSlots: 10,
          ),
          TimetableRoomOverview(
            gradeLevel: 'ม.6',
            room: '2',
            roomKey: 'ม.6/2',
            studentCount: 28,
            filledSlots: 10,
            lessonSlots: 10,
          ),
        ],
        loadSchedules: (a, b, c) async => const [
          ClassSchedule(
            courseId: 'c',
            dayOfWeek: 1,
            periodNo: 1,
            startTime: '08:30:00',
            endTime: '09:20:00',
            subjectName: 'วิทยาศาสตร์และเทคโนโลยี (ชีววิทยา)',
            teacherId: 't',
            teacherName: 'ครูสมชาย ใจดีมากที่สุดในโลก',
          ),
        ],
        loadTeacherSubjects: () async => const [],
        loadStaff: () async => const [],
        loadTeacherWeek: (_, _) async => const [],
        loadConflicts: (_) async => const [
          TeacherConflict(
            teacherId: 't',
            teacherName: 'ครูสมชาย',
            dayOfWeek: 1,
            periodNo: 1,
            rooms: ['ม.1/1', 'ม.1/2'],
          ),
        ],
        setSlot:
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
        savePeriods: (_) async {},
        copyRoom:
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
      await _phone(tester, SchoolTimetablePage(controller: controller));
      // overview rendered; open the room and render the day view too
      await controller.openRoom(controller.rooms.first);
      await tester.pumpAndSettle();
      expect(find.text('ตารางเรียน ม.1/1'), findsOneWidget);
    },
  );
}
