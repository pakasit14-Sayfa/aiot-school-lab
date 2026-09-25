import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_question_bank_page.dart';
import 'package:shared_core/shared_core.dart';

/// 2026-09-23: คลังข้อสอบเลือกได้แค่ "ทั้งชุด" — ครูที่อยากได้ 2 ข้อจากชุด 8 ข้อ
/// ต้องดึงมาทั้ง 8 แล้วไปลบทิ้ง 6 ข้อใน Exam Builder เอง สาเหตุคือ BankQuestion
/// ไม่มี id เลย (โค้ดทิ้ง question_id จาก RPC) จึงอ้างถึงรายข้อไม่ได้
/// เทสต์นี้ล็อกไว้ว่าเลือกเฉพาะบางข้อแล้วต้องได้เฉพาะข้อนั้นจริง ๆ

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

const _threeQuestions = [
  QuizQuestionSummary(
    id: 'q1',
    type: 'multiple_choice',
    question: 'ข้อหนึ่ง น้ำเดือดที่กี่องศา',
    points: 1,
    choices: [
      QuizQuestionChoice(id: 'c1', text: '100', isCorrect: true),
      QuizQuestionChoice(id: 'c2', text: '50', isCorrect: false),
    ],
  ),
  QuizQuestionSummary(
    id: 'q2',
    type: 'true_false',
    question: 'ข้อสอง น้ำแข็งลอยน้ำได้',
    points: 1,
    choices: [
      QuizQuestionChoice(id: 'c3', text: 'จริง', isCorrect: true),
      QuizQuestionChoice(id: 'c4', text: 'เท็จ', isCorrect: false),
    ],
  ),
  QuizQuestionSummary(
    id: 'q3',
    type: 'short_answer',
    question: 'ข้อสาม อธิบายการระเหย',
    points: 3,
    choices: [],
  ),
];

Future<List<BankQuestion>?> _openBank(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  List<BankQuestion>? result;
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
                    builder: (_) => TeacherQuestionBankPage(
                      loadCourses: () async => const [_course],
                      listQuizzesForCourse: (_) async => const [_quiz],
                      listQuizQuestions: (_) async => _threeQuestions,
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
  return result;
}

void main() {
  testWidgets('ติ๊ก 2 ข้อจาก 3 ต้องได้กลับ 2 ข้อที่เลือก ไม่ใช่ทั้งชุด', (
    tester,
  ) async {
    List<BankQuestion>? result;
    tester.view.physicalSize = const Size(1200, 2400);
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
                      builder: (_) => TeacherQuestionBankPage(
                        loadCourses: () async => const [_course],
                        listQuizzesForCourse: (_) async => const [_quiz],
                        listQuizQuestions: (_) async => _threeQuestions,
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

    // ติ๊กเฉพาะข้อ 1 กับ 3 — ข้าม 2
    await tester.tap(find.textContaining('ข้อหนึ่ง'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ข้อสาม'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ใช้ 2 ข้อ'), findsOneWidget);
    await tester.tap(find.textContaining('ใช้ 2 ข้อ'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('ยืนยันการเลือก'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.length, 2);
    expect(
      result!.map((q) => q.questionText).toList(),
      ['ข้อหนึ่ง น้ำเดือดที่กี่องศา', 'ข้อสาม อธิบายการระเหย'],
    );
    // ข้อที่ไม่ได้ติ๊กต้องไม่หลุดมา
    expect(
      result!.any((q) => q.questionText.contains('ข้อสอง')),
      isFalse,
    );
  });

  testWidgets('ชนิดคำถามยังติดมากับข้อที่เลือกถูกต้อง', (tester) async {
    await _openBank(tester);
    await tester.tap(find.text('แบบทดสอบก่อนเรียน บทที่ 1'));
    await tester.pumpAndSettle();
    // ข้อ 3 เป็นอัตนัย — ต้องไม่กลายเป็นปรนัย
    await tester.tap(find.textContaining('ข้อสาม'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ใช้ 1 ข้อ'), findsOneWidget);
  });
}
