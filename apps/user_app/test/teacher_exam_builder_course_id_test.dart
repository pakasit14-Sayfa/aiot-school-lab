import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_exam_builder_page.dart';

/// หน้านี้เริ่มจาก "ไม่มีโจทย์" เสมอ (เดิม seed ข้อสอบปลอมไว้ 3 ข้อ) — เทสต์ที่
/// ต้องการทดสอบ "เส้นทางบันทึก" ต้องกดเพิ่มโจทย์เองก่อน ไม่งั้นจะติด guard
/// "ยังไม่มีโจทย์ในชุดข้อสอบ"
Future<void> _addOneQuestion(WidgetTester tester) async {
  await tester.ensureVisible(find.text('เพิ่มข้อสอบใหม่'));
  await tester.pump();
  await tester.tap(find.text('เพิ่มข้อสอบใหม่'));
  await tester.pump();
}

void main() {
  testWidgets(
    'saving with a real courseId never falls back to "the first course of any list"',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var listMyCoursesCalled = false;
      String? capturedCourseId;

      await tester.pumpWidget(
        MaterialApp(
          home: TeacherExamBuilderPage(
            courseId: 'the-real-course-id',
            listMyCourses: () async {
              listMyCoursesCalled = true;
              return [];
            },
            createQuiz:
                ({
                  required courseId,
                  required type,
                  required title,
                  lessonId,
                  timeLimitMin,
                }) async {
                  capturedCourseId = courseId;
                  return 'quiz-1';
                },
          ),
        ),
      );
      await tester.pump();

      await _addOneQuestion(tester);

      await tester.ensureVisible(find.text('บันทึกร่างข้อสอบ'));
      await tester.pump();
      await tester.tap(find.text('บันทึกร่างข้อสอบ'));
      await tester.pump();

      // The old bug ignored widget.courseId entirely and always saved to
      // CourseService.listMyCourses().first — whichever course happened to
      // come first in the teacher's list, not the one the exam builder was
      // actually opened from. With a real courseId supplied, the course
      // list must never be consulted at all, and the real courseId must
      // reach QuizService.createQuiz unchanged.
      expect(listMyCoursesCalled, isFalse);
      expect(capturedCourseId, 'the-real-course-id');
    },
  );

  testWidgets(
    'saving with no courseId (dev-preview only) falls back to listMyCourses',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var listMyCoursesCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TeacherExamBuilderPage(
            listMyCourses: () async {
              listMyCoursesCalled = true;
              return [];
            },
          ),
        ),
      );
      await tester.pump();

      await _addOneQuestion(tester);

      await tester.ensureVisible(find.text('บันทึกร่างข้อสอบ'));
      await tester.pump();
      await tester.tap(find.text('บันทึกร่างข้อสอบ'));
      await tester.pump();

      expect(listMyCoursesCalled, isTrue);
      expect(
        find.text('ไม่พบรายวิชาของคุณในระบบ กรุณาสร้างรายวิชาก่อนออกข้อสอบ'),
        findsOneWidget,
      );
    },
  );
}
