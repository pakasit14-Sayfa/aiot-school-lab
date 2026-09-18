import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_search_popup.dart';
import 'package:shared_core/shared_core.dart';

/// The search popup's field used to search nothing and its chips were
/// invented labels. These pin that hits come only from the injected
/// loaders, that shortcuts are real tabs, and that a miss is reported.
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

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<int>? onOpenTab,
  VoidCallback? onClose,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(14),
          child: StudentSearchPopup(
            onClose: onClose ?? () {},
            onOpenTab: onOpenTab ?? (_) {},
            onOpenScore: () {},
            loadCourses: () async => const [_math, _sci],
            loadAssignmentsForCourse: (id) async =>
                id == 'c-sci' ? const [_hw] : const [],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'empty query shows real shortcuts, never the old invented chips',
    (tester) async {
      await _pump(tester);
      for (final label in ['บทเรียน', 'ใบงาน', 'ปฏิทิน', 'คะแนน']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('ครูสมชาย'), findsNothing);
      expect(find.text('AIoT'), findsNothing);
    },
  );

  testWidgets(
    'typing lists matching courses and assignments from the loaders',
    (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'เซนเซอร์');
      await tester.pumpAndSettle();
      expect(find.text('ใบงาน (1)'), findsOneWidget);
      expect(find.text('แบบฝึกหัดเซนเซอร์อุณหภูมิ'), findsOneWidget);
      expect(find.text('คณิตศาสตร์'), findsNothing);

      await tester.enterText(find.byType(TextField), 'ม.1');
      await tester.pumpAndSettle();
      expect(find.text('รายวิชา (2)'), findsOneWidget);
    },
  );

  testWidgets('a miss is reported with the query', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'ภาษาอังกฤษ');
    await tester.pumpAndSettle();
    expect(find.text('ไม่พบ "ภาษาอังกฤษ"'), findsOneWidget);
  });

  testWidgets('a shortcut closes the popup and switches the tab', (
    tester,
  ) async {
    int? tab;
    var closed = false;
    await _pump(
      tester,
      onOpenTab: (i) => tab = i,
      onClose: () => closed = true,
    );
    await tester.tap(find.text('ปฏิทิน'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(tab, 3);
  });
}
