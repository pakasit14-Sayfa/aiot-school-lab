import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/super_admin/super_admin_settings_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SuperAdminSettingsPage renders Tier B notice and thresholds', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminSettingsPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ตั้งค่าระบบส่วนกลาง (Platform Settings)', skipOffstage: false), findsOneWidget);
    expect(
      find.text(
        'หมายเหตุ: ระบบการตั้งค่าแพลตฟอร์มส่วนกลาง การแจ้งเตือน และ Thresholds ยังไม่เชื่อมต่อระบบหลังบ้าน การแก้ไขจะไม่ถูกบันทึกจริงลงฐานข้อมูล',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}
