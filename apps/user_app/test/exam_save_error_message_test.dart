import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_exam_builder_page.dart';

/// 2026-09-23: กดบันทึกข้อสอบแล้วไม่สำเร็จ หน้าจอขึ้นแค่ "บันทึกข้อสอบไม่สำเร็จ"
/// ทุกกรณี สาเหตุจริงถูกทิ้งลง debugPrint ซึ่งบนเครื่องจริงไม่มีใครเห็น —
/// เจ้าของงานเจออาการนี้บนมือถือแล้วไล่สาเหตุไม่ได้เลย เทสต์นี้ล็อกไว้ว่า
/// สาเหตุต้องไปถึงตาครูเสมอ ทั้งกรณีที่รู้จักและไม่รู้จัก
void main() {
  group('แปล error ตอนบันทึกข้อสอบ', () {
    test('สิทธิ์ไม่พอ บอกว่าต้องเป็นครูผู้สอนวิชานี้', () {
      final msg = examSaveErrorMessage(
        Exception('PostgrestException(message: forbidden, code: P0001)'),
      );
      expect(msg, contains('ไม่มีสิทธิ์'));
      expect(msg, contains('ครูผู้สอน'));
    });

    test('เซสชันหมดอายุ บอกให้เข้าสู่ระบบใหม่', () {
      expect(
        examSaveErrorMessage(Exception('invalid_session')),
        contains('เข้าสู่ระบบใหม่'),
      );
      expect(
        examSaveErrorMessage(Exception('not_signed_in')),
        contains('เข้าสู่ระบบใหม่'),
      );
    });

    test('ด่านใหม่ฝั่ง RPC แปลได้ครบ', () {
      expect(
        examSaveErrorMessage(Exception('choices_required')),
        contains('ตัวเลือก'),
      );
      expect(
        examSaveErrorMessage(Exception('short_answer_takes_no_choices')),
        contains('อัตนัย'),
      );
      expect(
        examSaveErrorMessage(Exception('exactly_one_correct_choice_required')),
        contains('เฉลย'),
      );
    });

    test('เน็ตหลุด แยกจากข้อมูลผิด', () {
      expect(
        examSaveErrorMessage(Exception('SocketException: Failed host lookup')),
        contains('อินเทอร์เน็ต'),
      );
    });

    test('error ที่ไม่รู้จัก ต้องโชว์ของจริง ไม่กลืนทิ้ง', () {
      final msg = examSaveErrorMessage(Exception('something_nobody_mapped_yet'));
      expect(msg, contains('something_nobody_mapped_yet'));
    });

    test('error ยาวมากถูกตัด ไม่ล้นจอ', () {
      final msg = examSaveErrorMessage(Exception('x' * 500));
      expect(msg.length, lessThan(220));
      expect(msg, contains('…'));
    });
  });

  testWidgets('บันทึกไม่ผ่านเพราะสิทธิ์ ต้องเห็นสาเหตุจริงบนหน้าจอ ไม่ใช่ข้อความรวม', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherExamBuilderPage(
          courseId: 'course-1',
          createQuiz:
              ({
                required courseId,
                required type,
                required title,
                lessonId,
                timeLimitMin,
              }) async {
                throw Exception(
                  'PostgrestException(message: forbidden, code: P0001)',
                );
              },
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('เพิ่มข้อสอบใหม่'));
    await tester.pump();
    await tester.tap(find.text('เพิ่มข้อสอบใหม่'));
    await tester.pump();

    await tester.ensureVisible(find.text('บันทึกร่างข้อสอบ'));
    await tester.pump();
    await tester.tap(find.text('บันทึกร่างข้อสอบ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('บันทึกข้อสอบไม่สำเร็จ'), findsNothing);
    expect(find.textContaining('ไม่มีสิทธิ์'), findsOneWidget);
  });
}
