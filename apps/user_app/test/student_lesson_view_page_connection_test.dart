import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_lesson_view_page.dart';
import 'package:shared_core/shared_core.dart';

/// Opening a lesson auto-updates real progress, and "mark complete" writes
/// a real completion record a student's grade/progress tracking depends
/// on. These tests pin down both reach the real RPCs with the right ids.

LessonDetail _lesson({bool completed = false, num? progressPct}) =>
    LessonDetail(
      id: 'lesson-1',
      courseId: 'course-1',
      title: 'บทที่ 1: เซนเซอร์ PM2.5',
      content: const {'body': 'เนื้อหาบทเรียนจริง'},
      status: 'published',
      publishedAt: DateTime(2026, 9, 1),
      materials: const [],
      sensorLinks: const [],
      progressPct: progressPct,
      completed: completed,
    );

const _course = CourseDetail(
  id: 'course-1',
  subjectName: 'วิทยาศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  description: null,
  status: 'active',
  termId: 'term-1',
  teacherNames: 'ครูสมศรี',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<LessonDetail> Function(String lessonId)? getLesson,
  Future<CourseDetail> Function(String courseId)? getCourse,
  Future<void> Function({required String lessonId, required num progressPct})?
  updateProgress,
  Future<void> Function(String lessonId)? markComplete,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentLessonViewPage(
        lessonId: 'lesson-1',
        getLesson: getLesson ?? (_) async => _lesson(),
        getCourse: getCourse ?? (_) async => _course,
        updateProgress: updateProgress,
        markComplete: markComplete,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  /// เดิมเปิดบทเรียนแล้วเขียนความคืบหน้ากลับเป็นค่าเดิม (no-op) หรือ **50%**
  /// ถ้ายังไม่มีค่า — นักเรียนที่แค่กดเปิดดูได้ครึ่งบททันที กติกาตอนนี้ตรงกับ
  /// pages/student/lesson_view_page.dart: เปิด = เริ่มเรียน = ขั้นต่ำ 10%
  testWidgets('opening a never-started lesson records 10%, not a fabricated 50%', (
    tester,
  ) async {
    String? updatedLessonId;
    num? updatedPct;
    await _pump(
      tester,
      getLesson: (_) async => _lesson(progressPct: null),
      updateProgress: ({required lessonId, required progressPct}) async {
        updatedLessonId = lessonId;
        updatedPct = progressPct;
      },
    );

    expect(updatedLessonId, 'lesson-1');
    expect(updatedPct, 10);
  });

  testWidgets('opening a lesson already past 10% does not rewrite its progress', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      getLesson: (_) async => _lesson(progressPct: 40),
      updateProgress: ({required lessonId, required progressPct}) async {
        calls++;
      },
    );

    expect(calls, 0, reason: 'nothing to record — progress is already 40%');
  });

  testWidgets('marking complete calls the real RPC and flips the UI to the completed state', (
    tester,
  ) async {
    String? completedLessonId;
    await _pump(
      tester,
      markComplete: (lessonId) async {
        completedLessonId = lessonId;
      },
    );

    expect(find.text('เรียนจบบทเรียนนี้แล้ว'), findsNothing);
    await tester.tap(find.text('ทำเครื่องหมายว่าเรียนจบแล้ว'));
    await tester.pumpAndSettle();

    expect(completedLessonId, 'lesson-1');
    expect(find.text('เรียนจบบทเรียนนี้แล้ว'), findsOneWidget);
    expect(find.text('ทำเครื่องหมายว่าเรียนจบแล้ว'), findsNothing);
  });

  testWidgets('a lesson already marked complete shows the completed state, not the mark-complete button', (
    tester,
  ) async {
    await _pump(tester, getLesson: (_) async => _lesson(completed: true));
    expect(find.text('เรียนจบบทเรียนนี้แล้ว'), findsOneWidget);
    expect(find.text('ทำเครื่องหมายว่าเรียนจบแล้ว'), findsNothing);
  });

  testWidgets('a failed mark-complete shows an honest message, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      markComplete: (_) async =>
          throw StateError('backend detail that must stay internal'),
    );

    await tester.tap(find.text('ทำเครื่องหมายว่าเรียนจบแล้ว'));
    await tester.pumpAndSettle();

    expect(find.text('เกิดข้อผิดพลาด กรุณาลองใหม่'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
    // Must not have flipped to completed on a failure.
    expect(find.text('เรียนจบบทเรียนนี้แล้ว'), findsNothing);
  });

  testWidgets('a failed lesson load shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      getLesson: (_) async =>
          throw StateError('backend detail that must stay internal'),
    );

    expect(find.text('ไม่สามารถโหลดข้อมูลบทเรียนได้'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });
}
