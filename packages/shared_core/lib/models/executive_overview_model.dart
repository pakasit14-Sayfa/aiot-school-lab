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

class CameraAccessGrantItem {
  final String grantId;
  final String? cameraDeviceId;
  final String cameraName;
  final String location;
  final String building;
  final String room;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String reason;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime grantedAt;
  final String? grantedByName;
  final bool isActive;

  const CameraAccessGrantItem({
    required this.grantId,
    this.cameraDeviceId,
    required this.cameraName,
    required this.location,
    required this.building,
    required this.room,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.reason,
    required this.validFrom,
    required this.validUntil,
    required this.grantedAt,
    this.grantedByName,
    required this.isActive,
  });

  factory CameraAccessGrantItem.fromRow(Map<String, dynamic> row) {
    return CameraAccessGrantItem(
      grantId: row['grant_id'] as String,
      cameraDeviceId: row['camera_device_id'] as String?,
      cameraName: row['camera_name'] as String? ?? 'ไม่ระบุชื่อกล้อง',
      location: row['location'] as String? ?? '',
      building: row['building'] as String? ?? '',
      room: row['room'] as String? ?? '',
      userId: row['user_id'] as String,
      userName: row['user_name'] as String? ?? '',
      userEmail: row['user_email'] as String? ?? '',
      userRole: row['user_role'] as String? ?? '',
      reason: row['reason'] as String? ?? '',
      validFrom: DateTime.parse(row['valid_from'] as String),
      validUntil: DateTime.parse(row['valid_until'] as String),
      grantedAt: DateTime.parse(row['granted_at'] as String),
      grantedByName: row['granted_by_name'] as String?,
      isActive: row['is_active'] as bool? ?? false,
    );
  }
}

