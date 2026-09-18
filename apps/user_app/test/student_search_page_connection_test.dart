import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_search_page.dart';
import 'package:shared_core/shared_core.dart';

/// StudentSearchPage replaced a glass dialog whose chips ("AIoT", "วิทย์",
/// "ครูสมชาย") were hardcoded and searched nothing. These pin that results
/// come only from the injected course/assignment loaders and that an empty
/// query shows shortcuts, not invented suggestions. Pumped at iPhone size.
const _math = CourseSummary(
  id: 'c-math',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 't1',
);
const _sci = CourseSummary(
  id: 'c-sci',
  subjectName: 'วิทยาศาสตร์ AIoT',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 't1',
);
const _hw = AssignmentSummary(
  id: 'a-1',
  type: 'homework',
  title: 'แบบฝึกหัดเซนเซอร์อุณหภูมิ',
  dueAt: null,
  status: 'published',
);

Future<void> _pump(WidgetTester tester, {ValueChanged<int>? onOpenTab}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentSearchPage(
        onOpenTab: onOpenTab,
        loadCourses: () async => const [_math, _sci],
        loadAssignmentsForCourse: (id) async =>
            id == 'c-sci' ? const [_hw] : const [],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'empty query shows shortcuts and the real course list, no fake chips',
    (tester) async {
      await _pump(tester);
      expect(find.text('ไปที่'), findsOneWidget);
      expect(find.text('รายวิชาของฉัน'), findsOneWidget);
      expect(find.text('คณิตศาสตร์'), findsOneWidget);
      expect(find.text('วิทยาศาสตร์ AIoT'), findsOneWidget);
      expect(find.text('ครูสมชาย'), findsNothing);
      expect(find.text('งานค้าง'), findsNothing);
    },
  );

  testWidgets('typing filters courses and assignments from the loaders', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'เซนเซอร์');
    await tester.pumpAndSettle();
    expect(find.text('ใบงาน (1)'), findsOneWidget);
    expect(find.text('แบบฝึกหัดเซนเซอร์อุณหภูมิ'), findsOneWidget);
    expect(find.text('คณิตศาสตร์'), findsNothing);

    await tester.enterText(find.byType(TextField), 'คณิต');
    await tester.pumpAndSettle();
    expect(find.text('รายวิชา (1)'), findsOneWidget);
    expect(find.text('คณิตศาสตร์'), findsOneWidget);
    expect(find.text('แบบฝึกหัดเซนเซอร์อุณหภูมิ'), findsNothing);
  });

  testWidgets(
    'no match says so with the query, instead of showing something else',
    (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'ภาษาอังกฤษ');
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบ "ภาษาอังกฤษ"'), findsOneWidget);
      expect(find.text('คณิตศาสตร์'), findsNothing);
    },
  );

  testWidgets('a shortcut pops the page and asks the shell for that tab', (
    tester,
  ) async {
    int? opened;
    await _pump(tester, onOpenTab: (i) => opened = i);
    await tester.tap(find.text('ใบงานและการบ้าน'));
    await tester.pumpAndSettle();
    expect(opened, 2);
  });
}
