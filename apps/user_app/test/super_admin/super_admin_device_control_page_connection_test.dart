import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_control_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart, and guards the write→confirm
/// contract on "หยุดฉุกเฉิน" (emergency stop) — this button queues a real
/// power-off command to every online, powered-on device across every
/// school at once. A version that reports success without the command
/// actually being queued is the highest-blast-radius kind of bug this app
/// has, since it can leave admins believing hardware was shut off when it
/// was not.

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
  String name = 'รีเลย์ห้อง 101',
  bool online = true,
  bool poweredOn = true,
}) => DeviceControlItemRecord(
  databaseId: id,
  schoolId: schoolId,
  schoolName: 'โรงเรียนทดสอบ',
  categoryCode: 'RLY',
  deviceCode: 'DEV-001',
  name: name,
  building: 'อาคาร 1',
  room: '101',
  status: online ? 'online' : 'offline',
  online: online,
  metadata: {'power': poweredOn},
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
  Future<DeviceControlDataModel> Function()? loadControlData,
  Future<String> Function({
    required String deviceId,
    required Map<String, dynamic> command,
  })?
  queueDeviceCommand,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminDeviceControlPage(
        loadControlData: loadControlData ?? () async => _data(),
        queueDeviceCommand: queueDeviceCommand,
      ),
    ),
  );
}

void main() {
  testWidgets('real devices are rendered', (tester) async {
    await _pump(
      tester,
      loadControlData: () async =>
          _data(schools: [_school()], devices: [_device()]),
    );
    await tester.pumpAndSettle();

    expect(find.text('รีเลย์ห้อง 101'), findsWidgets);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadControlData: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลควบคุมไม่สำเร็จ'), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<DeviceControlDataModel>();
    await _pump(tester, loadControlData: () => gate.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete(_data());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'emergency stop only queues commands through queueDeviceCommand, never fakes it',
    (tester) async {
      final queuedFor = <String>[];
      await _pump(
        tester,
        loadControlData: () async =>
            _data(schools: [_school()], devices: [_device()]),
        queueDeviceCommand: ({required deviceId, required command}) async {
          queuedFor.add(deviceId);
          return 'queued';
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('หยุดฉุกเฉิน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันหยุดทั้งหมด'));
      await tester.pumpAndSettle();

      expect(queuedFor, ['dev-1']);
      expect(find.textContaining('ส่งคำสั่งหยุดฉุกเฉิน'), findsOneWidget);
    },
  );

  testWidgets(
    'emergency stop reports failure honestly when the RPC throws',
    (tester) async {
      await _pump(
        tester,
        loadControlData: () async =>
            _data(schools: [_school()], devices: [_device()]),
        queueDeviceCommand: ({required deviceId, required command}) async {
          throw StateError('rpc rejected');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('หยุดฉุกเฉิน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันหยุดทั้งหมด'));
      await tester.pumpAndSettle();

      expect(find.textContaining('หยุดฉุกเฉินไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('ส่งคำสั่งหยุดฉุกเฉิน 1 เครื่องแล้ว'), findsNothing);
    },
  );

  testWidgets('emergency stop with no eligible devices does not queue anything', (
    tester,
  ) async {
    var called = false;
    await _pump(
      tester,
      loadControlData: () async => _data(
        schools: [_school()],
        devices: [_device(poweredOn: false)],
      ),
      queueDeviceCommand: ({required deviceId, required command}) async {
        called = true;
        return 'queued';
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('หยุดฉุกเฉิน'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.textContaining('ไม่มีอุปกรณ์ออนไลน์ที่กำลังเปิดอยู่'), findsOneWidget);
  });
}
