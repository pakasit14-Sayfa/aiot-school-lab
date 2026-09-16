import 'dart:typed_data';

import '../models/lesson_model.dart';
import '../models/school_device_identity.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Classroom & Learning — lesson authoring, materials, AIoT sensor links
/// (LRN-8) and per-student progress. Course management lives in
/// [CourseService]; both call RPCs from 20260724000000_classroom_core.sql.
class LessonService {
  static Future<SchoolDeviceIdentity?> getSchoolDeviceByCode(
    String code,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    final row = await supabase.rpc(
      'get_school_device_by_code',
      params: {'p_token': token, 'p_code': code.trim()},
    );
    return row == null
        ? null
        : SchoolDeviceIdentity.fromRow(Map<String, dynamic>.from(row as Map));
  }

  static Future<List<DeviceOption>> listSchoolDevices() async {
    final rows =
        await supabase.rpc(
              'list_school_devices',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => DeviceOption.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String> createLesson({
    required String courseId,
    required String title,
    Map<String, dynamic>? content,
  }) async {
    final rows =
        await supabase.rpc(
              'create_lesson',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
                'p_title': title.trim(),
                'p_content': content,
              },
            )
            as List;

    return (rows.first as Map<String, dynamic>)['lesson_id'] as String;
  }

  static Future<void> updateLesson({
    required String lessonId,
    String? title,
    Map<String, dynamic>? content,
  }) async {
    await supabase.rpc(
      'update_lesson',
      params: {
        'p_token': AuthService.sessionToken,
        'p_lesson_id': lessonId,
        'p_title': title?.trim(),
        'p_content': content,
      },
    );
  }

  static Future<void> publishLesson(String lessonId) async {
    await supabase.rpc(
      'publish_lesson',
      params: {'p_token': AuthService.sessionToken, 'p_lesson_id': lessonId},
    );
  }

  static Future<void> addLessonMaterial({
    required String lessonId,
    required String type,
    String? title,
    required String url,
    int sortOrder = 0,
  }) async {
    await supabase.rpc(
      'add_lesson_material',
      params: {
        'p_token': AuthService.sessionToken,
        'p_lesson_id': lessonId,
        'p_type': type,
        'p_title': title,
        'p_url': url.trim(),
        'p_sort_order': sortOrder,
      },
    );
  }

  /// Uploads real bytes to the private `lesson-materials` Storage bucket
  /// via a signed-upload URL minted by the lesson-material-upload Edge
  /// Function, then registers it as a lesson material. [type] must be
  /// one of the material_type enum values ('image', 'video', 'file') —
  /// not 'link' which is reserved for the URL-paste path.
  static Future<void> uploadMaterialFile({
    required String lessonId,
    required String fileName,
    required Uint8List bytes,
    required String type,
    int sortOrder = 0,
  }) async {
    final uploadUrlResponse = await supabase.functions.invoke(
      'lesson-material-upload',
      body: {
        'token': AuthService.sessionToken,
        'lesson_id': lessonId,
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
        .from('lesson-materials')
        .uploadBinaryToSignedUrl(storagePath, signedToken, bytes);

    await addLessonMaterial(
      lessonId: lessonId,
      type: type,
      title: fileName,
      url: storagePath,
      sortOrder: sortOrder,
    );
  }

  /// Resolves an uploaded material (type != 'link') to a short-lived
  /// signed download URL. External link materials should be launched
  /// directly using their stored url instead of calling this.
  static Future<String> getMaterialDownloadUrl(String materialId) async {
    final response = await supabase.functions.invoke(
      'lesson-material-download',
      body: {'token': AuthService.sessionToken, 'material_id': materialId},
    );
    final data = response.data as Map<String, dynamic>?;
    final signedUrl = data?['signed_url'] as String?;
    if (signedUrl == null) {
      throw Exception('download_url_unavailable');
    }
    return signedUrl;
  }

  static Future<void> linkLessonSensor({
    required String lessonId,
    required String deviceId,
    required String metric,
    DateTime? timeStart,
    DateTime? timeEnd,
    String? caption,
  }) async {
    await supabase.rpc(
      'link_lesson_sensor',
      params: {
        'p_token': AuthService.sessionToken,
        'p_lesson_id': lessonId,
        'p_device_id': deviceId,
        'p_metric': metric,
        'p_time_start': timeStart?.toUtc().toIso8601String(),
        'p_time_end': timeEnd?.toUtc().toIso8601String(),
        'p_caption': caption,
      },
    );
  }

  static Future<List<LessonSummary>> listLessons(String courseId) async {
    final rows =
        await supabase.rpc(
              'list_lessons',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => LessonSummary.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<LessonDetail> getLesson(String lessonId) async {
    final rows =
        await supabase.rpc(
              'get_lesson',
              params: {
                'p_token': AuthService.sessionToken,
                'p_lesson_id': lessonId,
              },
            )
            as List;

    if (rows.isEmpty) {
      throw Exception('lesson_not_found');
    }
    return LessonDetail.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<void> updateProgress({
    required String lessonId,
    required num progressPct,
  }) async {
    await supabase.rpc(
      'update_lesson_progress',
      params: {
        'p_token': AuthService.sessionToken,
        'p_lesson_id': lessonId,
        'p_progress_pct': progressPct,
      },
    );
  }

  /// Teacher/school_admin: per-student progress of one lesson, one row per
  /// enrolled student (0% for students who never opened it).
  static Future<List<LessonStudentProgress>> listProgress(
    String lessonId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_lesson_progress',
              params: {
                'p_token': AuthService.sessionToken,
                'p_lesson_id': lessonId,
              },
            )
            as List;
    return rows
        .map((r) => LessonStudentProgress.fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> markComplete(String lessonId) async {
    await supabase.rpc(
      'mark_lesson_complete',
      params: {'p_token': AuthService.sessionToken, 'p_lesson_id': lessonId},
    );
  }
}
