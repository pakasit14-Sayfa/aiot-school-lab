import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_lesson_editor_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets('TeacherLessonEditorPage displays editor correctly with blocks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testLesson = LessonModel(
      id: '', // local draft to bypass get_lesson call in widget test
      courseCode: 'CS101',
      courseName: 'IoT Basics',
      title: 'บทที่ 1: เซนเซอร์ PM2.5',
      status: LessonStatus.draft,
      lastEdited: 'เมื่อสักครู่',
      materialsCount: 2,
      sensorChartsCount: 1,
      blocks: [
        ContentBlockModel(
          id: 'b-head',
          type: ContentBlockType.heading,
          text: 'บทที่ 1: เซนเซอร์ PM2.5',
        ),
        ContentBlockModel(
          id: 'b-body',
          type: ContentBlockType.text,
          text: 'เซนเซอร์ PM2.5 วัดค่าฝุ่นละอองขนาดเล็กในอากาศ',
        ),
      ],
      materials: [
        LessonMaterialModel(
          id: 'm1',
          title: 'คู่มือการใช้งาน',
          type: 'link',
          url: 'https://example.com/manual.pdf',
        ),
      ],
      sensorLinks: [],
    );

    await tester.pumpWidget(
      MaterialApp(home: TeacherLessonEditorPage(lesson: testLesson)),
    );
    await tester.pumpAndSettle();

    expect(find.text('บทที่ 1: เซนเซอร์ PM2.5'), findsAtLeastNWidgets(1));
    expect(
      find.text('เซนเซอร์ PM2.5 วัดค่าฝุ่นละอองขนาดเล็กในอากาศ'),
      findsOneWidget,
    );
    expect(find.text('คลังสื่อแนบ (1)'), findsOneWidget);
  });
}
