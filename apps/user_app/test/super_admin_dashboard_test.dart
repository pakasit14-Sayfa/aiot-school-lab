import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/dashboard/super_admin_dashboard.dart';
import 'package:my_first_app/pages/super_admin/super_admin_schools_page.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_control_page.dart';

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

    expect(find.text('จัดการโรงเรียน (Schools)'), findsOneWidget);
    expect(find.text('ควบคุม & อนุมัติอุปกรณ์ (Device Control)'), findsOneWidget);
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
}
