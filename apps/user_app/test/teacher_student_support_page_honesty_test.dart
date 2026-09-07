import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_student_support_page.dart';

void main() {
  testWidgets(
    'a failed case list load shows an honest error, never the old fake at-risk students',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: TeacherStudentSupportPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The old bug fell back to 2 hardcoded "at-risk student" cases (fake
      // names, fake risk levels) on ANY load failure — a teacher hitting a
      // transient backend error would see fabricated at-risk students with
      // no indication they weren't real. Neither may ever render again.
      expect(find.textContaining('อภิสิทธิ์ วงศ์สวัสดิ์'), findsNothing);
      expect(find.textContaining('ณัฐธิดา ไพศาล'), findsNothing);
      expect(find.textContaining('โหลดรายการไม่สำเร็จ'), findsOneWidget);
    },
  );
}
