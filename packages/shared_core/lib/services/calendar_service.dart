import '../models/calendar_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// ตารางเรียนจริงต่อวิชา + แพลนงานส่วนตัวของนักเรียน. RPCs from
/// 20260818010000_calendar.sql. Teacher-side schedule-editing RPCs exist for
/// completeness but there's no schedule-editing UI yet — only the
/// student-facing read + personal-task CRUD flow is wired in the app.
class CalendarService {
  static Future<List<ClassScheduleSlot>> listMySchedule() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc('list_my_schedule', params: {'p_token': token})
            as List;
    return rows
        .map((row) => ClassScheduleSlot.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PersonalTask>> listMyPersonalTasks() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc('list_my_personal_tasks', params: {'p_token': token})
            as List;
    return rows
        .map((row) => PersonalTask.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createPersonalTask({
    required String title,
    String? note,
    DateTime? dueAt,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'create_personal_task',
      params: {
        'p_token': token,
        'p_title': title,
        'p_note': note,
        'p_due_at': dueAt?.toIso8601String(),
      },
    );
  }

  static Future<void> togglePersonalTask({
    required String taskId,
    required bool done,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'toggle_personal_task',
      params: {'p_token': token, 'p_task_id': taskId, 'p_done': done},
    );
  }

  static Future<void> deletePersonalTask(String taskId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'delete_personal_task',
      params: {'p_token': token, 'p_task_id': taskId},
    );
  }

  static Future<String> setClassSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'set_class_schedule',
              params: {
                'p_token': token,
                'p_course_id': courseId,
                'p_day_of_week': dayOfWeek,
                'p_start_time': startTime,
                'p_end_time': endTime,
                'p_room': room,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['schedule_id'] as String;
  }

  static Future<void> removeClassSchedule(String scheduleId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'remove_class_schedule',
      params: {'p_token': token, 'p_schedule_id': scheduleId},
    );
  }

  static Future<List<ClassScheduleSlot>> listTeacherSchedules({
    String? courseId,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final params = <String, dynamic>{'p_token': token};
    if (courseId != null) params['p_course_id'] = courseId;
    final rows =
        await supabase.rpc('list_teacher_schedules', params: params) as List;
    return rows
        .map((row) => ClassScheduleSlot.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
