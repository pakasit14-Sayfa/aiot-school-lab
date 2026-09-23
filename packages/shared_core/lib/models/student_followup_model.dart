class SchoolStudentOption {
  final String studentId;
  final String studentName;
  final String? gradeLevel;
  final String? room;

  const SchoolStudentOption({
    required this.studentId,
    required this.studentName,
    this.gradeLevel,
    this.room,
  });

  factory SchoolStudentOption.fromRow(Map<String, dynamic> row) =>
      SchoolStudentOption(
        studentId: row['student_id'] as String,
        studentName: (row['student_name'] as String?) ?? '',
        gradeLevel: row['grade_level'] as String?,
        room: row['room'] as String?,
      );

  String get label {
    final place = room ?? gradeLevel;
    return place == null ? studentName : '$studentName ($place)';
  }
}

class HomeVisit {
  final String visitId;
  final String studentId;
  final String studentName;
  final String visitedByName;
  final DateTime visitDate;
  final String purpose;
  final String? familySituation;
  final bool followUpNeeded;
  final String? followUpNotes;
  final DateTime createdAt;

  const HomeVisit({
    required this.visitId,
    required this.studentId,
    required this.studentName,
    required this.visitedByName,
    required this.visitDate,
    required this.purpose,
    this.familySituation,
    required this.followUpNeeded,
    this.followUpNotes,
    required this.createdAt,
  });

