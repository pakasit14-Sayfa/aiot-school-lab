import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_academic_calendar_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page looked connected and was not.
///
/// `_loadSchoolSchedules()` awaited a real RPC and dropped the result inside
/// `catch (_) {}`, while `_initCalendarEvents()` built 123 lines of fixed
/// August-2026 entries — "ประชุมฝ่ายบริหาร 09:00-10:30 ห้องประชุม 1",
/// "ประชุมหัวหน้ากลุ่มสาระ", attendees, alert-before times, the lot. It always
/// opened on August 2026 whatever the real month, and the summary cards read
/// '12', '4', '3' and '72' — that last one a claim about days remaining in the
/// term, which nothing in the schema records.
///
/// It is now driven by `list_calendar_events` (no role gate of its own, so
/// executive can read it) and `list_all_school_schedules`.

CalendarEventItem _event({
  required String title,
  required DateTime date,
  String type = 'activity',
  String? location,
}) => CalendarEventItem(
  eventId: 'evt-$title',
  title: title,
  description: 'รายละเอียดจริงจากฐานข้อมูล',
  location: location,
  startDate: date,
  endDate: null,
  eventType: type,
);

Future<void> _pump(
  WidgetTester tester, {
  CalendarEventsLoader? events,
  SchoolSchedulesLoader? schedules,
}) async {
  tester.view.physicalSize = const Size(1500, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorAcademicCalendarPage(
          loadEvents: events ?? () async => const <CalendarEventItem>[],
          loadSchedules: schedules ?? () async => const <SchoolScheduleItem>[],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no invented events survive', (tester) async {
    await _pump(tester);

    for (final invented in <String>[
      'ประชุมฝ่ายบริหาร',
      'ประชุมหัวหน้ากลุ่มสาระ',
      'ห้องประชุม 1',
      '09:00 - 10:30',
      'แจ้งเตือนก่อน 30 นาที',
      'ผู้อำนวยการ / รองผู้อำนวยการ / หัวหน้าฝ่าย',
      'สอบกลางภาคเริ่มในอีก 4 วัน',
      'หัวหน้ากลุ่มสาระ 8 กลุ่ม',
    ]) {
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'ยังพบของที่แต่งขึ้น: $invented',
      );
    }
  });

  testWidgets('summary cards count the real calendar, not fixed numbers', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pump(
      tester,
      events: () async => [
        _event(title: 'สอบปลายภาค', date: now, type: 'exam'),
        _event(
          title: 'กีฬาสี',
          date: now.add(const Duration(days: 3)),
          type: 'activity',
        ),
        // Outside the 7-day window, still inside this month's grid only if
        // the month happens to contain it — counted for exams regardless.
        _event(
          title: 'สอบซ่อม',
          date: now.add(const Duration(days: 40)),
          type: 'exam',
        ),
      ],
    );

    // Two exams across the whole calendar.
    expect(find.text('2'), findsWidgets);
    // The fixed values this page used to print no matter what.
    expect(find.text('72'), findsNothing);
    expect(find.textContaining('เหลืออีก 2 รายการ'), findsNothing);
    expect(find.textContaining('วันเรียนคงเหลือ'), findsNothing);
  });

  testWidgets('reminders count down to real dates and vanish when there are none', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pump(
      tester,
      events: () async => [
        _event(
          title: 'สอบกลางภาค',
          date: now.add(const Duration(days: 4)),
          type: 'exam',
        ),
      ],
    );

    expect(find.textContaining('สอบกลางภาค — อีก 4 วัน'), findsOneWidget);
  });

  testWidgets('a failed load says so and prints no counts', (tester) async {
    await _pump(
      tester,
      events: () async => throw StateError('calendar_unreachable'),
    );

    expect(
      find.textContaining('โหลดปฏิทินไม่สำเร็จ'),
      findsOneWidget,
    );
    // Counts fall back to an em dash rather than to zero, which would read as
    // "this school has nothing scheduled".
    expect(find.text('—'), findsWidgets);
    expect(find.text('0'), findsNothing);
    expect(find.textContaining('calendar_unreachable'), findsNothing);
  });

  testWidgets('an empty calendar is not a failure', (tester) async {
    await _pump(tester);

    expect(find.textContaining('โหลดปฏิทินไม่สำเร็จ'), findsNothing);
    expect(find.text('0'), findsWidgets);
  });
}
