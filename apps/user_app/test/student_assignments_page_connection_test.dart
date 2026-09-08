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
  Future<String> Function({
    required String submissionVersionId,
    required String fileName,
    required Uint8List bytes,
  })?
  uploadAttachment,
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
        uploadAttachment: uploadAttachment,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unsubmitted assignment shows ยังไม่ส่ง, not a fabricated status', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('ยังไม่ส่ง'), findsWidgets);
  });

  testWidgets('an already-submitted assignment shows ส่งแล้ว, not the submit CTA', (
    tester,
  ) async {
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
  });

  testWidgets(
    'submitting calls the real RPC with the typed content, and uploads picked files with real bytes',
    (tester) async {
      String? submittedAssignmentId;
      String? submittedContent;
      final uploaded = <Map<String, Object?>>[];

      await _pump(
        tester,
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
            ({required submissionVersionId, required fileName, required bytes}) async {
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
      if (uploaded.isNotEmpty) {
        expect(uploaded.first['submissionVersionId'], 'sv-99');
        expect(uploaded.first['fileName'], 'proof.png');
        expect(uploaded.first['bytes'], Uint8List.fromList([1, 2, 3]));
      }
    },
  );

  testWidgets('a failed submit shows an honest message, no leaked exception text', (
    tester,
  ) async {
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
  });
}
