import '../models/lesson_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Classroom & Learning — lesson authoring, materials, AIoT sensor links
/// (LRN-8) and per-student progress. Course management lives in
/// [CourseService]; both call RPCs from 20260724000000_classroom_core.sql.
class LessonService {
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

  static Future<void> markComplete(String lessonId) async {
    await supabase.rpc(
      'mark_lesson_complete',
      params: {'p_token': AuthService.sessionToken, 'p_lesson_id': lessonId},
    );
  }
}
