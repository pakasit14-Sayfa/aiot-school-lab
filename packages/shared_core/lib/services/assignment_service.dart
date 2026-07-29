import '../models/assignment_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Assignments (PBL) — individual submissions only, free resubmission via
/// versioned history. RPCs from 20260731000000_assignments_core.sql.
class AssignmentService {
  static Future<String> createAssignment({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
  }) async {
    final rows =
        await supabase.rpc(
              'create_assignment',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
                'p_type': type,
                'p_title': title.trim(),
                'p_instructions': instructions,
                'p_due_at': dueAt?.toUtc().toIso8601String(),
              },
            )
            as List;

    return (rows.first as Map<String, dynamic>)['assignment_id'] as String;
  }

  static Future<void> updateAssignment({
    required String assignmentId,
    String? title,
    String? instructions,
    DateTime? dueAt,
  }) async {
    await supabase.rpc(
      'update_assignment',
      params: {
        'p_token': AuthService.sessionToken,
        'p_assignment_id': assignmentId,
        'p_title': title?.trim(),
        'p_instructions': instructions,
        'p_due_at': dueAt?.toUtc().toIso8601String(),
      },
    );
  }

  static Future<void> publishAssignment(String assignmentId) async {
    await supabase.rpc(
      'publish_assignment',
      params: {
        'p_token': AuthService.sessionToken,
        'p_assignment_id': assignmentId,
      },
    );
  }

  static Future<void> linkSensorDataset({
    required String assignmentId,
    required String deviceId,
    required String metric,
    DateTime? timeStart,
    DateTime? timeEnd,
    String? label,
  }) async {
    await supabase.rpc(
      'link_assignment_sensor_dataset',
      params: {
        'p_token': AuthService.sessionToken,
        'p_assignment_id': assignmentId,
        'p_device_id': deviceId,
        'p_metric': metric,
        'p_time_start': timeStart?.toUtc().toIso8601String(),
        'p_time_end': timeEnd?.toUtc().toIso8601String(),
        'p_label': label,
      },
    );
  }

  static Future<List<AssignmentSummary>> listAssignments(
    String courseId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_assignments',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => AssignmentSummary.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<AssignmentDetail> getAssignment(String assignmentId) async {
    final rows =
        await supabase.rpc(
              'get_assignment',
              params: {
                'p_token': AuthService.sessionToken,
                'p_assignment_id': assignmentId,
              },
            )
            as List;

    if (rows.isEmpty) {
      throw Exception('assignment_not_found');
    }
    return AssignmentDetail.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<int> submitAssignment({
    required String assignmentId,
    required String content,
  }) async {
    final rows =
        await supabase.rpc(
              'submit_assignment',
              params: {
                'p_token': AuthService.sessionToken,
                'p_assignment_id': assignmentId,
                'p_content': content,
              },
            )
            as List;

    return (rows.first as Map<String, dynamic>)['version'] as int;
  }

  static Future<List<SubmissionVersion>> listMySubmissionVersions(
    String assignmentId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_my_submission_versions',
              params: {
                'p_token': AuthService.sessionToken,
                'p_assignment_id': assignmentId,
              },
            )
            as List;

    return rows
        .map((row) => SubmissionVersion.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SubmissionRoster>> listSubmissions(
    String assignmentId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_submissions',
              params: {
                'p_token': AuthService.sessionToken,
                'p_assignment_id': assignmentId,
              },
            )
            as List;

    return rows
        .map((row) => SubmissionRoster.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> giveFeedback({
    required String submissionId,
    required String body,
  }) async {
    await supabase.rpc(
      'give_feedback',
      params: {
        'p_token': AuthService.sessionToken,
        'p_submission_id': submissionId,
        'p_body': body.trim(),
      },
    );
  }

  static Future<List<AssignmentFeedback>> listFeedback(
    String submissionId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_feedback',
              params: {
                'p_token': AuthService.sessionToken,
                'p_submission_id': submissionId,
              },
            )
            as List;

    return rows
        .map((row) => AssignmentFeedback.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
