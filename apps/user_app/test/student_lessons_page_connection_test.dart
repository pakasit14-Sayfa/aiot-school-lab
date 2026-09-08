import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_lessons_page.dart';
import 'package:shared_core/shared_core.dart';

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

const _publishedLesson = LessonSummary(
  id: 'lesson-1',
  title: 'บทที่ 1: จำนวนเต็ม',
  status: 'published',
  publishedAt: null,
);

const _draftLesson = LessonSummary(
  id: 'lesson-2',
  title: 'บทที่ 2: ยังไม่เผยแพร่',
  status: 'draft',
  publishedAt: null,
);

void main() {
  testWidgets('a real published lesson shows the real title/subject, unpublished drafts are hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentLessonsPage(
          loadCourses: () async => const [_course],
          listLessons: (_) async => const [_publishedLesson, _draftLesson],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('บทที่ 1: จำนวนเต็ม'), findsOneWidget);
    expect(find.text('คณิตศาสตร์'), findsOneWidget);
    expect(find.text('บทที่ 2: ยังไม่เผยแพร่'), findsNothing);
    expect(find.text('1 บทเรียนที่เปิดสอน'), findsOneWidget);
  });

  testWidgets('zero real lessons shows an honest empty state, not fabricated content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentLessonsPage(
          loadCourses: () async => const [_course],
          listLessons: (_) async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีบทเรียนที่เปิดสอน'), findsOneWidget);
  });

  testWidgets('a real load failure shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentLessonsPage(
          loadCourses: () async =>
              throw StateError('backend detail that must stay internal'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('a single-course view (courseId given) uses listLessons for that course only', (
    tester,
  ) async {
    String? requestedCourseId;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentLessonsPage(
          courseId: 'course-1',
          courseName: 'คณิตศาสตร์',
          listLessons: (courseId) async {
            requestedCourseId = courseId;
            return const [_publishedLesson];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedCourseId, 'course-1');
    expect(find.text('บทที่ 1: จำนวนเต็ม'), findsOneWidget);
  });
}
