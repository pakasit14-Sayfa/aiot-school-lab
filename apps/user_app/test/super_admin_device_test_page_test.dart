import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_test_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SuperAdminDeviceTestPage renders Tier B notice and initial unmeasured state', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminDeviceTestPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ทดสอบอุปกรณ์และระบบ (Device Diagnostics)'), findsOneWidget);
    expect(
      find.text(
        'หมายเหตุ: ระบบทดสอบฮาร์ดแวร์จริงยังอยู่ระหว่างการพัฒนา การทดสอบนี้เป็นการตรวจสอบความพร้อมของ API และสถานะระบบส่วนกลาง',
      ),
      findsOneWidget,
    );
    expect(find.text('เริ่มทดสอบระบบทั้งหมด'), findsOneWidget);
    expect(find.text('ยังไม่วัด'), findsWidgets);
  });
}
