/// Counts for the current active student cohort on a chosen homeroom date.
class SchoolHomeroomAttendance {
  const SchoolHomeroomAttendance({
    this.gradeLevel,
    this.room,
    required this.studentCount,
    required this.present,
    required this.late,
    required this.absent,
    required this.excused,
    required this.unknown,
  });
  factory SchoolHomeroomAttendance.fromRow(Map<String, dynamic> row) =>
      SchoolHomeroomAttendance(
        gradeLevel: row['grade_level'] as String?,
        room: row['room'] as String?,
        studentCount: (row['student_count'] as num).toInt(),
        present: (row['present_count'] as num).toInt(),
        late: (row['late_count'] as num).toInt(),
        absent: (row['absent_count'] as num).toInt(),
        excused: (row['excused_count'] as num).toInt(),
        unknown: (row['unknown_count'] as num).toInt(),
      );
  final String? gradeLevel, room;
  final int studentCount, present, late, absent, excused, unknown;
  int get recorded => present + late + absent + excused;
  double? get attendancePercent =>
      recorded == 0 ? null : 100 * (present + late) / recorded;
  String get roomLabel => gradeLevel == null
      ? 'ยังไม่ระบุชั้น / ห้อง'
      : room?.startsWith('$gradeLevel/') == true
      ? room!
      : '$gradeLevel/${room ?? 'ยังไม่ระบุห้อง'}';
}
