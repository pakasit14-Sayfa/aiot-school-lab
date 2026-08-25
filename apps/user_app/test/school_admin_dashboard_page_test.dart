import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:my_first_app/pages/school_admin/school_admin_dashboard_page.dart';
import 'package:my_first_app/pages/school_admin/school_students_page.dart';
import 'package:my_first_app/pages/school_admin/school_teachers_page.dart';
import 'package:my_first_app/pages/school_admin/school_import_page.dart';
import 'package:my_first_app/pages/school_admin/school_permissions_page.dart';
import 'package:my_first_app/pages/school_admin/school_buildings_page.dart';
import 'package:my_first_app/pages/school_admin/school_devices_page.dart';
import 'package:my_first_app/pages/school_admin/school_resources_page.dart';
import 'package:my_first_app/pages/school_admin/school_scan_page.dart';
import 'package:my_first_app/pages/school_admin/school_alerts_page.dart';
import 'package:my_first_app/pages/school_admin/school_reports_page.dart';
import 'package:my_first_app/pages/school_admin/school_settings_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_energy_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_cctv_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_schedule_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_esg_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_control_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_incident_inbox_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_profile_page.dart';

import 'package:shared_core/shared_core.dart';

void main() {
  setUp(() {
    currentUserModel = const UserModel(
      uid: 'u-admin-1',
      name: 'แอดมินโรงเรียน',
      email: 'schooladmin@aiot-school-lab.local',
      role: UserRole.schoolAdmin,
      schoolId: 'sch-1',
    );
  });

  tearDown(() {
    currentUserModel = null;
  });

  testWidgets('SchoolAdminDashboardPage desktop navigates to core batch 1 and batch 2 pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(home: SchoolAdminDashboardPage()),
    );
    await tester.pumpAndSettle();

    // 0. Home
    expect(find.text('AIoT Smart Lab'), findsOneWidget);

    // 1. Students
    await tester.tap(find.text('จัดการนักเรียน').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolStudentsPage), findsOneWidget);

    // 2. Teachers
    await tester.tap(find.text('ครูและบุคลากร').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolTeachersPage), findsOneWidget);

    // 3. Import
    await tester.tap(find.text('นำเข้าข้อมูล').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolImportPage), findsOneWidget);

    // 4. Permissions
    await tester.tap(find.text('กำหนดสิทธิ์').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolPermissionsPage), findsOneWidget);

    // 5. Buildings
    await tester.tap(find.text('อาคารและห้อง').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolBuildingsPage), findsOneWidget);

    // 6. Devices
    await tester.tap(find.text('อุปกรณ์').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolDevicesPage), findsOneWidget);

    // 7. Resources
    await tester.tap(find.text('การใช้ทรัพยากร').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolResourcesPage), findsOneWidget);

    // 8. Scan
    await tester.tap(find.text('สแกนคิวอาร์โค้ด').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolScanPage), findsOneWidget);

    // 9. Alerts
    await tester.tap(find.text('การแจ้งเตือน').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolAlertsPage), findsOneWidget);

    // 10. Reports
    await tester.tap(find.text('รายงาน').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolReportsPage), findsOneWidget);

    // 11. Settings
    await tester.tap(find.text('ตั้งค่าโรงเรียน').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolSettingsPage), findsOneWidget);
  });

  testWidgets('SchoolAdminDashboardPage desktop navigates to operational pages and profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(home: SchoolAdminDashboardPage()),
    );
    await tester.pumpAndSettle();

    // 12. Users
    final usersItem = find.text('จัดการผู้ใช้').first;
    await tester.ensureVisible(usersItem);
    await tester.tap(usersItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(UserListPage), findsOneWidget);

    // 13. Consent Policy
    final consentItem = find.text('Consent Policy').first;
    await tester.ensureVisible(consentItem);
    await tester.tap(consentItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ConsentPolicyAdminPage), findsOneWidget);

    // 14. Energy
    final energyItem = find.text('พลังงานทั้งโรงเรียน').first;
    await tester.ensureVisible(energyItem);
    await tester.tap(energyItem);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolAdminEnergyPage), findsOneWidget);

    // 15. CCTV
    final cctvItem = find.text('กล้อง CCTV').first;
    await tester.ensureVisible(cctvItem);
    await tester.tap(cctvItem);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolAdminCctvPage), findsOneWidget);

    // 16. Schedule
    final scheduleItem = find.text('ตั้งเวลาอุปกรณ์').first;
    await tester.ensureVisible(scheduleItem);
    await tester.tap(scheduleItem);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolAdminDeviceSchedulePage), findsOneWidget);

    // 17. ESG
    final esgItem = find.text('รายงาน ESG').first;
    await tester.ensureVisible(esgItem);
    await tester.tap(esgItem);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolAdminEsgPage), findsOneWidget);

    // 18. Device Control
    final controlItem = find.text('ควบคุมไฟและน้ำ').first;
    await tester.ensureVisible(controlItem);
    await tester.tap(controlItem);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolAdminDeviceControlPage), findsOneWidget);

    // 19. Incident Inbox
    final inboxItem = find.text('กล่องแจ้งเหตุการณ์').first;
    await tester.ensureVisible(inboxItem);
    await tester.tap(inboxItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SchoolAdminIncidentInboxPage), findsOneWidget);

    // Profile Click
    final profileCard = find.byKey(const Key('sidebar_user_card'));
    await tester.tap(profileCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SchoolAdminProfilePage), findsOneWidget);
  });

  testWidgets('SchoolAdminDashboardPage mobile opens drawer and navigates cleanly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(home: SchoolAdminDashboardPage()),
    );
    await tester.pumpAndSettle();

    // Open Drawer on Mobile
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('AIoT Smart Lab'), findsWidgets);

    // Tap Students from Drawer
    await tester.tap(find.text('จัดการนักเรียน').first);
    await tester.pumpAndSettle();
    expect(find.byType(SchoolStudentsPage), findsOneWidget);
  });
}
