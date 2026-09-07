import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_lesson_editor_page.dart';

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

  testWidgets(
    'lesson analytics is an honest "not available" page, not fabricated stats',
    (tester) async {
      final lesson = LessonModel(
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

      await tester.pumpWidget(
        MaterialApp(
          home: TeacherLessonAnalyticsPage(lesson: lesson),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // The old bug showed hardcoded stats ("42 คน", "84%" average
      // progress) and a fake 5-student progress table after a fake
      // Future.delayed "loading" — none of that backend-less data may
      // render again.
      expect(find.textContaining('42 คน'), findsNothing);
      expect(find.textContaining('ณัฐวุฒิ ใจดี'), findsNothing);
      expect(find.text('สถิติบทเรียนรายคนยังไม่เปิดใช้งาน'), findsOneWidget);
    },
  );
}
