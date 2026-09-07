import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_notifications_page.dart';

void main() {
  testWidgets(
    'a failed/empty real notification load never leaves the old fake 4 notifications on screen',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: TeacherNotificationsPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The old bug seeded the page with 4 hardcoded notifications (SOS
      // emergency, UV sensor, grading, camera) and only overwrote them when
      // a real, non-empty load succeeded — a teacher with zero real
      // notifications, or hitting a load error, saw these forever.
      expect(find.textContaining('เกิดเหตุ SOS ฉุกเฉิน'), findsNothing);
      expect(find.textContaining('รังสี UV สูงเกินขอบเขต'), findsNothing);
      expect(find.textContaining('กล้อง AI Security'), findsNothing);
      expect(find.text('ไม่มีการแจ้งเตือนในหมวดนี้'), findsOneWidget);
    },
  );
}
