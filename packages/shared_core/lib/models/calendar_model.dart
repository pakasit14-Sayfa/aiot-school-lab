class ClassScheduleSlot {
  const ClassScheduleSlot({
    required this.id,
    required this.courseId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  final String id;
  final String courseId;
  final String subjectName;
  final int dayOfWeek; // 0=จันทร์ ... 6=อาทิตย์
  final String startTime; // "09:00:00"
  final String endTime;
  final String? room;

  static const dayLabels = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  String get dayLabel => dayOfWeek >= 0 && dayOfWeek < dayLabels.length
      ? dayLabels[dayOfWeek]
      : '';

  String get timeRangeLabel =>
      '${startTime.substring(0, 5)}-${endTime.substring(0, 5)}';

  factory ClassScheduleSlot.fromRow(Map<String, dynamic> row) =>
      ClassScheduleSlot(
        id: row['schedule_id'] as String,
        courseId: row['course_id'] as String,
        subjectName: row['subject_name'] as String,
        dayOfWeek: row['day_of_week'] as int,
        startTime: row['start_time'] as String,
        endTime: row['end_time'] as String,
        room: row['room'] as String?,
      );
}

class PersonalTask {
  const PersonalTask({
    required this.id,
    required this.title,
    required this.note,
    required this.dueAt,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? note;
  final DateTime? dueAt;
  final bool done;
  final DateTime createdAt;

  factory PersonalTask.fromRow(Map<String, dynamic> row) => PersonalTask(
    id: row['task_id'] as String,
    title: row['title'] as String,
    note: row['note'] as String?,
    dueAt: row['due_at'] == null
        ? null
        : DateTime.parse(row['due_at'] as String).toUtc(),
    done: row['done'] as bool,
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
  );
}
