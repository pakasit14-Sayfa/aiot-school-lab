import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_form_page.dart';
import 'package:shared_core/shared_core.dart';

/// ไฟล์แนบในใบงาน (2026-09-23)
///
/// สิ่งที่เทสต์ชุดนี้ตรึง ไม่ใช่หน้าตา แต่เป็นสัญญาที่ตกลงกันไว้:
///   * ไฟล์ไม่ขึ้นหลังบ้านจนกว่าจะกดบันทึก — กดยกเลิกแล้วต้องไม่เหลืออะไร
///     (แบบปุ่ม Save/Discard ของ Teams)
///   * ทุกอย่างที่แนบเข้าคลังความรู้ของวิชาเสมอ ไม่มีสวิตช์ให้ครูเลือก
///   * ใบงานใหม่ก็แนบได้ ไม่ต้องบันทึกก่อน — id เพิ่งมีตอนบันทึก ไฟล์จึงผูก
///     หลังจากนั้น
///   * 'เอาออกจากใบงาน' ไม่ใช่ 'ลบ' — ถอดการผูก ไม่แตะไฟล์ในคลัง
///   * อัปได้แต่ผูกไม่สำเร็จ ต้องไม่รายงานว่าเรียบร้อย
void main() {
  const course = 'c1';

  Uint8List bytes(int n) => Uint8List.fromList(List.filled(n, 7));

  ({
    List<String> uploaded,
    List<String> links,
    List<String> attached,
    List<String> detached,
    List<String> createdTitles,
  })
  recorder() => (
    uploaded: <String>[],
    links: <String>[],
    attached: <String>[],
    detached: <String>[],
    createdTitles: <String>[],
  );

  Future<void> pump(
    WidgetTester tester, {
    required dynamic rec,
    AssignmentSummary? existing,
    List<PlatformFile>? picked,
    List<AssignmentAttachment> loaded = const [],
    bool attachThrows = false,
  }) async {
    tester.view.physicalSize = const Size(402, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var saved = false;
    // readback ต้องสะท้อนชื่อที่เพิ่งเขียนจริง ไม่ใช่ค่าตายตัว — ไม่งั้น
    // AssignmentSaveController จะโยน backend_assignment_not_confirmed
    // แล้วไฟล์แนบไม่มีวันถูกเขียน (ซึ่งถูกต้องตามดีไซน์)
    String sentTitle = existing?.title ?? '';
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAssignmentFormPage(
          courseId: course,
          courseName: 'คณิตศาสตร์',
          existing: existing,
          listMyRubrics: () async => const [],
          createAssignment:
              ({
                required courseId,
                required type,
                required title,
                instructions,
                dueAt,
                rubricId,
                isGroup = false,
              }) async {
                rec.createdTitles.add(title);
                sentTitle = title;
                saved = true;
                return 'a1';
              },
          updateAssignment:
              ({
                required assignmentId,
                title,
                instructions,
                dueAt,
                rubricId,
                isGroup,
              }) async {
                sentTitle = title ?? sentTitle;
                saved = true;
              },
          publishAssignment: (_) async {},
          loadAssignmentsForCourse: (_) async => saved
              ? [
                  AssignmentSummary(
                    id: existing?.id ?? 'a1',
                    type: 'worksheet',
                    title: sentTitle,
                    instructions: '',
                    dueAt: null,
                    status: 'draft',
                  ),
                ]
              : const [],
          loadAssignmentDetail: (id) async => AssignmentDetail(
            id: id,
            courseId: course,
            type: 'worksheet',
            title: 'x',
            instructions: null,
            dueAt: null,
            status: 'draft',
            sensorDatasets: const [],
          ),
          listAttachments: (_) async => loaded,
          pickFiles: () async => picked,
          uploadCourseFile:
              ({
                required courseId,
                required fileName,
                required bytes,
                category,
              }) async {
                rec.uploaded.add(fileName);
                return 'file-$fileName';
              },
          addCourseLink: ({required courseId, required url, title}) async {
            rec.links.add(url);
            return 'file-link';
          },
          attachFile:
              ({
                required assignmentId,
                required courseFileId,
                sortOrder,
              }) async {
                if (attachThrows) throw StateError('boom');
                rec.attached.add('$assignmentId:$courseFileId');
                return 'att-$courseFileId';
              },
          detachFile: (id) async => rec.detached.add(id),
          getFileDownloadUrl: (_) async => 'https://example.org/x.png',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// ช่องในไดอะล็อกเท่านั้น — find.byType(TextField).first จะไปโดนช่อง
  /// 'ชื่อใบงาน' ของหน้า เพราะมันอยู่ก่อนในทรี ทำให้เทสต์ผ่านด้วยเหตุผลผิด
  Finder dialogField(int i) => find
      .descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      )
      .at(i);

  Future<void> saveDraft(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกร่าง').last);
    await tester.pumpAndSettle();
  }

  testWidgets('ใบงานใหม่แนบไฟล์ได้เลย ไม่ต้องบันทึกก่อน', (tester) async {
    final rec = recorder();
    await pump(
      tester,
      rec: rec,
      picked: [PlatformFile(name: 'ใบความรู้.pdf', size: 1024, bytes: bytes(1024))],
    );

    expect(find.text('ไฟล์แนบ'), findsOneWidget);
    await tester.tap(find.text('อัปโหลด'));
    await tester.pumpAndSettle();

    // โผล่บนจอแล้ว แต่ยังไม่แตะหลังบ้านเลย
    expect(find.text('ใบความรู้.pdf'), findsOneWidget);
    expect(find.textContaining('รออัปโหลด'), findsOneWidget);
    expect(rec.uploaded, isEmpty);
    expect(rec.attached, isEmpty);
  });

  testWidgets('กดบันทึกแล้วจึงอัปขึ้นคลัง แล้วผูกกับใบงานที่เพิ่งเกิด', (
    tester,
  ) async {
    final rec = recorder();
    await pump(
      tester,
      rec: rec,
      picked: [PlatformFile(name: 'รูปวงจร.png', size: 512, bytes: bytes(512))],
    );
    await tester.enterText(find.byType(TextField).first, 'ใบงานมีไฟล์แนบ');
    await tester.tap(find.text('อัปโหลด'));
    await tester.pumpAndSettle();
    await saveDraft(tester);

    // เข้าคลังความรู้เสมอ ไม่มีสวิตช์ให้เลือก
    expect(rec.uploaded, ['รูปวงจร.png']);
    // ผูกกับ id ที่ createAssignment เพิ่งคืนมา
    expect(rec.attached, ['a1:file-รูปวงจร.png']);
  });

  testWidgets('ลิงก์ที่ไม่ขึ้นต้นด้วย http ต้องไม่ผ่านตั้งแต่หน้าจอ', (
    tester,
  ) async {
    final rec = recorder();
    await pump(tester, rec: rec);

    await tester.tap(find.text('ใส่ลิงก์'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogField(0), 'ไม่ใช่ลิงก์');
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ต้องขึ้นต้นด้วย'), findsOneWidget);
    expect(rec.links, isEmpty);
  });

  testWidgets('ลิงก์ที่ถูกต้องถูกส่งเข้าคลังตอนบันทึก', (tester) async {
    final rec = recorder();
    await pump(tester, rec: rec);

    await tester.tap(find.text('ใส่ลิงก์'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogField(0), 'https://example.org/v');
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();
    // ไดอะล็อกต้องปิดไปแล้วจริง ๆ ไม่ใช่ค้างอยู่หลัง barrier
    expect(find.byType(AlertDialog), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'ใบงานมีลิงก์');
    await saveDraft(tester);

    expect(rec.links, ['https://example.org/v']);
    expect(rec.attached, ['a1:file-link']);
  });

  testWidgets("'เอาออกจากใบงาน' ถอดการผูก ไม่ลบไฟล์ในคลัง", (tester) async {
    final rec = recorder();
    await pump(
      tester,
      rec: rec,
      existing: const AssignmentSummary(
        id: 'a9',
        type: 'worksheet',
        title: 'ใบงานเดิม',
        dueAt: null,
        status: 'draft',
      ),
      loaded: const [
        AssignmentAttachment(
          id: 'att-1',
          courseFileId: 'f1',
          kind: CourseFileKind.file,
          fileName: 'เฉลย.pdf',
          sortOrder: 0,
        ),
      ],
    );

    expect(find.text('เฉลย.pdf'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    // ต้องเขียนให้ชัดว่าไฟล์ไม่ได้หายไปจากคลัง
    expect(find.textContaining('ยังอยู่ในคลังความรู้'), findsOneWidget);
    await tester.tap(find.text('เอาออกจากใบงาน').last);
    await tester.pumpAndSettle();
    await saveDraft(tester);

    expect(rec.detached, ['att-1']);
  });

  testWidgets('อัปขึ้นคลังได้แต่ผูกไม่สำเร็จ ต้องไม่บอกว่าเรียบร้อย', (
    tester,
  ) async {
    final rec = recorder();
    await pump(
      tester,
      rec: rec,
      picked: [PlatformFile(name: 'a.pdf', size: 10, bytes: bytes(10))],
      attachThrows: true,
    );
    await tester.enterText(find.byType(TextField).first, 'ใบงาน');
    await tester.tap(find.text('อัปโหลด'));
    await tester.pumpAndSettle();
    await saveDraft(tester);

    expect(rec.uploaded, ['a.pdf']);
    expect(find.textContaining('ยังไม่สำเร็จ'), findsOneWidget);
    // หน้ายังเปิดอยู่ ครูกดบันทึกซ้ำได้
    expect(find.text('ไฟล์แนบ'), findsOneWidget);
  });

  testWidgets('กดบันทึกซ้ำหลังผูกพลาด ต้องไม่อัปไฟล์เดิมซ้ำอีกใบ', (
    tester,
  ) async {
    final rec = recorder();
    await pump(
      tester,
      rec: rec,
      picked: [PlatformFile(name: 'a.pdf', size: 10, bytes: bytes(10))],
      attachThrows: true,
    );
    await tester.enterText(find.byType(TextField).first, 'ใบงาน');
    await tester.tap(find.text('อัปโหลด'));
    await tester.pumpAndSettle();
    await saveDraft(tester);
    await saveDraft(tester);

    // สองรอบ แต่ไฟล์ขึ้นคลังใบเดียว — courseFileId ถูกจำไว้
    expect(rec.uploaded, ['a.pdf']);
  });

  testWidgets('โหลดไฟล์แนบพัง ต้องแยกจาก "ไม่มีไฟล์แนบ"', (tester) async {
    tester.view.physicalSize = const Size(402, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAssignmentFormPage(
          courseId: course,
          courseName: 'คณิตศาสตร์',
          existing: const AssignmentSummary(
            id: 'a9',
            type: 'worksheet',
            title: 'ใบงานเดิม',
            dueAt: null,
            status: 'draft',
          ),
          listMyRubrics: () async => const [],
          loadAssignmentDetail: (id) async => AssignmentDetail(
            id: id,
            courseId: course,
            type: 'worksheet',
            title: 'x',
            instructions: null,
            dueAt: null,
            status: 'draft',
            sensorDatasets: const [],
          ),
          listAttachments: (_) async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดไฟล์แนบไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
  });
}
