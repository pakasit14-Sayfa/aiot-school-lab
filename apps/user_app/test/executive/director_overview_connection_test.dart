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
  TeacherWorkloadSummary? teacherWorkload,
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
  teacherWorkload: teacherWorkload,
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
      final teacherCard = find.byKey(const ValueKey('overview_summary_1'));
      expect(find.text('3'), findsOneWidget);
      await t.ensureVisible(teacherCard);
      await t.tap(teacherCard);
      expect(target, 3);
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
  testWidgets(
    'teacher workload bubbles show the 4 real weekly period categories, not invented ones',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      const workload = TeacherWorkloadSummary(
        regularPeriods: 6,
        activityLabPeriods: 3,
        regularTeacherCount: 4,
        activityLabTeacherCount: 2,
        substitutionRecorded: 1,
        substitutionNeeded: 2,
        prepMeetingCount: 0,
        prepMeetingTeacherCount: 0,
      );
      final c = DirectorOverviewController(
        loader: (_) async => data(teacherWorkload: workload),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(page(c));
      await t.pumpAndSettle();
      expect(find.text('สอนในตารางปกติ'), findsOneWidget);
      expect(find.text('6 คาบ (ครู 4 คน)'), findsOneWidget);
      expect(find.text('กิจกรรม & แล็บ'), findsOneWidget);
      expect(find.text('3 คาบ (ครู 2 คน)'), findsOneWidget);
      expect(find.text('จัดครูสอนแทน'), findsOneWidget);
      // ไม่ใช่ "ครบ 100%" ที่แต่งขึ้นแบบเวอร์ชัน 7 ก.ย. — ต้องบอกสัดส่วนที่
      // บันทึกแล้วจริงจากคาบที่ต้องจัดครูสอนแทนจริง
      expect(find.text('1 คาบ (บันทึกแล้ว 1/2)'), findsOneWidget);
      expect(find.text('เตรียมสอน/ประชุม'), findsOneWidget);
      expect(find.text('0 คาบ (ครู 0 คน)'), findsOneWidget);
      // bubble % ของ 4 หมวดจริง (total = 6+3+1+0 = 10): เตรียมสอน/ประชุม เป็น
      // 0 จึงไม่ขึ้นเป็นฟองเลย (กันฟอง 0% ทับกันจนอ่านไม่ออก)
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      // red-team: 0 เตรียมสอน/ประชุม อาจแปลว่ายังไม่มีใครบันทึก ไม่ใช่ไม่มี
      // เหตุการณ์จริง — ต้องมีคำเตือนกำกับ ไม่ให้ ผอ. เข้าใจผิดว่าระบบพัง
      expect(
        find.textContaining('นับจากการบันทึกของครู/ผู้ดูแลเอง'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'no self-report note when substitution and prep/meeting are both genuinely recorded',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      const workload = TeacherWorkloadSummary(
        regularPeriods: 6,
        activityLabPeriods: 3,
        regularTeacherCount: 4,
        activityLabTeacherCount: 2,
        substitutionRecorded: 2,
        substitutionNeeded: 2,
        prepMeetingCount: 3,
        prepMeetingTeacherCount: 2,
      );
      final c = DirectorOverviewController(
        loader: (_) async => data(teacherWorkload: workload),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(page(c));
      await t.pumpAndSettle();
      // ทั้งสองหมวดมีข้อมูลจริงไม่เป็นศูนย์ — ไม่ต้องมีคำเตือน ไม่งั้นจะกลาย
      // เป็นข้อความรกจอที่ไม่มีความหมายเมื่อระบบถูกใช้งานจริงแล้ว
      expect(
        find.textContaining('นับจากการบันทึกของครู/ผู้ดูแลเอง'),
        findsNothing,
      );
    },
  );
  testWidgets(
    'substitution legend says there is nothing to cover instead of a fake 100%',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      const workload = TeacherWorkloadSummary(
        regularPeriods: 4,
        activityLabPeriods: 0,
        regularTeacherCount: 2,
        activityLabTeacherCount: 0,
        substitutionRecorded: 0,
        substitutionNeeded: 0,
        prepMeetingCount: 1,
        prepMeetingTeacherCount: 1,
      );
      final c = DirectorOverviewController(
        loader: (_) async => data(teacherWorkload: workload),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(page(c));
      await t.pumpAndSettle();
      expect(find.text('ไม่มีคาบที่ต้องจัดครูสอนแทน'), findsOneWidget);
      expect(find.textContaining('บันทึกแล้ว'), findsNothing);
    },
  );
  testWidgets(
    'tapping the student summary card opens a real attendance breakdown, not a navigate-away',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final rooms = [
        const SchoolHomeroomAttendance(
          gradeLevel: 'ม.1',
          room: 'ม.1/1',
          studentCount: 30,
          present: 28,
          late: 1,
          absent: 1,
          excused: 0,
          unknown: 0,
        ),
        const SchoolHomeroomAttendance(
          gradeLevel: 'ม.2',
          room: 'ม.2/1',
          studentCount: 30,
          present: 25,
          late: 0,
          absent: 3,
          excused: 2,
          unknown: 0,
        ),
      ];
      final c = DirectorOverviewController(
        loader: (_) async => data(studentAttendance: rooms),
      );
      addTearDown(c.dispose);
      int? target;
      await t.pumpWidget(page(c, navigate: (v) => target = v));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('overview_summary_0')));
      await t.pumpAndSettle();
      expect(target, isNull, reason: 'ควรเปิด popup ไม่ใช่เปลี่ยนหน้า');
      expect(find.text('การเข้าเรียนของนักเรียน'), findsWidgets);
      expect(find.textContaining('สรุปการเข้าเรียนของนักเรียนรายวัน'), findsOneWidget);
      expect(find.text('มาเรียน 28 / 30 คน (93.3%)'), findsOneWidget);
      expect(find.text('มาเรียน 25 / 30 คน (83.3%)'), findsOneWidget);
      expect(find.text('ข้อมูลจำลอง'), findsNothing);

      await t.tap(find.text('ดูรายงานการเข้าเรียน >'));
      await t.pumpAndSettle();
      expect(target, 3);
    },
  );
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

  testWidgets(
    'sensor tiles with long danger-level real values do not overflow',
    (t) async {
      addTearDown(() => t.binding.setSurfaceSize(null));
      final stale = DateTime.now().toUtc().subtract(const Duration(hours: 6));
      final sensor = SensorModel(
        pm25: 999,
        co2: 9999,
        tvoc: 9999,
        temperature: 99.9,
        humidity: 100,
        lux: 99999,
        updatedAt: stale,
        metricUpdatedAt: {
          'pm25': stale,
          'temperature': stale,
          'humidity': stale,
          'light_lux': stale,
          'co2': stale,
          'tvoc': stale,
        },
      );
      final c = DirectorOverviewController(loader: (_) async => data());
      addTearDown(c.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectorOverviewPage(
              controller: c,
              onNavigate: (_) {},
              sensorStreamOverride: Stream<SensorModel?>.value(
                sensor,
              ).asBroadcastStream(),
              rawReadingsStreamOverride: Stream.value([
                {'metric': 'aqi', 'value': 5, 'ts': stale.toIso8601String()},
                {
                  'metric': 'gas_mq2_percent',
                  'value': 100,
                  'ts': stale.toIso8601String(),
                },
              ]).asBroadcastStream(),
            ),
          ),
        ),
      );
      for (final size in [
        const Size(360, 800),
        const Size(768, 1024),
        const Size(1200, 900),
        const Size(1440, 900),
      ]) {
        await t.binding.setSurfaceSize(size);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'Layout at $size');
      }
    },
  );
}
