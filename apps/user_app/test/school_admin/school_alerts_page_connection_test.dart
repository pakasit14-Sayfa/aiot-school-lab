import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_alerts_controller.dart';
import 'package:my_first_app/pages/school_admin/school_alerts_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets('empty backend is shown honestly without sample alert rules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SchoolAdminAlertsController(
      loadAlerts: () async => const <SchoolSensorAlertRecord>[],
      acknowledgeAlert: (alertId) async {},
      resolveAlert: (alertId, {note}) async {},
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAlertsPage(
          controller: controller,
          loadAuditLogs: () async => const <SchoolAdminAuditLog>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('อุปกรณ์ออฟไลน์'), findsNothing);
    expect(find.text('ใส่รหัสผ่านผิดเกิน 3 ครั้ง'), findsNothing);
  });
}
