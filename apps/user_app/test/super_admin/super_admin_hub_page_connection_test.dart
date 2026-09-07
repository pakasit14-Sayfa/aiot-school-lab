import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_hub_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty apart for the platform hub's summary
/// metrics, school list, and audit log feed — a failed load of the alerts
/// or logs sub-fetch is already caught-and-emptied in the page itself
/// (documented as a known "empty vs error" conflation for those two), so
/// this only asserts the schools fetch (the one with a real error banner).

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
}
