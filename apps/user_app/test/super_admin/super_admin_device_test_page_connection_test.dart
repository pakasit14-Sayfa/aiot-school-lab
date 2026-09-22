import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_test_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins the diagnostics page's real round-trip checks: each check must
/// reflect what its seam actually returns (pass/fail with a real latency),
/// not a hardcoded "always green" result — this page exists specifically to
/// tell Super Admin the truth about system health.

DeviceControlSchoolRecord _school({
  String id = 'school-1',
  String name = 'โรงเรียนทดสอบ',
}) => DeviceControlSchoolRecord(
  databaseId: id,
  schoolCode: 'TEST-1',
  name: name,
  province: 'กรุงเทพมหานคร',
  packageName: 'Pro',
  status: 'active',
  totalDevices: 1,
  onlineDevices: 1,
  openAlerts: 0,
);

DeviceControlItemRecord _device({
  String id = 'dev-1',
  String schoolId = 'school-1',
  String name = 'เซนเซอร์ห้อง 101',
  DateTime? readingAt,
}) => DeviceControlItemRecord(
  databaseId: id,
  schoolId: schoolId,
  schoolName: 'โรงเรียนทดสอบ',
  categoryCode: 'SEN',
  deviceCode: 'DEV-001',
  name: name,
  building: 'อาคาร 1',
  room: '101',
  status: 'online',
  online: true,
  metadata: const {},
  readingMetric: readingAt == null ? null : 'PM2.5',
  readingValue: readingAt == null ? null : 32,
  readingAt: readingAt,
);

DeviceControlDataModel _data({
  List<DeviceControlSchoolRecord>? schools,
  List<DeviceControlItemRecord>? devices,
}) => DeviceControlDataModel(
  schools: schools ?? <DeviceControlSchoolRecord>[],
  devices: devices ?? <DeviceControlItemRecord>[],
  commands: const <Map<String, dynamic>>[],
  approvals: const <DeviceControlApprovalRecord>[],
  permissions: const <DeviceControlPermissionRecord>[],
  logs: const <DeviceControlLogRecord>[],
  currentUserId: 'super-1',
  currentRole: 'super_admin',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<DeviceControlDataModel> Function()? loadDevices,
  Future<List<SchoolAdminAuditLog>> Function()? loadAuditLogs,
  Future<List<SchoolSensorAlertRecord>> Function()? loadAlerts,
}) async {
  tester.view.physicalSize = const Size(1400, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminDeviceTestPage(
        loadDevices: loadDevices ?? () async => _data(),
        loadAuditLogs: loadAuditLogs ?? () async => <SchoolAdminAuditLog>[],
        loadAlerts: loadAlerts ?? () async => <SchoolSensorAlertRecord>[],
      ),
    ),
  );
}

void main() {
  testWidgets('a passing database check reports passed, not hardcoded', (
    tester,
  ) async {
    await _pump(
      tester,
      loadDevices: () async =>
          _data(schools: [_school()], devices: [_device()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เริ่มทดสอบระบบทั้งหมด'));
    await tester.pumpAndSettle();

    expect(find.textContaining('เชื่อมต่อฐานข้อมูลหลักสำเร็จ'), findsOneWidget);
  });

  testWidgets('a failing database check reports the real failure', (
    tester,
  ) async {
    await _pump(
      tester,
      loadDevices: () async => throw StateError('connection refused'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เริ่มทดสอบระบบทั้งหมด'));
    await tester.pumpAndSettle();

    expect(find.textContaining('เชื่อมต่อฐานข้อมูลล้มเหลว'), findsOneWidget);
  });

  testWidgets('a failing auth check is distinct from a passing one', (
    tester,
  ) async {
    await _pump(
      tester,
      loadAuditLogs: () async => throw StateError('unauthorized'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เริ่มทดสอบระบบทั้งหมด'));
    await tester.pumpAndSettle();

    expect(find.textContaining('การยืนยันสิทธิ์ล้มเหลว'), findsOneWidget);
    expect(
      find.textContaining('เซสชัน Super Admin ได้รับการยืนยันสิทธิ์สำเร็จ'),
      findsNothing,
    );
  });

  testWidgets('a device that never sent telemetry says so honestly', (
    tester,
  ) async {
    await _pump(
      tester,
      loadDevices: () async =>
          _data(schools: [_school()], devices: [_device(readingAt: null)]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เริ่มทดสอบระบบทั้งหมด'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('ยังไม่เคยส่งค่าเซนเซอร์เข้าระบบ'),
      findsOneWidget,
    );
  });

  testWidgets('a device with fresh telemetry passes the freshness check', (
    tester,
  ) async {
    await _pump(
      tester,
      loadDevices: () async => _data(
        schools: [_school()],
        devices: [
          _device(
            readingAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เริ่มทดสอบระบบทั้งหมด'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ส่งค่าล่าสุด'), findsOneWidget);
  });
}
