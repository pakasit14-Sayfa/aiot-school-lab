import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_scan_controller.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_scan_page.dart';
import 'package:shared_core/models/school_device_identity.dart';

SchoolDeviceIdentity device() => SchoolDeviceIdentity.fromRow({
  'id': 'd1',
  'device_code': 'DEV-A',
  'kit_code': 'KIT-A',
  'name': 'อุปกรณ์จริง',
  'type': 'light_sensor',
  'status': 'offline',
  'location': null,
});
void main() {
  testWidgets(
    'typed code reaches lookup; loading, error, absent and data stay distinct',
    (tester) async {
      final pending = Completer<SchoolDeviceIdentity?>();
      var calls = 0;
      final controller = DirectorScanController(
        lookup: (code) {
          expect(code, 'DEV-A');
          calls++;
          return calls == 1
              ? pending.future
              : Future.value(calls == 2 ? null : device());
        },
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: DirectorScanPage(controller: controller)),
      );
      expect(find.text('ยังไม่ได้ค้นหาอุปกรณ์'), findsOneWidget);
      await tester.enterText(find.byType(TextField), ' DEV-A ');
      await tester.tap(find.text('ค้นหา'));
      await tester.pump();
      expect(find.text('กำลังค้นหาอุปกรณ์'), findsOneWidget);
      expect(find.text('ไม่พบอุปกรณ์ในโรงเรียน'), findsNothing);
      pending.completeError(StateError('private error'));
      await tester.pumpAndSettle();
      expect(find.text('ค้นหาไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('private error'), findsNothing);
      await tester.ensureVisible(find.text('ลองอีกครั้ง'));
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบอุปกรณ์ในโรงเรียน'), findsOneWidget);
      await tester.ensureVisible(find.text('ค้นหา'));
      await tester.tap(find.text('ค้นหา'));
      await tester.pumpAndSettle();
      expect(find.text('อุปกรณ์จริง'), findsOneWidget);
      expect(find.text('สถานะในทะเบียน: ออฟไลน์'), findsOneWidget);
      expect(find.textContaining('พร้อมใช้งาน'), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'บันทึกยืม–คืน'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'editing code invalidates an in-flight lookup and blank input does not call backend',
    () async {
      final pending = Completer<SchoolDeviceIdentity?>();
      var calls = 0;
      final controller = DirectorScanController(
        lookup: (_) {
          calls++;
          return pending.future;
        },
      );
      addTearDown(controller.dispose);
      await controller.search(' ');
      expect(calls, 0);
      final lookup = controller.search('DEV-A');
      controller.clear();
      pending.complete(device());
      await lookup;
      expect(controller.device, isNull);
      expect(controller.searched, isFalse);
    },
  );
  testWidgets('scan form and results fit a small phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = DirectorScanController(lookup: (_) async => device());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: DirectorScanPage(controller: controller)),
    );
    await controller.search('DEV-A');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
