import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/pages/super_admin/super_admin_alerts_logs_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'SuperAdminAlertsLogsPage renders gracefully in unmocked environment',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: SuperAdminAlertsLogsPage()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('การแจ้งเตือนและประวัติระบบ (Alerts & Logs)'),
        findsOneWidget,
      );
    },
  );
}
