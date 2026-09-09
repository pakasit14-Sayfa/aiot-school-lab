import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_exam_builder_page.dart';

/// หน้าออกข้อสอบเคย seed โจทย์ AIoT ปลอมไว้ 3 ข้อ (PM2.5 / I2C / %RH) พร้อม
/// ชื่อชุดข้อสอบที่แต่งขึ้น ทุกครั้งที่เปิดหน้า — ครูที่กด "บันทึกร่างข้อสอบ"
/// โดยไม่ทันสังเกตจะได้ข้อสอบที่ตัวเองไม่ได้เขียน ถูกเขียนลงฐานข้อมูลจริงผ่าน
/// QuizService.addQuizQuestion เทสต์ชุดนี้ล็อกไว้ว่าหน้าเริ่มจากว่างเสมอ
void main() {
  Future<void> pumpBuilder(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TeacherExamBuilderPage(courseId: 'the-real-course-id'),
      ),
    );
    await tester.pump();
  }

  testWidgets('เปิดหน้ามาต้องไม่มีโจทย์ที่ครูไม่ได้เขียนอยู่ในชุดข้อสอบ', (
    tester,
  ) async {
    await pumpBuilder(tester);

    // โจทย์ปลอมทั้ง 3 ข้อของเดิม
    expect(find.textContaining('PM2.5'), findsNothing);
    expect(find.textContaining('SDA, SCL'), findsNothing);
    expect(find.textContaining('ความชื้นสัมพัทธ์'), findsNothing);

    expect(find.text('0 ข้อ'), findsOneWidget);
    expect(find.text('ยังไม่มีโจทย์ในชุดข้อสอบนี้'), findsOneWidget);
  });

  testWidgets('ชื่อชุดข้อสอบต้องไม่ถูกเติมหัวข้อที่แต่งขึ้นให้อัตโนมัติ', (
    tester,
  ) async {
    await pumpBuilder(tester);

    // ของเดิมเติม 'ข้อสอบก่อนเรียน: เรื่องการใช้งานเซนเซอร์วัดฝุ่นและการ
    // สื่อสารข้อมูล' ให้เอง แล้วบันทึกเป็นชื่อข้อสอบจริงถ้าครูไม่ได้แก้
    expect(find.textContaining('เซนเซอร์วัดฝุ่น'), findsNothing);

    final titleField = tester.widget<TextField>(
      find
          .byWidgetPredicate(
            (w) => w is TextField && w.controller?.text.contains('ข้อสอบ') == true,
          )
          .first,
    );
    expect(titleField.controller!.text, 'ข้อสอบก่อนเรียน: ');
  });

  testWidgets('บันทึกตอนยังไม่มีโจทย์ต้องถูกบล็อก ไม่ใช่บันทึกชุดเปล่าเงียบ ๆ', (
    tester,
  ) async {
    var listMyCoursesCalled = false;
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherExamBuilderPage(
          courseId: 'the-real-course-id',
          listMyCourses: () async {
            listMyCoursesCalled = true;
            return [];
          },
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('บันทึกร่างข้อสอบ'));
    await tester.pump();
    await tester.tap(find.text('บันทึกร่างข้อสอบ'));
    await tester.pump();

    expect(
      find.text('ยังไม่มีโจทย์ในชุดข้อสอบ กรุณาเพิ่มอย่างน้อย 1 ข้อ'),
      findsOneWidget,
    );
    // ต้องไม่มีการยิงอะไรไปหลังบ้านเลย
    expect(listMyCoursesCalled, isFalse);
    expect(find.textContaining('not_signed_in'), findsNothing);
  });

  testWidgets('กดเพิ่มโจทย์แล้ว empty state ต้องหายไปและนับจำนวนถูก', (
    tester,
  ) async {
    await pumpBuilder(tester);

    await tester.ensureVisible(find.text('เพิ่มข้อสอบใหม่'));
    await tester.pump();
    await tester.tap(find.text('เพิ่มข้อสอบใหม่'));
    await tester.pump();

    expect(find.text('ยังไม่มีโจทย์ในชุดข้อสอบนี้'), findsNothing);
    expect(find.text('1 ข้อ'), findsOneWidget);
  });
}
