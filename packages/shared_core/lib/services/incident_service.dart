import '../models/incident_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// แจ้งเหตุฉุกเฉินผ่านแอป (Incident Report). RPCs from
/// 20260818020000_incident_reports.sql. Teacher/admin inbox + escalate/close
/// RPCs exist for completeness but there's no teacher-facing UI yet — only
/// the student-facing report/history flow (S1-S3, S5) is wired in the app.
class IncidentService {
  static Future<MyStudentRoom?> getMyStudentRoom() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows = await supabase
        .rpc('get_my_student_room', params: {'p_token': token}) as List;
    if (rows.isEmpty) return null;
    return MyStudentRoom.fromRow(rows.first as Map<String, dynamic>);
  }

  static Stream<List<Map<String, dynamic>>> streamIncidentReports() {
    return supabase
        .from('incident_reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  static Future<String> createIncidentReport({
    required IncidentCategory category,
    String? room,
    String? reason,
    String? severity,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows = await supabase.rpc(
      'create_incident_report',
      params: {
        'p_token': token,
        'p_category': incidentCategoryToDb(category),
        'p_room': room,
        'p_reason': reason,
        'p_severity': severity,
      },
    ) as List;
    return (rows.first as Map<String, dynamic>)['incident_id'] as String;
  }

  static Future<List<MyIncidentReport>> listMyIncidentReports() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows = await supabase.rpc(
      'list_my_incident_reports',
      params: {'p_token': token},
    ) as List;
    return rows
        .map((row) => MyIncidentReport.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<IncidentReportDetail> getIncidentReport(
    String incidentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows = await supabase.rpc(
      'get_incident_report',
      params: {'p_token': token, 'p_id': incidentId},
    ) as List;
    return IncidentReportDetail.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<IncidentReportDetail> getIncidentReportForStaff(
    String incidentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows = await supabase.rpc(
      'get_incident_report_for_staff',
      params: {'p_token': token, 'p_id': incidentId},
    ) as List;
    if (rows.isEmpty) throw Exception('not_found');
    return IncidentReportDetail.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<List<TeacherIncidentReport>> listStaffIncidentReports() {
    if (AuthService.sessionToken == null) {
      throw Exception('not_signed_in');
    }
    return listTeacherIncidentReports();
  }

  static Future<List<TeacherIncidentReport>> listTeacherIncidentReports({
    String? status,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final params = <String, dynamic>{'p_token': token};
    if (status != null) params['p_status'] = status;
    final rows =
        await supabase.rpc('list_incident_reports', params: params) as List;
    return rows
        .map(
          (row) => TeacherIncidentReport.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> acknowledgeIncidentReport(String id) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'acknowledge_incident_report',
      params: {'p_token': token, 'p_id': id},
    );
  }

  static Future<void> assignIncidentReport(String id, String assigneeId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'assign_incident_report',
      params: {'p_token': token, 'p_id': id, 'p_assignee_id': assigneeId},
    );
  }

  static Future<void> addIncidentAction(String id, String note) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'add_incident_action',
      params: {'p_token': token, 'p_id': id, 'p_note': note},
    );
  }

  /// Canonical read for the "save progress note" seam: the exact incident's
  /// action timeline, newest first — lets the client confirm a note was
  /// actually persisted instead of trusting [addIncidentAction]'s void
  /// return alone.
  static Future<List<IncidentActionEntry>> listIncidentActions(
    String id,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows = await supabase.rpc(
      'list_incident_actions',
      params: {'p_token': token, 'p_id': id},
    ) as List;
    return rows
        .map(
          (row) => IncidentActionEntry.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> escalateIncidentReport(String id) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'escalate_incident_report',
      params: {'p_token': token, 'p_id': id},
    );
  }

  static Future<void> closeIncidentReport(
    String id, {
    required String resolutionType,
    required String resolutionNote,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'close_incident_report',
      params: {
        'p_token': token,
        'p_id': id,
        'p_resolution_type': resolutionType,
        'p_resolution_note': resolutionNote,
      },
    );
  }

  static Future<List<IncidentSummaryItem>> getIncidentSummary() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows = await supabase
        .rpc('get_incident_summary', params: {'p_token': token}) as List;
    return rows
        .map((row) => IncidentSummaryItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// List sensor alerts for the active school (School Admin / Super Admin)
  static Future<List<SchoolSensorAlertRecord>> listSchoolAlerts({
    String? status,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final params = <String, dynamic>{'p_token': token};
    if (status != null) params['p_status'] = status;
    final rows =
        await supabase.rpc('list_school_alerts', params: params) as List;
    return rows
        .map((row) =>
            SchoolSensorAlertRecord.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Acknowledge a sensor alert for school_admin
  static Future<void> acknowledgeSensorAlert(String alertId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'acknowledge_sensor_alert_for_school_admin',
      params: {
        'p_token': token,
        'p_alert_id': alertId,
      },
    );
  }

  /// Resolve a sensor alert for school_admin
  static Future<void> resolveSensorAlert(
    String alertId, {
    String? note,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'resolve_sensor_alert_for_school_admin',
      params: {
        'p_token': token,
        'p_alert_id': alertId,
        if (note != null) 'p_note': note,
      },
    );
  }
}
