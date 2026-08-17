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
  });

  final String id;
  final IncidentCategory category;
  final String? room;
  final String status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? closedAt;

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
