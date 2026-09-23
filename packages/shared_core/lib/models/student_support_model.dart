class StudentSupportCase {
  final String caseId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String? courseId;
  final String courseName;
  final String category;
  final String riskLevel;
  final String status;
  final String title;
  final String? notes;
  final String createdByName;
  final int interventionCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gradeLevel;
  final String? room;

  const StudentSupportCase({
    required this.caseId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.courseId,
    required this.courseName,
    required this.category,
    required this.riskLevel,
    required this.status,
    required this.title,
    this.notes,
    required this.createdByName,
    required this.interventionCount,
    required this.createdAt,
    required this.updatedAt,
    this.gradeLevel,
    this.room,
  });

  factory StudentSupportCase.fromRow(Map<String, dynamic> row) =>
      StudentSupportCase(
        caseId: row['case_id'] as String,
        studentId: row['student_id'] as String,
        studentName: (row['student_name'] as String?) ?? '',
        studentEmail: (row['student_email'] as String?) ?? '',
        courseId: row['course_id'] as String?,
        courseName: (row['course_name'] as String?) ?? 'ภาพรวมทั่วไป',
        category: (row['category'] as String?) ?? 'academic',
        riskLevel: (row['risk_level'] as String?) ?? 'medium',
        status: (row['status'] as String?) ?? 'open',
        title: (row['title'] as String?) ?? '',
        notes: row['notes'] as String?,
        createdByName: (row['created_by_name'] as String?) ?? '',
        interventionCount: (row['intervention_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
        gradeLevel: row['grade_level'] as String?,
        room: row['room'] as String?,
      );

  String get categoryLabel => switch (category) {
    'academic' => 'ด้านการเรียน',
    'behavioral' => 'ด้านพฤติกรรม & การเข้าเรียน',
    'emotional' => 'ด้านสภาพจิตใจ & อารมณ์',
    'safety' => 'ด้านความปลอดภัย',
    _ => category,
  };

  String get statusLabel => switch (status) {
    'open' => 'เปิดเคสใหม่',
    'in_progress' => 'กำลังช่วยเหลือ',
    'escalated' => 'ส่งต่อฝ่ายแนะแนว',
    'resolved' => 'ปิดเคสสำเร็จ',
    _ => status,
  };
}

class StudentSupportIntervention {
  final String interventionId;
  final String caseId;
  final String actionType;
  final String notes;
  final String recordedByName;
  final DateTime createdAt;

  const StudentSupportIntervention({
    required this.interventionId,
    required this.caseId,
    required this.actionType,
    required this.notes,
    required this.recordedByName,
    required this.createdAt,
  });

  factory StudentSupportIntervention.fromRow(Map<String, dynamic> row) =>
      StudentSupportIntervention(
        interventionId: row['intervention_id'] as String,
        caseId: row['case_id'] as String,
        actionType: (row['action_type'] as String?) ?? 'observation',
        notes: (row['notes'] as String?) ?? '',
        recordedByName: (row['recorded_by_name'] as String?) ?? '',
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  String get actionTypeLabel => switch (actionType) {
    'counseling' => 'การให้คำปรึกษา/พูดคุย',
    'remedial_lesson' => 'สอนเสริม/ทบทวนบทเรียน',
    'parent_meeting' => 'ติดต่อผู้ปกครอง',
    'activity_assigned' => 'มอบหมายแบบฝึกหัดเสริม',
    'observation' => 'บันทึกการสังเกตการณ์',
    _ => actionType,
  };
}

/// Auto-computed "needs attention" signal (overdue work / frequent
/// absence / low grade average) — distinct from [StudentSupportCase],
/// which a teacher creates manually.
class AutoFlaggedStudent {
  final String studentId;
  final String studentName;
  final String reason;
  final String detail;
  final String actionLabel;
  final String severity;
  final String? gradeLevel;
  final String? room;
  final String? advisorName;

  const AutoFlaggedStudent({
    required this.studentId,
    required this.studentName,
    required this.reason,
    required this.detail,
    required this.actionLabel,
    required this.severity,
    this.gradeLevel,
    this.room,
    this.advisorName,
  });

  factory AutoFlaggedStudent.fromRow(Map<String, dynamic> row) =>
      AutoFlaggedStudent(
        studentId: row['student_id'] as String,
        studentName: (row['student_name'] as String?) ?? '',
        reason: (row['reason'] as String?) ?? '',
        detail: (row['detail'] as String?) ?? '',
        actionLabel: (row['action_label'] as String?) ?? '',
        severity: (row['severity'] as String?) ?? 'normal',
        gradeLevel: row['grade_level'] as String?,
        room: row['room'] as String?,
        advisorName: row['advisor_name'] as String?,
      );
}
