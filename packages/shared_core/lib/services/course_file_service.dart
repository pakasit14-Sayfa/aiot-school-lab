import 'dart:typed_data';

import '../models/course_file_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Course files — metadata via [list_course_files]/[register_course_file],
/// bytes via the private `course-files` Storage bucket mediated by the
/// course-file-upload/course-file-download Edge Functions (signed URLs).
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

  static Future<void> uploadFile({
    required String courseId,
    required String fileName,
    required Uint8List bytes,
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

    await supabase.rpc(
      'register_course_file',
      params: {
        'p_token': AuthService.sessionToken,
        'p_course_id': courseId,
        'p_storage_path': storagePath,
        'p_file_name': fileName,
        'p_size_bytes': bytes.length,
      },
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
}
