enum IncidentCategory { sos, anomaly }

IncidentCategory incidentCategoryFromDb(String value) => switch (value) {
  'sos' => IncidentCategory.sos,
  'anomaly' => IncidentCategory.anomaly,
  _ => IncidentCategory.anomaly,
};

String incidentCategoryToDb(IncidentCategory category) => switch (category) {
  IncidentCategory.sos => 'sos',
  IncidentCategory.anomaly => 'anomaly',
};

class MyIncidentReport {
  const MyIncidentReport({
    required this.id,
    required this.category,
    required this.room,
    required this.status,
    required this.createdAt,
    required this.acknowledgedAt,
    required this.closedAt,
    this.reason,
    this.severity,
  });

  final String id;
  final IncidentCategory category;
  final String? room;
  final String status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? closedAt;
  final String? reason;
  final String? severity;

  /// จริง ๆ ยังไม่จบเรื่อง ("escalated" คือกำลังเป็นเหตุฉุกเฉินจริงอยู่ ยังไม่
  /// นับว่าจบ) — จบจริงเมื่อ resolved/cancelled เท่านั้น
  bool get isOpen =>
      status == 'new' ||
      status == 'acknowledged' ||
      status == 'in_progress' ||
      status == 'escalated';

  factory MyIncidentReport.fromRow(Map<String, dynamic> row) =>
      MyIncidentReport(
        id: row['id'] as String,
        category: incidentCategoryFromDb(row['category'] as String),
        room: row['room'] as String?,
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
        acknowledgedAt: row['acknowledged_at'] == null
            ? null
            : DateTime.parse(row['acknowledged_at'] as String).toUtc(),
        closedAt: row['closed_at'] == null
            ? null
            : DateTime.parse(row['closed_at'] as String).toUtc(),
        reason: row['reason'] as String?,
        severity: row['severity'] as String?,
      );
}

class IncidentReportDetail {
  const IncidentReportDetail({
    required this.id,
    required this.category,
    required this.room,
    required this.status,
    required this.resolutionType,
    required this.resolutionNote,
    required this.createdAt,
    required this.acknowledgedAt,
    required this.closedAt,
    this.reason,
    this.severity,
  });

  final String id;
  final IncidentCategory category;
  final String? room;
  final String status;
  final String? resolutionType;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? closedAt;
  final String? reason;
  final String? severity;

  factory IncidentReportDetail.fromRow(Map<String, dynamic> row) =>
      IncidentReportDetail(
        id: row['id'] as String,
        category: incidentCategoryFromDb(row['category'] as String),
        room: row['room'] as String?,
        status: row['status'] as String,
        resolutionType: row['resolution_type'] as String?,
        resolutionNote: row['resolution_note'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
        acknowledgedAt: row['acknowledged_at'] == null
            ? null
            : DateTime.parse(row['acknowledged_at'] as String).toUtc(),
        closedAt: row['closed_at'] == null
            ? null
            : DateTime.parse(row['closed_at'] as String).toUtc(),
        reason: row['reason'] as String?,
        severity: row['severity'] as String?,
      );
}

/// One row of an incident's action timeline (note | assign | status_change),
/// as returned by `list_incident_actions` — the canonical read a staff
/// member's progress-note save is confirmed against.
class IncidentActionEntry {
  const IncidentActionEntry({
    required this.id,
    required this.actionType,
    required this.note,
    required this.actorName,
    required this.createdAt,
  });

  final String id;
  final String actionType;
  final String? note;
  final String actorName;
  final DateTime createdAt;

  factory IncidentActionEntry.fromRow(Map<String, dynamic> row) =>
      IncidentActionEntry(
        id: row['id'] as String,
        actionType: row['action_type'] as String,
        note: row['note'] as String?,
        actorName: row['actor_name'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      );
}

class MyStudentRoom {
  const MyStudentRoom({required this.room, required this.gradeLevel});

  final String? room;
  final String? gradeLevel;

  factory MyStudentRoom.fromRow(Map<String, dynamic> row) => MyStudentRoom(
    room: row['room'] as String?,
    gradeLevel: row['grade_level'] as String?,
  );
}

class TeacherIncidentReport {
  const TeacherIncidentReport({
    required this.id,
    required this.category,
    required this.room,
    required this.status,
    required this.reporterName,
    required this.createdAt,
    this.acknowledgedAt,
    this.reason,
    this.severity,
  });

  final String id;
  final IncidentCategory category;
  final String? room;
  final String status;
  final String reporterName;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? reason;
  final String? severity;

  factory TeacherIncidentReport.fromRow(Map<String, dynamic> row) =>
      TeacherIncidentReport(
        id: row['id'] as String,
        category: incidentCategoryFromDb(row['category'] as String),
        room: row['room'] as String?,
        status: row['status'] as String,
        reporterName: row['reporter_name'] as String? ?? 'นักเรียน',
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
        acknowledgedAt: row['acknowledged_at'] == null
            ? null
            : DateTime.parse(row['acknowledged_at'] as String).toUtc(),
        reason: row['reason'] as String?,
        severity: row['severity'] as String?,
      );
}

class IncidentSummaryItem {
  const IncidentSummaryItem({
    required this.category,
    required this.totalCount,
    this.avgResponseSeconds,
  });

  final IncidentCategory category;
  final int totalCount;
  final double? avgResponseSeconds;

  factory IncidentSummaryItem.fromRow(Map<String, dynamic> row) =>
      IncidentSummaryItem(
        category: incidentCategoryFromDb(row['category'] as String),
        totalCount: (row['total_count'] as num).toInt(),
        avgResponseSeconds: row['avg_response_seconds'] == null
            ? null
            : (row['avg_response_seconds'] as num).toDouble(),
      );
}

class SchoolSensorAlertRecord {
  const SchoolSensorAlertRecord({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceCode,
    required this.schoolId,
    required this.metric,
    required this.value,
    required this.triggeredAt,
    required this.status,
    this.thresholdId,
    this.acknowledgedBy,
    this.acknowledgedByName,
    this.acknowledgedAt,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceCode;
  final String schoolId;
  final String metric;
  final double value;
  final DateTime triggeredAt;
  final String status;
  final String? thresholdId;
  final String? acknowledgedBy;
  final String? acknowledgedByName;
  final DateTime? acknowledgedAt;

  bool get isNew => status == 'new';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isResolved => status == 'resolved';

  factory SchoolSensorAlertRecord.fromRow(Map<String, dynamic> row) =>
      SchoolSensorAlertRecord(
        id: row['id'] as String,
        deviceId: row['device_id'] as String,
        deviceName: row['device_name'] as String? ?? 'Unknown Device',
        deviceCode: row['device_code'] as String? ?? 'DEV-UNKNOWN',
        schoolId: row['school_id'] as String,
        thresholdId: row['threshold_id'] as String?,
        metric: row['metric'] as String? ?? 'unknown',
        value: (row['value'] as num?)?.toDouble() ?? 0.0,
        triggeredAt: row['triggered_at'] != null
            ? DateTime.parse(row['triggered_at'] as String).toLocal()
            : DateTime.now(),
        status: row['status'] as String? ?? 'new',
        acknowledgedBy: row['acknowledged_by'] as String?,
        acknowledgedByName: row['acknowledged_by_name'] as String?,
        acknowledgedAt: row['acknowledged_at'] != null
            ? DateTime.parse(row['acknowledged_at'] as String).toLocal()
            : null,
      );
}
