import 'package:shared_core/shared_core.dart';

typedef CreateAssignment =
    Future<String> Function({
      required String courseId,
      required String type,
      required String title,
      String? instructions,
      DateTime? dueAt,
      String? rubricId,
      bool isGroup,
    });
typedef UpdateAssignment =
    Future<void> Function({
      required String assignmentId,
      String? title,
      String? instructions,
      DateTime? dueAt,
      String? rubricId,
      bool? isGroup,
    });

/// Keeps the created id across a failed publish/readback, so retrying a
/// partially completed save does not create a second assignment.
class AssignmentSaveController {
  AssignmentSaveController({
    required this.create,
    required this.update,
    required this.publish,
    required this.read,
    String? assignmentId,
  }) : _assignmentId = assignmentId;

  final CreateAssignment create;
  final UpdateAssignment update;
  final Future<void> Function(String) publish;
  final Future<List<AssignmentSummary>> Function(String) read;
  String? _assignmentId;
  bool busy = false;
  bool hasWritten = false;

  /// id ของใบงานที่เขียนไปแล้ว — ผู้เรียกต้องใช้ผูกไฟล์แนบหลังบันทึกสำเร็จ
  /// (ใบงานใหม่เพิ่งมี id ตอนนี้เอง) null = ยังไม่เคยเขียนอะไรลงไป
  String? get assignmentId => _assignmentId;

  Future<AssignmentSummary> save({
    required String courseId,
    required String type,
    required String title,
    required String instructions,
    required DateTime? dueAt,
    required String? rubricId,
    required bool isGroup,
    required bool publishNow,
  }) async {
    if (busy) throw StateError('assignment_save_in_progress');
    busy = true;
    try {
      if (_assignmentId == null) {
        _assignmentId = await create(
          courseId: courseId,
          type: type,
          title: title,
          instructions: instructions,
          dueAt: dueAt,
          rubricId: rubricId,
          isGroup: isGroup,
        );
        if (_assignmentId!.trim().isEmpty) {
          throw StateError('backend_assignment_id_missing');
        }
      } else {
        await update(
          assignmentId: _assignmentId!,
          title: title,
          instructions: instructions,
          dueAt: dueAt,
          rubricId: rubricId,
          isGroup: isGroup,
        );
      }
      hasWritten = true;
      if (publishNow) await publish(_assignmentId!);
      final rows = await read(courseId);
      final row = rows.where((a) => a.id == _assignmentId).firstOrNull;
      final dueMatches = row?.dueAt == null
          ? dueAt == null
          : dueAt != null && row!.dueAt!.isAtSameMomentAs(dueAt);
      if (row == null ||
          row.title != title ||
          (row.instructions ?? '') != instructions ||
          !dueMatches ||
          row.rubricId != rubricId ||
          row.isGroup != isGroup ||
          (publishNow && !row.isPublished)) {
        throw StateError('backend_assignment_not_confirmed');
      }
      return row;
    } finally {
      busy = false;
    }
  }
}
