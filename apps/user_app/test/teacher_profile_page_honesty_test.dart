import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_profile_page.dart';

void main() {
  testWidgets(
    'a teacher with no real courses/devices never sees the old fabricated stats',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TeacherProfilePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The old bug fabricated a name, subjects, classroom size, and 2
      // hardware devices with fake MAC addresses whenever real data was
      // empty/unavailable — none of that may render again.
      expect(find.text('ครูสมชาย สายวิทย์'), findsNothing);
      expect(find.textContaining('ฟิสิกส์ประยุกต์'), findsNothing);
      expect(find.textContaining('ม.5/2 · 32 คน'), findsNothing);
      expect(find.textContaining('AA:BB:CC:DD:EE:01'), findsNothing);
      // The school-name detail row was hardcoded to 'โรงเรียนสาธิต AIoT' for
      // every teacher regardless of account — no schoolName field/service
      // exists to resolve a real one, so the row was dropped entirely
      // rather than keep showing a fake school for every account.
      expect(find.textContaining('โรงเรียนสาธิต AIoT'), findsNothing);
      expect(find.text('ยังไม่มีวิชาที่สอน'), findsOneWidget);
      expect(find.text('ยังไม่มีอุปกรณ์แล็บ AIoT ที่ผูกกับบัญชีนี้'), findsOneWidget);
    },
  );
}
