import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/dashboard/super_admin_dashboard.dart';
import 'package:my_first_app/pages/super_admin/super_admin_schools_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_control_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_permissions_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_alerts_logs_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_hub_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_devices_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_test_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_settings_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SuperAdminDashboard displays cards and navigates to Schools page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    expect(find.text('ศูนย์ควบคุมภาพรวม (Platform Hub)'), findsOneWidget);
    expect(find.text('จัดการโรงเรียน (Schools)'), findsOneWidget);
    expect(find.text('ควบคุม & อนุมัติอุปกรณ์ (Device Control)'), findsOneWidget);
    expect(find.text('ทะเบียนและ QR Code (Devices & QR)'), findsOneWidget);
    expect(find.text('ทดสอบอุปกรณ์ (Device Diagnostics)'), findsOneWidget);
    expect(find.text('กำหนดสิทธิ์และบทบาท (Permissions)'), findsOneWidget);
    expect(find.text('การแจ้งเตือนและประวัติ (Alerts & Logs)'), findsOneWidget);
    expect(find.text('ตั้งค่าระบบส่วนกลาง (Settings)'), findsOneWidget);
    expect(find.text('จัดการผู้ใช้ (User Management)'), findsOneWidget);

    await tester.tap(find.text('จัดการโรงเรียน (Schools)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminSchoolsPage), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard drawer opens and navigates to Device Control page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('ควบคุมและอนุมัติอุปกรณ์ (Device Control)'), findsOneWidget);

    await tester.tap(find.text('ควบคุมและอนุมัติอุปกรณ์ (Device Control)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminDeviceControlPage), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard navigates to Permissions page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    await tester.tap(find.text('กำหนดสิทธิ์และบทบาท (Permissions)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminPermissionsPage), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard navigates to Alerts & Logs page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    await tester.tap(find.text('การแจ้งเตือนและประวัติ (Alerts & Logs)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminAlertsLogsPage), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard navigates to Hub page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    await tester.tap(find.text('ศูนย์ควบคุมภาพรวม (Platform Hub)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminHubPage), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard navigates to Devices page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    await tester.tap(find.text('ทะเบียนและ QR Code (Devices & QR)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminDevicesPage), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard navigates to Device Test page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    await tester.tap(find.text('ทดสอบอุปกรณ์ (Device Diagnostics)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminDeviceTestPage), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard navigates to Settings page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDashboard(),
      ),
    );

    await tester.tap(find.text('ตั้งค่าระบบส่วนกลาง (Settings)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminSettingsPage), findsOneWidget);
  });
}
