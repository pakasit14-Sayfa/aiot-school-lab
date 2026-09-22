import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_pretest_posttest_page.dart';
import 'package:shared_core/shared_core.dart';

/// The pretest/posttest quiz attempt flow (start → save each answer →
/// submit) writes real state a student's grade depends on. These tests
/// pin down that the full sequence really calls through to the injected
/// service seams with the right arguments, not just updates local state
/// and pretends to have submitted.

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'วิทยาศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

const _quiz = QuizSummary(
  id: 'quiz-1',
  type: 'pre_test',
  title: 'แบบทดสอบก่อนเรียน บทที่ 1',
  timeLimitMin: 20,
  status: 'published',
  lessonId: null,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<QuizSummary>> Function(String courseId)? loadQuizzesForCourse,
  Future<QuizAttemptResult?> Function(String quizId)? loadLatestAttempt,
  Future<QuizForStudent> Function(String quizId)? getQuizForStudent,
  Future<({String attemptId, DateTime startedAt})> Function(String quizId)?
  startQuizAttempt,
  Future<void> Function({
    required String attemptId,
    required String questionId,
    required Map<String, dynamic> answer,
  })?
  saveQuizAnswer,
  Future<num> Function(String attemptId)? submitQuizAttempt,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentPretestPosttestPage(
        loadCourses: loadCourses ?? () async => const [_course],
        loadQuizzesForCourse:
            loadQuizzesForCourse ?? (_) async => const [_quiz],
        loadLatestAttempt: loadLatestAttempt ?? (_) async => null,
        getQuizForStudent: getQuizForStudent,
        startQuizAttempt: startQuizAttempt,
        saveQuizAnswer: saveQuizAnswer,
        submitQuizAttempt: submitQuizAttempt,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a published quiz with no attempt yet shows "เริ่มทำ", not a score',
    (tester) async {
      await _pump(tester);
      expect(find.text('เริ่มทำ'), findsOneWidget);
      expect(find.textContaining('คะแนน'), findsNothing);
    },
  );

  testWidgets(
    'an already-submitted quiz shows the real score, not a start button',
    (tester) async {
      await _pump(
        tester,
        loadLatestAttempt: (_) async => QuizAttemptResult(
          attemptId: 'attempt-1',
          startedAt: DateTime(2026, 9, 1, 9),
          submittedAt: DateTime(2026, 9, 1, 9, 15),
          autoScore: 8,
        ),
      );
      expect(find.textContaining('8 คะแนน'), findsOneWidget);
      expect(find.text('เริ่มทำ'), findsNothing);
    },
  );

  testWidgets(
    'an empty course list shows an honest empty state, no fake quiz',
    (tester) async {
      await _pump(tester, loadCourses: () async => const []);
      expect(
        find.text('ยังไม่มีแบบทดสอบก่อน-หลังเรียนที่เปิดให้ทำ'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'taking the quiz calls start → save each answer → submit in order, with real answer content',
    (tester) async {
      var startCalls = 0;
      final savedAnswers = <Map<String, dynamic>>[];
      var submitCalls = 0;

      await _pump(
        tester,
        getQuizForStudent: (quizId) async {
          expect(quizId, 'quiz-1');
          return QuizForStudent(
            quizId: 'quiz-1',
            title: 'แบบทดสอบก่อนเรียน บทที่ 1',
            type: 'pre_test',
            timeLimitMin: 20,
            questions: const [
              QuizQuestion(
                id: 'q1',
                type: 'multiple_choice',
                question: 'น้ำเดือดที่กี่องศา?',
                points: 1,
                sortOrder: 0,
                choices: [
                  QuizChoice(id: 'c1', text: '100'),
                  QuizChoice(id: 'c2', text: '50'),
                ],
              ),
            ],
          );
        },
        startQuizAttempt: (quizId) async {
          startCalls++;
          expect(quizId, 'quiz-1');
          return (attemptId: 'attempt-99', startedAt: DateTime(2026, 9, 8));
        },
        saveQuizAnswer:
            ({required attemptId, required questionId, required answer}) async {
              expect(attemptId, 'attempt-99');
              savedAnswers.add({'questionId': questionId, ...answer});
            },
        submitQuizAttempt: (attemptId) async {
          submitCalls++;
          expect(attemptId, 'attempt-99');
          return 10;
        },
      );

      await tester.tap(find.text('เริ่มทำ'));
      await tester.pumpAndSettle();

      expect(
        startCalls,
        1,
        reason: 'opening the quiz must start a real attempt',
      );
      expect(find.textContaining('น้ำเดือดที่กี่องศา?'), findsOneWidget);

      await tester.tap(find.text('100'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ส่งคำตอบ'));
      await tester.pumpAndSettle();

      expect(
        savedAnswers.length,
        1,
        reason: 'the selected choice must be saved',
      );
      expect(savedAnswers.first['questionId'], 'q1');
      expect(savedAnswers.first['choice_id'], 'c1');
      expect(submitCalls, 1, reason: 'submit must be called exactly once');
    },
  );

  testWidgets('a failed submit shows an error, not a fake success score', (
    tester,
  ) async {
    await _pump(
      tester,
      getQuizForStudent: (_) async => const QuizForStudent(
        quizId: 'quiz-1',
        title: 'แบบทดสอบก่อนเรียน บทที่ 1',
        type: 'pre_test',
        timeLimitMin: null,
        questions: [
          QuizQuestion(
            id: 'q1',
            type: 'multiple_choice',
            question: 'น้ำเดือดที่กี่องศา?',
            points: 1,
            sortOrder: 0,
            choices: [QuizChoice(id: 'c1', text: '100')],
          ),
        ],
      ),
      startQuizAttempt: (_) async =>
          (attemptId: 'attempt-99', startedAt: DateTime(2026, 9, 8)),
      saveQuizAnswer:
          ({required attemptId, required questionId, required answer}) async {},
      submitQuizAttempt: (_) async =>
          throw StateError('backend detail that must stay internal'),
    );

    await tester.tap(find.text('เริ่มทำ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('100'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งคำตอบ'));
    await tester.pumpAndSettle();

    expect(find.text('ส่งไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
    // Must still be on the quiz-taking page, not popped as if it succeeded.
    expect(find.text('ส่งคำตอบ'), findsOneWidget);
  });
}
