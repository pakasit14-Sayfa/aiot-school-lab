import '../models/timetable_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// D6 phase 2: the school admin's timetable. Every call is a
/// token-authenticated RPC from 20260919000000/20260920000000 — the token is
/// the app's own session token (hard rule 1: this project does not use
/// Supabase Auth, so `client.auth.currentSession` is always null here).
class TimetableService {
  static String _token() {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    return token;
  }

  static Future<List<Term>> listTerms() async {
    final res = await supabase.rpc('list_terms', params: {'p_token': _token()});
    return (res as List)
        .map((x) => Term.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  /// `list_school_classes` needs an academic year; when none is given, pick
  /// the year whose date range contains today (else the newest one).
  static Future<List<SchoolRoom>> listSchoolRooms({
    String? academicYearId,
  }) async {
    final token = _token();
    var yearId = academicYearId;
    if (yearId == null) {
      final years =
          (await supabase.rpc('list_academic_years', params: {'p_token': token})
                  as List)
              .cast<Map<String, dynamic>>();
      if (years.isEmpty) return const [];
      final today = DateTime.now();
      Map<String, dynamic>? current;
      for (final y in years) {
        final start = DateTime.tryParse('${y['start_date']}');
        final end = DateTime.tryParse('${y['end_date']}');
        if (start != null &&
            end != null &&
            !today.isBefore(start) &&
            !today.isAfter(end)) {
          current = y;
          break;
        }
      }
      yearId = (current ?? years.first)['id'] as String;
    }
    final res = await supabase.rpc(
      'list_school_classes',
      params: {'p_token': token, 'p_academic_year_id': yearId},
    );
    return (res as List)
        .map((x) => SchoolRoom.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SchoolPeriod>> listSchoolPeriods() async {
    final res = await supabase.rpc(
      'list_school_periods',
      params: {'p_token': _token()},
    );
    return (res as List)
        .map((x) => SchoolPeriod.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  /// `list_teacher_subjects` returns one teacher's subjects (admins must name
  /// the teacher; teachers get their own). The RPC has no full name — the
  /// UI merges it from the staff directory.
  static Future<List<TeacherSubject>> listTeacherSubjects({
    String? teacherId,
  }) async {
    final res = await supabase.rpc(
      'list_teacher_subjects',
      params: {'p_token': _token(), 'p_teacher_id': teacherId},
    );
    return (res as List)
        .map(
          (x) => TeacherSubject(
            teacherId: x['teacher_id'] as String,
            subjectName: x['subject_name'] as String,
            fullName: '',
          ),
        )
        .toList();
  }

  static Future<List<ClassSchedule>> listRoomTimetable(
    String termId,
    String gradeLevel,
    String room,
  ) async {
    final res = await supabase.rpc(
      'list_room_timetable',
      params: {
        'p_token': _token(),
        'p_term_id': termId,
        'p_grade_level': gradeLevel,
        'p_room': room,
      },
    );
    return (res as List)
        .map((x) => ClassSchedule.fromJson(x as Map<String, dynamic>))
        .toList();
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
    await supabase.rpc(
      'admin_set_room_timetable_slot',
      params: {
        'p_token': _token(),
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
    await supabase.rpc(
      'admin_clear_room_timetable_slot',
      params: {
        'p_token': _token(),
        'p_term_id': termId,
        'p_grade_level': gradeLevel,
        'p_room': room,
        'p_day_of_week': dayOfWeek,
        'p_period_no': periodNo,
      },
    );
  }
}
