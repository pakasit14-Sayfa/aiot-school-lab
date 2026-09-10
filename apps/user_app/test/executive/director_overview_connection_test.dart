import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_overview_controller.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';

DirectorOverviewData data({
  bool empty = false,
  List<AppNotification> notices = const [],
  List<SchoolHomeroomAttendance> studentAttendance = const [],
  StaffAttendanceSummary? staffAttendance,
}) => DirectorOverviewData(
  counts: empty ? {} : {'student': 3, 'teacher': 1},
  devices: [],
  incidents: [],
  tracks: [],
  notices: notices,
  energy: empty
      ? []
      : [UtilityTrendPoint(day: DateTime(2026, 9, 8), value: 12.5)],
  water: [],
  studentAttendance: studentAttendance,
  staffAttendance: staffAttendance,
);
Widget page(DirectorOverviewController c, {ValueChanged<int>? navigate}) =>
    MaterialApp(
      home: Scaffold(
        body: DirectorOverviewPage(
          controller: c,
          onNavigate: navigate ?? (_) {},
          sensorStreamOverride: Stream<SensorModel?>.value(null),
          rawReadingsStreamOverride: Stream.value(<Map<String, dynamic>>[]),
        ),
      ),
    );
void main() {
  testWidgets('loading error retry empty never invent totals or events', (
    t,
  ) async {
    final pending = Completer<DirectorOverviewData>();
    var calls = 0;
    final c = DirectorOverviewController(
      loader: (_) =>
          calls++ == 0 ? pending.future : Future.value(data(empty: true)),
    );
    addTearDown(c.dispose);
    await t.pumpWidget(page(c));
    expect(find.text('กำลังโหลดภาพรวม'), findsOneWidget);
    expect(find.text('3 คน'), findsNothing);
    pending.completeError(StateError('secret'));
    await t.pumpAndSettle();
    expect(find.text('โหลดภาพรวมไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    await t.ensureVisible(find.text('ลองอีกครั้ง'));
    await t.tap(find.text('ลองอีกครั้ง'));
    await t.pumpAndSettle();
    expect(find.text('ยังไม่มีข้อมูลภาพรวม'), findsOneWidget);
    expect(find.textContaining('ทะเลาะวิวาท'), findsNothing);
  });
  testWidgets(
    'real values and navigation work on phone; missing trends stay unknown',
    (t) async {
      await t.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = DirectorOverviewController(loader: (_) async => data());
      addTearDown(c.dispose);
      int? target;
      await t.pumpWidget(page(c, navigate: (v) => target = v));
      await t.pumpAndSettle();
      final studentCard = find.byKey(const ValueKey('overview_summary_0'));
      expect(find.text('3'), findsOneWidget);
      await t.ensureVisible(studentCard);
      await t.tap(studentCard);
      expect(target, 2);
      expect(find.text('รวม 12.50 kWh ในวันที่มีข้อมูล'), findsOneWidget);
      expect(find.text('ยังไม่มีข้อมูลย้อนหลัง'), findsOneWidget);
      expect(find.text('ข้อมูลจำลอง'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('notice filters and source buttons navigate to working pages', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final notices = [
      AppNotification(
        id: 'meeting-1',
        type: 'meeting_invited',
        category: 'meeting_invited',
        title: 'ประชุมประจำเดือน',
        body: 'ตรวจสอบวาระการประชุม',
        createdAt: DateTime(2026, 9, 9, 9),
        readAt: DateTime(2026, 9, 9, 10),
      ),
      AppNotification(
        id: 'incident-1',
        type: 'incident_report',
        category: 'incident_report',
        title: 'แจ้งเหตุผิดปกติ',
        body: 'ตรวจสอบเหตุการณ์ล่าสุด',
        createdAt: DateTime(2026, 9, 9, 11),
      ),
    ];
    final c = DirectorOverviewController(
      loader: (_) async => data(notices: notices),
    );
    addTearDown(c.dispose);
    int? target;
    await t.pumpWidget(page(c, navigate: (v) => target = v));
    await t.pumpAndSettle();

    await t.ensureVisible(find.text('ต้องติดตาม (1)'));
    await t.tap(find.text('ต้องติดตาม (1)'));
    await t.pump();
    expect(find.text('แจ้งเหตุผิดปกติ'), findsOneWidget);
    expect(find.text('ประชุมประจำเดือน'), findsNothing);

    await t.tap(find.text('ทั้งหมด (2)'));
    await t.pump();
    await t.ensureVisible(
      find.byKey(const ValueKey('overview_notice_action_meeting-1')),
    );
    await t.tap(find.byKey(const ValueKey('overview_notice_action_meeting-1')));
    expect(target, 5);

    await t.ensureVisible(
      find.byKey(const ValueKey('overview_notice_action_incident-1')),
    );
    await t.tap(
      find.byKey(const ValueKey('overview_notice_action_incident-1')),
    );
    expect(target, 1);

    await t.ensureVisible(
      find.byKey(const ValueKey('overview_notice_view_all')),
    );
    await t.tap(find.byKey(const ValueKey('overview_notice_view_all')));
    expect(target, 10);
  });
  test('stale period reads cannot overwrite a new period', () async {
    final a = Completer<DirectorOverviewData>();
    final b = Completer<DirectorOverviewData>();
    final c = DirectorOverviewController(
      loader: (days) => days == 7 ? a.future : b.future,
    );
    addTearDown(c.dispose);
    final one = c.load();
    final two = c.load(period: 30);
    b.complete(data());
    await two;
    a.complete(data(empty: true));
    await one;
    expect(c.days, 30);
    expect(c.data!.counts['student'], 3);
  });
}