  factory HomeVisit.fromRow(Map<String, dynamic> row) => HomeVisit(
    visitId: row['visit_id'] as String,
    studentId: row['student_id'] as String,
    studentName: (row['student_name'] as String?) ?? '',
    visitedByName: (row['visited_by_name'] as String?) ?? '',
    visitDate: DateTime.parse(row['visit_date'] as String),
    purpose: (row['purpose'] as String?) ?? '',
    familySituation: row['family_situation'] as String?,
    followUpNeeded: row['follow_up_needed'] as bool? ?? false,
    followUpNotes: row['follow_up_notes'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}

/// Goodman SDQ, teacher-rated: 25 items, 5 subscales of 5 items each.
/// `totalDifficultiesScore` = emotional+conduct+hyperactivity+peer (excludes
/// prosocial), matching the real instrument. Deliberately carries no
/// diagnostic band (normal/borderline/abnormal) — see the migration
/// comment in 20260911020000_student_followup_system.sql for why: the
/// published cutoffs vary by rater form and weren't verified against an
/// authoritative source. UI must show raw scores, not a diagnostic label.
class SdqAssessment {
  final String assessmentId;
  final String assessedByName;
  final String raterType;
  final DateTime assessmentDate;
  final int emotionalScore;
  final int conductScore;
  final int hyperactivityScore;
  final int peerScore;
  final int prosocialScore;
  final int totalDifficultiesScore;
  final String? notes;

  const SdqAssessment({
    required this.assessmentId,
    required this.assessedByName,
    required this.raterType,
    required this.assessmentDate,
    required this.emotionalScore,
    required this.conductScore,
    required this.hyperactivityScore,
    required this.peerScore,
    required this.prosocialScore,
    required this.totalDifficultiesScore,
    this.notes,
  });

  factory SdqAssessment.fromRow(Map<String, dynamic> row) => SdqAssessment(
    assessmentId: row['assessment_id'] as String,
    assessedByName: (row['assessed_by_name'] as String?) ?? '',
    raterType: (row['rater_type'] as String?) ?? 'teacher',
    assessmentDate: DateTime.parse(row['assessment_date'] as String),
    emotionalScore: (row['emotional_score'] as num).toInt(),
    conductScore: (row['conduct_score'] as num).toInt(),
    hyperactivityScore: (row['hyperactivity_score'] as num).toInt(),
    peerScore: (row['peer_score'] as num).toInt(),
    prosocialScore: (row['prosocial_score'] as num).toInt(),
    totalDifficultiesScore: (row['total_difficulties_score'] as num).toInt(),
    notes: row['notes'] as String?,
  );
}

class SchoolSdqSummaryRow {
  final String assessmentId;
  final String studentId;
  final String studentName;
  final DateTime assessmentDate;
  final int totalDifficultiesScore;

  const SchoolSdqSummaryRow({
    required this.assessmentId,
    required this.studentId,
    required this.studentName,
    required this.assessmentDate,
    required this.totalDifficultiesScore,
  });

  factory SchoolSdqSummaryRow.fromRow(Map<String, dynamic> row) =>
      SchoolSdqSummaryRow(
        assessmentId: row['assessment_id'] as String,
        studentId: row['student_id'] as String,
        studentName: (row['student_name'] as String?) ?? '',
        assessmentDate: DateTime.parse(row['assessment_date'] as String),
        totalDifficultiesScore: (row['total_difficulties_score'] as num)
            .toInt(),
      );
}

class Scholarship {
  final String scholarshipId;
  final String name;
  final String? sponsor;
  final double? amountThb;
  final String? description;
  final int awardCount;
  final DateTime createdAt;

  const Scholarship({
    required this.scholarshipId,
    required this.name,
    this.sponsor,
    this.amountThb,
    this.description,
    required this.awardCount,
    required this.createdAt,
  });

  factory Scholarship.fromRow(Map<String, dynamic> row) => Scholarship(
    scholarshipId: row['scholarship_id'] as String,
    name: (row['name'] as String?) ?? '',
    sponsor: row['sponsor'] as String?,
    amountThb: (row['amount_thb'] as num?)?.toDouble(),
    description: row['description'] as String?,
    awardCount: (row['award_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}

class ScholarshipAward {
  final String awardId;
  final String scholarshipId;
  final String scholarshipName;
  final String studentId;
  final String studentName;
  final String status;
  final double? awardedAmountThb;
  final String? notes;
  final DateTime createdAt;

  const ScholarshipAward({
    required this.awardId,
    required this.scholarshipId,
    required this.scholarshipName,
    required this.studentId,
    required this.studentName,
    required this.status,
    this.awardedAmountThb,
    this.notes,
    required this.createdAt,
  });

  factory ScholarshipAward.fromRow(Map<String, dynamic> row) =>
      ScholarshipAward(
        awardId: row['award_id'] as String,
        scholarshipId: row['scholarship_id'] as String,
        scholarshipName: (row['scholarship_name'] as String?) ?? '',
        studentId: row['student_id'] as String,
        studentName: (row['student_name'] as String?) ?? '',
        status: (row['status'] as String?) ?? 'applied',
        awardedAmountThb: (row['awarded_amount_thb'] as num?)?.toDouble(),
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  String get statusLabel => switch (status) {
    'applied' => 'รอพิจารณา',
    'approved' => 'อนุมัติแล้ว',
    'rejected' => 'ไม่อนุมัติ',
    'disbursed' => 'เบิกจ่ายแล้ว',
    _ => status,
  };
}

class ExecutiveDirective {
  final String directiveId;
  final String title;
  final String? instructions;
  final String? studentName;
  final String counterpartyName;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;

  const ExecutiveDirective({
    required this.directiveId,
    required this.title,
    this.instructions,
    this.studentName,
    required this.counterpartyName,
    this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory ExecutiveDirective.fromRow(
    Map<String, dynamic> row, {
    required String counterpartyKey,
  }) => ExecutiveDirective(
    directiveId: row['directive_id'] as String,
    title: (row['title'] as String?) ?? '',
    instructions: row['instructions'] as String?,
    studentName: (row['student_name'] as String?)?.trim().isEmpty == true
        ? null
        : row['student_name'] as String?,
    counterpartyName: (row[counterpartyKey] as String?) ?? '',
    dueDate: row['due_date'] == null
        ? null
        : DateTime.parse(row['due_date'] as String),
    status: (row['status'] as String?) ?? 'pending',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );

  bool get isOverdue =>
      status != 'completed' &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  String get statusLabel => switch (status) {
    'pending' => 'รอรับทราบ',
    'acknowledged' => 'รับทราบแล้ว',
    'completed' => 'เสร็จสิ้น',
    _ => status,
  };
}

class StudentFollowupSummary {
  final int homeVisitsThisMonth;
  final int homeVisitsFollowUpNeeded;
  final int sdqAssessmentsTotal;
  final int sdqAssessmentsThisMonth;
  final int scholarshipsActive;
  final int scholarshipAwardsPending;
  final int directivesOpen;
  final int directivesOverdue;

  const StudentFollowupSummary({
    required this.homeVisitsThisMonth,
    required this.homeVisitsFollowUpNeeded,
    required this.sdqAssessmentsTotal,
    required this.sdqAssessmentsThisMonth,
    required this.scholarshipsActive,
    required this.scholarshipAwardsPending,
    required this.directivesOpen,
    required this.directivesOverdue,
  });

  factory StudentFollowupSummary.fromRow(
    Map<String, dynamic> row,
  ) => StudentFollowupSummary(
    homeVisitsThisMonth: (row['home_visits_this_month'] as num?)?.toInt() ?? 0,
    homeVisitsFollowUpNeeded:
        (row['home_visits_follow_up_needed'] as num?)?.toInt() ?? 0,
    sdqAssessmentsTotal: (row['sdq_assessments_total'] as num?)?.toInt() ?? 0,
    sdqAssessmentsThisMonth:
        (row['sdq_assessments_this_month'] as num?)?.toInt() ?? 0,
    scholarshipsActive: (row['scholarships_active'] as num?)?.toInt() ?? 0,
    scholarshipAwardsPending:
        (row['scholarship_awards_pending'] as num?)?.toInt() ?? 0,
    directivesOpen: (row['directives_open'] as num?)?.toInt() ?? 0,
    directivesOverdue: (row['directives_overdue'] as num?)?.toInt() ?? 0,
  );
}
