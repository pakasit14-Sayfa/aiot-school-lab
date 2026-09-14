import '../models/student_followup_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Home visits, SDQ screening, scholarships and executive directives.
/// RPCs from `20260911020000_student_followup_system.sql`.
class StudentFollowupService {
  // ---- Student picker (shared by every create dialog) ----
  static Future<List<SchoolStudentOption>> listSchoolStudents({
    String? search,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_school_students',
              params: {'p_token': token, 'p_search': search},
            )
            as List;
    return rows
        .map(
          (r) => SchoolStudentOption.fromRow(
            Map<String, dynamic>.from(r as Map),
          ),
        )
        .toList();
  }

  // ---- Home visits ----
  static Future<String> createHomeVisit({
    required String studentId,
    required DateTime visitDate,
    required String purpose,
    String? familySituation,
    bool followUpNeeded = false,
    String? followUpNotes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    final rows =
        await supabase.rpc(
              'create_student_home_visit',
              params: {
                'p_token': token,
                'p_student_id': studentId,
                'p_visit_date': _dateOnly(visitDate),
                'p_purpose': purpose,
                'p_family_situation': familySituation,
                'p_follow_up_needed': followUpNeeded,
                'p_follow_up_notes': followUpNotes,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['visit_id'] as String;
  }

  static Future<List<HomeVisit>> listStudentHomeVisits(
    String studentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_student_home_visits',
              params: {'p_token': token, 'p_student_id': studentId},
            )
            as List;
    return rows
        .map((r) => HomeVisit.fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<List<HomeVisit>> listSchoolHomeVisits({int limit = 50}) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_school_home_visits',
              params: {'p_token': token, 'p_limit': limit},
            )
            as List;
    return rows
        .map((r) => HomeVisit.fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // ---- SDQ ----
  /// Returns the new assessment's id plus the server-computed scores (the
  /// RPC does the subscale math — see the migration's scoring note — so the
  /// caller never needs to recompute or trust a client-side sum). Reload
  /// `listStudentSdqAssessments` afterward for the full row with rater name
  /// and formatted date, same pattern as every other create* method here.
  static Future<({String assessmentId, int totalDifficultiesScore})>
  recordSdqAssessment({
    required String studentId,
    required List<int> itemScores,
    String raterType = 'teacher',
    String? notes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    if (itemScores.length != 25) throw ArgumentError('must_have_25_items');
    final rows =
        await supabase.rpc(
              'record_sdq_assessment',
              params: {
                'p_token': token,
                'p_student_id': studentId,
                'p_item_scores': itemScores,
                'p_rater_type': raterType,
                'p_notes': notes,
              },
            )
            as List;
    final row = Map<String, dynamic>.from(rows.first as Map);
    return (
      assessmentId: row['assessment_id'] as String,
      totalDifficultiesScore: (row['total_difficulties_score'] as num)
          .toInt(),
    );
  }

  static Future<List<SdqAssessment>> listStudentSdqAssessments(
    String studentId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_student_sdq_assessments',
              params: {'p_token': token, 'p_student_id': studentId},
            )
            as List;
    return rows
        .map(
          (r) => SdqAssessment.fromRow(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  static Future<List<SchoolSdqSummaryRow>> listSchoolSdqAssessments({
    int limit = 50,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_school_sdq_assessments',
              params: {'p_token': token, 'p_limit': limit},
            )
            as List;
    return rows
        .map(
          (r) => SchoolSdqSummaryRow.fromRow(
            Map<String, dynamic>.from(r as Map),
          ),
        )
        .toList();
  }

  // ---- Scholarships ----
  static Future<String> createScholarship({
    required String name,
    String? sponsor,
    double? amountThb,
    String? description,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    final rows =
        await supabase.rpc(
              'create_scholarship',
              params: {
                'p_token': token,
                'p_name': name,
                'p_sponsor': sponsor,
                'p_amount_thb': amountThb,
                'p_description': description,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['scholarship_id'] as String;
  }

  static Future<String> nominateScholarshipAward({
    required String scholarshipId,
    required String studentId,
    String? notes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    final rows =
        await supabase.rpc(
              'nominate_scholarship_award',
              params: {
                'p_token': token,
                'p_scholarship_id': scholarshipId,
                'p_student_id': studentId,
                'p_notes': notes,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['award_id'] as String;
  }

  static Future<void> setScholarshipAwardStatus({
    required String awardId,
    required String status,
    double? awardedAmountThb,
    String? notes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    await supabase.rpc(
      'set_scholarship_award_status',
      params: {
        'p_token': token,
        'p_award_id': awardId,
        'p_status': status,
        'p_awarded_amount_thb': awardedAmountThb,
        'p_notes': notes,
      },
    );
  }

  static Future<List<Scholarship>> listScholarships() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_scholarships',
              params: {'p_token': token},
            )
            as List;
    return rows
        .map((r) => Scholarship.fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<List<ScholarshipAward>> listScholarshipAwards({
    String? scholarshipId,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_scholarship_awards',
              params: {
                'p_token': token,
                'p_scholarship_id': scholarshipId,
              },
            )
            as List;
    return rows
        .map(
          (r) => ScholarshipAward.fromRow(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  // ---- Executive directives ----
  static Future<String> createDirective({
    required String assignedTo,
    required String title,
    String? instructions,
    String? studentId,
    String? caseId,
    DateTime? dueDate,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    final rows =
        await supabase.rpc(
              'create_directive',
              params: {
                'p_token': token,
                'p_assigned_to': assignedTo,
                'p_title': title,
                'p_instructions': instructions,
                'p_student_id': studentId,
                'p_case_id': caseId,
                'p_due_date': dueDate == null ? null : _dateOnly(dueDate),
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['directive_id'] as String;
  }

  static Future<void> acknowledgeDirective(String directiveId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    await supabase.rpc(
      'acknowledge_directive',
      params: {'p_token': token, 'p_directive_id': directiveId},
    );
  }

  static Future<void> completeDirective(
    String directiveId, {
    String? completedNotes,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw StateError('not_signed_in');
    await supabase.rpc(
      'complete_directive',
      params: {
        'p_token': token,
        'p_directive_id': directiveId,
        'p_completed_notes': completedNotes,
      },
    );
  }

  static Future<List<ExecutiveDirective>> listMyDirectives() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_my_directives',
              params: {'p_token': token},
            )
            as List;
    return rows
        .map(
          (r) => ExecutiveDirective.fromRow(
            Map<String, dynamic>.from(r as Map),
            counterpartyKey: 'assigned_by_name',
          ),
        )
        .toList();
  }

  static Future<List<ExecutiveDirective>> listExecutiveDirectives() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_executive_directives',
              params: {'p_token': token},
            )
            as List;
    return rows
        .map(
          (r) => ExecutiveDirective.fromRow(
            Map<String, dynamic>.from(r as Map),
            counterpartyKey: 'assigned_to_name',
          ),
        )
        .toList();
  }

  // ---- Summary ----
  static Future<StudentFollowupSummary?> getSummary() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_student_followup_summary',
              params: {'p_token': token},
            )
            as List;
    if (rows.isEmpty) return null;
    return StudentFollowupSummary.fromRow(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
