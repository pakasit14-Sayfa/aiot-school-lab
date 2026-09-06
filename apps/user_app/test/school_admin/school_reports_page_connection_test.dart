import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_reports_page.dart';
import 'package:shared_core/shared_core.dart';

/// Before this suite the page had no loading state, no error state, and
/// `catch (_) {}` swallowing every failure — a failed load and a school with
/// genuinely no data both rendered the same '--'. These tests pin the four
/// states apart so that cannot regress silently.

SchoolAdminDashboardSummary _summary({
  int students = 120,
  int devices = 8,
  int online = 5,
  int buildings = 3,
  int rooms = 24,
  int alerts = 2,
}) => SchoolAdminDashboardSummary(
  schoolId: 'school-1',
  schoolName: 'โรงเรียนทดสอบ',
  schoolCode: 'TEST-1',
  studentsCount: students,
  teachersCount: 10,
  devicesCount: devices,
  devicesOnline: online,
  buildingsCount: buildings,
  roomsCount: rooms,
  openAlertsCount: alerts,
);

SchoolAdminAuditLog _log(String action) => SchoolAdminAuditLog(
  id: 1,
  action: action,
  target: 'reports',
  detail: 'รายละเอียดจริง',
  actorName: 'ผู้ดูแล ทดสอบ',
  actorRole: 'school_admin',
  createdAt: DateTime(2026, 9, 6, 10, 30),
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<SchoolAdminDashboardSummary> Function() loadSummary,
  required Future<List<SchoolAdminAuditLog>> Function() loadLogs,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolReportsPage(loadSummary: loadSummary, loadLogs: loadLogs),
    ),
  );
}

void main() {
  testWidgets('loading is visually distinct from an empty result', (
    tester,
  ) async {
    final gate = Completer<SchoolAdminDashboardSummary>();
    await _pump(
      tester,
      loadSummary: () => gate.future,
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pump();

    expect(find.text('กำลังโหลด…'), findsOneWidget);
    expect(
      find.textContaining('ยังไม่มีข้อมูล'),
      findsNothing,
      reason: 'a slow load must not read as "this school has no data"',
    );

    gate.complete(_summary());
    await tester.pumpAndSettle();
    expect(find.text('กำลังโหลด…'), findsNothing);
  });

  testWidgets('real numbers are rendered, including a genuine zero', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSummary: () async => _summary(students: 0, alerts: 0),
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pumpAndSettle();

    // A real 0 must show as 0, never as an empty state — that distinction is
    // the whole point of separating "no data" from "data that happens to be 0".
    expect(find.text('0'), findsWidgets);
    expect(find.text('3 / 24'), findsOneWidget);
  });

  testWidgets('an empty log list says so honestly instead of staying blank', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSummary: () async => _summary(),
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูลประวัติการใช้งานรายงาน'), findsOneWidget);
  });

  testWidgets('a failed load surfaces a retryable error, not a silent "--"', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadSummary: () async {
        calls++;
        throw StateError('backend detail that must not reach the user');
      },
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลรายงานไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    expect(
      find.textContaining('backend detail'),
      findsNothing,
      reason: 'raw backend text must never be shown to the user',
    );
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a recovered retry clears the error and shows real data', (
    tester,
  ) async {
    var shouldFail = true;
    await _pump(
      tester,
      loadSummary: () async {
        if (shouldFail) throw StateError('transient');
        return _summary(students: 321);
      },
      loadLogs: () async => <SchoolAdminAuditLog>[_log('report.export')],
    );
    await tester.pumpAndSettle();
    expect(find.text('โหลดข้อมูลรายงานไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลรายงานไม่สำเร็จ กรุณาลองใหม่'), findsNothing);
    expect(find.text('321'), findsOneWidget);
  });
}
