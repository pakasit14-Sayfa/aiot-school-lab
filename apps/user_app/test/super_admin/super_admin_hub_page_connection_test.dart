import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_hub_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the platform hub's summary
/// metrics, school list, and audit log feed. The alerts and logs sub-fetches
/// used to be caught-and-emptied, so a failed read looked exactly like
/// "no alerts, nothing happened" on the platform's top-level summary — that
/// conflation is fixed and pinned below.

SchoolPlatformRecord _school({
  String id = 's-1',
  String name = 'โรงเรียนทดสอบ',
  int devicesTotal = 10,
  int devicesOnline = 8,
  int usersCount = 20,
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
  usersCount: usersCount,
  devicesTotal: devicesTotal,
  devicesOnline: devicesOnline,
  buildingsCount: 1,
  roomsCount: 3,
  alertsCount: 0,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<SchoolPlatformRecord>> Function()? loadSchools,
  Future<List<SchoolSensorAlertRecord>> Function()? loadAlerts,
  Future<List<SchoolAdminAuditLog>> Function()? loadAuditLogs,
}) async {
  tester.view.physicalSize = const Size(1400, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminHubPage(
        loadSchools: loadSchools ?? () async => <SchoolPlatformRecord>[],
        loadAlerts: loadAlerts ?? () async => <SchoolSensorAlertRecord>[],
        loadAuditLogs: loadAuditLogs ?? () async => <SchoolAdminAuditLog>[],
      ),
    ),
  );
}

void main() {
  testWidgets('real schools and their real device counts are rendered', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSchools: () async => [_school(devicesTotal: 12, devicesOnline: 9)],
    );
    await tester.pumpAndSettle();

    expect(find.text('โรงเรียนทดสอบ'), findsOneWidget);
    expect(find.textContaining('9/12 อุปกรณ์ออนไลน์'), findsOneWidget);
  });

  testWidgets('no schools says so, not an error', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูลโรงเรียน'), findsOneWidget);
    expect(find.textContaining('ไม่สามารถเชื่อมต่อฐานข้อมูลภาพรวมได้'), findsNothing);
  });

  testWidgets('a failed schools load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadSchools: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ไม่สามารถเชื่อมต่อฐานข้อมูลภาพรวมได้'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Future.delayed(
      const Duration(milliseconds: 200),
      () => [_school()],
    );
    await _pump(tester, loadSchools: () => gate);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('real audit logs are rendered when present', (tester) async {
    await _pump(
      tester,
      loadAuditLogs: () async => [
        SchoolAdminAuditLog(
          id: 1,
          action: 'เปลี่ยนสิทธิ์ผู้ใช้',
          target: 'user-1',
          detail: 'เปลี่ยนบทบาทเป็น school_admin',
          actorName: 'ผู้ดูแลระบบ',
          actorRole: 'super_admin',
          createdAt: DateTime(2026, 9, 1, 9, 0),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('เปลี่ยนสิทธิ์ผู้ใช้'), findsOneWidget);
  });

  group('โหลดไม่สำเร็จ ต้องไม่อ่านเป็น "ไม่มีเหตุ"', () {
    testWidgets('แจ้งเตือนโหลดพัง — การ์ดต้องไม่ขึ้นเลข 0 สีเขียว', (
      tester,
    ) async {
      await _pump(
        tester,
        loadSchools: () async => <SchoolPlatformRecord>[_school()],
        loadAlerts: () async => throw Exception('alerts_unreachable'),
      );
      await tester.pumpAndSettle();

      expect(find.text('โหลดไม่สำเร็จ'), findsOneWidget);
      expect(find.text('อ่านข้อมูลแจ้งเตือนไม่ได้'), findsOneWidget);
      // ข้อความ exception ดิบต้องไม่หลุดขึ้นจอ
      expect(find.textContaining('alerts_unreachable'), findsNothing);
    });

    testWidgets('ประวัติกิจกรรมโหลดพัง — ต้องบอกว่าโหลดไม่สำเร็จ ไม่ใช่ "ยังไม่มีประวัติ"', (
      tester,
    ) async {
      await _pump(
        tester,
        loadSchools: () async => <SchoolPlatformRecord>[_school()],
        loadAuditLogs: () async => throw Exception('logs_unreachable'),
      );
      await tester.pumpAndSettle();

      expect(find.text('โหลดประวัติกิจกรรมไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ยังไม่มีประวัติกิจกรรม'), findsNothing);
      expect(find.textContaining('logs_unreachable'), findsNothing);
    });

    testWidgets('ทุกอย่างโหลดสำเร็จแต่ว่างจริง ต้องยังขึ้น "ยังไม่มีประวัติกิจกรรม"', (
      tester,
    ) async {
      await _pump(tester, loadSchools: () async => <SchoolPlatformRecord>[_school()]);
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีประวัติกิจกรรม'), findsOneWidget);
      expect(find.text('โหลดประวัติกิจกรรมไม่สำเร็จ'), findsNothing);
      expect(find.text('โหลดไม่สำเร็จ'), findsNothing);
    });
  });
}
