import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/super_admin/super_admin_permissions_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'SuperAdminPermissionsPage renders and shows error state gracefully in unmocked environment',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: SuperAdminPermissionsPage()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('กำหนดสิทธิ์และบทบาท (Permissions)'), findsOneWidget);
      expect(
        find.text('ไม่สามารถโหลดข้อมูลสิทธิ์และผู้ใช้ได้'),
        findsOneWidget,
      );
      expect(find.text('ลองใหม่อีกครั้ง'), findsOneWidget);
    },
  );
}
