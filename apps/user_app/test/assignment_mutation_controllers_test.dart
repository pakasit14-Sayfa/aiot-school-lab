import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/assignments/assignment_save_controller.dart';
import 'package:my_first_app/pages/assignments/assignment_submission_controller.dart';

void main() {
  test(
    'save retry after read failure reuses created assignment and rejects stale values',
    () async {
      var creates = 0;
      var updates = 0;
      var title = 'stale';
      final c = AssignmentSaveController(
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
              creates++;
              return 'a';
            },
        update:
            ({
              required assignmentId,
              title,
              instructions,
              dueAt,
              rubricId,
              isGroup,
            }) async {
              expect(assignmentId, 'a');
              updates++;
            },
        publish: (_) async {},
        read: (_) async => [
          AssignmentSummary(
            id: 'a',
            type: 'homework',
            title: title,
            instructions: 'body',
            dueAt: DateTime.utc(2027),
            status: 'published',
          ),
        ],
      );
      Future<void> save() => c.save(
        courseId: 'c',
        type: 'homework',
        title: 'new',
        instructions: 'body',
        dueAt: DateTime.utc(2027),
        rubricId: null,
        isGroup: false,
        publishNow: true,
      );
      await expectLater(save(), throwsStateError);
      title = 'new';
      await save();
      expect(creates, 1);
      expect(updates, 1);
    },
  );

  test('published request is not confirmed by a draft row', () async {
    final c = AssignmentSaveController(
      create:
          ({
            required courseId,
            required type,
            required title,
            instructions,
            dueAt,
            rubricId,
            isGroup = false,
          }) async => 'a',
      update:
          ({
            required assignmentId,
            title,
            instructions,
            dueAt,
            rubricId,
            isGroup,
          }) async {},
      publish: (_) async {},
      read: (_) async => [
        const AssignmentSummary(
          id: 'a',
          type: 'homework',
          title: 'new',
          instructions: '',
          dueAt: null,
          status: 'draft',
        ),
      ],
    );
    await expectLater(
      c.save(
        courseId: 'c',
        type: 'homework',
        title: 'new',
        instructions: '',
        dueAt: null,
        rubricId: null,
        isGroup: false,
        publishNow: true,
      ),
      throwsStateError,
    );
  });

  test(
    'retry confirmation never creates another submission or reuploads acknowledged attachments',
    () async {
      var submits = 0;
      var uploads = 0;
      var showAttachment = false;
      final c = AssignmentSubmissionController(
        assignmentId: 'a',
        submit: ({required assignmentId, required content}) async {
          submits++;
          return (version: 2, submissionVersionId: 'v');
        },
        upload:
            ({
              required submissionVersionId,
              required fileName,
              required bytes,
            }) async {
              uploads++;
              return 'attachment';
            },
        read: (_) async => [
          SubmissionVersion(
            version: 2,
            content: 'answer',
            submittedAt: DateTime(2026),
            submissionVersionId: 'v',
            attachments: showAttachment
                ? [const SubmissionAttachment(id: 'attachment')]
                : [],
          ),
        ],
      );
      final files = [
        SubmissionFile('file', Uint8List.fromList([1])),
      ];
      await expectLater(c.send('answer', files), throwsStateError);
      expect(c.step, SubmissionStep.confirmAttachments);
      showAttachment = true;
      await c.send('answer', files);
      expect(submits, 1);
      expect(uploads, 1);
      expect(c.step, SubmissionStep.complete);
    },
  );

  test('double tap while submitting calls backend once', () async {
    var submits = 0;
    final receipt = Completer<({int version, String submissionVersionId})>();
    final c = AssignmentSubmissionController(
      assignmentId: 'a',
      submit: ({required assignmentId, required content}) {
        submits++;
        return receipt.future;
      },
      upload:
          ({
            required submissionVersionId,
            required fileName,
            required bytes,
          }) async => 'unused',
      read: (_) async => [
        SubmissionVersion(
          version: 1,
          content: 'answer',
          submittedAt: DateTime(2026),
          submissionVersionId: 'v',
        ),
      ],
    );
    final first = c.send('answer', []);
    await c.send('answer', []);
    receipt.complete((version: 1, submissionVersionId: 'v'));
    await first;
    expect(submits, 1);
  });
}
