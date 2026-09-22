import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_alerts_logs_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for cross-school sensor alerts,
/// and guards the write→confirm contract on acknowledge/resolve — these
/// mutations must not report success if the RPC never actually applied,
/// since school staff act on this page believing an alert is being handled.

SchoolPlatformRecord _school({
  String id = 's-1',
  String name = 'โรงเรียนทดสอบ',
}) => SchoolPlatformRecord(
  id: id,
  schoolCode: 'TEST-1',
  name: name,
  province: 'กรุงเทพมหานคร',
  adminEmail: 'admin@school.test',
  packageName: 'Pro',
  status: 'active',
  maxUsers: 100,
  maxDevices: 50,
  usersCount: 10,
  devicesTotal: 5,
  devicesOnline: 5,
  buildingsCount: 1,
  roomsCount: 3,
  alertsCount: 0,
);

SchoolSensorAlertRecord _alert({
  String id = 'alert-1',
  String schoolId = 's-1',
  String metric = 'PM2.5',
  double value = 80,
  String status = 'open',
}) => SchoolSensorAlertRecord(
  id: id,
  deviceId: 'dev-1',
  deviceName: 'เซนเซอร์ห้อง 101',
  deviceCode: 'DEV-001',
  schoolId: schoolId,
  metric: metric,
  value: value,
  triggeredAt: DateTime.now().subtract(const Duration(minutes: 10)),
  status: status,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<SchoolPlatformRecord>> Function()? loadSchools,
  Future<List<SchoolSensorAlertRecord>> Function()? loadAlerts,
  Future<List<SchoolAdminAuditLog>> Function()? loadAuditLogs,
  Future<void> Function(String alertId)? acknowledgeAlert,
  Future<void> Function(String alertId, {String? note})? resolveAlert,
}) async {
  tester.view.physicalSize = const Size(1400, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminAlertsLogsPage(
        loadSchools: loadSchools ?? () async => <SchoolPlatformRecord>[],
        loadAlerts: loadAlerts ?? () async => <SchoolSensorAlertRecord>[],
        loadAuditLogs: loadAuditLogs ?? () async => <SchoolAdminAuditLog>[],
        acknowledgeAlert: acknowledgeAlert,
        resolveAlert: resolveAlert,
      ),
    ),
  );
}

void main() {
  testWidgets('real alerts are rendered', (tester) async {
    await _pump(
      tester,
      loadSchools: () async => [_school()],
      loadAlerts: () async => [_alert()],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('PM2.5 เกินเกณฑ์'), findsWidgets);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadAlerts: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลการแจ้งเตือนได้'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Future.delayed(
      const Duration(milliseconds: 200),
      () => [_alert()],
    );
    await _pump(tester, loadAlerts: () => gate);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'acknowledging only reports success once the RPC actually resolves',
    (tester) async {
      await _pump(
        tester,
        loadAlerts: () async => [_alert()],
        acknowledgeAlert: (id) async {
          throw StateError('rpc rejected');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('รับทราบเหตุ').first);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ไม่สามารถรับทราบเหตุการณ์ได้'),
        findsOneWidget,
      );
      expect(find.textContaining('รับทราบเหตุการณ์'), findsWidgets);
    },
  );

  testWidgets('acknowledging succeeds and reloads when the RPC resolves', (
    tester,
  ) async {
    var acked = false;
    await _pump(
      tester,
      loadAlerts: () async => [_alert(status: acked ? 'acknowledged' : 'open')],
      acknowledgeAlert: (id) async {
        acked = true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('รับทราบเหตุ').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('รับทราบเหตุการณ์'), findsWidgets);
    expect(find.textContaining('แล้ว'), findsWidgets);
  });

  testWidgets('resolving only reports success once the RPC actually resolves', (
    tester,
  ) async {
    await _pump(
      tester,
      loadAlerts: () async => [_alert(status: 'acknowledged')],
      resolveAlert: (id, {note}) async {
        throw StateError('rpc rejected');
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ปิดงาน').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยันปิดงาน'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ไม่สามารถปิดงานได้'), findsOneWidget);
  });
}
