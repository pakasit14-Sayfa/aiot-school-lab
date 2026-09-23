import 'dart:typed_data';

import '../models/course_file_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// คลังความรู้ของรายวิชา — metadata ผ่าน RPC, ไบต์ของไฟล์ผ่านถัง `course-files`
/// ที่เข้าถึงด้วย signed URL จาก Edge Function course-file-upload/-download
///
/// 2026-09-23: คลังรับลิงก์ด้วย และรับ "หมวด" ที่เดิมกรอกแล้วหายทุกครั้ง
class CourseFileService {
  static Future<List<CourseFile>> listFiles(String courseId) async {
    final rows =
        await supabase.rpc(
              'list_course_files',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => CourseFile.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// คืน id ของแถวในคลัง เพื่อให้ผู้เรียกเอาไปผูกกับใบงานต่อได้ทันที
  static Future<String> uploadFile({
    required String courseId,
    required String fileName,
    required Uint8List bytes,
    String? category,
  }) async {
    final uploadUrlResponse = await supabase.functions.invoke(
      'course-file-upload',
      body: {
        'token': AuthService.sessionToken,
        'course_id': courseId,
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
        .from('course-files')
        .uploadBinaryToSignedUrl(storagePath, signedToken, bytes);

    final rows =
        await supabase.rpc(
              'register_course_file',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
                'p_storage_path': storagePath,
                'p_file_name': fileName,
                'p_size_bytes': bytes.length,
                'p_category': category,
              },
            )
            as List;
    final id =
        (rows.firstOrNull as Map<String, dynamic>?)?['file_id'] as String?;
    if (id == null) throw StateError('backend_file_id_missing');
    return id;
  }

  static Future<String> addLink({
    required String courseId,
    required String url,
    String? title,
    String? category,
  }) async {
    final rows =
        await supabase.rpc(
              'register_course_link',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
                'p_url': url,
                'p_title': title,
                'p_category': category,
              },
            )
            as List;
    final id =
        (rows.firstOrNull as Map<String, dynamic>?)?['file_id'] as String?;
    if (id == null) throw StateError('backend_file_id_missing');
    return id;
  }

  /// ชื่อกับหมวดเป็นของตัวไฟล์ในคลัง แก้ที่นี่เปลี่ยนทุกใบงานที่อ้างถึง
  static Future<void> updateFile({
    required String fileId,
    String? fileName,
    String? category,
    String? url,
  }) async {
    await supabase.rpc(
      'update_course_file',
      params: {
        'p_token': AuthService.sessionToken,
        'p_file_id': fileId,
        'p_file_name': fileName,
        'p_category': category,
        'p_url': url,
      },
    );
  }

  /// ลบถาวร — ของที่ยังมีใบงานอ้างอยู่จะโยน `file_in_use_by_N assignments`
  static Future<void> deleteFile(String fileId) async {
    await supabase.rpc(
      'delete_course_file',
      params: {'p_token': AuthService.sessionToken, 'p_file_id': fileId},
    );
  }

  static Future<String> getDownloadUrl(String fileId) async {
    final response = await supabase.functions.invoke(
      'course-file-download',
      body: {'token': AuthService.sessionToken, 'file_id': fileId},
    );
    final data = response.data as Map<String, dynamic>?;
    final signedUrl = data?['signed_url'] as String?;
    if (signedUrl == null) {
      throw Exception('download_url_unavailable');
    }
    return signedUrl;
  }

  // ── ไฟล์แนบของใบงาน ────────────────────────────────────────────────

  static Future<List<AssignmentAttachment>> listAttachments(
    String assignmentId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_assignment_attachments',
              params: {
                'p_token': AuthService.sessionToken,
                'p_assignment_id': assignmentId,
              },
            )
            as List;
    return rows
        .map((r) => AssignmentAttachment.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  static Future<String> attach({
    required String assignmentId,
    required String courseFileId,
    int? sortOrder,
  }) async {
    final rows =
        await supabase.rpc(
              'attach_assignment_file',
              params: {
                'p_token': AuthService.sessionToken,
                'p_assignment_id': assignmentId,
                'p_course_file_id': courseFileId,
                'p_sort_order': sortOrder,
              },
            )
            as List;
    final id =
        (rows.firstOrNull as Map<String, dynamic>?)?['attachment_id']
            as String?;
    if (id == null) throw StateError('backend_attachment_id_missing');
    return id;
  }

  /// เอาออกจากใบงาน ไม่ใช่ลบไฟล์ — ไฟล์ยังอยู่ในคลัง
  static Future<void> detach(String attachmentId) async {
    await supabase.rpc(
      'detach_assignment_file',
      params: {
        'p_token': AuthService.sessionToken,
        'p_attachment_id': attachmentId,
      },
    );
  }

  static Future<void> reorder({
    required String attachmentId,
    required int sortOrder,
  }) async {
    await supabase.rpc(
      'reorder_assignment_attachment',
      params: {
        'p_token': AuthService.sessionToken,
        'p_attachment_id': attachmentId,
        'p_sort_order': sortOrder,
      },
    );
  }
}
