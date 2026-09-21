import '../models/calendar_model.dart';
import '../models/parent_portal_model.dart' show CalendarEventItem;
import 'auth_service.dart';
import 'supabase_config.dart';

/// ตารางเรียนจริงต่อวิชา + แพลนงานส่วนตัวของนักเรียน. RPCs from
/// 20260818010000_calendar.sql, `period_type` from
/// 20260910160000_teacher_workload_categories.sql. Teacher-side
/// schedule-editing is wired into `teacher_class_schedule_page.dart`.
class CalendarService {
  /// School-wide calendar entries (`list_calendar_events`).
  ///
  /// The RPC has no role gate of its own — it only validates the session and
  /// resolves the caller's school — so every role can read its own school's
  /// calendar. `p_student_id` narrows it to one student's classes and is left
  /// null for a school-wide view.
  ///
  /// It was previously only reachable through `ParentPortalService`, which is
  /// why the executive calendar page fell back to hardcoded events.
  static Future<List<CalendarEventItem>> listSchoolCalendarEvents() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_calendar_events',
              params: {'p_token': token, 'p_student_id': null},
            )
            as List;
    return rows
        .map(
          (row) =>
              CalendarEventItem.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  /// school_admin/super_admin: add a school-wide calendar event
  /// (`create_school_event`). Until 2026-09-17 this RPC had no caller — every
  /// role's calendar read school_events but nothing could add to it.
  /// `eventType` ∈ holiday · public_holiday · exam · activity · study.
  static Future<String> createSchoolEvent({
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    String? description,
    String eventType = 'activity',
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('invalid_session');
    String d(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final id = await supabase.rpc(
      'create_school_event',
      params: {
        'p_token': token,
        'p_title': title.trim(),
        'p_start_date': d(startDate),
        'p_end_date': endDate == null ? null : d(endDate),
        'p_location': location?.trim().isEmpty ?? true ? null : location!.trim(),
        'p_description':
            description?.trim().isEmpty ?? true ? null : description!.trim(),
        'p_event_type': eventType,
      },
    );
    return id as String;
  }

  /// school_admin/super_admin: remove an event (`delete_school_event`,
  /// 20260917020000).
  static Future<void> deleteSchoolEvent(String eventId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('invalid_session');
    await supabase.rpc(
      'delete_school_event',
      params: {'p_token': token, 'p_event_id': eventId},
    );
  }

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
    String periodType = 'regular',
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
                'p_period_type': periodType,
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
