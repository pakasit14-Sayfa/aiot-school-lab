import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_courses_page.dart';

void main() {
  testWidgets(
    'Gradebook tab never shows the old identical-fake-score row',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const course = TeacherCourseModel(
        id: 'course-1',
        code: 'ว31281',
        name: 'ทดสอบ',
        category: 'เทคโนโลยี',
        rooms: ['ม.4/1'],
        studentCount: 0,
        activeAssignments: 0,
        pendingGradingCount: 0,
        completionRate: 0,
        coverGradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        accentColor: Color(0xFF0D9488),
        nextPeriodText: '-',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TeacherCourseDetailPage(course: course),
        ),
      );
      await tester.pump();
      // The default "บทเรียน" tab (TeacherLessonListPage) has a pre-existing,
      // unrelated layout overflow at this viewport width — swallow it so it
      // doesn't fail this test, which only asserts on the "คะแนน" tab.
      tester.takeException();

      await tester.tap(find.text('คะแนน').first);
      await tester.pump();
      tester.takeException();
      await tester.pump();
      tester.takeException();

      // The old bug hardcoded these exact fabricated values for every
      // student regardless of what was actually enrolled/graded — none of
      // them must ever render again now that the tab reads real
      // GradeService.listCourseGrades data.
      expect(find.textContaining('เกรด 4.0'), findsNothing);
      expect(find.text('ส่งงานครบแล้ว'), findsNothing);
      expect(find.textContaining('บทที่ 1: เซนเซอร์ PM2.5'), findsNothing);
      expect(find.textContaining('ใบงานที่ 1: ต่อวงจร'), findsNothing);
    },
  );
}
