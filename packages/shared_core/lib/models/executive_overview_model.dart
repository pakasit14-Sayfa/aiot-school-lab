class LearningTrack {
  final String trackId;
  final String name;
  final String color;
  final int sortOrder;

  const LearningTrack({
    required this.trackId,
    required this.name,
    required this.color,
    required this.sortOrder,
  });

  factory LearningTrack.fromRow(Map<String, dynamic> row) {
    return LearningTrack(
      trackId: row['track_id'] as String,
      name: row['name'] as String? ?? '',
      color: row['color'] as String? ?? '#7C3AED',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class LearningTrackOverview {
  final String trackId;
  final String name;
  final String color;
  final int sortOrder;
  final int studentCount;
  final int roomCount;
  final double? avgGradePercent;

  const LearningTrackOverview({
    required this.trackId,
    required this.name,
    required this.color,
    required this.sortOrder,
    required this.studentCount,
    required this.roomCount,
    this.avgGradePercent,
  });

  factory LearningTrackOverview.fromRow(Map<String, dynamic> row) {
    return LearningTrackOverview(
      trackId: row['track_id'] as String,
      name: row['name'] as String? ?? '',
      color: row['color'] as String? ?? '#7C3AED',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      studentCount: (row['student_count'] as num?)?.toInt() ?? 0,
      roomCount: (row['room_count'] as num?)?.toInt() ?? 0,
      avgGradePercent: (row['avg_grade_percent'] as num?)?.toDouble(),
    );
  }
}

class LearningTrackRoom {
  final String gradeLevel;
  final String room;
  final int studentCount;
  final String? trackId;
  final String? trackName;

  const LearningTrackRoom({
    required this.gradeLevel,
    required this.room,
    required this.studentCount,
    this.trackId,
    this.trackName,
  });

  factory LearningTrackRoom.fromRow(Map<String, dynamic> row) {
    return LearningTrackRoom(
      gradeLevel: row['grade_level'] as String? ?? '',
      room: row['room'] as String? ?? '',
      studentCount: (row['student_count'] as num?)?.toInt() ?? 0,
      trackId: row['track_id'] as String?,
      trackName: row['track_name'] as String?,
    );
  }
}

class PlatformSettings {
  final double mq2Threshold;
  final double pm25Threshold;
  final double temperatureThreshold;
  final int offlineMinutes;
  final String mqttHost;
  final int mqttPort;
  final bool lineNotify;
  final bool emailNotify;
  final bool pushNotify;
  final bool automaticBackup;
  final bool maintenanceMode;
  final bool twoFactorRequired;
  final bool auditLogEnabled;
  final String language;
  final String timezone;
  final int logRetentionDays;
  final String backupTime;
  final DateTime updatedAt;

  const PlatformSettings({
    required this.mq2Threshold,
    required this.pm25Threshold,
    required this.temperatureThreshold,
    required this.offlineMinutes,
    required this.mqttHost,
    required this.mqttPort,
    required this.lineNotify,
    required this.emailNotify,
    required this.pushNotify,
    required this.automaticBackup,
    required this.maintenanceMode,
    required this.twoFactorRequired,
    required this.auditLogEnabled,
    required this.language,
    required this.timezone,
    required this.logRetentionDays,
    required this.backupTime,
    required this.updatedAt,
  });

  factory PlatformSettings.fromRow(Map<String, dynamic> row) {
    return PlatformSettings(
      mq2Threshold: (row['mq2_threshold'] as num).toDouble(),
      pm25Threshold: (row['pm25_threshold'] as num).toDouble(),
      temperatureThreshold: (row['temperature_threshold'] as num).toDouble(),
      offlineMinutes: (row['offline_minutes'] as num).toInt(),
      mqttHost: row['mqtt_host'] as String,
      mqttPort: (row['mqtt_port'] as num).toInt(),
      lineNotify: row['line_notify'] as bool,
      emailNotify: row['email_notify'] as bool,
      pushNotify: row['push_notify'] as bool,
      automaticBackup: row['automatic_backup'] as bool,
      maintenanceMode: row['maintenance_mode'] as bool,
      twoFactorRequired: row['two_factor_required'] as bool,
      auditLogEnabled: row['audit_log_enabled'] as bool,
      language: row['language'] as String,
      timezone: row['timezone'] as String,
      logRetentionDays: (row['log_retention_days'] as num).toInt(),
      backupTime: row['backup_time'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

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

