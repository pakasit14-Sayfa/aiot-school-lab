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
  await tester.tap(find.text('สร้างใบงานใหม่'));
  await tester.pumpAndSettle();
  final fields = find.byType(TextField);
  // The modal's title field follows the page search field.
  await tester.enterText(fields.at(1), 'ทดสอบบันทึก');
}

void main() {
  testWidgets('invalid calendar date is rejected before writing', (
    tester,
  ) async {
    var writes = 0;
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
            writes++;
            return 'a1';
          },
      read: (_) async => [],
    );
    await tester.enterText(
      find.byKey(const Key('assignment-due-field')),
      '2027-02-31 16:30',
    );
    await tester.tap(find.text('บันทึกร่าง'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(
      find.textContaining('กรุณากรอกวันและเวลาให้ถูกต้อง'),
      findsOneWidget,
    );
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
            dueAt: DateTime(2027, 1, 25, 16, 30),
            status: 'draft',
          ),
        ];
      },
    );
    await tester.enterText(
      find.byKey(const Key('assignment-due-field')),
      '2027-01-25 16:30',
    );
    await tester.tap(find.text('บันทึกร่าง'));
    await tester.pumpAndSettle();
    expect(received, DateTime(2027, 1, 25, 16, 30));
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
    await tester.tap(find.text('บันทึกร่าง'));
    await tester.pumpAndSettle();
    expect(find.textContaining('เรียบร้อยแล้ว'), findsNothing);
    expect(find.textContaining('ยังยืนยัน'), findsOneWidget);
  });
}
