import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/widgets/parent_common_widgets.dart';
import 'package:shared_core/shared_core.dart';

const _students = [
  LinkedStudentItem(
    studentId: 'student-1',
    firstName: 'นักเรียน',
    lastName: 'หนึ่ง',
    schoolId: 'school-1',
    relationship: 'บุตร',
  ),
  LinkedStudentItem(
    studentId: 'student-2',
    firstName: 'นักเรียน',
    lastName: 'สอง',
    schoolId: 'school-2',
    relationship: 'หลาน',
  ),
];

Widget _app({required Size size, required ValueChanged<String> onSelected}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: ParentStudentSwitcher(
            students: _students,
            selectedStudent: _students.first,
            onSelected: onSelected,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('desktop selector sends the newly selected student id', (
    tester,
  ) async {
    String? selectedId;
    await tester.binding.setSurfaceSize(const Size(1100, 700));
    await tester.pumpWidget(
      _app(
        size: const Size(1100, 700),
        onSelected: (value) => selectedId = value,
      ),
    );

    await tester.tap(find.byKey(const Key('parent-student-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('นักเรียน สอง').last);
    await tester.pumpAndSettle();

    expect(selectedId, 'student-2');
  });

  testWidgets('mobile selector opens a bottom sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      _app(size: const Size(390, 844), onSelected: (_) {}),
    );

    await tester.tap(find.byKey(const Key('parent-student-switcher')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('parent-student-bottom-sheet')),
      findsOneWidget,
    );
    expect(find.text('เลือกนักเรียน'), findsOneWidget);
    expect(find.text('นักเรียน หนึ่ง'), findsWidgets);
    expect(find.text('นักเรียน สอง'), findsOneWidget);
  });

  testWidgets('student switcher does not overflow a mobile page header', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ParentPageHeader(
              title: 'ปฏิทินวิชาการ',
              subtitle: 'ติดตามกำหนดการของโรงเรียน',
              icon: Icons.calendar_month_rounded,
              trailing: ParentStudentSwitcher(
                students: _students,
                selectedStudent: _students.first,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('นักเรียน หนึ่ง'), findsOneWidget);
  });

  testWidgets(
    'mobile selector scrolls to and selects a student in a long list',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final manyStudents = List.generate(
        20,
        (index) => LinkedStudentItem(
          studentId: 'student-$index',
          firstName: 'นักเรียน',
          lastName: 'คนที่ ${index + 1}',
          schoolId: 'school-1',
          relationship: 'บุตร',
        ),
      );
      String? selectedId;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 600)),
            child: Scaffold(
              body: ParentStudentSwitcher(
                students: manyStudents,
                selectedStudent: manyStudents.first,
                onSelected: (value) => selectedId = value,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('parent-student-switcher')));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('นักเรียน คนที่ 20'),
        find.byType(ListView),
        const Offset(0, -250),
      );
      await tester.tap(find.text('นักเรียน คนที่ 20'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(selectedId, 'student-19');
    },
  );
}
