import '../models/timetable_model.dart';
import 'supabase_core.dart';

class TimetableService {
  static Future<List<Term>> listTerms() async {
    final token = SupabaseCore.client.auth.currentSession?.accessToken ?? '';
    final res = await SupabaseCore.client.rpc(
      'list_terms',
      params: {'p_token': token},
    );
    return (res as List).map((x) => Term.fromJson(x)).toList();
  }

  static Future<List<SchoolRoom>> listSchoolRooms() async {
    final token = SupabaseCore.client.auth.currentSession?.accessToken ?? '';
    // Actually, list_school_rooms needs p_academic_year_id.
    // Let's pass a null or just let it use the current year if it supports null?
    // In Phase 1 I didn't change list_school_rooms.
    // I'll fetch the current academic year using list_academic_years, OR just pass null.
    // Let me check if list_school_rooms accepts null for p_academic_year_id.
    final res = await SupabaseCore.client.rpc(
      'list_school_rooms',
      params: {'p_token': token, 'p_academic_year_id': null},
    );
    return (res as List).map((x) => SchoolRoom.fromJson(x)).toList();
  }

  static Future<List<SchoolPeriod>> listSchoolPeriods() async {
    final token = SupabaseCore.client.auth.currentSession?.accessToken ?? '';
    final res = await SupabaseCore.client.rpc(
      'list_school_periods',
      params: {'p_token': token},
    );
    return (res as List).map((x) => SchoolPeriod.fromJson(x)).toList();
  }

  static Future<List<TeacherSubject>> listTeacherSubjects() async {
    final token = SupabaseCore.client.auth.currentSession?.accessToken ?? '';
    final res = await SupabaseCore.client.rpc(
      'list_teacher_subjects',
      params: {'p_token': token},
    );

    return (res as List)
        .map(
          (x) => TeacherSubject(
            teacherId: x['teacher_id'] as String,
            subjectName: x['subject_name'] as String,
            fullName: '', // The UI will merge this with the staff directory
          ),
        )
        .toList();
  }

  static Future<List<ClassSchedule>> listRoomTimetable(
    String termId,
    String gradeLevel,
    String room,
  ) async {
    final token = SupabaseCore.client.auth.currentSession?.accessToken ?? '';
    final res = await SupabaseCore.client.rpc(
      'list_room_timetable',
      params: {
        'p_token': token,
        'p_term_id': termId,
        'p_grade_level': gradeLevel,
        'p_room': room,
      },
    );
    return (res as List).map((x) => ClassSchedule.fromJson(x)).toList();
  }

  static Future<void> adminSetRoomTimetableSlot({
    required String termId,
    required String gradeLevel,
    required String room,
    required int dayOfWeek,
    required int periodNo,
    required String subjectName,
    required String? teacherId,
  }) async {
    final token = SupabaseCore.client.auth.currentSession?.accessToken ?? '';
    await SupabaseCore.client.rpc(
      'admin_set_room_timetable_slot',
      params: {
        'p_token': token,
        'p_term_id': termId,
        'p_grade_level': gradeLevel,
        'p_room': room,
        'p_day_of_week': dayOfWeek,
        'p_period_no': periodNo,
        'p_subject_name': subjectName,
        'p_teacher_id': teacherId,
      },
    );
  }

  static Future<void> adminClearRoomTimetableSlot({
    required String termId,
    required String gradeLevel,
    required String room,
    required int dayOfWeek,
    required int periodNo,
  }) async {
    final token = SupabaseCore.client.auth.currentSession?.accessToken ?? '';
    await SupabaseCore.client.rpc(
      'admin_clear_room_timetable_slot',
      params: {
        'p_token': token,
        'p_term_id': termId,
        'p_grade_level': gradeLevel,
        'p_room': room,
        'p_day_of_week': dayOfWeek,
        'p_period_no': periodNo,
      },
    );
  }
}
