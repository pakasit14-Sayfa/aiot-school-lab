/// LRN-11/LRN-12: teacher-facing pending G-Score entry, awaiting confirm.
class PendingGScoreEntry {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String courseId;
  final String subjectName;
  final String source; // 'lesson_completed' | 'assignment_on_time'
  final num points;
  final DateTime createdAt;

  const PendingGScoreEntry({
    required this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    required this.courseId,
    required this.subjectName,
    required this.source,
    required this.points,
    required this.createdAt,
  });

  factory PendingGScoreEntry.fromRow(Map<String, dynamic> row) =>
      PendingGScoreEntry(
        id: row['entry_id'] as String,
        studentId: row['student_id'] as String,
        studentFirstName: row['student_first_name'] as String,
        studentLastName: row['student_last_name'] as String,
        courseId: row['course_id'] as String,
        subjectName: row['subject_name'] as String,
        source: row['source'] as String,
        points: row['points'] as num,
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      );

  String get studentFullName => '$studentFirstName $studentLastName'.trim();
}

/// LRN-11/LRN-12: student-facing confirmed G-Score entry.
class MyGScoreEntry {
  final String id;
  final String courseId;
  final String subjectName;
  final String source;
  final num points;
  final DateTime confirmedAt;

  const MyGScoreEntry({
    required this.id,
    required this.courseId,
    required this.subjectName,
    required this.source,
    required this.points,
    required this.confirmedAt,
  });

  factory MyGScoreEntry.fromRow(Map<String, dynamic> row) => MyGScoreEntry(
    id: row['entry_id'] as String,
    courseId: row['course_id'] as String,
    subjectName: row['subject_name'] as String,
    source: row['source'] as String,
    points: row['points'] as num,
    confirmedAt: DateTime.parse(row['confirmed_at'] as String).toUtc(),
  );
}
