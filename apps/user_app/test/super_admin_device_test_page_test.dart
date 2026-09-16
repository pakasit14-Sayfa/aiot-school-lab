import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/super_admin/super_admin_device_test_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SuperAdminDeviceTestPage states its real scope and the initial unmeasured state', (tester) async {
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
    expect(find.textContaining('การทดสอบนี้วัดจริง 4 อย่าง'), findsOneWidget);
    // The permanent "MQTT Gateway Direct Probe — ยังไม่สามารถวัดได้" row is gone.
    expect(find.textContaining('MQTT'), findsNothing);
    expect(find.textContaining('ยังไม่สามารถวัดได้'), findsNothing);
    expect(find.text('เริ่มทดสอบระบบทั้งหมด'), findsOneWidget);
    expect(find.text('ยังไม่วัด'), findsWidgets);
  });
}
