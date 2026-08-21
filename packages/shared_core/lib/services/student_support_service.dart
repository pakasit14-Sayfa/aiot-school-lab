import '../models/student_support_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class StudentSupportService {
  static Future<List<StudentSupportCase>> listCases({
    String? courseId,
    String? status,
  }) async {
    final rows = await supabase.rpc(
      'list_student_support_cases',
      params: {
        'p_token': AuthService.sessionToken,
        'p_course_id': courseId,
        'p_status': status,
      },
    ) as List;

    return rows
        .map((r) => StudentSupportCase.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  static Future<String> createCase({
    required String studentId,
    String? courseId,
    String category = 'academic',
    String riskLevel = 'medium',
    required String title,
    String? notes,
  }) async {
    final rows = await supabase.rpc(
      'create_student_support_case',
      params: {
        'p_token': AuthService.sessionToken,
        'p_student_id': studentId,
        'p_course_id': courseId,
        'p_category': category,
        'p_risk_level': riskLevel,
        'p_title': title.trim(),
        'p_notes': notes?.trim(),
      },
    ) as List;

    return (rows.first as Map<String, dynamic>)['case_id'] as String;
  }

  static Future<void> updateCaseStatus({
    required String caseId,
    required String status,
    String? note,
  }) async {
    await supabase.rpc(
      'update_student_support_case_status',
      params: {
        'p_token': AuthService.sessionToken,
        'p_case_id': caseId,
        'p_status': status,
        'p_note': note?.trim(),
      },
    );
  }

  static Future<String> addIntervention({
    required String caseId,
    required String actionType,
    required String notes,
  }) async {
    final rows = await supabase.rpc(
      'add_student_support_intervention',
      params: {
        'p_token': AuthService.sessionToken,
        'p_case_id': caseId,
        'p_action_type': actionType,
        'p_notes': notes.trim(),
      },
    ) as List;

    return (rows.first as Map<String, dynamic>)['intervention_id'] as String;
  }

  static Future<List<StudentSupportIntervention>> listInterventions(
    String caseId,
  ) async {
    final rows = await supabase.rpc(
      'list_student_support_interventions',
      params: {
        'p_token': AuthService.sessionToken,
        'p_case_id': caseId,
      },
    ) as List;

    return rows
        .map((r) => StudentSupportIntervention.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
