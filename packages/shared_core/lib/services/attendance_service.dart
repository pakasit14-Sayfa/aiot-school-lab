import 'auth_service.dart';
import 'supabase_config.dart';

class CourseAttendanceStudentItem {
  final String studentId;
  final String studentName;
  final String studentCode;
  final String? status;
  final String? note;
  final DateTime? markedAt;

  const CourseAttendanceStudentItem({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.status,
    this.note,
    this.markedAt,
  });

  factory CourseAttendanceStudentItem.fromRow(Map<String, dynamic> row) {
    return CourseAttendanceStudentItem(
      studentId: row['student_id'] as String,
      studentName: row['student_name'] as String? ?? '',
      studentCode: row['student_code'] as String? ?? '',
      status: row['status'] as String?,
      note: row['note'] as String?,
      markedAt: row['marked_at'] != null
          ? DateTime.tryParse(row['marked_at'] as String)
          : null,
    );
  }
}

class AttendanceService {
  static Future<int> markHomeroomAttendance({
    required String gradeLevel,
    required String room,
    required DateTime classDate,
    required List<Map<String, dynamic>> records,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return 0;

    final dateStr =
        '${classDate.year}-${classDate.month.toString().padLeft(2, '0')}-${classDate.day.toString().padLeft(2, '0')}';

    final result =
        await supabase.rpc(
              'mark_homeroom_attendance',
              params: {
                'p_token': token,
                'p_grade_level': gradeLevel,
                'p_room': room,
                'p_class_date': dateStr,
                'p_records': records,
              },
            )
            as int?;

    return result ?? 0;
  }

  static Future<List<CourseAttendanceStudentItem>> listHomeroomAttendance({
    required String gradeLevel,
    required String room,
    required DateTime classDate,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final dateStr =
        '${classDate.year}-${classDate.month.toString().padLeft(2, '0')}-${classDate.day.toString().padLeft(2, '0')}';

    final rows =
        await supabase.rpc(
              'list_homeroom_attendance',
              params: {
                'p_token': token,
                'p_grade_level': gradeLevel,
                'p_room': room,
                'p_class_date': dateStr,
              },
            )
            as List;

    return rows
        .map(
          (row) =>
              CourseAttendanceStudentItem.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<int> markAttendance({
    required String courseId,
    required DateTime classDate,
    required List<Map<String, dynamic>> records,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return 0;

    final dateStr =
        '${classDate.year}-${classDate.month.toString().padLeft(2, '0')}-${classDate.day.toString().padLeft(2, '0')}';

    final result =
        await supabase.rpc(
              'mark_attendance',
              params: {
                'p_token': token,
                'p_course_id': courseId,
                'p_class_date': dateStr,
                'p_records': records,
              },
            )
            as int?;

    return result ?? 0;
  }

  static Future<List<CourseAttendanceStudentItem>> listCourseAttendance({
    required String courseId,
    required DateTime classDate,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final dateStr =
        '${classDate.year}-${classDate.month.toString().padLeft(2, '0')}-${classDate.day.toString().padLeft(2, '0')}';

    final rows =
        await supabase.rpc(
              'list_course_attendance',
              params: {
                'p_token': token,
                'p_course_id': courseId,
                'p_class_date': dateStr,
              },
            )
            as List;

    return rows
        .map(
          (row) =>
              CourseAttendanceStudentItem.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }
}
