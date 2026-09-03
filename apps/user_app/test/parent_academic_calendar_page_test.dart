import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_academic_calendar_page.dart';
import 'package:shared_core/shared_core.dart';

const _student = LinkedStudentItem(
  studentId: 'student-1',
  firstName: 'นักเรียน',
  lastName: 'ทดสอบ',
  schoolId: 'school-1',
);

Widget _app(
  ParentCalendarLoader loader, {
  ParentCalendarStudentsLoader? studentsLoader,
}) => MaterialApp(
  home: ParentAcademicCalendarPage(
    eventsLoader: loader,
    studentsLoader: studentsLoader ?? () async => const [_student],
    now: () => DateTime(2026, 9, 3, 10),
  ),
);

void main() {
  testWidgets('shows explicit empty cards without prototype events', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(_app((_) async => const []));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('กิจกรรมวันวิทยาศาสตร์'), findsNothing);
    expect(find.text('ประชุมผู้ปกครองออนไลน์'), findsNothing);
    expect(find.text('ภาคเรียนที่ 1 / 2569'), findsNothing);
  });

  testWidgets('keeps failures distinct from empty data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      _app((_) async => throw Exception('network_error')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('distinguishes no linked student from an empty calendar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      _app((_) async => const [], studentsLoader: () async => const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีนักเรียนที่เชื่อมกับบัญชีนี้'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('derives summary upcoming and selected-day cards from events', (
    tester,
  ) async {
    final events = [
      CalendarEventItem(
        eventId: 'event-1',
        title: 'สอบวิทยาศาสตร์',
        description: 'ห้องสอบ 201',
        location: 'อาคาร 2',
        startDate: DateTime(2026, 9, 3),
        eventType: 'exam',
      ),
      CalendarEventItem(
        eventId: 'event-2',
        title: 'วันกีฬาสี',
        startDate: DateTime(2026, 9, 10),
        eventType: 'activity',
      ),
    ];
    await tester.binding.setSurfaceSize(const Size(1200, 2000));
    await tester.pumpWidget(_app((_) async => events));
    await tester.pumpAndSettle();

    expect(find.text('สอบวิทยาศาสตร์'), findsWidgets);
    expect(find.text('วันกีฬาสี'), findsWidgets);
    expect(find.text('ห้องสอบ 201'), findsWidgets);
    expect(find.text('2 กำหนดการถัดไป'), findsOneWidget);
    expect(find.text('10 วัน'), findsNothing);
  });
}
