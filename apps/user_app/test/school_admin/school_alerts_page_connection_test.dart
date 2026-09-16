import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_alerts_controller.dart';
import 'package:my_first_app/pages/school_admin/school_alerts_page.dart';
import 'package:shared_core/shared_core.dart';

SchoolSensorAlertRecord _alert({
  required String id,
  required String status,
  String metric = 'pm25',
}) => SchoolSensorAlertRecord(
  id: id,
  deviceId: 'device-$id',
  deviceName: 'เซนเซอร์ห้อง 101',
  deviceCode: 'DEV-$id',
  schoolId: 'school-1',
  metric: metric,
  value: 88.5,
  triggeredAt: DateTime(2026, 9, 6, 9, 15),
  status: status,
);

Future<void> _pumpWith(
  WidgetTester tester,
  List<SchoolSensorAlertRecord> alerts,
) async {
  tester.view.physicalSize = const Size(1600, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);

  final controller = SchoolAdminAlertsController(
    loadAlerts: () async => alerts,
    acknowledgeAlert: (alertId) async {},
    resolveAlert: (alertId, {note}) async {},
  );
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAlertsPage(
        controller: controller,
        loadAuditLogs: () async => const <SchoolAdminAuditLog>[],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty backend is shown honestly without sample alert rules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SchoolAdminAlertsController(
      loadAlerts: () async => const <SchoolSensorAlertRecord>[],
      acknowledgeAlert: (alertId) async {},
      resolveAlert: (alertId, {note}) async {},
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAlertsPage(
          controller: controller,
          loadAuditLogs: () async => const <SchoolAdminAuditLog>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('อุปกรณ์ออฟไลน์'), findsNothing);
    expect(find.text('ใส่รหัสผ่านผิดเกิน 3 ครั้ง'), findsNothing);
  });

  testWidgets('filters offer only values that can actually match', (
    tester,
  ) async {
    // Every dropdown used to be a const list. `list_school_alerts` returns
    // device sensor alerts with no severity, building or room, and the page
    // maps them all to category 'อุปกรณ์' — so choosing ไฟฟ้า, เร่งด่วน or
    // "อาคารเรียน A" emptied the table and read as "nothing in that
    // building" rather than "this filter cannot work". Two of the offered
    // statuses do not exist in `sensor_alerts` at all.
    await _pumpWith(tester, [
      _alert(id: '1', status: 'new'),
      _alert(id: '2', status: 'acknowledged'),
    ]);

    // Statuses present in the data are offered.
    expect(find.text('ทุกสถานะ'), findsOneWidget);

    // Values no alert can ever carry are gone.
    for (final impossible in <String>[
      'ไฟฟ้า',
      'คุณภาพอากาศ',
      'ความปลอดภัย',
      'เฝ้าระวัง',
      'ส่งต่อแล้ว',
      'อาคารเรียน A',
      'อาคารเรียน B',
      'อาคารปฏิบัติการ',
      'ระบบกลาง',
    ]) {
      expect(find.text(impossible), findsNothing, reason: impossible);
    }

    // 'เร่งด่วน' and 'กำลังตรวจสอบ' have no backing data or status at all —
    // the '--' summary cards were removed 2026-09-14; only real counters remain.
    expect(find.text('ยังไม่มีข้อมูลระดับความเร่งด่วน'), findsNothing);
    expect(find.text('ยังไม่มีสถานะนี้จากระบบหลังบ้าน'), findsNothing);
    expect(find.text('รับทราบแล้ว'), findsWidgets);

    // Fields the backend never populates drop their filter entirely rather
    // than offering a control that does nothing.
    expect(find.text('ทุกระดับ'), findsNothing);
    expect(find.text('ทุกอาคาร'), findsNothing);
  });

  testWidgets('"รับทราบทั้งหมด" writes through the bulk RPC and only reports success after read-back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    var acknowledgedAll = false;
    final controller = SchoolAdminAlertsController(
      loadAlerts: () async => [
        _alert(id: '1', status: acknowledgedAll ? 'acknowledged' : 'new'),
        _alert(id: '2', status: acknowledgedAll ? 'acknowledged' : 'new'),
      ],
      acknowledgeAlert: (alertId) async {},
      resolveAlert: (alertId, {note}) async {},
      acknowledgeAllAlerts: () async {
        acknowledgedAll = true;
        return 2;
      },
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAlertsPage(
          controller: controller,
          loadAuditLogs: () async => const <SchoolAdminAuditLog>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // FilledButton.icon เป็น subclass ส่วนตัว — หาปุ่มผ่าน ButtonStyleButton
    Finder ackAll() => find.ancestor(
      of: find.text('รับทราบทั้งหมด'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    final button = ackAll();
    expect(button, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNotNull);
    expect(find.text('รับทราบทั้งหมด (ยังไม่เปิดใช้งาน)'), findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(acknowledgedAll, isTrue);
    expect(find.text('รับทราบแล้ว 2 รายการ'), findsOneWidget);
    // ไม่เหลือ new → ปุ่มปิดตัวเอง
    expect(tester.widget<ButtonStyleButton>(ackAll()).onPressed, isNull);
  });

  testWidgets('"รับทราบทั้งหมด" that does not clear every new alert on read-back is reported as a failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SchoolAdminAlertsController(
      loadAlerts: () async => [_alert(id: '1', status: 'new')],
      acknowledgeAlert: (alertId) async {},
      resolveAlert: (alertId, {note}) async {},
      acknowledgeAllAlerts: () async => 1, // claims success, backend still says new
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAlertsPage(
          controller: controller,
          loadAuditLogs: () async => const <SchoolAdminAuditLog>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.ancestor(
      of: find.text('รับทราบทั้งหมด'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    ));
    await tester.pumpAndSettle();

    expect(find.text('รับทราบแล้ว 1 รายการ'), findsNothing);
    expect(find.textContaining('รับทราบทั้งหมดไม่สำเร็จ'), findsWidgets);
  });

  testWidgets('no "ตรวจสอบ" control exists — alert_status has no investigating state', (
    tester,
  ) async {
    await _pumpWith(tester, [_alert(id: '1', status: 'new')]);

    expect(find.text('ตรวจสอบ'), findsNothing);
    expect(find.text('กำลังตรวจสอบ'), findsNothing);
    for (final snack in <String>[
      'ฟังก์ชันส่งออกรายงานยังไม่เชื่อมต่อระบบหลังบ้าน',
      'การรับทราบทั้งหมดพร้อมกันยังไม่เชื่อมต่อระบบหลังบ้าน',
      'สถานะกำลังตรวจสอบยังไม่เชื่อมต่อระบบหลังบ้าน',
    ]) {
      expect(find.text(snack), findsNothing, reason: snack);
    }
  });

  testWidgets('export downloads a real CSV of the filtered alerts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SchoolAdminAlertsController(
      loadAlerts: () async => [_alert(id: '1', status: 'new')],
      acknowledgeAlert: (alertId) async {},
      resolveAlert: (alertId, {note}) async {},
    );
    addTearDown(controller.dispose);

    String? downloadedFilename;
    List<int>? downloadedBytes;

    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAlertsPage(
          controller: controller,
          loadAuditLogs: () async => const <SchoolAdminAuditLog>[],
          downloadBytesOverride:
              ({
                required String filename,
                required List<int> bytes,
                required String mimeType,
              }) {
                downloadedFilename = filename;
                downloadedBytes = bytes;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออกรายงาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งออกเป็น CSV'));
    await tester.pump();

    expect(downloadedFilename, contains('alerts_'));
    expect(downloadedFilename, endsWith('.csv'));
    expect(downloadedBytes, isNotNull);
    final csv = utf8.decode(downloadedBytes!, allowMalformed: true);
    expect(csv, contains('DEV-1'));
    expect(find.textContaining('ส่งออกรายงานเหตุแจ้งเตือน'), findsOneWidget);
  });

  testWidgets('export downloads a real Excel file of the filtered alerts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SchoolAdminAlertsController(
      loadAlerts: () async => [_alert(id: '1', status: 'new')],
      acknowledgeAlert: (alertId) async {},
      resolveAlert: (alertId, {note}) async {},
    );
    addTearDown(controller.dispose);

    String? downloadedFilename;
    List<int>? downloadedBytes;

    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAlertsPage(
          controller: controller,
          loadAuditLogs: () async => const <SchoolAdminAuditLog>[],
          downloadBytesOverride:
              ({
                required String filename,
                required List<int> bytes,
                required String mimeType,
              }) {
                downloadedFilename = filename;
                downloadedBytes = bytes;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออกรายงาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งออกเป็น Excel'));
    await tester.pump();

    expect(downloadedFilename, endsWith('.xlsx'));
    expect(downloadedBytes, isNotNull);
    expect(downloadedBytes![0], 0x50);
    expect(downloadedBytes![1], 0x4B);
    expect(find.textContaining('ส่งออกรายงานเหตุแจ้งเตือน'), findsOneWidget);
  });
}
