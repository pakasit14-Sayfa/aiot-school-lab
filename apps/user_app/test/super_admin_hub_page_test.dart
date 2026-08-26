import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/super_admin/super_admin_hub_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_schools_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_control_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_devices_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_test_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_permissions_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_alerts_logs_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_settings_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SuperAdminHubPage renders all 8 quick action cards and drawer', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: const SuperAdminHubPage(),
        routes: {
          '/users': (ctx) => const Scaffold(body: Text('User Management Route Screen')),
        },
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ศูนย์ควบคุมภาพรวม (Platform Hub)'), findsOneWidget);
    expect(find.text('จัดการโรงเรียน (Schools)', skipOffstage: false), findsWidgets);
    expect(find.text('ควบคุมอุปกรณ์ (Device Control)', skipOffstage: false), findsOneWidget);
    expect(find.text('ทะเบียน & QR Code (Devices & QR)', skipOffstage: false), findsOneWidget);
    expect(find.text('ทดสอบอุปกรณ์ (Device Diagnostics)', skipOffstage: false), findsOneWidget);
    expect(find.text('จัดการสิทธิ์ (Permissions)', skipOffstage: false), findsOneWidget);
    expect(find.text('การแจ้งเตือน (Alerts & Logs)', skipOffstage: false), findsOneWidget);
    expect(find.text('ตั้งค่าระบบส่วนกลาง (Settings)', skipOffstage: false), findsOneWidget);
    expect(find.text('รายชื่อผู้ใช้ (Users)', skipOffstage: false), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Schools page from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('จัดการโรงเรียน (Schools)').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminSchoolsPage), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Device Control page from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ควบคุมอุปกรณ์ (Device Control)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminDeviceControlPage), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Devices page from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ทะเบียน & QR Code (Devices & QR)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminDevicesPage), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Device Diagnostics from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ทดสอบอุปกรณ์ (Device Diagnostics)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminDeviceTestPage), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Permissions page from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('จัดการสิทธิ์ (Permissions)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminPermissionsPage), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Alerts & Logs page from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('การแจ้งเตือน (Alerts & Logs)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminAlertsLogsPage), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Settings from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ตั้งค่าระบบส่วนกลาง (Settings)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminSettingsPage), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage navigates to Users route from quick action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: const SuperAdminHubPage(),
        routes: {
          '/users': (ctx) => const Scaffold(body: Text('User Management Screen')),
        },
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('รายชื่อผู้ใช้ (Users)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('User Management Screen'), findsOneWidget);
  });

  testWidgets('SuperAdminHubPage drawer opens and navigates to Devices page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminHubPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ทะเบียนและ QR Code (Devices & QR)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminDevicesPage), findsOneWidget);
  });
}
