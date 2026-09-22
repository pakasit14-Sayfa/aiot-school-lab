import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/school_admin/school_permissions_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'SchoolPermissionsPage renders redesigned tabs, header and filters',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolPermissionsPage()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Header & Summary
      expect(
        find.text('จัดการสิทธิ์และบทบาท (Roles & Permissions)'),
        findsOneWidget,
      );
      expect(find.text('ผู้มีสิทธิ์ทั้งหมด'), findsOneWidget);

      // Tab Bar buttons
      expect(find.text('ผู้ใช้งานและสิทธิ์'), findsWidgets);
      expect(find.text('ตารางสิทธิ์ตามบทบาท'), findsOneWidget);
      expect(find.text('ประวัติการปรับสิทธิ์'), findsOneWidget);

      // Tab 0 default: search filter visible
      expect(find.text('ค้นหาและกรองผู้ใช้งาน'), findsOneWidget);

      // Switch to Tab 1: Role Matrix
      await tester.tap(find.text('ตารางสิทธิ์ตามบทบาท'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('บทบาทในระบบ'), findsOneWidget);
      expect(find.text('ตารางสิทธิ์ตามบทบาท'), findsWidgets);
      expect(find.text('หลักการกำหนดสิทธิ์ที่แนะนำ'), findsOneWidget);

      // Switch to Tab 2: Audit Logs
      await tester.tap(find.text('ประวัติการปรับสิทธิ์'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Log การเปลี่ยนสิทธิ์ล่าสุด'), findsOneWidget);
    },
  );

  // "เพิ่มสิทธิ์" used to build a fake `_PermissionUser` in memory and claim
  // it was saved. Since 2026-09-16 the page offers "เชิญผู้ใช้งาน", backed by
  // create_school_invitation — an enabled button with a real backend. The
  // fake creation dialog must not come back.
  testWidgets(
    'SchoolPermissionsPage offers a real invite instead of faking account creation',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SchoolPermissionsPage()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('เพิ่มสิทธิ์'), findsNothing);
      final invite = find.byWidgetPredicate(
        (w) => w is ButtonStyleButton && w.onPressed != null,
      );
      expect(
        find.descendant(of: invite, matching: find.text('เชิญผู้ใช้งาน')),
        findsOneWidget,
      );
      expect(find.text('เพิ่มสิทธิ์ผู้ใช้งาน'), findsNothing);
    },
  );
}
