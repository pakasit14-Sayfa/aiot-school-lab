import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_score_page.dart';
import 'package:shared_core/shared_core.dart';

final _confirmedGrade = CourseGrade(
  id: 'g-1',
  courseId: 'course-1',
  subjectName: 'คณิตศาสตร์',
  score: 85,
  maxScore: 100,
  confirmedAt: DateTime(2026, 9, 1),
);

final _gScoreEntry = MyGScoreEntry(
  id: 'gs-1',
  courseId: 'course-1',
  subjectName: 'คณิตศาสตร์',
  source: 'lesson_completed',
  points: 5,
  confirmedAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseGrade>> Function()? loadGrades,
  Future<List<MyGScoreEntry>> Function()? loadGScore,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentScorePage(
        loadGrades: loadGrades ?? () async => const [],
        loadGScore: loadGScore ?? () async => const [],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'real confirmed grades show the real subject/score, no invented GPA/badges',
    (tester) async {
      await _pump(tester, loadGrades: () async => [_confirmedGrade]);
      expect(find.text('คณิตศาสตร์'), findsWidgets);
      expect(find.textContaining('85/100'), findsOneWidget);
    },
  );

  testWidgets(
    'zero real grades shows an honest empty state, not fabricated ones',
    (tester) async {
      await _pump(tester);
      expect(find.text('ยังไม่มีคะแนนที่ยืนยันแล้ว'), findsOneWidget);
    },
  );

  testWidgets('real G-Score entries show without the demo badge', (
    tester,
  ) async {
    await _pump(tester, loadGScore: () async => [_gScoreEntry]);
    expect(find.textContaining('เรียนจบบทเรียน'), findsOneWidget);
    expect(find.textContaining('ตัวอย่าง — ข้อมูลจำลอง'), findsNothing);
  });

  /// เดิมตอนไม่มี G-Score จริงจะสลับไปโชว์รายการจำลอง 3 รายการพร้อมป้าย
  /// "ข้อมูลจำลอง" — แต่หัวการ์ดก็ขึ้น "13 คะแนน" นักเรียนที่ยังไม่มีคะแนน
  /// เห็นคะแนนที่ไม่ใช่ของตัวเอง ตอนนี้ต้องเป็น 0 และบอกว่าจะได้คะแนนจากอะไร
  testWidgets(
    'zero real G-Score shows 0 and how to earn it — never demo entries',
    (tester) async {
      await _pump(tester);
      expect(find.text('0 คะแนน'), findsOneWidget);
      expect(
        find.textContaining('ยังไม่มีคะแนน G-Score ที่ครูยืนยัน'),
        findsOneWidget,
      );
      expect(find.textContaining('ข้อมูลจำลอง'), findsNothing);
      expect(find.textContaining('วิทยาศาสตร์ ม.5'), findsNothing);
      expect(find.textContaining('การออกแบบเทคโนโลยี'), findsNothing);
      expect(find.text('13 คะแนน'), findsNothing);
    },
  );

  testWidgets(
    'a real load failure shows an honest error, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        loadGrades: () async =>
            throw StateError('backend detail that must stay internal'),
      );
      expect(find.textContaining('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );
}
