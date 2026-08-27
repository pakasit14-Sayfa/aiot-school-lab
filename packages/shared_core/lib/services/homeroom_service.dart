import 'auth_service.dart';
import 'supabase_config.dart';

class HomeroomAssignment {
  final String assignmentId;
  final String gradeLevel;
  final String room;
  final String? teacherId;
  final String? teacherName;
  final int studentCount;

  const HomeroomAssignment({
    required this.assignmentId,
    required this.gradeLevel,
    required this.room,
    this.teacherId,
    this.teacherName,
    required this.studentCount,
  });

  factory HomeroomAssignment.fromRow(Map<String, dynamic> row) {
    return HomeroomAssignment(
      assignmentId: row['assignment_id'] as String,
      gradeLevel: row['grade_level'] as String? ?? '',
      room: row['room'] as String? ?? '',
      teacherId: row['teacher_id'] as String?,
      teacherName: row['teacher_name'] as String?,
      studentCount: (row['student_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeroomRosterItem {
  final String studentId;
  final String studentName;
  final String studentCode;

  const HomeroomRosterItem({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
  });

  factory HomeroomRosterItem.fromRow(Map<String, dynamic> row) {
    return HomeroomRosterItem(
      studentId: row['student_id'] as String,
      studentName: row['student_name'] as String? ?? '',
      studentCode: row['student_code'] as String? ?? '',
    );
  }
}

class HomeroomService {
  static Future<String?> setHomeroomTeacher({
    required String gradeLevel,
    required String room,
    required String teacherId,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return null;

    final result =
        await supabase.rpc(
              'set_homeroom_teacher',
              params: {
                'p_token': token,
                'p_grade_level': gradeLevel,
                'p_room': room,
                'p_teacher_id': teacherId,
              },
            )
            as String?;
    return result;
  }

  static Future<bool> removeHomeroomTeacher(String assignmentId) async {
    final token = AuthService.sessionToken;
    if (token == null) return false;

    final result =
        await supabase.rpc(
              'remove_homeroom_teacher',
              params: {'p_token': token, 'p_assignment_id': assignmentId},
            )
            as bool?;
    return result ?? false;
  }

  static Future<List<HomeroomAssignment>> listHomeroomAssignments() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_homeroom_assignments',
              params: {'p_token': token},
            )
            as List;
    return rows
        .map((row) => HomeroomAssignment.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<HomeroomAssignment>> listMyHomeroomClasses() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_my_homeroom_classes',
              params: {'p_token': token},
            )
            as List;
    return rows
        .map((row) => HomeroomAssignment.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<HomeroomRosterItem>> listHomeroomRoster({
    required String gradeLevel,
    required String room,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_homeroom_roster',
              params: {
                'p_token': token,
                'p_grade_level': gradeLevel,
                'p_room': room,
              },
            )
            as List;
    return rows
        .map(
          (row) => HomeroomRosterItem.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }
}
