import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_scan_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins the manual-code-entry lookup path (the camera itself needs real
/// hardware, so this exercises the same [_matchDevice] logic a real scan
/// would hit) against the real device list — a device that exists must be
/// recognized, and one that doesn't must say so honestly rather than
/// silently matching the wrong thing.

DeviceControlItemRecord _device({
  String id = 'dev-1',
  String schoolId = 'school-1',
  String deviceCode = 'DEV-001',
  String name = 'รีเลย์ห้อง 101',
  bool online = true,
}) => DeviceControlItemRecord(
  databaseId: id,
  schoolId: schoolId,
  schoolName: 'โรงเรียนทดสอบ',
  categoryCode: 'RLY',
  deviceCode: deviceCode,
  name: name,
  building: 'อาคาร 1',
  room: '101',
  status: online ? 'online' : 'offline',
  online: online,
  metadata: const {},
);

DeviceControlDataModel _data({List<DeviceControlItemRecord>? devices}) =>
    DeviceControlDataModel(
      schools: const <DeviceControlSchoolRecord>[],
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
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminScanPage(
        loadDevices: loadDevices ?? () async => _data(),
      ),
    ),
  );
}

// The live camera preview underneath keeps scheduling frames, so
// pumpAndSettle never converges here — step through with fixed pumps
// instead of settling.
const _step = Duration(milliseconds: 300);

void main() {
  testWidgets('a known device code is recognized', (tester) async {
    await _pump(tester, loadDevices: () async => _data(devices: [_device()]));
    await tester.pump(_step);

    await tester.tap(find.text('กรอกรหัส'));
    await tester.pump(_step);
    await tester.enterText(find.byType(TextField), 'DEV-001');
    await tester.tap(find.text('ค้นหา'));
    await tester.pump(_step);
    await tester.pump(_step);

    expect(find.text('พบอุปกรณ์ในระบบ'), findsOneWidget);
    expect(find.text('รีเลย์ห้อง 101'), findsOneWidget);
  });

  testWidgets('an unknown code says so, not a false match', (tester) async {
    await _pump(tester, loadDevices: () async => _data(devices: [_device()]));
    await tester.pump(_step);

    await tester.tap(find.text('กรอกรหัส'));
    await tester.pump(_step);
    await tester.enterText(find.byType(TextField), 'NOT-A-REAL-CODE');
    await tester.tap(find.text('ค้นหา'));
    await tester.pump(_step);
    await tester.pump(_step);

    expect(find.text('ไม่พบอุปกรณ์นี้ในระบบ'), findsOneWidget);
  });

  testWidgets('devices load before a lookup is attempted', (tester) async {
    final gate = Future.delayed(
      const Duration(milliseconds: 200),
      () => _data(devices: [_device()]),
    );
    await _pump(tester, loadDevices: () => gate);
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pump(_step);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
