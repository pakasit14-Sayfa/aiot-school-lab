import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import '../lib/pages/student_redesign_prototype/widgets/student_navigation_prototype.dart';

// StudentGradeLevelText is the exact widget both of the student shell's
// real-estate entry points (mobile drawer header, desktop sidebar class
// card) now construct. Testing it directly avoids mounting the full
// StudentNavigationPrototype shell's other 4 IndexedStack tabs, several of
// which start real, non-injectable device/sensor polling — same reasoning
// as student_navigation_notification_test.dart's StudentNotificationBell
// harness.

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.2/3',
  room: '203',
  status: 'active',
  termId: 'term-1',
);

Widget _harness({
  Future<List<CourseSummary>> Function()? listMyCourses,
  String? fallback,
}) {
  return MaterialApp(
    home: Scaffold(
      body: StudentGradeLevelText(
        style: const TextStyle(fontSize: 12),
        fallback: fallback,
        listMyCourses: listMyCourses,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a real grade level shows the real value, not the old hardcoded ม.5/2',
    (tester) async {
      await tester.pumpWidget(
        _harness(listMyCourses: () async => const [_course]),
      );
      await tester.pumpAndSettle();

      expect(find.text('ชั้น ม.2/3'), findsOneWidget);
      expect(find.textContaining('ม.5/2'), findsNothing);
    },
  );

  testWidgets(
    'no real courses with a fallback set shows the honest fallback text',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          listMyCourses: () async => const [],
          fallback: 'ยังไม่มีข้อมูลชั้นเรียน',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีข้อมูลชั้นเรียน'), findsOneWidget);
    },
  );

  testWidgets(
    'no real courses with no fallback renders nothing, matching the mobile drawer default',
    (tester) async {
      await tester.pumpWidget(_harness(listMyCourses: () async => const []));
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsNothing);
    },
  );

  testWidgets('a real load failure fails silently, no leaked exception text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        listMyCourses: () async =>
            throw StateError('backend detail that must stay internal'),
        fallback: 'ยังไม่มีข้อมูลชั้นเรียน',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูลชั้นเรียน'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });
}
