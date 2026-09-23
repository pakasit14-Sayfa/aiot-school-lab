import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_question_bank_page.dart';
import 'package:shared_core/shared_core.dart';

/// 2026-09-23: the bank decided a question's type with
/// `question.type == 'essay'`, but the `question_type` enum in the database
/// only has `multiple_choice` / `true_false` / `short_answer` — there is no
/// `'essay'`. The comparison was therefore false for every row, so every
/// question loaded from the backend became ปรนัย: อัตนัย questions were
/// imported into the exam builder as multiple choice with no choices and an
/// answer key pointing at a choice that does not exist, and nothing in the
/// app or the RPC objected. These tests fail if any of that comes back.

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

const _allThreeTypes = [
  QuizQuestionSummary(
    id: 'q1',
    type: 'multiple_choice',
    question: 'เซนเซอร์ DHT22 ใช้วัดค่าอะไรได้บ้าง',
    points: 2,
    choices: [
      QuizQuestionChoice(id: 'c1', text: 'อุณหภูมิและความชื้น', isCorrect: true),
      QuizQuestionChoice(id: 'c2', text: 'ความเข้มแสงเท่านั้น', isCorrect: false),
    ],
  ),
  QuizQuestionSummary(
    id: 'q2',
    type: 'true_false',
    question: 'ค่าที่อ่านได้จากเซนเซอร์ควรสอบเทียบก่อนใช้อ้างอิง',
    points: 1,
    choices: [
      QuizQuestionChoice(id: 'c3', text: 'จริง', isCorrect: true),
      QuizQuestionChoice(id: 'c4', text: 'เท็จ', isCorrect: false),
    ],
  ),
  QuizQuestionSummary(
    id: 'q3',
    type: 'short_answer',
    question: 'อธิบายสั้น ๆ ว่าเหตุใดจึงต้องวัดค่าซ้ำหลายครั้ง',
    points: 3,
    choices: [],
  ),
];

void main() {
  group('การแปลงชนิดคำถามจากฐานข้อมูล', () {
    test('ทั้งสามค่าของ enum question_type แปลงได้ตรงตัว', () {
      expect(bankTypeFromDb('multiple_choice'), BankQuestionType.multipleChoice);
      expect(bankTypeFromDb('true_false'), BankQuestionType.trueFalse);
      expect(bankTypeFromDb('short_answer'), BankQuestionType.shortAnswer);
    });

    test('อัตนัยไม่ถูกจัดเป็นปรนัย', () {
      // ตัวบั๊กเดิมทั้งหมดอยู่ตรงนี้
      expect(
        bankTypeFromDb('short_answer'),
        isNot(BankQuestionType.multipleChoice),
      );
      expect(bankTypeFromDb('true_false'), isNot(BankQuestionType.multipleChoice));
    });

    test('มีเพียงอัตนัยที่ไม่มีตัวเลือก', () {
      expect(bankTypeHasChoices(BankQuestionType.multipleChoice), isTrue);
      expect(bankTypeHasChoices(BankQuestionType.trueFalse), isTrue);
      expect(bankTypeHasChoices(BankQuestionType.shortAnswer), isFalse);
    });

    test('ป้ายชนิดแยกได้ครบสามแบบ ไม่ใช่สองแบบ', () {
      final labels = BankQuestionType.values.map(bankTypeLabel).toSet();
      expect(labels.length, 3);
      expect(bankTypeLabel(BankQuestionType.shortAnswer), 'อัตนัย');
      expect(bankTypeLabel(BankQuestionType.trueFalse), 'ถูก / ผิด');
    });
  });

  testWidgets('คำถามอัตนัยจากหลังบ้านถูกส่งกลับเป็นอัตนัย ไม่ใช่ปรนัยที่ไม่มีตัวเลือก', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    List<BankQuestion>? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await Navigator.push<List<BankQuestion>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherQuestionBankPage(
                        loadCourses: () async => const [_course],
                        listQuizzesForCourse: (_) async => const [_quiz],
                        listQuizQuestions: (_) async => _allThreeTypes,
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

    // เปิดชุดแล้วเพิ่มทั้งชุดเข้าไป เพื่อดูว่าชนิดที่ส่งกลับตรงกับของจริง
    await tester.tap(find.textContaining('แบบทดสอบก่อนเรียน บทที่ 1').first);
    await tester.pumpAndSettle();
    final addAll = find.textContaining('เพิ่มทั้งชุด');
    if (addAll.evaluate().isNotEmpty) {
      await tester.tap(addAll.first);
      await tester.pumpAndSettle();
    }

    if (popped != null) {
      final byText = {for (final q in popped!) q.questionText: q};
      final essay = byText.entries
          .firstWhere((e) => e.key.startsWith('อธิบายสั้น ๆ'))
          .value;
      expect(essay.type, BankQuestionType.shortAnswer);
      expect(essay.options, isEmpty);
      // ไม่มีตัวเลือก = ไม่มีเฉลย ห้ามเป็น 0
      expect(essay.correctIndex, isNull);

      final tf = byText.entries
          .firstWhere((e) => e.key.startsWith('ค่าที่อ่านได้'))
          .value;
      expect(tf.type, BankQuestionType.trueFalse);
      expect(tf.correctIndex, 0);
    }
  });
}
