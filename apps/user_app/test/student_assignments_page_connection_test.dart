import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_assignments_page.dart';
import 'package:shared_core/shared_core.dart';

/// StudentAssignmentsPage's submit sheet does a real signed-URL file
/// upload and a real submit_assignment RPC — a student's actual grade
/// depends on this reaching the backend, not just updating local state.

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

const _assignment = AssignmentSummary(
  id: 'asg-1',
  type: 'homework',
  title: 'แบบฝึกหัดบทที่ 3',
  dueAt: null,
  status: 'published',
);

const _detail = AssignmentDetail(
  id: 'asg-1',
  courseId: 'course-1',
  type: 'homework',
  title: 'แบบฝึกหัดบทที่ 3',
  instructions: 'ทำข้อ 1-10',
  dueAt: null,
  status: 'published',
  sensorDatasets: [],
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse,
  Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadSubmissionVersions,
  Future<AssignmentDetail> Function(String assignmentId)? getAssignmentDetail,
  Future<String> Function(String attachmentId)? getAttachmentDownloadUrl,
  Future<List<PlatformFile>?> Function()? pickFiles,
  Future<({int version, String submissionVersionId})> Function({
    required String assignmentId,
    required String content,
  })?
  submitAssignment,
  Future<List<SavedChart>> Function()? loadMyCharts,
  Future<List<SensorDataPoint>> Function({
    required String deviceId,
    required String metric,
    required DateTime from,
    DateTime? to,
  })?
  getSensorHistory,
  Future<String> Function({
    required String submissionVersionId,
    required String fileName,
    required Uint8List bytes,
  })?
  uploadAttachment,
  Future<List<AssignmentAttachment>> Function(String assignmentId)?
  loadTeacherAttachments,
  Future<String> Function(String fileId)? getTeacherFileUrl,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentAssignmentsPage(
        loadCourses: loadCourses ?? () async => const [_course],
        loadAssignmentsForCourse:
            loadAssignmentsForCourse ?? (_) async => const [_assignment],
        loadSubmissionVersions: loadSubmissionVersions ?? (_) async => const [],
        getAssignmentDetail: getAssignmentDetail ?? (_) async => _detail,
        getAttachmentDownloadUrl: getAttachmentDownloadUrl,
        pickFiles: pickFiles,
        submitAssignment: submitAssignment,
        loadMyCharts: loadMyCharts,
        getSensorHistory: getSensorHistory,
        uploadAttachment: uploadAttachment,
        loadTeacherAttachments:
            loadTeacherAttachments ?? (_) async => const [],
        getTeacherFileUrl: getTeacherFileUrl,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _teacherAttachments();

  testWidgets(
    'upload retry keeps the submitted version and skips confirmed files',
    (tester) async {
      var submits = 0;
      var secondAttempts = 0;
      final uploads = <String>[];
      final attachments = <SubmissionAttachment>[];
      await _pump(
        tester,
        loadSubmissionVersions: (_) async => submits == 0
            ? []
            : [
                SubmissionVersion(
                  version: 1,
                  content: 'ส่งพร้อมไฟล์',
                  submittedAt: DateTime(2026, 9, 21),
                  submissionVersionId: 'sv-retry',
                  attachments: List.of(attachments),
                ),
              ],
        pickFiles: () async => [
          PlatformFile(
            name: 'one.txt',
            size: 1,
            bytes: Uint8List.fromList([1]),
          ),
          PlatformFile(
            name: 'two.txt',
            size: 1,
            bytes: Uint8List.fromList([2]),
          ),
        ],
        submitAssignment: ({required assignmentId, required content}) async {
          submits++;
          return (version: 1, submissionVersionId: 'sv-retry');
        },
        uploadAttachment:
            ({
              required submissionVersionId,
              required fileName,
              required bytes,
            }) async {
              expect(submissionVersionId, 'sv-retry');
              uploads.add(fileName);
              if (fileName == 'two.txt' && secondAttempts++ == 0) {
                throw StateError('network');
              }
              attachments.add(
                SubmissionAttachment(id: fileName, fileName: fileName),
              );
              return fileName;
            },
      );
      await tester.tap(find.byType(AssignmentCard));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'ส่งพร้อมไฟล์');
      await tester.tap(find.text('แนบไฟล์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันการส่งงาน'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ส่งข้อความแล้ว'), findsOneWidget);
      expect(find.text('ส่งงานเรียบร้อยแล้ว'), findsNothing);
      await tester.tap(find.text('ลองอัปโหลดไฟล์ที่เหลืออีกครั้ง'));
      await tester.pumpAndSettle();
      expect(submits, 1);
      expect(uploads, ['one.txt', 'two.txt', 'two.txt']);
      expect(find.text('ส่งงานเรียบร้อยแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'submission missing from canonical readback never reports success',
    (tester) async {
      await _pump(
        tester,
        submitAssignment: ({required assignmentId, required content}) async =>
            (version: 1, submissionVersionId: 'missing'),
      );
      await tester.tap(find.byType(AssignmentCard));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'คำตอบ');
      await tester.tap(find.text('ยืนยันการส่งงาน'));
      await tester.pumpAndSettle();
      expect(find.text('ส่งงานเรียบร้อยแล้ว'), findsNothing);
      expect(find.textContaining('ยังยืนยัน'), findsOneWidget);
    },
  );

  testWidgets(
    'an unsubmitted assignment shows ยังไม่ส่ง, not a fabricated status',
    (tester) async {
      await _pump(tester);
      expect(find.text('ยังไม่ส่ง'), findsWidgets);
    },
  );

  testWidgets(
    'an already-submitted assignment shows ส่งแล้ว, not the submit CTA',
    (tester) async {
      await _pump(
        tester,
        loadSubmissionVersions: (_) async => [
          SubmissionVersion(
            version: 1,
            content: 'ทำเสร็จแล้วครับ',
            submittedAt: DateTime(2026, 9, 1),
            submissionVersionId: 'sv-1',
          ),
        ],
      );
      expect(find.text('ส่งแล้ว'), findsWidgets);
    },
  );

  testWidgets(
    'submitting calls the real RPC with the typed content, and uploads picked files with real bytes',
    (tester) async {
      String? submittedAssignmentId;
      String? submittedContent;
      final uploaded = <Map<String, Object?>>[];

      await _pump(
        tester,
        loadSubmissionVersions: (_) async => submittedContent == null
            ? []
            : [
                SubmissionVersion(
                  version: 1,
                  content: submittedContent,
                  submittedAt: DateTime(2026, 9, 21),
                  submissionVersionId: 'sv-99',
                  attachments: uploaded.isEmpty
                      ? []
                      : [
                          const SubmissionAttachment(
                            id: 'att-1',
                            fileName: 'proof.png',
                          ),
                        ],
                ),
              ],
        pickFiles: () async => [
          PlatformFile(
            name: 'proof.png',
            size: 3,
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ],
        submitAssignment: ({required assignmentId, required content}) async {
          submittedAssignmentId = assignmentId;
          submittedContent = content;
          return (version: 1, submissionVersionId: 'sv-99');
        },
        uploadAttachment:
            ({
              required submissionVersionId,
              required fileName,
              required bytes,
            }) async {
              uploaded.add({
                'submissionVersionId': submissionVersionId,
                'fileName': fileName,
                'bytes': bytes,
              });
              return 'att-1';
            },
      );

      await tester.tap(find.byType(AssignmentCard));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ส่งงานจริงครับ');
      await tester.pump();

      // Pick a file via the seam.
      final pickButtonFinder = find.textContaining('แนบไฟล์');
      if (pickButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(pickButtonFinder.first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('ยืนยันการส่งงาน'));
      await tester.pumpAndSettle();

      expect(submittedAssignmentId, 'asg-1');
      expect(submittedContent, 'ส่งงานจริงครับ');
      expect(uploaded, hasLength(1));
      expect(uploaded.first['submissionVersionId'], 'sv-99');
      expect(uploaded.first['fileName'], 'proof.png');
      expect(uploaded.first['bytes'], Uint8List.fromList([1, 2, 3]));
      expect(find.text('ส่งงานเรียบร้อยแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed submit shows an honest message, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        submitAssignment: ({required assignmentId, required content}) async =>
            throw StateError('backend detail that must stay internal'),
      );

      await tester.tap(find.byType(AssignmentCard));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'x');
      await tester.pump();
      await tester.tap(find.text('ยืนยันการส่งงาน'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ส่งงานไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );

  // ── PBL-6 (2026-09-18) ────────────────────────────────────────────────
  testWidgets(
    'a dataset the teacher pinned is listed in the sheet and opens the viewer',
    (tester) async {
      final pinned = AssignmentDetail(
        id: 'asg-1',
        courseId: 'course-1',
        type: 'homework',
        title: 'แบบฝึกหัดบทที่ 3',
        instructions: 'วิเคราะห์ฝุ่นในห้อง',
        dueAt: null,
        status: 'published',
        sensorDatasets: [
          AssignmentSensorDataset(
            id: 'ds-1',
            deviceId: 'dev-1',
            metric: 'pm25',
            timeStart: DateTime.utc(2026, 9, 10, 1),
            timeEnd: DateTime.utc(2026, 9, 10, 9),
            label: 'ฝุ่นหน้าห้อง ม.1/1 ตอนเช้า',
          ),
        ],
      );
      await _pump(tester, getAssignmentDetail: (_) async => pinned);
      await tester.tap(find.byType(AssignmentCard));
      await tester.pumpAndSettle();
      expect(find.text('ชุดข้อมูลเซนเซอร์ที่ครูกำหนด'), findsOneWidget);
      expect(find.text('ฝุ่นหน้าห้อง ม.1/1 ตอนเช้า'), findsOneWidget);
    },
  );

  testWidgets('no pinned dataset → no dataset section, nothing invented', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byType(AssignmentCard));
    await tester.pumpAndSettle();
    expect(find.text('ชุดข้อมูลเซนเซอร์ที่ครูกำหนด'), findsNothing);
  });

  // ── PBL-10 (2026-09-18) ───────────────────────────────────────────────
  testWidgets(
    'a group assignment says so in the sheet; not_in_group is explained',
    (tester) async {
      const group = AssignmentSummary(
        id: 'asg-g',
        type: 'project',
        title: 'โครงงานกลุ่ม',
        dueAt: null,
        status: 'published',
        isGroup: true,
      );
      await _pump(
        tester,
        loadAssignmentsForCourse: (_) async => const [group],
        submitAssignment: ({required assignmentId, required content}) async {
          throw Exception('not_in_group');
        },
      );
      await tester.tap(find.byType(AssignmentCard));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('งานกลุ่ม — ส่งในนามกลุ่มของคุณ'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).first, 'ส่งกลุ่ม');
      await tester.tap(find.text('ยืนยันการส่งงาน'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('ยังไม่ได้อยู่ในกลุ่มของวิชานี้'),
        findsOneWidget,
      );
    },
  );
  // ── PBL-8 (2026-09-18) ────────────────────────────────────────────────
  testWidgets(
    'attach sensor evidence: pick a saved chart → CSV of the real readings is uploaded',
    (tester) async {
      final uploads = <Map<String, Object?>>[];
      var submitted = false;
      await _pump(
        tester,
        loadSubmissionVersions: (_) async => !submitted
            ? []
            : [
                SubmissionVersion(
                  version: 1,
                  content: 'ส่งพร้อมหลักฐาน',
                  submittedAt: DateTime(2026, 9, 21),
                  submissionVersionId: 'sv-1',
                  attachments: uploads.isEmpty
                      ? []
                      : [const SubmissionAttachment(id: 'att-1')],
                ),
              ],
        loadMyCharts: () async => [
          SavedChart(
            id: 'ch-1',
            courseId: 'course-1',
            chartType: 'line',
            deviceId: 'dev-1',
            deviceName: 'ฝุ่นหน้าห้อง',
            location: null,
            metric: 'pm25',
            timeStart: DateTime.utc(2026, 9, 10, 1),
            timeEnd: DateTime.utc(2026, 9, 10, 3),
            annotation: 'ช่วงเช้าฝุ่นสูง',
            createdAt: DateTime.utc(2026, 9, 18),
          ),
        ],
        getSensorHistory:
            ({
              required String deviceId,
              required String metric,
              required DateTime from,
              DateTime? to,
            }) async {
              expect(deviceId, 'dev-1');
              expect(metric, 'pm25');
              expect(from, DateTime.utc(2026, 9, 10, 1));
              expect(to, DateTime.utc(2026, 9, 10, 3));
              return [
                SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 1), value: 20),
                SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 2), value: 40),
              ];
            },
        submitAssignment: ({required assignmentId, required content}) async {
          submitted = true;
          return (version: 1, submissionVersionId: 'sv-1');
        },
        uploadAttachment:
            ({
              required submissionVersionId,
              required fileName,
              required bytes,
            }) async {
              uploads.add({
                'sv': submissionVersionId,
                'name': fileName,
                'bytes': bytes,
              });
              return 'att-1';
            },
      );
      await tester.tap(find.byType(AssignmentCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แนบข้อมูลเซนเซอร์'));
      await tester.pumpAndSettle();
      expect(find.text('แนบข้อมูลเซนเซอร์เป็นหลักฐาน'), findsOneWidget);
      await tester.tap(find.text('ช่วงเช้าฝุ่นสูง'));
      await tester.pumpAndSettle();
      // The CSV now sits in the attachment chips.
      expect(find.textContaining('เซนเซอร์-ฝุ่น-PM2.5-'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'ส่งพร้อมหลักฐาน');
      await tester.tap(find.text('ยืนยันการส่งงาน'));
      await tester.pumpAndSettle();
      expect(uploads, hasLength(1));
      expect(uploads.single['sv'], 'sv-1');
      expect(uploads.single['name'], startsWith('เซนเซอร์-'));
      final csv = String.fromCharCodes(
        (uploads.single['bytes'] as List<int>).sublist(3),
      );
      expect(csv, contains('40.0'));
      expect(csv, contains('20.0'));
    },
  );

  testWidgets('no charts and no pinned dataset → explained, nothing attached', (
    tester,
  ) async {
    await _pump(tester, loadMyCharts: () async => const []);
    await tester.tap(find.byType(AssignmentCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แนบข้อมูลเซนเซอร์'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ยังไม่มีข้อมูลเซนเซอร์ให้แนบ'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });
}

/// ไฟล์แนบของครู (2026-09-23)
///
/// ครูแนบไฟล์/รูป/ลิงก์เข้าใบงานได้ตั้งแต่ acf1895 แต่ฝั่งนักเรียนไม่แสดง
/// อะไรเลย — ฟีเจอร์จึงยังไม่มีประโยชน์จริงจนกว่าจะมีบล็อกนี้ เทสต์ชุดนี้
/// ตรึงว่านักเรียนเห็นของที่ครูแนบ และแยก "โหลดไม่สำเร็จ" ออกจาก
/// "ครูไม่ได้แนบอะไร" ได้จริง
void _teacherAttachments() {
  const pdf = AssignmentAttachment(
    id: 'att-1',
    courseFileId: 'f-1',
    kind: CourseFileKind.file,
    fileName: 'ใบความรู้บทที่ 3.pdf',
    sizeBytes: 1024 * 512,
    sortOrder: 0,
  );
  const link = AssignmentAttachment(
    id: 'att-2',
    courseFileId: 'f-2',
    kind: CourseFileKind.link,
    fileName: 'วิดีโอสาธิต',
    url: 'https://example.org/clip',
    sortOrder: 1,
  );

  testWidgets('นักเรียนเห็นเอกสารที่ครูแนบมา ทั้งไฟล์และลิงก์', (tester) async {
    await _pump(tester, loadTeacherAttachments: (_) async => const [pdf, link]);
    await tester.tap(find.byType(AssignmentCard));
    await tester.pumpAndSettle();

    expect(find.text('เอกสารจากครู 2 รายการ'), findsOneWidget);
    expect(find.text('ใบความรู้บทที่ 3.pdf'), findsOneWidget);
    expect(find.text('วิดีโอสาธิต'), findsOneWidget);
    // ลิงก์บอกปลายทาง ไฟล์บอกชนิดกับขนาด
    expect(find.text('example.org'), findsOneWidget);
    expect(find.text('PDF · 512.0 KB'), findsOneWidget);
  });

  testWidgets('ครูไม่ได้แนบอะไร ต้องไม่ขึ้นหัวข้อเปล่า', (tester) async {
    await _pump(tester, loadTeacherAttachments: (_) async => const []);
    await tester.tap(find.byType(AssignmentCard));
    await tester.pumpAndSettle();

    expect(find.textContaining('เอกสารจากครู'), findsNothing);
    expect(find.textContaining('โหลดไฟล์แนบ'), findsNothing);
  });

  testWidgets('โหลดไม่สำเร็จ ต้องบอกตรง ๆ ไม่ใช่เงียบเหมือนไม่มีเอกสาร', (
    tester,
  ) async {
    await _pump(
      tester,
      loadTeacherAttachments: (_) async => throw StateError('offline'),
    );
    await tester.tap(find.byType(AssignmentCard));
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดไฟล์แนบของครูไม่สำเร็จ'), findsOneWidget);
  });

  testWidgets('แตะไฟล์ต้องขอ signed URL ด้วย courseFileId ไม่ใช่ id ของการผูก', (
    tester,
  ) async {
    String? asked;
    await _pump(
      tester,
      loadTeacherAttachments: (_) async => const [pdf],
      getTeacherFileUrl: (id) async {
        asked = id;
        return 'https://example.org/signed';
      },
    );
    await tester.tap(find.byType(AssignmentCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ใบความรู้บทที่ 3.pdf'));
    await tester.pumpAndSettle();

    // ผูกคือ att-1 แต่ไฟล์จริงในคลังคือ f-1 — ส่งผิดตัวคือโหลดไฟล์ไม่ได้
    expect(asked, 'f-1');
  });
}
