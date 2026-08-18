class EmergencyEventItem {
  EmergencyEventItem({
    required this.id,
    required this.schoolId,
    this.sourceDeviceId,
    required this.deviceName,
    required this.location,
    required this.triggeredAt,
    required this.status, // 'new', 'acknowledged', 'closed'
    required this.warningLightOn,
    this.acknowledgedBy,
    this.acknowledgedByName,
    this.acknowledgedAt,
    this.closedAt,
    this.reviewNote,
  });

  factory EmergencyEventItem.fromRow(Map<String, dynamic> row) {
    return EmergencyEventItem(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      sourceDeviceId: row['source_device_id'] as String?,
      deviceName: (row['device_name'] as String?) ?? 'ปุ่มกดกายภาพ',
      location: (row['location'] as String?) ?? 'ไม่ระบุตำแหน่ง',
      triggeredAt: row['triggered_at'] != null
          ? DateTime.parse(row['triggered_at'] as String).toLocal()
          : DateTime.now(),
      status: (row['status'] as String?) ?? 'new',
      warningLightOn: (row['warning_light_on'] as bool?) ?? false,
      acknowledgedBy: row['acknowledged_by'] as String?,
      acknowledgedByName: row['acknowledged_by_name'] as String?,
      acknowledgedAt: row['acknowledged_at'] != null
          ? DateTime.parse(row['acknowledged_at'] as String).toLocal()
          : null,
      closedAt: row['closed_at'] != null
          ? DateTime.parse(row['closed_at'] as String).toLocal()
          : null,
      reviewNote: row['review_note'] as String?,
    );
  }

  final String id;
  final String schoolId;
  final String? sourceDeviceId;
  final String deviceName;
  final String location;
  final DateTime triggeredAt;
  final String status;
  final bool warningLightOn;
  final String? acknowledgedBy;
  final String? acknowledgedByName;
  final DateTime? acknowledgedAt;
  final DateTime? closedAt;
  final String? reviewNote;

  bool get isNew => status == 'new';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isClosed => status == 'closed';
}
