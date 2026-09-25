import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_question_bank_page.dart';
import 'package:shared_core/shared_core.dart';

/// There used to be no RPC to list a quiz's real questions at all, so
/// every set's count badge showed "0 ข้อ" regardless of real content, and
/// this page never popped a selection back to its caller (exam builder)
/// even when questions were ticked. These tests pin down that the real
/// question count renders and that confirming a selection actually
/// returns the real questions through Navigator.pop.

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
  timeLimitMin: null,
  status: 'published',
  lessonId: null,
);

const _questions = [
  QuizQuestionSummary(
    id: 'q1',
    type: 'multiple_choice',
    question: 'น้ำเดือดที่กี่องศา?',
    points: 2,
    choices: [
      QuizQuestionChoice(id: 'c1', text: '100', isCorrect: true),
      QuizQuestionChoice(id: 'c2', text: '50', isCorrect: false),
    ],
  ),
];

Future<List<BankQuestion>?> _pumpAsPushedRoute(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<QuizSummary>> Function(String courseId)? listQuizzesForCourse,
  Future<List<QuizQuestionSummary>> Function(String quizId)?
  listQuizQuestions,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  List<BankQuestion>? poppedResult;
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                poppedResult = await Navigator.push<List<BankQuestion>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherQuestionBankPage(
                      loadCourses: loadCourses ?? () async => const [_course],
                      listQuizzesForCourse:
                          listQuizzesForCourse ?? (_) async => const [_quiz],
                      listQuizQuestions:
                          listQuizQuestions ?? (_) async => _questions,
                    ),
                  ),
                );
              },
              child: const Text('open bank'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open bank'));
  await tester.pumpAndSettle();
  return poppedResult;
}

void main() {
  testWidgets('a quiz with real questions shows the real count, not "0 ข้อ"', (
    tester,
  ) async {
    await _pumpAsPushedRoute(tester);
    expect(find.textContaining('เพิ่มทั้งชุด (1 ข้อ)'), findsNothing);
    // count badge on the list card itself:
    expect(find.textContaining('1 ข้อ'), findsWidgets);
  });

  testWidgets('confirming a real selection returns the actual question text, not an empty list', (
    tester,
  ) async {
    List<BankQuestion>? result;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<List<BankQuestion>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherQuestionBankPage(
                        loadCourses: _loadCourses,
                        listQuizzesForCourse: _listQuizzes,
                        listQuizQuestions: _listQuestions,
                      ),
                    ),
                  );
                },
                child: const Text('open bank'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open bank'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('แบบทดสอบก่อนเรียน บทที่ 1'));
    await tester.pumpAndSettle();
    // 2026-09-23: "เพิ่มทั้งชุด" เดิมเลือกแล้วเด้งกลับทันที ซึ่งเป็นเหตุผลที่
    // เลือกทีละข้อไม่ได้ ตอนนี้มันแค่ติ๊กทุกข้อ แล้วกด "ใช้ n ข้อ" เพื่อยืนยัน
    await tester.tap(find.textContaining('เพิ่มทั้งชุด'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ใช้ 1 ข้อ'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ยืนยันการเลือก'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.length, 1);
    expect(result!.first.questionText, 'น้ำเดือดที่กี่องศา?');
    expect(result!.first.options, ['100', '50']);
    expect(result!.first.correctIndex, 0);
  });
}

Future<List<CourseSummary>> _loadCourses() async => const [_course];
Future<List<QuizSummary>> _listQuizzes(String courseId) async => const [_quiz];
Future<List<QuizQuestionSummary>> _listQuestions(String quizId) async =>
    _questions;
