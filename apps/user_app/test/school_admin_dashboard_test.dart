import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/dashboard/school_admin_dashboard.dart';
import 'package:my_first_app/pages/school_admin/school_admin_energy_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_cctv_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_schedule_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_esg_page.dart';

import 'package:my_first_app/pages/school_admin/school_admin_device_control_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_incident_inbox_page.dart';

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
