import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_exam_builder_page.dart';

void main() {
  testWidgets(
    'saving with a real courseId never falls back to "the first course of any list"',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var listMyCoursesCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TeacherExamBuilderPage(
            courseId: 'the-real-course-id',
            listMyCourses: () async {
              listMyCoursesCalled = true;
              return [];
            },
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('บันทึกร่างข้อสอบ'));
      await tester.pump();
      await tester.tap(find.text('บันทึกร่างข้อสอบ'));
      await tester.pump();

      // The old bug ignored widget.courseId entirely and always saved to
      // CourseService.listMyCourses().first — whichever course happened to
      // come first in the teacher's list, not the one the exam builder was
      // actually opened from. With a real courseId supplied, the course
      // list must never be consulted at all.
      expect(listMyCoursesCalled, isFalse);
      // QuizService.createQuiz throws "not_signed_in" before ever reaching
      // the network in this session-less test harness — confirming save
      // proceeded straight to using the real courseId instead of the
      // "no courses found" branch that only fires on the listMyCourses path.
      expect(find.textContaining('not_signed_in'), findsOneWidget);
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
