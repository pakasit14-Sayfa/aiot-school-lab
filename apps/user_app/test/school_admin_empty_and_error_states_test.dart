import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/school_admin/school_buildings_page.dart';
import 'package:my_first_app/pages/school_admin/school_students_page.dart';
import 'package:my_first_app/pages/school_admin/school_teachers_page.dart';
import 'package:my_first_app/pages/school_admin/school_devices_page.dart';
import 'package:my_first_app/pages/school_admin/school_permissions_page.dart';
import 'package:my_first_app/pages/school_admin/school_import_page.dart';
import 'package:my_first_app/pages/school_admin/school_alerts_page.dart';
import 'package:my_first_app/pages/school_admin/school_reports_page.dart';
import 'package:my_first_app/pages/school_admin/school_settings_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_profile_page.dart';

void main() {
  setUp(() {
    currentUserModel = const UserModel(
      uid: 'test-admin',
      name: 'ทดสอบ แอดมิน',
      email: 'admin@school.test',
      role: UserRole.schoolAdmin,
      schoolId: 'sch-test',
    );
  });

  tearDown(() {
    currentUserModel = null;
  });

  testWidgets(
    'SchoolBuildingsPage displays honest error/empty states with 0 mock buildings',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolBuildingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('โหลดข้อมูลอาคารไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ยังไม่มีประวัติการจัดการอาคารและห้อง'), findsOneWidget);
    },
  );

  testWidgets(
    'SchoolStudentsPage displays honest empty state with 0 mock students',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolStudentsPage()));
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบรายชื่อนักเรียน'), findsOneWidget);
    },
  );

  testWidgets(
    'SchoolTeachersPage displays honest empty state with 0 mock teachers',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolTeachersPage()));
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบรายชื่อครูและบุคลากร'), findsOneWidget);
    },
  );

  testWidgets(
    'SchoolDevicesPage displays honest empty states with 0 mock devices & logs',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolDevicesPage()));
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบอุปกรณ์'), findsOneWidget);
      expect(find.text('ยังไม่มีประวัติการจัดการอุปกรณ์'), findsOneWidget);
    },
  );

  testWidgets('SchoolPermissionsPage displays honest empty state for logs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: SchoolPermissionsPage()));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีประวัติการจัดการสิทธิ์'), findsOneWidget);
  });

  testWidgets(
    'SchoolImportPage displays honest empty history and safe summary',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolImportPage()));
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีประวัติการนำเข้าข้อมูลในระบบ'), findsOneWidget);
      expect(find.text('ยังไม่มีประวัติการนำเข้า'), findsOneWidget);
    },
  );

  testWidgets(
    'SchoolAlertsPage distinguishes audit-log error from empty alerts',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolAlertsPage()));
      await tester.pumpAndSettle();

      expect(find.text('โหลดประวัติการแจ้งเตือนไม่สำเร็จ'), findsOneWidget);
    },
  );

  testWidgets(
    'SchoolReportsPage displays honest disclosure on preview reports and empty logs',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolReportsPage()));
      await tester.pumpAndSettle();

      expect(
        find.text('ระบบสร้างรายงานและส่งออกไฟล์ยังไม่พร้อมใช้งานในเวอร์ชันนี้'),
        findsOneWidget,
      );
      expect(find.text('ยังไม่มีประวัติการใช้งานรายงาน'), findsOneWidget);
    },
  );

  testWidgets(
    'SchoolSettingsPage displays Tier B disclosure notice and empty logs',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolSettingsPage()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'ระบบการตั้งค่าโรงเรียน การแจ้งเตือน และความปลอดภัยยังไม่เชื่อมต่อระบบหลังบ้าน',
        ),
        findsOneWidget,
      );
      expect(find.text('ยังไม่มีประวัติการแก้ไขการตั้งค่า'), findsOneWidget);
    },
  );

  testWidgets(
    'SchoolAdminProfilePage displays Tier B disclosure notice and empty logs',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: SchoolAdminProfilePage()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ข้อมูลโปรไฟล์ดึงจากบัญชีปัจจุบัน'),
        findsOneWidget,
      );
      expect(find.text('ยังไม่มีประวัติกิจกรรมล่าสุด'), findsOneWidget);
    },
  );
}
