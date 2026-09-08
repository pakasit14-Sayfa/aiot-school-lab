import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_gscore_confirm_page.dart';
import 'package:shared_core/shared_core.dart';

final _entry = PendingGScoreEntry(
  id: 'gs-1',
  studentId: 's-1',
  studentFirstName: 'สมชาย',
  studentLastName: 'ใจดี',
  courseId: 'course-1',
  subjectName: 'วิทยาศาสตร์',
  source: 'lesson_completed',
  points: 10,
  createdAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<PendingGScoreEntry>> Function()? listPendingGScore,
  Future<void> Function(String entryId)? confirmGScore,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherGScoreConfirmPage(
        listPendingGScore: listPendingGScore ?? () async => [_entry],
        confirmGScore: confirmGScore,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a real pending entry shows the real student/subject/points, not fabricated data', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('สมชาย ใจดี'), findsOneWidget);
    expect(find.textContaining('วิทยาศาสตร์'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
  });

  testWidgets('confirming calls the real RPC with the real entry id and removes it from the list', (
    tester,
  ) async {
    String? confirmedId;
    await _pump(
      tester,
      confirmGScore: (entryId) async {
        confirmedId = entryId;
      },
    );

    await tester.tap(find.text('ยืนยัน'));
    await tester.pumpAndSettle();

    expect(confirmedId, 'gs-1');
    expect(find.text('สมชาย ใจดี'), findsNothing);
    expect(find.text('ไม่มีรายการรออนุมัติในตอนนี้'), findsOneWidget);
  });

  testWidgets('a failed confirm keeps the entry in the list, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      confirmGScore: (_) async =>
          throw StateError('backend detail that must stay internal'),
    );

    await tester.tap(find.text('ยืนยัน'));
    await tester.pumpAndSettle();

    expect(find.text('สมชาย ใจดี'), findsOneWidget);
    expect(find.text('ยืนยันไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('zero pending entries shows an honest empty state', (
    tester,
  ) async {
    await _pump(tester, listPendingGScore: () async => const []);
    expect(find.text('ไม่มีรายการรออนุมัติในตอนนี้'), findsOneWidget);
  });

  testWidgets('a real load failure shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      listPendingGScore: () async =>
          throw StateError('backend detail that must stay internal'),
    );
    expect(find.text('โหลดรายการรออนุมัติไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });
}
