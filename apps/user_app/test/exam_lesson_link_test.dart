import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_exam_builder_page.dart';
import 'package:shared_core/shared_core.dart';

/// 2026-09-23: `create_quiz` รับ `p_lesson_id` มาตั้งแต่แรก แต่หน้านี้ไม่เคย
/// ส่งไป — ข้อสอบทุกชุดที่ครูสร้างจากแอปจึงไม่ผูกกับบทเรียนใดเลย ยืนยันกับ
/// ฐานข้อมูลจริง: ชุดที่สร้างจากแอปขึ้น "— ยังไม่ผูกบทเรียน —" ส่วนชุดที่
/// seed ไว้ผูกบทที่ 1 ปกติ เทสต์นี้ล็อกไว้ว่าเมื่อครูเลือกบท ค่าต้องไปถึง RPC

const _lessons = [
  LessonSummary(
    id: 'lesson-1',
    title: 'บทที่ 1: รู้จักเซนเซอร์ PM2.5',
    status: 'published',
    publishedAt: null,
    materialsCount: 0,
    sensorLinksCount: 0,
  ),
  LessonSummary(
    id: 'lesson-2',
    title: 'บทที่ 2: เก็บข้อมูลและกราฟ',
    status: 'draft',
    publishedAt: null,
    materialsCount: 0,
    sensorLinksCount: 0,
  ),
];

Future<String?> _saveAndCaptureLessonId(
  WidgetTester tester, {
  required Future<void> Function(WidgetTester tester) beforeSave,
  List<LessonSummary> lessons = _lessons,
}) async {
  tester.view.physicalSize = const Size(1400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  String? captured;
  var called = false;

  await tester.pumpWidget(
    MaterialApp(
      home: TeacherExamBuilderPage(
        courseId: 'course-1',
        listLessons: (_) async => lessons,
        createQuiz:
            ({
              required courseId,
              required type,
              required title,
              lessonId,
              timeLimitMin,
            }) async {
              called = true;
              captured = lessonId;
              return 'quiz-1';
            },
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('เพิ่มข้อสอบใหม่'));
  await tester.pump();
  await tester.tap(find.text('เพิ่มข้อสอบใหม่'));
  await tester.pump();

  await beforeSave(tester);

  await tester.ensureVisible(find.text('บันทึกร่างข้อสอบ'));
  await tester.pump();
  await tester.tap(find.text('บันทึกร่างข้อสอบ'));
  await tester.pumpAndSettle();

  expect(called, isTrue, reason: 'createQuiz ต้องถูกเรียก');
  return captured;
}

void main() {
  testWidgets('เลือกบทเรียนแล้ว lessonId ต้องไปถึง create_quiz', (tester) async {
    final lessonId = await _saveAndCaptureLessonId(
      tester,
      beforeSave: (tester) async {
        await tester.ensureVisible(find.text('ยังไม่ผูกบทเรียน'));
        await tester.pump();
        await tester.tap(find.text('ยังไม่ผูกบทเรียน'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('บทที่ 2: เก็บข้อมูลและกราฟ').last);
        await tester.pumpAndSettle();
      },
    );
    expect(lessonId, 'lesson-2');
  });

  testWidgets('ไม่เลือกบทเรียน ยังบันทึกได้ และส่ง null ไม่ใช่ค่ามั่ว', (
    tester,
  ) async {
    final lessonId = await _saveAndCaptureLessonId(
      tester,
      beforeSave: (_) async {},
    );
    expect(lessonId, isNull);
  });

  testWidgets('วิชาที่ยังไม่มีบทเรียน ต้องสร้างข้อสอบได้ตามปกติ', (tester) async {
    final lessonId = await _saveAndCaptureLessonId(
      tester,
      lessons: const [],
      beforeSave: (_) async {},
    );
    expect(lessonId, isNull);
    expect(find.text('ยังไม่ผูกบทเรียน'), findsOneWidget);
  });
}
