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

  static Future<List<StudentAttendanceItem>> listMyStudentAttendance(
    String studentId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final params = <String, dynamic>{
      'p_token': token,
      'p_student_id': studentId,
    };
    if (dateFrom != null) {
      params['p_date_from'] =
          '${dateFrom.year}-${dateFrom.month.toString().padLeft(2, '0')}-${dateFrom.day.toString().padLeft(2, '0')}';
    }
    if (dateTo != null) {
      params['p_date_to'] =
          '${dateTo.year}-${dateTo.month.toString().padLeft(2, '0')}-${dateTo.day.toString().padLeft(2, '0')}';
    }

    final rows =
        await supabase.rpc('list_my_student_attendance', params: params)
            as List;

    return rows
        .map((row) => StudentAttendanceItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> listMyStudentAssignments(
    String studentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc('list_my_student_assignments', params: {
      'p_token': token,
      'p_student_id': studentId,
    }) as List;
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<SchoolEventItem>> listSchoolEvents() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    try {
      final rows = await supabase.rpc('list_school_events', params: {
        'p_token': token,
      }) as List;
      return rows
          .map((row) => SchoolEventItem.fromRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list on error (e.g. RPC missing)
      return const [];
    }
  }

  static Future<List<CalendarEventItem>> listCalendarEvents() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc('list_calendar_events', params: {
      'p_token': token,
    }) as List;
    return rows
        .map((row) => CalendarEventItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> submitLeaveRequest({
    required String studentId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    dynamic attachmentFile, // Use dynamic to avoid importing dart:io in shared_core if it causes issues, but we can type check
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    String? attachmentUrl;

    // Handle file upload if present
    if (attachmentFile != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${studentId}.jpg';
        // Check if the object has a readAsBytes method (works for XFile or dart:io File)
        final bytes = await attachmentFile.readAsBytes();
        
        await supabase.storage.from('leave_attachments').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        attachmentUrl = supabase.storage.from('leave_attachments').getPublicUrl(fileName);
      } catch (e) {
        print('Error uploading file: $e');
        // Continue even if upload fails, or throw. For now, continue but maybe log.
      }
    }

    await supabase.rpc('submit_leave_request', params: {
      'p_token': token,
      'p_student_id': studentId,
      'p_leave_type': leaveType,
      'p_start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'p_end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'p_reason': reason,
      'p_attachment_url': attachmentUrl,
    });
  }
}
