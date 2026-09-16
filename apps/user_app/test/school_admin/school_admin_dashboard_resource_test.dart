import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_dashboard_page.dart';
import 'package:shared_core/shared_core.dart';

/// The resource card on the School Admin home page used to be four `const`
/// literals — "428 kWh", "12.6 m³", "PM2.5 21" plus invented day-over-day
/// deltas — shown as confidently on an empty database as on a real one.
/// These tests keep loading / data / empty / error distinguishable so that
/// cannot come back.

EnergyUsageSummary _energy({double kwh = 128.5, int devices = 3}) =>
    EnergyUsageSummary(
      deviceCount: devices,
      totalKwh: kwh,
      electricityRateThb: 4.2,
      isRateDefault: false,
      estimatedCostThb: kwh * 4.2,
      disclaimer: '',
    );

WaterUsageSummary _water({double m3 = 9.5, int devices = 2}) =>
    WaterUsageSummary(
      deviceCount: devices,
      totalM3: m3,
      waterRateThb: 18,
      isRateDefault: false,
      estimatedCostThb: m3 * 18,
      disclaimer: '',
    );

SchoolAdminDashboardSummary _summary() => const SchoolAdminDashboardSummary(
  schoolId: 'school-1',
  schoolName: 'โรงเรียนทดสอบ',
  schoolCode: 'TEST-1',
  studentsCount: 0,
  teachersCount: 0,
  devicesCount: 0,
  devicesOnline: 0,
  buildingsCount: 0,
  roomsCount: 0,
  openAlertsCount: 0,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<EnergyUsageSummary?> Function()? loadEnergy,
  Future<WaterUsageSummary?> Function()? loadWater,
  Future<SensorModel?> Function()? loadSensor,
  Future<Set<String>> Function()? loadMetricsWithData,
}) async {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminDashboardPage(
        loadEnergy: loadEnergy ?? () async => _energy(),
        loadWater: loadWater ?? () async => _water(),
        loadSensor: loadSensor ?? () async => null,
        loadMetricsWithData: loadMetricsWithData ?? () async => <String>{},
        // seam ใหม่จาก sidebar identity fix — ไม่เกี่ยวกับสิ่งที่ไฟล์นี้
        // ทดสอบ (การ์ดทรัพยากรพลังงาน/น้ำ) ให้ resolve จริงเสมอกันชน
        // กับ 'ยังไม่มีข้อมูล' ที่ sidebar โชว์ตอน RPC จริงล้มในเทส
        loadSummary: () async => _summary(),
      ),
    ),
  );
}

void main() {
  setUp(() {
    // _UserCard falls back to 'ยังไม่มีข้อมูล' for a signed-out user (fixed
    // in 7c091b4 to stop showing a fake 'admin@aiot-school.ac.th'); that
    // fallback collides with this file's own 'ยังไม่มีข้อมูล' assertions
    // unless a real signed-in user is present, same as
    // school_admin_dashboard_page_test.dart.
    currentUserModel = const UserModel(
      uid: 'u-admin-1',
      name: 'แอดมินโรงเรียน',
      email: 'schooladmin@aiot-school-lab.local',
      role: UserRole.schoolAdmin,
      schoolId: 'sch-1',
    );
  });

  tearDown(() {
    currentUserModel = null;
  });

  testWidgets('real utility totals are rendered, not invented ones', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('128.5 kWh'), findsOneWidget);
    expect(find.textContaining('9.5 m³'), findsOneWidget);

    // The old hardcoded values must never reappear.
    expect(find.textContaining('428 kWh'), findsNothing);
    expect(find.textContaining('12.6 m³'), findsNothing);
    expect(find.textContaining('PM2.5 21'), findsNothing);
  });

  testWidgets('invented day-over-day trends are gone', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    // The summary RPCs return a window total, not a previous-period delta,
    // so any "x% from yesterday" line would have to be fabricated.
    expect(find.textContaining('จากเมื่อวาน'), findsNothing);
  });

  testWidgets('no utility data says so instead of showing a number', (
    tester,
  ) async {
    await _pump(
      tester,
      loadEnergy: () async => null,
      loadWater: () async => null,
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.textContaining('kWh'), findsNothing);
  });

  testWidgets(
    'PM2.5 is hidden unless that metric really has readings, because '
    'SensorModel reports an absent metric as 0',
    (tester) async {
      // A sensor object exists, but pm25 is not among the metrics that have
      // data. Trusting sensor.pm25 here would print a confident "PM2.5 0".
      await _pump(
        tester,
        loadSensor: () async => SensorModel(
          pm25: 0,
          temperature: 27,
          humidity: 55,
          updatedAt: DateTime(2026, 9, 7),
          metricUpdatedAt: {'temperature': DateTime(2026, 9, 7)},
        ),
        loadMetricsWithData: () async => <String>{'temperature'},
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('PM2.5 0'), findsNothing);
      expect(find.text('ยังไม่มีเซนเซอร์ที่ส่งค่า PM2.5'), findsOneWidget);
    },
  );

  testWidgets('a failed load shows a retry that actually re-issues the call', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadEnergy: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดไม่สำเร็จ'), findsWidgets);
    expect(find.textContaining('backend detail'), findsNothing);
    expect(calls, 1);

    // Scope to this card's own retry. Other panels on the dashboard call the
    // real services and also fail in a test environment, so a bare
    // find.text('ลองใหม่') matches several buttons and .first can land on
    // someone else's — which is exactly what made this assertion pass
    // vacuously at first.
    final resourceCardActions = find.ancestor(
      of: find.text('ดูรายละเอียด'),
      matching: find.byType(Wrap),
    );
    await tester.tap(
      find.descendant(
        of: resourceCardActions.first,
        matching: find.text('ลองใหม่'),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('loading is not shown as an empty state', (tester) async {
    final gate = Completer<EnergyUsageSummary?>();
    await _pump(tester, loadEnergy: () => gate.future);
    await tester.pump();

    expect(find.text('…'), findsWidgets);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);

    gate.complete(_energy());
    await tester.pumpAndSettle();
    expect(find.text('…'), findsNothing);
  });

  testWidgets('automation rules state whether they actually run', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    // Verified against pg_trigger and cron.job on 2026-09-07: only the
    // threshold check runs. The card used to present all four as working;
    // since 2026-09-16 the three that never ran are gone (DoD: a rule with
    // no backend is removed, not shown as "coming soon").
    expect(find.text('เปิดใช้งาน'), findsOneWidget);
    expect(find.text('ยังไม่เปิดใช้งาน'), findsNothing);
  });
}
