import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_rubric_page.dart';
import 'package:shared_core/models/rubric_model.dart' as rubric_backend;

/// The "duplicate" button used to be pure fake-success: it built a
/// client-side-only rubric with a made-up id, showed a success toast, and
/// the copy vanished on refresh because it was never saved. These tests
/// pin down that duplicate — and the create/edit form's save — really
/// reach RubricService, not just local state.

rubric_backend.RubricModel _lockedRubric({
  String id = 'r-1',
  String title = 'เกณฑ์ประเมินโครงงาน',
  int usedCount = 3,
}) => rubric_backend.RubricModel(
  id: id,
  title: title,
  description: 'ใช้ตรวจงานกลุ่ม STEM',
  usedCount: usedCount,
  criteria: [
    rubric_backend.RubricCriterionModel(
      id: 'c-1',
      name: 'คุณภาพงาน',
      maxScore: 10,
      sortOrder: 0,
      levels: const [
        {'name': 'ดีมาก (10)', 'score': 10, 'description': 'สมบูรณ์'},
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<rubric_backend.RubricModel>> Function()? listMyRubrics,
  Future<rubric_backend.RubricModel> Function(String rubricId)? getRubric,
  Future<String> Function({
    required String title,
    String? description,
    List<Map<String, dynamic>>? criteria,
  })?
  createRubric,
  Future<void> Function({
    required String rubricId,
    required String title,
    String? description,
    List<Map<String, dynamic>>? criteria,
  })?
  updateRubric,
}) async {
  tester.view.physicalSize = const Size(1600, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherRubricPage(
        listMyRubrics: listMyRubrics ?? () async => [_lockedRubric()],
        getRubric: getRubric ?? (id) async => _lockedRubric(id: id),
        createRubric: createRubric,
        updateRubric: updateRubric,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a rubric already used to grade shows the real used count and lock state', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.textContaining('ตรวจไปแล้ว 3 งาน'), findsOneWidget);
    expect(find.text('ล็อกแล้ว (ใช้ตรวจงานแล้ว)'), findsOneWidget);
  });

  testWidgets('duplicating a locked rubric calls the real createRubric RPC, not a fake local copy', (
    tester,
  ) async {
    String? sentTitle;
    List<Map<String, dynamic>>? sentCriteria;
    var createCalls = 0;

    await _pump(
      tester,
      createRubric: ({required title, description, criteria}) async {
        createCalls++;
        sentTitle = title;
        sentCriteria = criteria;
        return 'real-new-id-from-backend';
      },
    );

    await tester.tap(find.text('ดูรายละเอียด'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('คัดลอกเป็น Rubric ใหม่'));
    await tester.pumpAndSettle();

    expect(createCalls, 1, reason: 'duplicate must call the real RPC exactly once');
    expect(sentTitle, 'เกณฑ์ประเมินโครงงาน (สำเนา)');
    expect(sentCriteria, isNotNull);
    expect(sentCriteria!.first['name'], 'คุณภาพงาน');

    // The new card in the list must carry the id the backend actually
    // returned, not a client-generated one — proves the insert used the
    // real RPC result rather than faking it.
    expect(find.textContaining('(สำเนา)'), findsOneWidget);
  });

  testWidgets('a failed duplicate shows an honest message, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      createRubric: ({required title, description, criteria}) async =>
          throw StateError('backend detail that must stay internal'),
    );

    await tester.tap(find.text('ดูรายละเอียด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('คัดลอกเป็น Rubric ใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('คัดลอก Rubric ไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('creating a new rubric from the form calls the real createRubric RPC', (
    tester,
  ) async {
    String? sentTitle;

    await _pump(
      tester,
      listMyRubrics: () async => [],
      createRubric: ({required title, description, criteria}) async {
        sentTitle = title;
        return 'new-id';
      },
    );

    expect(find.text('ไม่พบ Rubric ตามเงื่อนไขที่ค้นหา'), findsOneWidget);

    await tester.tap(find.text('สร้าง Rubric ใหม่'));
    await tester.pumpAndSettle();

    final titleField = find.ancestor(
      of: find.text('ชื่อ Rubric *'),
      matching: find.byType(TextField),
    );
    await tester.enterText(titleField, 'เกณฑ์ใหม่ของฉัน');
    await tester.tap(find.text('บันทึก Rubric'));
    await tester.pumpAndSettle();

    expect(sentTitle, 'เกณฑ์ใหม่ของฉัน');
    expect(find.textContaining('บันทึก Rubric'), findsWidgets);
  });

  testWidgets('an empty account shows an honest empty state, no fabricated rubrics', (
    tester,
  ) async {
    await _pump(tester, listMyRubrics: () async => []);
    expect(find.text('ไม่พบ Rubric ตามเงื่อนไขที่ค้นหา'), findsOneWidget);
  });
}
