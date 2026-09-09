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

class CourseOverviewRecord {
  final String schoolId;
  final String schoolName;
  final int coursesTotal;
  final int coursesActive;
  final int lessonsTotal;
  final int lessonsPublished;
  final int lessonsDraft;

  const CourseOverviewRecord({
    required this.schoolId,
    required this.schoolName,
    required this.coursesTotal,
    required this.coursesActive,
    required this.lessonsTotal,
    required this.lessonsPublished,
    required this.lessonsDraft,
  });

  factory CourseOverviewRecord.fromRow(Map<String, dynamic> row) {
    return CourseOverviewRecord(
      schoolId: row['school_id'] as String,
      schoolName: row['school_name'] as String? ?? '',
      coursesTotal: (row['courses_total'] as num?)?.toInt() ?? 0,
      coursesActive: (row['courses_active'] as num?)?.toInt() ?? 0,
      lessonsTotal: (row['lessons_total'] as num?)?.toInt() ?? 0,
      lessonsPublished: (row['lessons_published'] as num?)?.toInt() ?? 0,
      lessonsDraft: (row['lessons_draft'] as num?)?.toInt() ?? 0,
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

class ClassroomLearningSummary {
  final String gradeLevel;
  final String room;
  final int studentCount;
  final int scoredStudentCount;
  final double? averageGradePercent;
  final int ungradedStudentCount;

  const ClassroomLearningSummary({
    required this.gradeLevel,
    required this.room,
    required this.studentCount,
    required this.scoredStudentCount,
    required this.averageGradePercent,
    required this.ungradedStudentCount,
  });

  factory ClassroomLearningSummary.fromRow(Map<String, dynamic> row) {
    return ClassroomLearningSummary(
      gradeLevel: row['grade_level'] as String? ?? '',
      room: row['room'] as String? ?? '',
      studentCount: (row['student_count'] as num?)?.toInt() ?? 0,
      scoredStudentCount: (row['scored_student_count'] as num?)?.toInt() ?? 0,
      averageGradePercent: (row['avg_grade_percent'] as num?)?.toDouble(),
      ungradedStudentCount:
          (row['ungraded_student_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassroomWorkActivity {
  final String gradeLevel;
  final String room;
  final int assignmentCount;
  final int expectedSubmissionCount;
  final int submittedCount;
  final int pendingSubmissionCount;
  final DateTime? lastActivityAt;
  final String? lastActivityType;
  final String? lastActivityBy;

  const ClassroomWorkActivity({
    required this.gradeLevel,
    required this.room,
    required this.assignmentCount,
    required this.expectedSubmissionCount,
    required this.submittedCount,
    required this.pendingSubmissionCount,
    required this.lastActivityAt,
    required this.lastActivityType,
    required this.lastActivityBy,
  });

  factory ClassroomWorkActivity.fromRow(Map<String, dynamic> row) {
    return ClassroomWorkActivity(
      gradeLevel: row['grade_level'] as String? ?? '',
      room: row['room'] as String? ?? '',
      assignmentCount: (row['assignment_count'] as num?)?.toInt() ?? 0,
      expectedSubmissionCount:
          (row['expected_submission_count'] as num?)?.toInt() ?? 0,
      submittedCount: (row['submitted_count'] as num?)?.toInt() ?? 0,
      pendingSubmissionCount:
          (row['pending_submission_count'] as num?)?.toInt() ?? 0,
      lastActivityAt: row['last_activity_at'] == null
          ? null
          : DateTime.tryParse(row['last_activity_at'].toString())?.toLocal(),
      lastActivityType: row['last_activity_type'] as String?,
      lastActivityBy: row['last_activity_by'] as String?,
    );
  }
}

class ClassroomAssignmentDetail {
  final String assignmentId, title, status, teacher;
  final String? instructions;
  final DateTime? dueAt, createdAt;
  final bool isGroup;
  final int expected, submitted, pending;
  const ClassroomAssignmentDetail({
    required this.assignmentId,
    required this.title,
    required this.status,
    required this.teacher,
    required this.instructions,
    required this.dueAt,
    required this.createdAt,
    required this.isGroup,
    required this.expected,
    required this.submitted,
    required this.pending,
  });
  factory ClassroomAssignmentDetail.fromJson(Map<String, dynamic> row) =>
      ClassroomAssignmentDetail(
        assignmentId: row['assignment_id'] as String,
        title: row['title'] as String? ?? '',
        status: row['status'] as String? ?? '',
        teacher: row['teacher'] as String? ?? '',
        instructions: row['instructions'] as String?,
        dueAt: row['due_at'] == null
            ? null
            : DateTime.tryParse(row['due_at'].toString())?.toLocal(),
        createdAt: row['created_at'] == null
            ? null
            : DateTime.tryParse(row['created_at'].toString())?.toLocal(),
        isGroup: row['is_group'] as bool? ?? false,
        expected: (row['expected'] as num?)?.toInt() ?? 0,
        submitted: (row['submitted'] as num?)?.toInt() ?? 0,
        pending: (row['pending'] as num?)?.toInt() ?? 0,
      );
}

class ClassroomTeacherActivity {
  final String type, title, teacher;
  final DateTime? createdAt;
  const ClassroomTeacherActivity({
    required this.type,
    required this.title,
    required this.teacher,
    required this.createdAt,
  });
  factory ClassroomTeacherActivity.fromJson(Map<String, dynamic> row) =>
      ClassroomTeacherActivity(
        type: row['type'] as String? ?? '',
        title: row['title'] as String? ?? '',
        teacher: row['teacher'] as String? ?? '',
        createdAt: row['created_at'] == null
            ? null
            : DateTime.tryParse(row['created_at'].toString()),
      );
}

class ClassroomWorkDetails {
  final String gradeLevel, room;
  final List<ClassroomAssignmentDetail> assignments;
  final List<ClassroomTeacherActivity> teacherActivities;
  const ClassroomWorkDetails({
    required this.gradeLevel,
    required this.room,
    required this.assignments,
    required this.teacherActivities,
  });
  factory ClassroomWorkDetails.fromRow(Map<String, dynamic> row) =>
      ClassroomWorkDetails(
        gradeLevel: row['grade_level'] as String? ?? '',
        room: row['room'] as String? ?? '',
        assignments: (row['assignments'] as List? ?? const [])
            .map(
              (e) => ClassroomAssignmentDetail.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
        teacherActivities: (row['teacher_activities'] as List? ?? const [])
            .map(
              (e) => ClassroomTeacherActivity.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}

class ClassroomAssignmentRosterItem {
  final String studentId, studentName, submissionStatus;
  final DateTime? submittedAt;
  const ClassroomAssignmentRosterItem({
    required this.studentId,
    required this.studentName,
    required this.submissionStatus,
    required this.submittedAt,
  });
  factory ClassroomAssignmentRosterItem.fromRow(Map<String, dynamic> row) =>
      ClassroomAssignmentRosterItem(
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String? ?? '',
        submissionStatus: row['submission_status'] as String? ?? 'ยังไม่ส่ง',
        submittedAt: row['submitted_at'] == null
            ? null
            : DateTime.tryParse(row['submitted_at'].toString()),
      );
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
