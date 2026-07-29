class CourseGrade {
  final String id;
  final String courseId;
  final String subjectName;
  final num score;
  final num maxScore;
  final DateTime? confirmedAt;

  const CourseGrade({
    required this.id,
    required this.courseId,
    required this.subjectName,
    required this.score,
    required this.maxScore,
    required this.confirmedAt,
  });

  factory CourseGrade.fromRow(Map<String, dynamic> row) => CourseGrade(
    id: row['grade_id'] as String,
    courseId: row['course_id'] as String,
    subjectName: row['subject_name'] as String,
    score: row['score'] as num,
    maxScore: row['max_score'] as num,
    confirmedAt: row['confirmed_at'] == null
        ? null
        : DateTime.parse(row['confirmed_at'] as String).toUtc(),
  );

  double get percent => maxScore == 0 ? 0 : (score / maxScore) * 100;
}

class GradeRecord {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final num score;
  final num maxScore;
  final String status;
  final bool coiFlag;
  final String? coiReviewStatus;
  final DateTime? confirmedAt;

  const GradeRecord({
    required this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    required this.score,
    required this.maxScore,
    required this.status,
    required this.coiFlag,
    required this.coiReviewStatus,
    required this.confirmedAt,
  });

  factory GradeRecord.fromRow(Map<String, dynamic> row) => GradeRecord(
    id: row['grade_id'] as String,
    studentId: row['student_id'] as String,
    studentFirstName: row['student_first_name'] as String,
    studentLastName: row['student_last_name'] as String,
    score: row['score'] as num,
    maxScore: row['max_score'] as num,
    status: row['status'] as String,
    coiFlag: row['coi_flag'] as bool,
    coiReviewStatus: row['coi_review_status'] as String?,
    confirmedAt: row['confirmed_at'] == null
        ? null
        : DateTime.parse(row['confirmed_at'] as String).toUtc(),
  );

  String get studentFullName => '$studentFirstName $studentLastName'.trim();
  bool get isConfirmed => status == 'confirmed';
}

class PendingCoiGrade {
  final String id;
  final String studentFirstName;
  final String studentLastName;
  final String courseId;
  final String subjectName;
  final String gradedBy;
  final num score;
  final num maxScore;
  final String status;

  const PendingCoiGrade({
    required this.id,
    required this.studentFirstName,
    required this.studentLastName,
    required this.courseId,
    required this.subjectName,
    required this.gradedBy,
    required this.score,
    required this.maxScore,
    required this.status,
  });

  factory PendingCoiGrade.fromRow(Map<String, dynamic> row) => PendingCoiGrade(
    id: row['grade_id'] as String,
    studentFirstName: row['student_first_name'] as String,
    studentLastName: row['student_last_name'] as String,
    courseId: row['course_id'] as String,
    subjectName: row['subject_name'] as String,
    gradedBy: row['graded_by'] as String,
    score: row['score'] as num,
    maxScore: row['max_score'] as num,
    status: row['status'] as String,
  );

  String get studentFullName => '$studentFirstName $studentLastName'.trim();
}
