import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_devices_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the device registry and its
/// audit-log panel, driven through the `loadDevices` / `loadLogs` seams so no
/// real Supabase client is needed. Also guards the fabricated-field removal:
/// serial number, IP address, firmware, calibration and "last seen" used to
/// be invented from the device's uuid/name — `list_school_devices` never
/// returns any of them.

DeviceOption _device({
  String id = 'dev-1',
  String name = 'เซนเซอร์ห้องทดลอง',
  String type = 'pm25_sensor',
  String? location = 'อาคาร 1 ชั้น 2',
  String status = 'online',
}) => DeviceOption(
  id: id,
  name: name,
  type: type,
  location: location,
  status: status,
);

SchoolAdminAuditLog _log({String action = 'แก้ไขอุปกรณ์'}) =>
    SchoolAdminAuditLog(
      id: 1,
      action: action,
      target: 'เซนเซอร์ห้องทดลอง',
      detail: '',
      actorName: 'ผู้ดูแล ทดสอบ',
      actorRole: 'school_admin',
      createdAt: DateTime(2026, 9, 1),
    );

Future<void> _pump(
  WidgetTester tester, {
  Future<List<DeviceOption>> Function()? loadDevices,
  Future<List<SchoolAdminAuditLog>> Function()? loadLogs,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolDevicesPage(
        loadDevices: loadDevices ?? () async => <DeviceOption>[],
        loadLogs: loadLogs ?? () async => <SchoolAdminAuditLog>[],
      ),
    ),
  );
}

void main() {
  testWidgets('real devices are rendered, not fabricated fields', (
    tester,
  ) async {
    await _pump(tester, loadDevices: () async => [_device()]);
    await tester.pumpAndSettle();

    expect(find.text('เซนเซอร์ห้องทดลอง'), findsOneWidget);
    expect(find.text('เซนเซอร์ PM2.5'), findsWidgets);
    expect(find.text('อาคาร 1 ชั้น 2'), findsWidgets);
    expect(find.text('ออนไลน์'), findsWidgets);
  });

  testWidgets('device detail sheet reports unstored fields honestly', (
    tester,
  ) async {
    await _pump(tester, loadDevices: () async => [_device()]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('รายละเอียด'));
    await tester.pumpAndSettle();

    // The old sheet invented Serial Number / IP Address / Firmware / last
    // seen from the device's uuid or name hash. None of those columns exist
    // in list_school_devices, so they must read as "ยังไม่มีข้อมูล".
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.textContaining('SN-'), findsNothing);
    expect(find.textContaining('192.168.'), findsNothing);
    expect(find.text('v2.4.1'), findsNothing);
  });

  testWidgets('no devices says so, distinct from a failed load', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบอุปกรณ์'), findsOneWidget);
    expect(find.text('ยังไม่มีอุปกรณ์ที่ลงทะเบียนกับสถานศึกษานี้'), findsOneWidget);
  });

  testWidgets('a failed device load is distinct from empty, with retry', (
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

    expect(find.text('โหลดรายการอุปกรณ์ไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ไม่พบอุปกรณ์'), findsNothing);
    expect(find.textContaining('backend detail'), findsNothing);
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่').first);
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a slow device load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<DeviceOption>>();
    await _pump(tester, loadDevices: () => gate.future);
    await tester.pump();

    expect(find.text('กำลังโหลดรายการอุปกรณ์…'), findsOneWidget);
    expect(find.text('ไม่พบอุปกรณ์'), findsNothing);

    gate.complete([_device()]);
    await tester.pumpAndSettle();
    expect(find.text('กำลังโหลดรายการอุปกรณ์…'), findsNothing);
  });

  testWidgets('audit log error is distinct from an empty log list', (
    tester,
  ) async {
    await _pump(
      tester,
      loadDevices: () async => [_device()],
      loadLogs: () async => throw StateError('log query failed'),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดประวัติการจัดการอุปกรณ์ไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ยังไม่มีประวัติการจัดการอุปกรณ์'), findsNothing);
  });

  testWidgets('a real audit log entry is rendered', (tester) async {
    await _pump(
      tester,
      loadDevices: () async => [_device()],
      loadLogs: () async => [_log()],
    );
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขอุปกรณ์'), findsOneWidget);
  });

  testWidgets('filters read their options from real device data', (
    tester,
  ) async {
    await _pump(
      tester,
      loadDevices: () async => [
        _device(id: 'a', type: 'camera', status: 'online'),
        _device(id: 'b', type: 'relay', status: 'offline'),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('กล้องวงจรปิด'), findsWidgets);
    expect(find.text('รีเลย์ควบคุม'), findsWidgets);
  });
}
