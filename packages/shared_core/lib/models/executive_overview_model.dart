class ClassroomsOverviewItem {
  final int roomCount;
  final int courseCount;
  final int activeStudentCount;
  final int assignmentsDueThisWeek;

  const ClassroomsOverviewItem({
    required this.roomCount,
    required this.courseCount,
    required this.activeStudentCount,
    required this.assignmentsDueThisWeek,
  });

  factory ClassroomsOverviewItem.fromRow(Map<String, dynamic> row) {
    return ClassroomsOverviewItem(
      roomCount: (row['room_count'] as num?)?.toInt() ?? 0,
      courseCount: (row['course_count'] as num?)?.toInt() ?? 0,
      activeStudentCount: (row['active_student_count'] as num?)?.toInt() ?? 0,
      assignmentsDueThisWeek:
          (row['assignments_due_this_week'] as num?)?.toInt() ?? 0,
    );
  }
}

class SchoolScheduleItem {
  final String scheduleId;
  final String courseId;
  final String subjectName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;

  const SchoolScheduleItem({
    required this.scheduleId,
    required this.courseId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory SchoolScheduleItem.fromRow(Map<String, dynamic> row) {
    return SchoolScheduleItem(
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
