import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/dashboard/school_admin_dashboard.dart';

void main() {
  testWidgets('CCTV drawer item shows Phase 5 coming soon snackbar', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('กล้อง CCTV'));
    await tester.pumpAndSettle();

    expect(find.text('กล้อง CCTV อยู่ระหว่างพัฒนา (Phase 5)'), findsOneWidget);
  });

  testWidgets('Schedule drawer item shows Phase 4 coming soon snackbar', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('ตั้งเวลาอุปกรณ์'));
    await tester.pumpAndSettle();

    expect(find.text('ตั้งเวลาอุปกรณ์ อยู่ระหว่างพัฒนา (Phase 4)'), findsOneWidget);
  });

  testWidgets('ESG drawer item shows Phase 6 coming soon snackbar', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolAdminDashboard()));

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('รายงาน ESG'));
    await tester.pumpAndSettle();

    expect(find.text('รายงาน ESG อยู่ระหว่างพัฒนา (Phase 6)'), findsOneWidget);
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
