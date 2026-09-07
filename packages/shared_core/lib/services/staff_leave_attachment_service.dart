import 'dart:typed_data';

import '../models/staff_leave_attachment_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Files attached to a `staff_leave_requests` row — metadata through RPCs,
/// bytes through the private `staff-leave-attachments` bucket mediated by
/// the staff-leave-attachment-upload / -download Edge Functions (signed
/// URLs), per hard rule 3.
///
/// Backed by `20260907060000_staff_leave_attachments.sql`.
class StaffLeaveAttachmentService {
  static Future<List<StaffLeaveAttachment>> list(String leaveRequestId) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_staff_leave_attachments',
              params: {'p_token': token, 'p_leave_request_id': leaveRequestId},
            )
            as List;
    return rows
        .map(
          (row) => StaffLeaveAttachment.fromRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  /// Uploads the bytes, then records the metadata. Returns the new
  /// attachment's id. The storage path is chosen by the Edge Function from
  /// the session's school, not by this client.
  static Future<String> upload({
    required String leaveRequestId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    final uploadResponse = await supabase.functions.invoke(
      'staff-leave-attachment-upload',
      body: {
        'token': token,
        'leave_request_id': leaveRequestId,
        'file_name': fileName,
      },
    );
    final uploadData = uploadResponse.data as Map<String, dynamic>?;
    final storagePath = uploadData?['storage_path'] as String?;
    final signedToken = uploadData?['token'] as String?;
    if (storagePath == null || signedToken == null) {
      throw StateError('upload_url_unavailable');
    }

    await supabase.storage
        .from('staff-leave-attachments')
        .uploadBinaryToSignedUrl(storagePath, signedToken, bytes);

    final res = await supabase.rpc(
      'register_staff_leave_attachment',
      params: {
        'p_token': token,
        'p_leave_request_id': leaveRequestId,
        'p_storage_path': storagePath,
        'p_file_name': fileName,
        'p_size_bytes': bytes.length,
      },
    );
    final id = res?.toString() ?? '';
    if (id.isEmpty || id.toLowerCase() == 'null') {
      throw StateError('backend_attachment_id_missing');
    }
    return id;
  }

  /// A short-lived signed URL. Access is re-checked on every call.
  static Future<String> getDownloadUrl(String attachmentId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final response = await supabase.functions.invoke(
      'staff-leave-attachment-download',
      body: {'token': token, 'attachment_id': attachmentId},
    );
    final data = response.data as Map<String, dynamic>?;
    final signedUrl = data?['signed_url'] as String?;
    if (signedUrl == null) {
      throw StateError('download_url_unavailable');
    }
    return signedUrl;
  }

  /// Only while the leave request is still pending — once decided, an
  /// attachment is part of the record and cannot be removed.
  static Future<void> remove(String attachmentId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'remove_staff_leave_attachment',
      params: {'p_token': token, 'p_attachment_id': attachmentId},
    );
  }
}
