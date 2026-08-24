class LinkedStudentItem {
  final String studentId;
  final String firstName;
  final String lastName;
  final String schoolId;
  final String? relationship;
  final DateTime? linkedAt;

  const LinkedStudentItem({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.schoolId,
    this.relationship,
    this.linkedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory LinkedStudentItem.fromRow(Map<String, dynamic> row) {
    return LinkedStudentItem(
      studentId: row['student_id'] as String,
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      schoolId: row['school_id'] as String? ?? '',
      relationship: row['relationship'] as String?,
      linkedAt: row['linked_at'] != null
          ? DateTime.tryParse(row['linked_at'] as String)
          : null,
    );
  }
}

class StudentGradeItem {
  final String gradeId;
  final String courseId;
  final String subjectName;
  final num score;
  final num maxScore;
  final DateTime? confirmedAt;

  const StudentGradeItem({
    required this.gradeId,
    required this.courseId,
    required this.subjectName,
    required this.score,
    required this.maxScore,
    this.confirmedAt,
  });

  double get percentage =>
      maxScore > 0 ? (score.toDouble() / maxScore.toDouble()) * 100 : 0;

  factory StudentGradeItem.fromRow(Map<String, dynamic> row) {
    return StudentGradeItem(
      gradeId: row['grade_id'] as String,
      courseId: row['course_id'] as String,
      subjectName: row['subject_name'] as String? ?? '',
      score: row['score'] as num? ?? 0,
      maxScore: row['max_score'] as num? ?? 100,
      confirmedAt: row['confirmed_at'] != null
          ? DateTime.tryParse(row['confirmed_at'] as String)
          : null,
    );
  }
}

class StudentScheduleItem {
  final String scheduleId;
  final String courseId;
  final String subjectName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;

  const StudentScheduleItem({
    required this.scheduleId,
    required this.courseId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory StudentScheduleItem.fromRow(Map<String, dynamic> row) {
    return StudentScheduleItem(
      scheduleId: row['schedule_id'] as String,
      courseId: row['course_id'] as String,
      subjectName: row['subject_name'] as String? ?? '',
      dayOfWeek: (row['day_of_week'] as num?)?.toInt() ?? 0,
      startTime: row['start_time'] as String? ?? '',
      endTime: row['end_time'] as String? ?? '',
      room: row['room'] as String?,
    );
  }
}
