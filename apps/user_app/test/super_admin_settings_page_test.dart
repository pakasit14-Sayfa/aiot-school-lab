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
    // Updated 2026-09-07: this page is now genuinely connected
    // (getPlatformSettings/updatePlatformSettings write and read back for
    // real) — the old "ยังไม่เชื่อมต่อระบบหลังบ้าน" (nothing is connected)
    // banner is gone. The Tier B disclosure that replaced it says the
    // opposite: values ARE saved, they just aren't enforced automatically
    // yet (e.g. no real notification dispatch, no real MFA enforcement).
    expect(
      find.textContaining(
        'ค่าที่กรอกในหน้านี้ถูกบันทึกจริงแล้ว แต่ระบบยังไม่มีการบังคับใช้อัตโนมัติตามค่าเหล่านี้',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}
