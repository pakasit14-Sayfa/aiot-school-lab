import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_devices_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/models/school_device_identity.dart'
    show SchoolDeviceDetail;

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

SchoolDeviceDetail _detail({
  String? ipAddress,
  String? firmwareVersion,
  DateTime? lastSeenAt,
  String? deviceCode = 'PM-101',
}) => SchoolDeviceDetail(
  id: 'dev-1',
  name: 'เซนเซอร์ห้องทดลอง',
  type: 'pm25_sensor',
  status: 'online',
  effectiveStatus: 'online',
  serialNo: 'SN-REAL-0001',
  deviceCode: deviceCode,
  kitCode: null,
  categoryCode: null,
  location: 'อาคาร 1 ชั้น 2',
  building: 'อาคาร 1',
  room: 'ห้องทดลอง',
  ipAddress: ipAddress,
  firmwareVersion: firmwareVersion,
  lastSeenAt: lastSeenAt,
  registeredAt: DateTime(2026, 9, 1, 9),
  updatedAt: null,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<DeviceOption>> Function()? loadDevices,
  Future<List<SchoolAdminAuditLog>> Function()? loadLogs,
  Future<SchoolDeviceDetail?> Function(String)? loadDeviceDetail,
  Future<Map<String, dynamic>> Function({
    required String type,
    required String name,
    String? serialNo,
    String? location,
    String? kitCode,
  })?
  registerDevice,
  Future<void> Function({
    required String deviceId,
    required String name,
    String? location,
    String? building,
    String? room,
    String? status,
  })?
  updateDevice,
  void Function({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  })?
  downloadBytesOverride,
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
        loadDeviceDetail: loadDeviceDetail ?? (_) async => _detail(),
        registerDevice: registerDevice,
        updateDevice: updateDevice,
        downloadBytesOverride:
            downloadBytesOverride ??
            ({required filename, required bytes, required mimeType}) {},
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

  /// รอบแรกแผ่นรายละเอียดแต่ง serial/IP/เฟิร์มแวร์จาก uuid → ถูกเปลี่ยนเป็น
  /// "ยังไม่มีข้อมูล" ทั้งที่คอลัมน์มีจริง → ตอนนี้อ่านจาก get_school_device_detail:
  /// ค่าที่อุปกรณ์เคยรายงานแสดงจริง ค่าที่ไม่เคยรายงานบอกว่าไม่เคยรายงาน
  testWidgets(
    'device detail sheet shows the stored serial/room and marks never-reported fields honestly',
    (tester) async {
      await _pump(
        tester,
        loadDevices: () async => [_device()],
        loadDeviceDetail: (id) async => _detail(firmwareVersion: 'v3.1.0'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('รายละเอียด'));
      await tester.pumpAndSettle();

      expect(find.text('SN-REAL-0001'), findsOneWidget);
      expect(find.text('ห้องทดลอง'), findsWidgets);
      expect(
        find.text('v3.1.0'),
        findsOneWidget,
        reason: 'reported by heartbeat → shown',
      );
      // IP / last seen never reported → said so, never '192.168.1.100' / now()
      expect(find.text('ยังไม่เคยรายงาน'), findsNWidgets(2));
      expect(find.textContaining('192.168.'), findsNothing);
      expect(find.byType(QrImageView), findsOneWidget);
    },
  );

  testWidgets(
    'registering a device sends the form to register_device and shows the one-time token',
    (tester) async {
      Map<String, Object?>? sent;
      await _pump(
        tester,
        registerDevice:
            ({
              required type,
              required name,
              serialNo,
              location,
              kitCode,
            }) async {
              sent = {
                'type': type,
                'name': name,
                'serialNo': serialNo,
                'location': location,
                'kitCode': kitCode,
              };
              return {'device_id': 'dev-new', 'device_token': 'dev_abc123'};
            },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เพิ่มอุปกรณ์'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่ออุปกรณ์'),
        'มิเตอร์ใหม่',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Serial Number (ถ้ามี)'),
        'SN-9',
      );
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();

      expect(sent, {
        'type': 'mini_pc',
        'name': 'มิเตอร์ใหม่',
        'serialNo': 'SN-9',
        'location': null,
        'kitCode': null,
      });
      expect(
        find.text('dev_abc123'),
        findsOneWidget,
        reason: 'token shown once for provisioning',
      );
    },
  );

  testWidgets(
    'editing a device from the detail sheet writes through update_school_device',
    (tester) async {
      Map<String, Object?>? sent;
      await _pump(
        tester,
        loadDevices: () async => [_device()],
        updateDevice:
            ({
              required deviceId,
              required name,
              location,
              building,
              room,
              status,
            }) async {
              sent = {
                'id': deviceId,
                'name': name,
                'room': room,
                'status': status,
              };
            },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('รายละเอียด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขข้อมูลอุปกรณ์'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ห้อง'),
        'ห้อง 202',
      );
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(sent, {
        'id': 'dev-1',
        'name': 'เซนเซอร์ห้องทดลอง',
        'room': 'ห้อง 202',
        'status': 'online',
      });
    },
  );

  testWidgets('export produces a real CSV of the loaded devices', (
    tester,
  ) async {
    String? savedName;
    List<int>? savedBytes;
    await _pump(
      tester,
      loadDevices: () async => [_device()],
      downloadBytesOverride:
          ({required filename, required bytes, required mimeType}) {
            savedName = filename;
            savedBytes = bytes;
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออก CSV'));
    await tester.pumpAndSettle();

    expect(savedName, startsWith('devices_'));
    expect(utf8.decode(savedBytes!), contains('เซนเซอร์ห้องทดลอง'));
    expect(find.text('คำสั่งที่ยังไม่เปิดใช้งาน'), findsNothing);
  });

  testWidgets('no devices says so, distinct from a failed load', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบอุปกรณ์'), findsOneWidget);
    expect(
      find.text('ยังไม่มีอุปกรณ์ที่ลงทะเบียนกับสถานศึกษานี้'),
      findsOneWidget,
    );
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
