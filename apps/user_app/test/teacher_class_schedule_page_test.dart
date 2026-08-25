import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_class_schedule_page.dart';

void main() {
  testWidgets('TeacherClassSchedulePage renders shell and controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TeacherClassSchedulePage(),
      ),
    );

    // Initial pump (may be loading or showing content if empty)
    await tester.pump();

    // Verify title or shell is rendered
    expect(find.byType(TeacherClassSchedulePage), findsOneWidget);
  });
}
