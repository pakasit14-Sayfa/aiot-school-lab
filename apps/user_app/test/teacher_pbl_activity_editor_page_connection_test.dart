import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_pbl_activity_editor_page.dart';
import 'package:shared_core/shared_core.dart';

final _device = AiotLabDeviceItem(
  deviceId: 'dev-1',
  name: 'เซนเซอร์อุณหภูมิ',
  type: 'sensor',
  location: 'ห้อง 101',
  status: 'online',
  courseId: 'course-1',
  courseName: 'วิทยาศาสตร์',
);

final _rubricSummary = RubricModel(id: 'rubric-1', title: 'เกณฑ์ประเมิน PBL');

final _rubricDetail = RubricModel(
  id: 'rubric-1',
  title: 'เกณฑ์ประเมิน PBL',
  description: 'รายละเอียด',
  criteria: [
    RubricCriterionModel(
      id: 'c-1',
      name: 'ความคิดสร้างสรรค์',
      maxScore: 10,
      sortOrder: 0,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<AiotLabDeviceItem>> Function()? listTeachingKitDevices,
  Future<List<RubricModel>> Function()? listMyRubrics,
  Future<RubricModel> Function(String rubricId)? getRubric,
  Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
  })?
  createAssignment,
  Future<void> Function(String assignmentId)? publishAssignment,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherPblActivityEditorPage(
        courseId: 'course-1',
        listTeachingKitDevices: listTeachingKitDevices ?? () async => [_device],
        listMyRubrics: listMyRubrics ?? () async => [_rubricSummary],
        getRubric: getRubric ?? (_) async => _rubricDetail,
        createAssignment: createAssignment,
        publishAssignment: publishAssignment,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _walkToReviewStep(WidgetTester tester) async {
  // Step 0: topic
  await tester.tap(find.text('พลังงาน'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ถัดไป'));
  await tester.pumpAndSettle();

  // Step 1: problem/objective/outcome
  await tester.enterText(find.byType(TextField).at(0), 'โจทย์ทดสอบ');
  await tester.enterText(find.byType(TextField).at(1), 'วัตถุประสงค์ทดสอบ');
  await tester.enterText(find.byType(TextField).at(2), 'ผลลัพธ์ทดสอบ');
  await tester.pumpAndSettle();
  await tester.tap(find.text('ถัดไป'));
  await tester.pumpAndSettle();

  // Step 2: device
  await tester.tap(find.text('เซนเซอร์อุณหภูมิ (ห้อง 101)'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ถัดไป'));
  await tester.pumpAndSettle();

  // Step 3: rubric
  await tester.tap(find.text('เกณฑ์ประเมิน PBL'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ถัดไป'));
  await tester.pumpAndSettle();

  // Step 4: timeline
  await tester.tap(find.text('ถัดไป'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'devices and rubrics loaded show real names, not fabricated data',
    (tester) async {
      await _pump(tester);
      expect(find.text('เลือกหัวข้อกิจกรรม PBL'), findsOneWidget);
    },
  );

  testWidgets(
    'publishing sends the real selected rubric id, not silently dropping it',
    (tester) async {
      String? sentRubricId;
      String? publishedId;
      await _pump(
        tester,
        createAssignment:
            ({
              required courseId,
              required type,
              required title,
              instructions,
              dueAt,
              rubricId,
            }) async {
              sentRubricId = rubricId;
              return 'pbl-1';
            },
        publishAssignment: (id) async {
          publishedId = id;
        },
      );

      await _walkToReviewStep(tester);
      expect(find.text('เผยแพร่กิจกรรม'), findsOneWidget);
      await tester.tap(find.text('เผยแพร่กิจกรรม'));
      await tester.pumpAndSettle();

      expect(sentRubricId, 'rubric-1');
      expect(publishedId, 'pbl-1');
    },
  );

  testWidgets(
    'a real load failure shows an honest error, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        listTeachingKitDevices: () async =>
            throw StateError('backend detail that must stay internal'),
      );
      expect(
        find.text('โหลดข้อมูลอุปกรณ์/เกณฑ์ประเมินไม่สำเร็จ'),
        findsOneWidget,
      );
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );

  testWidgets(
    'zero devices registered to this course shows an honest empty state',
    (tester) async {
      await _pump(tester, listTeachingKitDevices: () async => const []);
      await tester.tap(find.text('พลังงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'a');
      await tester.enterText(find.byType(TextField).at(1), 'b');
      await tester.enterText(find.byType(TextField).at(2), 'c');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ยังไม่มีอุปกรณ์ AIoT ที่ลงทะเบียนในวิชานี้'),
        findsOneWidget,
      );
    },
  );
}
