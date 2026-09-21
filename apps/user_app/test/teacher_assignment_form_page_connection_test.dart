import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_form_page.dart';
import 'package:shared_core/shared_core.dart';

/// หน้าแก้ไขสูงกว่าจอ 844pt ตั้งแต่มีหัวการ์ดสีวิชา — ListView สร้างเฉพาะ
/// แถวที่อยู่ในกรอบ ทำให้ find หาแถวล่าง ๆ ไม่เจอถ้ายังไม่เลื่อน
/// (ผู้ใช้จริงก็ต้องเลื่อนเหมือนกัน) — เลื่อนสุดก่อนค่อยตรวจแถวท้ายหน้า
Future<void> _scrollToBottom(WidgetTester tester) async {
  final pos = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  pos.jumpTo(pos.maxScrollExtent);
  await tester.pumpAndSettle();
}

/// ฟอร์มใบงาน (2026-09-21): create sends the course it was opened from
/// (never courses.first), edit sends the real due DateTime, the status
/// switch maps to publish / unpublish, dataset ✕ reaches
/// unlink_assignment_sensor_dataset.
Future<void> _pump(
  WidgetTester tester, {
  AssignmentSummary? existing,
  Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool isGroup,
  })?
  create,
  Future<void> Function({
    required String assignmentId,
    String? title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool? isGroup,
  })?
  update,
  Future<void> Function(String)? publish,
  Future<void> Function(String)? unpublish,
  Future<void> Function(String)? unlink,
  List<AssignmentSensorDataset> datasets = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherAssignmentFormPage(
        courseId: 'course-7',
        courseName: 'คณิตศาสตร์',
        existing: existing,
        listMyRubrics: () async => [
          RubricModel(id: 'r1', title: 'เกณฑ์ทดลอง', criteriaCount: 3),
        ],
        createAssignment:
            create ??
            ({
              required courseId,
              required type,
              required title,
              instructions,
              dueAt,
              rubricId,
              isGroup = false,
            }) async => 'new-1',
        updateAssignment:
            update ??
            ({
              required assignmentId,
              title,
              instructions,
              dueAt,
              rubricId,
              isGroup,
            }) async {},
        publishAssignment: publish ?? (_) async {},
        unpublishAssignment: unpublish ?? (_) async {},
        loadAssignmentDetail: (id) async => AssignmentDetail(
          id: id,
          courseId: 'course-7',
          type: 'worksheet',
          title: 't',
          instructions: null,
          dueAt: null,
          status: 'draft',
          sensorDatasets: datasets,
        ),
        listDevices: () async => const [
          DeviceOption(
            id: 'dev1',
            name: 'เซนเซอร์ห้อง 1',
            type: 'air_quality_sensor',
            location: 'ม.1/1',
            status: 'online',
          ),
        ],
        unlinkSensorDataset: unlink ?? (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'create sends the opening course, type worksheet, no ประเภทงาน field',
    (tester) async {
      // Create mode became a 4-step wizard 2026-09-21 (owner: "เอาที่ง่ายต่อ
      // การใช้งาน" — a guided walk fits first-time creation better than one
      // long form). There's no longer a single "บันทึก" reachable right
      // after typing the title, or a static "ใบงานใหม่" page title — walk
      // all 4 steps like a real user would.
      String? sentCourse;
      String? sentType;
      bool? group;
      await _pump(
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
              sentCourse = courseId;
              sentType = type;
              group = isGroup;
              return 'new-1';
            },
      );
      expect(find.text('ประเภทงาน'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อใบงาน'),
        'งานใหม่',
      );
      await tester.tap(find.text('ถัดไป — การส่งงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ถัดไป — การเผยแพร่'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ถัดไป — ชุดข้อมูลเซนเซอร์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึกใบงาน'));
      await tester.pumpAndSettle();
      expect(sentCourse, 'course-7');
      expect(sentType, 'worksheet');
      expect(group, false);
    },
  );

  testWidgets('empty title is refused before any RPC', (tester) async {
    // Same wizard change as above — the "ถัดไป" button on step 1 is what
    // validates the title now, not a "บันทึก" button (that only exists on
    // step 4).
    var called = false;
    await _pump(
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
            called = true;
            return 'x';
          },
    );
    await tester.tap(find.text('ถัดไป — การส่งงาน'));
    await tester.pumpAndSettle();
    expect(called, false);
    expect(find.text('กรุณากรอกชื่อใบงาน'), findsOneWidget);
  });

  testWidgets(
    'edit: switching เผยแพร่ off on a published work calls unpublish',
    (tester) async {
      String? unpublished;
      String? updated;
      DateTime? sentDue;
      final due = DateTime(2026, 10, 1, 23, 59);
      await _pump(
        tester,
        existing: AssignmentSummary(
          id: 'a9',
          type: 'worksheet',
          title: 'เดิม',
          dueAt: due,
          status: 'published',
        ),
        update:
            ({
              required assignmentId,
              title,
              instructions,
              dueAt,
              rubricId,
              isGroup,
            }) async {
              updated = assignmentId;
              sentDue = dueAt;
            },
        unpublish: (id) async => unpublished = id,
      );
      expect(find.text('แก้ไขใบงาน'), findsOneWidget);
      expect(find.text('1 ต.ค. 2569 · 23:59 น.'), findsOneWidget); // Thai date
      // การเผยแพร่ไม่ใช่สวิตช์ในฟอร์มอีกแล้ว — เป็นคำสั่ง: ปุ่มหลักที่แถบล่าง
      // กับทางเลือกรองในเมนู ⋯ (วิธีเดียวกับ Google Classroom)
      expect(find.text('บันทึก'), findsOneWidget); // ใบงานที่มอบหมายแล้ว
      await tester.tap(find.byTooltip('ตัวเลือกเพิ่มเติม'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิกการเผยแพร่'));
      await tester.pumpAndSettle();
      expect(updated, 'a9');
      expect(sentDue, due);
      expect(unpublished, 'a9');
    },
  );

  testWidgets('edit: ใบงานร่าง กด "มอบหมายให้นักเรียน" แล้ว publish ถูกเรียก', (
    tester,
  ) async {
    String? published;
    String? updated;
    await _pump(
      tester,
      existing: const AssignmentSummary(
        id: 'a10',
        type: 'worksheet',
        title: 'ร่างอยู่',
        dueAt: null,
        status: 'draft',
      ),
      update:
          ({
            required assignmentId,
            title,
            instructions,
            dueAt,
            rubricId,
            isGroup,
          }) async => updated = assignmentId,
      publish: (id) async => published = id,
    );
    expect(find.text('ยังไม่ได้มอบหมาย — นักเรียนยังไม่เห็น'), findsOneWidget);
    await tester.tap(find.text('มอบหมายให้นักเรียน'));
    await tester.pumpAndSettle();
    expect(updated, 'a10');
    expect(published, 'a10');
  });

  testWidgets('dataset rows show Thai metric + device and ✕ unlinks', (
    tester,
  ) async {
    String? unlinked;
    await _pump(
      tester,
      existing: const AssignmentSummary(
        id: 'a9',
        type: 'worksheet',
        title: 'เดิม',
        dueAt: null,
        status: 'draft',
      ),
      datasets: const [
        AssignmentSensorDataset(
          id: 'ds1',
          deviceId: 'dev1',
          metric: 'temperature',
          timeStart: null,
          timeEnd: null,
          label: null,
        ),
      ],
      unlink: (id) async => unlinked = id,
    );
    // Every row grew taller in the 2026-09-21 redesign (field labels, more
    // padding between standalone tinted rows instead of a dense card list),
    // and the hero card added another ~160pt on top, so the dataset row is
    // genuinely below the fold in the fixed 844pt test viewport now — a
    // real user just scrolls, same as the live app. ListView never builds
    // it until then, which is why the scroll has to come before the finds.
    // ensureVisible()/dragUntilVisible() both left the derived tap offset
    // unchanged, so jump the Scrollable directly rather than fight gesture
    // routing over the rows in between.
    await _scrollToBottom(tester);
    expect(find.text('อุณหภูมิ'), findsOneWidget);
    expect(find.textContaining('เซนเซอร์ห้อง 1'), findsOneWidget);
    await tester.tap(find.byTooltip('เอาออก'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เอาออก').last);
    await tester.pumpAndSettle();
    expect(unlinked, 'ds1');
  });
}
