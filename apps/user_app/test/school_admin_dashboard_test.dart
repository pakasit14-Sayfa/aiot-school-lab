import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/dashboard/school_admin_dashboard.dart';
import 'package:my_first_app/pages/school_admin/school_admin_energy_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_cctv_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_schedule_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_esg_page.dart';

import 'package:my_first_app/pages/school_admin/school_admin_device_control_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_incident_inbox_page.dart';
import 'package:my_first_app/pages/school_admin/school_students_page.dart';
import 'package:my_first_app/pages/school_admin/school_teachers_page.dart';
import 'package:my_first_app/pages/school_admin/school_permissions_page.dart';
import 'package:my_first_app/pages/school_admin/school_import_page.dart';
import 'package:my_first_app/pages/school_admin/school_alerts_page.dart';
import 'package:my_first_app/pages/school_admin/school_resources_page.dart';
import 'package:my_first_app/pages/school_admin/school_devices_page.dart';
import 'package:my_first_app/pages/school_admin/school_buildings_page.dart';
import 'package:my_first_app/pages/school_admin/school_reports_page.dart';
import 'package:my_first_app/pages/school_admin/school_settings_page.dart';
import 'package:my_first_app/pages/school_admin/school_scan_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_dashboard_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_profile_page.dart';

void main() {
  testWidgets('Energy drawer item opens SchoolAdminEnergyPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('พลังงานทั้งโรงเรียน'));
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminEnergyPage), findsOneWidget);
  });

  testWidgets('CCTV drawer item opens SchoolAdminCctvPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('กล้อง CCTV'));
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminCctvPage), findsOneWidget);
  });

  testWidgets('Schedule drawer item opens SchoolAdminDeviceSchedulePage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('ตั้งเวลาอุปกรณ์'));
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminDeviceSchedulePage), findsOneWidget);
  });

  testWidgets('ESG drawer item opens SchoolAdminEsgPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('รายงาน ESG'));
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminEsgPage), findsOneWidget);
  });

  testWidgets('Device control drawer item opens SchoolAdminDeviceControlPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('ควบคุมไฟและน้ำ'));
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminDeviceControlPage), findsOneWidget);
  });

  testWidgets('Incident inbox drawer item opens SchoolAdminIncidentInboxPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('กล่องแจ้งเหตุการณ์'));
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminIncidentInboxPage), findsOneWidget);
  });

  testWidgets('Students card opens SchoolStudentsPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('ข้อมูลนักเรียน').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolStudentsPage), findsOneWidget);
  });

  testWidgets('Teachers card opens SchoolTeachersPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('ครูและบุคลากร').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolTeachersPage), findsOneWidget);
  });

  testWidgets('Permissions card opens SchoolPermissionsPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('กำหนดสิทธิ์บุคลากร').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolPermissionsPage), findsOneWidget);
  });

  testWidgets('Import card opens SchoolImportPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('นำเข้าข้อมูล (Batch Import)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolImportPage), findsOneWidget);
  });

  testWidgets('Alerts card opens SchoolAlertsPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('การแจ้งเตือนเซนเซอร์ & ระบบ').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAlertsPage), findsOneWidget);
  });

  testWidgets('Resources card opens SchoolResourcesPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('การใช้ทรัพยากร (น้ำ/ไฟ)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolResourcesPage), findsOneWidget);
  });

  testWidgets('Devices card opens SchoolDevicesPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('คลังอุปกรณ์ IoT (Inventory)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolDevicesPage), findsOneWidget);
  });

  testWidgets('Buildings card opens SchoolBuildingsPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('อาคารและห้องเรียน (Buildings & Rooms)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolBuildingsPage), findsOneWidget);
  });

  testWidgets('Reports card opens SchoolReportsPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('รายงานและสถิติ (School Reports)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolReportsPage), findsOneWidget);
  });

  testWidgets('Settings card opens SchoolSettingsPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('ตั้งค่าโรงเรียน (School Settings)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolSettingsPage), findsOneWidget);
  });

  testWidgets('Scan card opens SchoolScanPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('สแกน QR Code (Scanner)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolScanPage), findsOneWidget);
  });

  testWidgets('Admin Hub card opens SchoolAdminDashboardPage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('ศูนย์กลางแดชบอร์ดใหม่ (Admin Hub)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminDashboardPage), findsOneWidget);
  });

  testWidgets('Admin Profile card opens SchoolAdminProfilePage', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));
    await tester.pumpAndSettle();

    final target = find.text('โปรไฟล์ผู้ดูแล (Admin Profile)').first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(SchoolAdminProfilePage), findsOneWidget);
  });

  testWidgets('Dashboard drawer item closes drawer without error', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Dashboard โรงเรียน'), findsOneWidget);
    await tester.tap(find.text('Dashboard โรงเรียน'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard โรงเรียน'), findsNothing);
  });
}

