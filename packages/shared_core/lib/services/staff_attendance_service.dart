import '../models/staff_attendance_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// ลงเวลาปฏิบัติงานของบุคลากร and staff leave.
///
/// Backed by `20260907010000_staff_attendance.sql`. Reads of the whole school
/// are school_admin/executive; a teacher can check themselves in and read
/// their own leave, nothing more.
class StaffAttendanceService {
  /// Null when the school has not configured its hours — which is a state the
  /// caller must show, not silently replace with a default.
  static Future<StaffWorkHours?> getWorkHours() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc('get_staff_work_hours', params: {'p_token': token})
            as List;
    if (rows.isEmpty) return null;
    return StaffWorkHours.fromRow(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }

  /// [workStartTime] / [workEndTime] as `HH:mm`.
  static Future<void> setWorkHours({
    required String workStartTime,
    required String workEndTime,
    int lateGraceMinutes = 0,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'set_staff_work_hours',
      params: {
        'p_token': token,
        'p_work_start_time': workStartTime,
        'p_work_end_time': workEndTime,
        'p_late_grace_minutes': lateGraceMinutes,
      },
    );
  }

  /// Returns the status the backend derived — `present` or `late`. Throws
  /// `work_hours_not_configured` when lateness has no basis, and
  /// `already_checked_in` on a repeat.
  static Future<String> checkIn({String? note}) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final res = await supabase.rpc(
      'staff_check_in',
      params: {'p_token': token, 'p_note': note},
    );
    final status = res?.toString() ?? '';
    if (status.isEmpty || status.toLowerCase() == 'null') {
      throw StateError('backend_check_in_status_missing');
    }
    return status;
  }

  static Future<void> checkOut() async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc('staff_check_out', params: {'p_token': token});
  }

  /// The admin path: ไปราชการ, ขาดงาน, or a check-in entered for someone.
  static Future<void> recordAttendance({
    required String userId,
    required DateTime workDate,
    required String status,
    String? note,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'record_staff_attendance',
      params: {
        'p_token': token,
        'p_user_id': userId,
        'p_work_date': _date(workDate),
        'p_status': status,
        'p_note': note,
      },
    );
  }

  /// Every staff member's standing for [workDate] (today when omitted).
  static Future<List<StaffAttendanceDay>> listDay({DateTime? workDate}) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_staff_attendance',
              params: {
                'p_token': token,
                'p_work_date': workDate == null ? null : _date(workDate),
              },
            )
            as List;
    return rows
        .map(
          (row) =>
              StaffAttendanceDay.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  /// Null only when the RPC returns no row at all, which it does not do for a
  /// valid session — kept nullable so a caller cannot fabricate zeroes.
  static Future<StaffAttendanceSummary?> getSummary({
    DateTime? workDate,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_staff_attendance_summary',
              params: {
                'p_token': token,
                'p_work_date': workDate == null ? null : _date(workDate),
              },
            )
            as List;
    if (rows.isEmpty) return null;
    return StaffAttendanceSummary.fromRow(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }

  /// Returns the new request's id.
  static Future<String> requestLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final res = await supabase.rpc(
      'request_staff_leave',
      params: {
        'p_token': token,
        'p_leave_type': leaveType,
        'p_start_date': _date(startDate),
        'p_end_date': _date(endDate),
        'p_reason': reason?.trim(),
      },
    );
    final id = res?.toString() ?? '';
    if (id.isEmpty || id.toLowerCase() == 'null') {
      throw StateError('backend_leave_request_id_missing');
    }
    return id;
  }

  /// A teacher gets only their own; the RPC decides the scope from the role,
  /// not from anything the caller passes.
  static Future<List<StaffLeaveRequest>> listLeaveRequests({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_staff_leave_requests',
              params: {
                'p_token': token,
                'p_status': status,
                'p_from': from == null ? null : _date(from),
                'p_to': to == null ? null : _date(to),
              },
            )
            as List;
    return rows
        .map(
          (row) =>
              StaffLeaveRequest.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  static Future<void> reviewLeaveRequest({
    required String requestId,
    required bool approve,
    String? note,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'review_staff_leave_request',
      params: {
        'p_token': token,
        'p_request_id': requestId,
        'p_approve': approve,
        'p_note': note?.trim(),
      },
    );
  }

  static Future<void> cancelLeaveRequest(String requestId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'cancel_staff_leave_request',
      params: {'p_token': token, 'p_request_id': requestId},
    );
  }

  /// Postgres `date` wants the calendar day, not an instant — sending an
  /// ISO-8601 timestamp would reintroduce the timezone slip the migration
  /// takes care to avoid.
  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
