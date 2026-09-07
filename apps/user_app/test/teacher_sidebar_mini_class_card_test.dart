import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_courses_page.dart';

void main() {
  testWidgets(
    'the sidebar homeroom mini-card never shows the old fixed "ม.5/2 · 32 คน" for every teacher',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // TeacherCoursesPage renders the shared persistent sidebar, which is
      // where _SidebarMiniClassCard lives — it used to hardcode the same
      // homeroom size for literally every teacher, on every page.
      await tester.pumpWidget(
        const MaterialApp(home: TeacherCoursesPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('ม.5/2 · 32 คน'), findsNothing);
    },
  );
}
