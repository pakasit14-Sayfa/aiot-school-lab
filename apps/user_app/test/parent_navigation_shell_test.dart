import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/widgets/parent_navigation_shell.dart';
import 'package:shared_core/shared_core.dart';

const _secondStudent = LinkedStudentItem(
  studentId: 'student-2',
  firstName: 'นักเรียน',
  lastName: 'สอง',
  schoolId: 'school-2',
  relationship: 'บุตร',
);

void main() {
  testWidgets('one student selection is shared across parent pages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: ParentNavigationShell(
          pagesBuilder: (selectedStudentId, onStudentSelected) => List.generate(
            7,
            (index) => Scaffold(
              body: Column(
                children: [
                  Text('page-$index:${selectedStudentId ?? 'none'}'),
                  FilledButton(
                    onPressed: () => onStudentSelected(_secondStudent),
                    child: const Text('เลือกคนที่สอง'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('page-0:none'), findsOneWidget);
    await tester.tap(find.text('เลือกคนที่สอง'));
    await tester.pumpAndSettle();
    expect(find.text('page-0:student-2'), findsOneWidget);

    await tester.tap(find.text('การเรียน'));
    await tester.pumpAndSettle();
    expect(find.text('page-1:student-2'), findsOneWidget);
  });
}
