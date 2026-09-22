import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_lesson_editor_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets(
    'an empty/unreachable course shows the honest empty state, never the old 6 sample lessons',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeacherLessonListPage(
                courseId: 'course-with-no-lessons',
                courseCode: 'ว31281',
                courseName: 'ทดสอบ',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // Loading -> real LessonService.listLessons call fails/returns empty
      // in this session-less test harness.
      await tester.pump(const Duration(milliseconds: 50));

      // The old bug seeded `_lessons` with 6 hardcoded sample lessons and
      // only overwrote them when a real, non-empty result came back — so a
      // genuinely empty (or errored) course kept showing fake lessons
      // forever. None of their titles must ever appear.
      expect(
        find.textContaining('การคิดเชิงคำนวณและการทำความรู้จักกับ AI'),
        findsNothing,
      );
      expect(find.textContaining('Image Classification Model'), findsNothing);
      expect(find.text('ยังไม่มีบทเรียนในวิชานี้'), findsOneWidget);
    },
  );

  LessonModel lesson() => LessonModel(
    id: 'lesson-1',
    courseCode: 'ว31281',
    courseName: 'ทดสอบ',
    title: 'บทเรียนทดสอบ',
    status: LessonStatus.published,
    lastEdited: '-',
    materialsCount: 0,
    sensorChartsCount: 0,
    blocks: [],
    materials: [],
    sensorLinks: [],
  );

  LessonStudentProgress row(
    String name,
    double pct, {
    bool done = false,
    bool opened = true,
  }) => LessonStudentProgress(
    studentId: name,
    firstName: name,
    lastName: '',
    email: '$name@x',
    progressPct: pct,
    completed: done,
    completedAt: done ? DateTime(2026, 9, 16) : null,
    updatedAt: opened ? DateTime(2026, 9, 16) : null,
  );

  testWidgets(
    'lesson analytics shows real per-student progress from list_lesson_progress',
    (tester) async {
      String? askedFor;
      await tester.pumpWidget(
        MaterialApp(
          home: TeacherLessonAnalyticsPage(
            lesson: lesson(),
            loadProgress: (id) async {
              askedFor = id;
              return [
                row('อนันต์', 40),
                row('บุญมี', 100, done: true),
                row('ชนา', 0, opened: false),
              ];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(askedFor, 'lesson-1');
      expect(find.text('3 คน'), findsOneWidget);
      expect(find.text('2 คน'), findsOneWidget); // opened
      expect(find.text('1 คน'), findsOneWidget); // completed
      expect(find.text('47%'), findsOneWidget); // (40+100+0)/3
      expect(find.text('ยังไม่เปิดบทเรียน'), findsOneWidget);
      expect(find.text('เรียนจบแล้ว'), findsOneWidget);
      // The old fabricated stats never come back.
      expect(find.textContaining('42 คน'), findsNothing);
      expect(find.textContaining('ณัฐวุฒิ ใจดี'), findsNothing);
      expect(find.text('สถิติบทเรียนรายคนยังไม่เปิดใช้งาน'), findsNothing);
    },
  );

  testWidgets(
    'lesson analytics: failure is an error with retry, empty roster is empty',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: TeacherLessonAnalyticsPage(
            lesson: lesson(),
            loadProgress: (_) async {
              calls++;
              if (calls == 1) throw StateError('secret');
              return const [];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('โหลดสถิติไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      expect(find.text('ยังไม่มีนักเรียนในวิชานี้'), findsNothing);

      await tester.tap(find.text('ลองใหม่'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('ยังไม่มีนักเรียนในวิชานี้'), findsOneWidget);
    },
  );
}
