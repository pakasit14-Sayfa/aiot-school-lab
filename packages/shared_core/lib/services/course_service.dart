import '../models/course_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Classroom & Learning — course management (create/edit, roster).
/// Lessons live in [LessonService]; both call the same `courses`/
/// `course_teachers`/`course_students` RPCs added in
/// 20260724000000_classroom_core.sql.
class CourseService {
  static Future<StudentLookup?> findStudentByEmail(String email) async {
    final rows =
        await supabase.rpc(
              'find_student_by_email',
              params: {
                'p_token': AuthService.sessionToken,
                'p_email': email.trim(),
              },
            )
            as List;

    if (rows.isEmpty) return null;
    return StudentLookup.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<List<TermOption>> listTerms() async {
    final rows =
        await supabase.rpc(
              'list_terms',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => TermOption.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String> createCourse({
    required String termId,
    required String subjectName,
    String? gradeLevel,
    String? room,
    String? description,
    String? teacherId,
  }) async {
    final rows =
        await supabase.rpc(
              'create_course',
              params: {
                'p_token': AuthService.sessionToken,
                'p_term_id': termId,
                'p_subject_name': subjectName.trim(),
                'p_grade_level': gradeLevel,
                'p_room': room,
                'p_description': description,
                'p_teacher_id': teacherId,
              },
            )
            as List;

    return (rows.first as Map<String, dynamic>)['course_id'] as String;
  }

  static Future<void> updateCourse({
    required String courseId,
    String? subjectName,
    String? gradeLevel,
    String? room,
    String? description,
  }) async {
    await supabase.rpc(
      'update_course',
      params: {
        'p_token': AuthService.sessionToken,
        'p_course_id': courseId,
        'p_subject_name': subjectName?.trim(),
        'p_grade_level': gradeLevel,
        'p_room': room,
        'p_description': description,
      },
    );
  }

  /// Real course close (see close_course in
  /// supabase/migrations/20260826170000_teacher_close_course_update_rubric.sql)
  static Future<void> closeCourse(String courseId) async {
    await supabase.rpc(
      'close_course',
      params: {'p_token': AuthService.sessionToken, 'p_course_id': courseId},
    );
  }

  static Future<List<CourseSummary>> listMyCourses() async {
    final rows =
        await supabase.rpc(
              'list_my_courses',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => CourseSummary.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<CourseDetail> getCourse(String courseId) async {
    final rows =
        await supabase.rpc(
              'get_course',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    if (rows.isEmpty) {
      throw Exception('course_not_found');
    }
    return CourseDetail.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<List<CourseStudent>> listCourseStudents(String courseId) async {
    final rows =
        await supabase.rpc(
              'list_course_students',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => CourseStudent.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> enrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    await supabase.rpc(
      'enroll_student',
      params: {
        'p_token': AuthService.sessionToken,
        'p_course_id': courseId,
        'p_student_id': studentId,
      },
    );
  }

  static Future<void> removeStudent({
    required String courseId,
    required String studentId,
  }) async {
    await supabase.rpc(
      'remove_student_from_course',
      params: {
        'p_token': AuthService.sessionToken,
        'p_course_id': courseId,
        'p_student_id': studentId,
      },
    );
  }

  static Future<List<StudentLookup>> searchSchoolStudents({
    String query = '',
  }) async {
    final rows =
        await supabase.rpc(
              'search_school_students',
              params: {'p_token': AuthService.sessionToken, 'p_query': query},
            )
            as List;

    return rows
        .map((row) => StudentLookup.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Returns the course's real join code, generating and persisting one on
  /// first call if it doesn't have one yet.
  static Future<String> getOrCreateJoinCode(String courseId) async {
    return await supabase.rpc(
          'get_or_create_course_join_code',
          params: {
            'p_token': AuthService.sessionToken,
            'p_course_id': courseId,
          },
        )
        as String;
  }

  /// Generates a new random join code for the course, invalidating the
  /// previous one.
  static Future<String> regenerateJoinCode(String courseId) async {
    return await supabase.rpc(
          'regenerate_course_join_code',
          params: {
            'p_token': AuthService.sessionToken,
            'p_course_id': courseId,
          },
        )
        as String;
  }
}
