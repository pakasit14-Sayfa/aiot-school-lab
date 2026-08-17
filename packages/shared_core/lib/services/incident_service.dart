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
    final rows =
        await supabase.rpc('get_my_student_room', params: {'p_token': token})
            as List;
    if (rows.isEmpty) return null;
    return MyStudentRoom.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<String> createIncidentReport({
    required IncidentCategory category,
    String? room,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'create_incident_report',
              params: {
                'p_token': token,
                'p_category': incidentCategoryToDb(category),
                'p_room': room,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['incident_id'] as String;
  }

  static Future<List<MyIncidentReport>> listMyIncidentReports() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_my_incident_reports',
              params: {'p_token': token},
            )
            as List;
    return rows
        .map((row) => MyIncidentReport.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<IncidentReportDetail> getIncidentReport(
    String incidentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'get_incident_report',
              params: {'p_token': token, 'p_id': incidentId},
            )
            as List;
    return IncidentReportDetail.fromRow(rows.first as Map<String, dynamic>);
  }
}
