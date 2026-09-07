import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_devices_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the cross-school device
/// registry, and guards that registering a new device only reports success
/// (and shows the one-time device token) once the RPC actually resolves.

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
  bool online = true,
}) => DeviceControlItemRecord(
  databaseId: id,
  schoolId: schoolId,
  schoolName: 'โรงเรียนทดสอบ',
  categoryCode: 'SEN',
  deviceCode: 'DEV-001',
  name: name,
  building: 'อาคาร 1',
  room: '101',
  status: online ? 'online' : 'offline',
  online: online,
  metadata: const {},
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
  Future<Map<String, dynamic>> Function({
    required String schoolId,
    required String name,
    required String type,
    String? categoryCode,
    String? deviceCode,
    String? building,
    String? room,
  })?
  registerDevice,
}) async {
  tester.view.physicalSize = const Size(1400, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminDevicesPage(
        loadDevices: loadDevices ?? () async => _data(),
        registerDevice: registerDevice,
      ),
    ),
  );
}

void main() {
  testWidgets('real devices are rendered', (tester) async {
    await _pump(
      tester,
      loadDevices: () async =>
          _data(schools: [_school()], devices: [_device()]),
    );
    await tester.pumpAndSettle();

    expect(find.text('เซนเซอร์ห้อง 101'), findsOneWidget);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadDevices: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดทะเบียนอุปกรณ์ได้'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Future.delayed(
      const Duration(milliseconds: 200),
      () => _data(schools: [_school()], devices: [_device()]),
    );
    await _pump(tester, loadDevices: () => gate);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'registering only shows the token once the RPC actually resolves',
    (tester) async {
      await _pump(
        tester,
        loadDevices: () async => _data(schools: [_school()]),
        registerDevice:
            ({
              required schoolId,
              required name,
              required type,
              categoryCode,
              deviceCode,
              building,
              room,
            }) async => {'device_token': 'real-token-abc123'},
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ลงทะเบียนอุปกรณ์ใหม่'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่ออุปกรณ์'),
        'เซนเซอร์ใหม่',
      );
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();

      expect(find.text('real-token-abc123'), findsOneWidget);
    },
  );

  testWidgets(
    'registering shows an error instead of a silent success when the RPC rejects',
    (tester) async {
      await _pump(
        tester,
        loadDevices: () async => _data(schools: [_school()]),
        registerDevice:
            ({
              required schoolId,
              required name,
              required type,
              categoryCode,
              deviceCode,
              building,
              room,
            }) async => throw StateError('rpc rejected'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ลงทะเบียนอุปกรณ์ใหม่'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่ออุปกรณ์'),
        'เซนเซอร์ใหม่',
      );
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ลงทะเบียนไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ลงทะเบียนสำเร็จ'), findsNothing);
    },
  );

  testWidgets('registering is blocked with a message when no schools exist', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadDevices: () async => _data(),
      registerDevice:
          ({
            required schoolId,
            required name,
            required type,
            categoryCode,
            deviceCode,
            building,
            room,
          }) async {
            calls++;
            return {'device_token': 'unused'};
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ลงทะเบียนอุปกรณ์ใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีโรงเรียนในระบบให้ลงทะเบียนอุปกรณ์'), findsOneWidget);
    expect(calls, 0);
  });
}
