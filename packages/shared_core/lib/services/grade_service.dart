import '../models/grade_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Grades — Slice 3 manual grade entry (independent of Assignments/Quizzes,
/// which don't exist yet). See supabase/migrations/20260730010000_grades_core.sql.
///
/// CoI handling: `coiFlag` on [GradeRecord] is system-owned — the API never
/// exposes a way to clear it. A teacher can still confirm a CoI-flagged
/// grade (Decision Log permits this); School Admin separately reviews it
/// via [listPendingCoiGrades]/[reviewCoiGrade].
class GradeService {
  static Future<String> createGrade({
    required String studentId,
    required String courseId,
    required num score,
    required num maxScore,
  }) async {
    final rows =
        await supabase.rpc(
              'create_grade',
              params: {
                'p_token': AuthService.sessionToken,
                'p_student_id': studentId,
                'p_course_id': courseId,
                'p_score': score,
                'p_max_score': maxScore,
              },
            )
            as List;

    return (rows.first as Map<String, dynamic>)['grade_id'] as String;
  }

  static Future<void> updateGrade({
    required String gradeId,
    required num score,
    required num maxScore,
  }) async {
    await supabase.rpc(
      'update_grade',
      params: {
        'p_token': AuthService.sessionToken,
        'p_grade_id': gradeId,
        'p_score': score,
        'p_max_score': maxScore,
      },
    );
  }

  static Future<void> confirmGrade(String gradeId) async {
    await supabase.rpc(
      'confirm_grade',
      params: {'p_token': AuthService.sessionToken, 'p_grade_id': gradeId},
    );
  }

  static Future<List<GradeRecord>> listCourseGrades(String courseId) async {
    final rows =
        await supabase.rpc(
              'list_course_grades',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => GradeRecord.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CourseGrade>> listMyGrades() async {
    final rows =
        await supabase.rpc(
              'list_my_grades',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => CourseGrade.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PendingCoiGrade>> listPendingCoiGrades() async {
    final rows =
        await supabase.rpc(
              'list_pending_coi_grades',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => PendingCoiGrade.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> reviewCoiGrade(String gradeId) async {
    await supabase.rpc(
      'review_coi_grade',
      params: {'p_token': AuthService.sessionToken, 'p_grade_id': gradeId},
    );
  }
}
