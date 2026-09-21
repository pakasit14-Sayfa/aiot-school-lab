import 'dart:typed_data';
import 'package:shared_core/shared_core.dart';

typedef SubmitAssignment =
    Future<({int version, String submissionVersionId})> Function({
      required String assignmentId,
      required String content,
    });
typedef UploadSubmissionFile =
    Future<String> Function({
      required String submissionVersionId,
      required String fileName,
      required Uint8List bytes,
    });

class SubmissionFile {
  const SubmissionFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

enum SubmissionStep {
  submit,
  confirmSubmission,
  upload,
  confirmAttachments,
  complete,
}

/// A retry resumes the same version and skips files already acknowledged.
/// Success is only exposed after the version and every attachment are read back.
class AssignmentSubmissionController {
  AssignmentSubmissionController({
    required this.assignmentId,
    required this.submit,
    required this.upload,
    required this.read,
  });
  final String assignmentId;
  final SubmitAssignment submit;
  final UploadSubmissionFile upload;
  final Future<List<SubmissionVersion>> Function(String) read;
  ({int version, String submissionVersionId})? _receipt;
  String? _content;
  List<SubmissionFile> _files = [];
  final Map<int, String> _uploaded = {};
  bool busy = false;
  bool get hasSubmitted => _receipt != null;
  SubmissionStep step = SubmissionStep.submit;

  String get retryLabel => step == SubmissionStep.upload
      ? 'ลองอัปโหลดไฟล์ที่เหลืออีกครั้ง'
      : 'ตรวจสอบผลการส่งอีกครั้ง';

  Future<SubmissionVersion> _confirmedVersion() async {
    final rows = await read(assignmentId);
    final row = rows
        .where((v) => v.submissionVersionId == _receipt!.submissionVersionId)
        .firstOrNull;
    if (row == null ||
        row.version != _receipt!.version ||
        row.content != _content) {
      throw StateError('backend_submission_not_confirmed');
    }
    return row;
  }

  Future<void> send(String content, List<SubmissionFile> files) async {
    if (busy) return;
    busy = true;
    try {
      if (_receipt == null) {
        step = SubmissionStep.submit;
        _content = content;
        _files = List.of(files);
        _receipt = await submit(assignmentId: assignmentId, content: content);
      }
      step = SubmissionStep.confirmSubmission;
      await _confirmedVersion();
      for (var i = 0; i < _files.length; i++) {
        if (_uploaded.containsKey(i)) continue;
        step = SubmissionStep.upload;
        _uploaded[i] = await upload(
          submissionVersionId: _receipt!.submissionVersionId,
          fileName: _files[i].name,
          bytes: _files[i].bytes,
        );
      }
      step = SubmissionStep.confirmAttachments;
      final confirmed = await _confirmedVersion();
      if (!_uploaded.values.every(
        (id) => confirmed.attachments.any((a) => a.id == id),
      )) {
        throw StateError('backend_submission_attachments_not_confirmed');
      }
      step = SubmissionStep.complete;
    } finally {
      busy = false;
    }
  }
}
