import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_editor_page.dart';
import 'package:shared_core/shared_core.dart';

const course = CourseSummary(
  id: 'c1',
  subjectName: 'วิทยาศาสตร์',
  gradeLevel: 'ม.1',
  room: '1',
  status: 'active',
  termId: 't1',
);

Future<void> openEditor(
  WidgetTester tester, {
  required Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool isGroup,
  })
  create,
  required Future<List<AssignmentSummary>> Function(String) read,
}) async {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherAssignmentEditorPage(
        loadCourses: () async => [course],
        loadAssignmentsForCourse: read,
        loadCourseStudents: (_) async => [],
        loadSubmissions: (_) async => [],
        listMyRubrics: () async => [],
        createAssignment: create,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // ชีตแก้ไขใบงานถูกยุบเข้าหน้าฟอร์มเต็มจอ 2026-09-22 — กดสร้างแล้วเปิด
  // TeacherAssignmentFormPage ซึ่งตอนนี้ใช้ AssignmentSaveController
  // ตัวเดียวกับที่ชีตเคยใช้ การรับประกันในไฟล์นี้จึงยังต้องเป็นจริง
  await tester.tap(find.text('สร้างใบงานใหม่'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'ทดสอบบันทึก');
}

void main() {
  // ช่องพิมพ์วันที่เปลี่ยนเป็นชีตเลือกวัน-เวลาเมื่อ 2026-09-22 — พิมพ์
  // '2027-02-31' ผ่านหน้าจอไม่ได้อีกแล้ว บั๊กคลาสนี้ถูกออกแบบทิ้งไป
  // สิ่งที่ยังต้องกันคือการแปลงไป-กลับระหว่าง DateTime กับข้อความที่เก็บ
  // ซึ่งเป็นความเสี่ยงใหม่ที่การเปลี่ยนนี้สร้างขึ้น
  test('วันที่ที่ไม่มีอยู่จริงต้อง parse ไม่ผ่าน ไม่ใช่เลื่อนเป็นวันถัดไป', () {
    expect(parseAssignmentDue('2027-02-31 16:30'), isNull);
    expect(parseAssignmentDue('  '), isNull);
    expect(parseAssignmentDue('ไม่ใช่วันที่'), isNull);
  });

  /// 2026-09-22: ชีตนี้เคยให้เลือกประเภทงานซ้ำอีกรอบ ทั้งที่ทางเข้า
  /// ('สร้างงาน / สื่อ' → ใบงานดิจิทัล / คลังข้อสอบ / สไลด์) เลือกไปแล้ว
  /// และค่านั้นไม่เคยเปลี่ยนพฤติกรรมอะไร — Google Classroom เลือกชนิดตอน
  /// กดสร้างแล้วไม่ถามซ้ำ ส่วน Teams ไม่มีประเภทตายตัวเลย
  testWidgets('หน้าฟอร์มไม่ถามประเภทงาน และของใหม่ถูกบันทึกเป็น worksheet', (
    tester,
  ) async {
    String? sentType;
    await openEditor(
      tester,
      create:
          ({
            required courseId,
            required type,
            required title,
            instructions,
            dueAt,
            rubricId,
            isGroup = false,
          }) async {
            sentType = type;
            return 'a1';
          },
      read: (_) async => [],
    );

    expect(find.text('ประเภทงาน'), findsNothing);
    expect(find.text('ใบงานทดลอง'), findsNothing);
    expect(find.text('โครงงาน AIoT'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกร่าง').last);
    await tester.pumpAndSettle();
    expect(sentType, 'worksheet');
  });

  test('format แล้ว parse กลับต้องได้เวลาเดิมเป๊ะ', () {
    for (final dt in [
      DateTime(2027, 1, 25, 16, 30),
      DateTime(2026, 12, 31, 23, 59),
      DateTime(2027, 3, 1, 0, 0),
    ]) {
      expect(parseAssignmentDue(formatAssignmentDue(dt)), dt);
    }
  });

  testWidgets('create sends the due date and waits for canonical readback', (
    tester,
  ) async {
    DateTime? received;
    var saved = false;
    var readsAfterSave = 0;
    await openEditor(
      tester,
      create:
          ({
            required courseId,
            required type,
            required title,
            instructions,
            dueAt,
            rubricId,
            isGroup = false,
          }) async {
            received = dueAt;
            saved = true;
            return 'a1';
          },
      read: (_) async {
        if (!saved) return [];
        readsAfterSave++;
        return [
          AssignmentSummary(
            id: 'a1',
            type: 'worksheet',
            title: 'ทดสอบบันทึก',
            instructions: '',
            // readback ต้องสะท้อนค่าที่เพิ่งเขียนจริง ไม่ใช่ค่าตายตัว —
            // ตัวคุมการบันทึกเทียบสองค่านี้ก่อนจะบอกว่าสำเร็จ
            dueAt: received,
            status: 'draft',
          ),
        ];
      },
    );
    // เปิดชีตเลือกวัน-เวลาแล้วกดเสร็จ — ยืนยันว่าสายไฟจากชีตถึง
    // createAssignment ต่อครบ ส่วนความถูกต้องของค่าที่แปลงมีเทสต์ยูนิตข้างบน
    await tester.tap(find.text('ยังไม่กำหนด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เสร็จ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกร่าง').last);
    await tester.pumpAndSettle();
    expect(received, isNotNull);
    expect(readsAfterSave, greaterThan(0));
    expect(find.textContaining('เรียบร้อยแล้ว'), findsOneWidget);
  });

  testWidgets('missing canonical row never reports save success', (
    tester,
  ) async {
    await openEditor(
      tester,
      create:
          ({
            required courseId,
            required type,
            required title,
            instructions,
            dueAt,
            rubricId,
            isGroup = false,
          }) async => 'a1',
      read: (_) async => [],
    );
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกร่าง').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('เรียบร้อยแล้ว'), findsNothing);
    expect(find.textContaining('ยังยืนยัน'), findsOneWidget);
  });
}
