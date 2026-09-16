/// Real weekly breakdown of teaching periods for the executive "ภาพรวมครูและ
/// การสอน" card — 4 categories: regular teaching, activity/lab periods,
/// substitute-teacher coverage, and prep/meeting periods. Backed by
/// `get_teacher_workload_summary` (school-wide, current week).
class TeacherWorkloadSummary {
  const TeacherWorkloadSummary({
    required this.regularPeriods,
    required this.activityLabPeriods,
    required this.regularTeacherCount,
    required this.activityLabTeacherCount,
    required this.substitutionRecorded,
    required this.substitutionNeeded,
    required this.prepMeetingCount,
    required this.prepMeetingTeacherCount,
  });

  final int regularPeriods;
  final int activityLabPeriods;
  final int regularTeacherCount;
  final int activityLabTeacherCount;
  final int substitutionRecorded;
  final int substitutionNeeded;
  final int prepMeetingCount;
  final int prepMeetingTeacherCount;

  /// Bubble percentages are of *recorded* substitution coverage, not the
  /// need-count — a period nobody has assigned a substitute for yet
  /// shouldn't inflate this category.
  int get totalPeriods =>
      regularPeriods + activityLabPeriods + substitutionRecorded + prepMeetingCount;

  bool get isEmpty => totalPeriods == 0;

  factory TeacherWorkloadSummary.fromRow(Map<String, dynamic> row) =>
      TeacherWorkloadSummary(
        regularPeriods: (row['regular_periods'] as num).toInt(),
        activityLabPeriods: (row['activity_lab_periods'] as num).toInt(),
        regularTeacherCount: (row['regular_teacher_count'] as num).toInt(),
        activityLabTeacherCount:
            (row['activity_lab_teacher_count'] as num).toInt(),
        substitutionRecorded: (row['substitution_recorded'] as num).toInt(),
        substitutionNeeded: (row['substitution_needed'] as num).toInt(),
        prepMeetingCount: (row['prep_meeting_count'] as num).toInt(),
        prepMeetingTeacherCount:
            (row['prep_meeting_teacher_count'] as num).toInt(),
      );
}

/// One period on a given date whose regular teacher is on approved leave —
/// from `list_periods_needing_substitute`.
class PeriodNeedingSubstitute {
  const PeriodNeedingSubstitute({
    required this.classScheduleId,
    required this.subjectName,
    this.gradeLevel,
    this.room,
    required this.startTime,
    required this.endTime,
    required this.originalTeacherId,
    required this.originalTeacherName,
    required this.alreadyCovered,
    this.substituteTeacherName,
    this.assignedByName,
    this.reassigned = false,
  });

  final String classScheduleId;
  final String subjectName;
  final String? gradeLevel;
  final String? room;
  final String startTime;
  final String endTime;
  final String originalTeacherId;
  final String originalTeacherName;
  final bool alreadyCovered;
  final String? substituteTeacherName;

  /// Who most recently assigned/reassigned this — the reassigner if this was
  /// changed after the first assignment, otherwise the original assigner.
  final String? assignedByName;

  /// True when a substitute was assigned, then changed to someone else —
  /// distinguishes a reassignment from the first assignment (red-team
  /// finding: silent overwrite gave no visibility into who changed what).
  final bool reassigned;

  String get timeRangeLabel =>
      '${startTime.substring(0, 5)}-${endTime.substring(0, 5)}';

  factory PeriodNeedingSubstitute.fromRow(Map<String, dynamic> row) =>
      PeriodNeedingSubstitute(
        classScheduleId: row['class_schedule_id'] as String,
        subjectName: (row['subject_name'] as String?) ?? '',
        gradeLevel: row['grade_level'] as String?,
        room: row['room'] as String?,
        startTime: row['start_time'] as String,
        endTime: row['end_time'] as String,
        originalTeacherId: row['original_teacher_id'] as String,
        originalTeacherName: (row['original_teacher_name'] as String?) ?? '',
        alreadyCovered: row['already_covered'] as bool? ?? false,
        substituteTeacherName:
            (row['substitute_teacher_name'] as String?)?.isEmpty ?? true
                ? null
                : row['substitute_teacher_name'] as String?,
        assignedByName:
            (row['assigned_by_name'] as String?)?.isEmpty ?? true
                ? null
                : row['assigned_by_name'] as String?,
        reassigned: row['reassigned'] as bool? ?? false,
      );
}
