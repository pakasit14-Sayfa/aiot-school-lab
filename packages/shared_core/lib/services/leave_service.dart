import 'dart:typed_data';

import '../models/leave_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class LeaveService {
  static Future<List<LeaveRequestForReview>> listPendingLeaveRequests({
    String? status = 'pending',
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_leave_requests_for_review',
              params: {'p_token': token, 'p_status': status},
            )
            as List;

    return rows
        .map(
          (row) => LeaveRequestForReview.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<List<MyLeaveRequestItem>> listMyLeaveRequests(
    String studentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_my_leave_requests',
              params: {'p_token': token, 'p_student_id': studentId},
            )
            as List;

    return rows
        .map((row) => MyLeaveRequestItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> reviewLeaveRequest({
    required String leaveId,
    required String status,
    String? reviewNote,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    await supabase.rpc(
      'review_leave_request',
      params: {
        'p_token': token,
        'p_leave_id': leaveId,
        'p_status': status,
        'p_review_note': reviewNote,
      },
    );
  }

  /// Uploads real bytes to the private `leave_attachments` Storage
  /// bucket via a signed-upload URL minted by the
  /// leave-attachment-upload Edge Function. Returns the storage path
  /// (not a public URL — the bucket is private).
  static Future<String> uploadLeaveAttachment({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    final uploadUrlResponse = await supabase.functions.invoke(
      'leave-attachment-upload',
      body: {'token': token, 'file_name': fileName},
    );
    final uploadData = uploadUrlResponse.data as Map<String, dynamic>?;
    final storagePath = uploadData?['storage_path'] as String?;
    final signedToken = uploadData?['token'] as String?;
    if (storagePath == null || signedToken == null) {
      throw Exception('upload_url_unavailable');
    }

    await supabase.storage
        .from('leave_attachments')
        .uploadBinaryToSignedUrl(storagePath, signedToken, bytes);

    return storagePath;
  }

  /// Resolves a leave request's attachment to a short-lived signed
  /// download URL. Works for the parent who submitted it or a
  /// teacher/school_admin/executive of the same school.
  static Future<String> getAttachmentDownloadUrl(String leaveId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    final response = await supabase.functions.invoke(
      'leave-attachment-download',
      body: {'token': token, 'leave_id': leaveId},
    );
    final data = response.data as Map<String, dynamic>?;
    final signedUrl = data?['signed_url'] as String?;
    if (signedUrl == null) {
      throw Exception('download_url_unavailable');
    }
    return signedUrl;
  }
}
