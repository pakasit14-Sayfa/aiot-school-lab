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

class StudentAttendanceItem {
  final String recordId;
  final String courseId;
  final String courseName;
  final String courseCode;
  final DateTime classDate;
  final String status;
  final String? note;
  final DateTime markedAt;

  const StudentAttendanceItem({
    required this.recordId,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.classDate,
    required this.status,
    this.note,
    required this.markedAt,
  });

  bool get isPresent => status == 'present';
  bool get isLate => status == 'late';
  bool get isAbsent => status == 'absent';
  bool get isExcused => status == 'excused';

  factory StudentAttendanceItem.fromRow(Map<String, dynamic> row) {
    return StudentAttendanceItem(
      recordId: row['record_id'] as String,
      courseId: row['course_id'] as String,
      courseName: row['course_name'] as String? ?? '',
      courseCode: row['course_code'] as String? ?? '',
      classDate: DateTime.parse(row['class_date'] as String),
      status: row['status'] as String? ?? 'present',
      note: row['note'] as String?,
      markedAt: DateTime.parse(row['marked_at'] as String),
    );
  }
}


class SchoolEventItem {
  final String eventId;
  final String title;
  final String? location;
  final DateTime startDate;

  SchoolEventItem({
    required this.eventId,
    required this.title,
    this.location,
    required this.startDate,
  });

  factory SchoolEventItem.fromRow(Map<String, dynamic> row) {
    return SchoolEventItem(
      eventId: row['event_id'] as String,
      title: row['title'] as String,
      location: row['location'] as String?,
      startDate: DateTime.parse(row['start_date'] as String),
    );
  }
}

class CalendarEventItem {
  final String eventId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final String eventType;

  CalendarEventItem({
    required this.eventId,
    required this.title,
    this.description,
    this.location,
    required this.startDate,
    this.endDate,
    required this.eventType,
  });

  factory CalendarEventItem.fromRow(Map<String, dynamic> row) {
    return CalendarEventItem(
      eventId: row['event_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      location: row['location'] as String?,
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: row['end_date'] != null
          ? DateTime.parse(row['end_date'] as String)
          : null,
      eventType: row['event_type'] as String? ?? 'activity',
    );
  }
}
