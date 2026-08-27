import 'dart:typed_data';

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

  static Future<({int version, String submissionVersionId})>
  submitAssignment({required String assignmentId, required String content}) async {
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

    final row = rows.first as Map<String, dynamic>;
    return (
      version: row['version'] as int,
      submissionVersionId: row['submission_version_id'] as String,
    );
  }

  /// Uploads real bytes to the private `submission-attachments` Storage
  /// bucket via a signed-upload URL minted by the
  /// submission-attachment-upload Edge Function, then registers it
  /// against the submission version.
  static Future<String> uploadSubmissionAttachment({
    required String submissionVersionId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    final uploadUrlResponse = await supabase.functions.invoke(
      'submission-attachment-upload',
      body: {
        'token': token,
        'submission_version_id': submissionVersionId,
        'file_name': fileName,
      },
    );
    final uploadData = uploadUrlResponse.data as Map<String, dynamic>?;
    final storagePath = uploadData?['storage_path'] as String?;
    final signedToken = uploadData?['token'] as String?;
    if (storagePath == null || signedToken == null) {
      throw Exception('upload_url_unavailable');
    }

    await supabase.storage
        .from('submission-attachments')
        .uploadBinaryToSignedUrl(storagePath, signedToken, bytes);

    final rows =
        await supabase.rpc(
              'add_submission_attachment',
              params: {
                'p_token': token,
                'p_submission_version_id': submissionVersionId,
                'p_storage_path': storagePath,
                'p_file_name': fileName,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['attachment_id'] as String;
  }

  /// Resolves a submission attachment to a short-lived signed download URL.
  static Future<String> getSubmissionAttachmentDownloadUrl(
    String attachmentId,
  ) async {
    final response = await supabase.functions.invoke(
      'submission-attachment-download',
      body: {
        'token': AuthService.sessionToken,
        'attachment_id': attachmentId,
      },
    );
    final data = response.data as Map<String, dynamic>?;
    final signedUrl = data?['signed_url'] as String?;
    if (signedUrl == null) {
      throw Exception('download_url_unavailable');
    }
    return signedUrl;
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
