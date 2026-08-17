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
}
