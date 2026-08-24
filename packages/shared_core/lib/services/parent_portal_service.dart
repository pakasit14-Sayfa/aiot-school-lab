import '../models/parent_portal_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class ParentPortalService {
  static Future<List<LinkedStudentItem>> listMyLinkedStudents() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_my_linked_students',
              params: {'p_token': token},
            )
            as List;

    return rows
        .map((row) => LinkedStudentItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<StudentGradeItem>> listMyStudentGrades(
    String studentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_my_student_grades',
              params: {'p_token': token, 'p_student_id': studentId},
            )
            as List;

    return rows
        .map((row) => StudentGradeItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<StudentScheduleItem>> listMyStudentSchedule(
    String studentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_my_student_schedule',
              params: {'p_token': token, 'p_student_id': studentId},
            )
            as List;

    return rows
        .map((row) => StudentScheduleItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
