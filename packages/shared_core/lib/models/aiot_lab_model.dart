class AiotLabDeviceItem {
  AiotLabDeviceItem({
    required this.deviceId,
    required this.name,
    required this.type,
    required this.location,
    required this.status,
    required this.courseId,
    required this.courseName,
  });

  factory AiotLabDeviceItem.fromRow(Map<String, dynamic> row) {
    return AiotLabDeviceItem(
      deviceId: row['device_id'] as String,
      name: (row['name'] as String?) ?? '',
      type: (row['type'] as String?) ?? 'relay',
      location: (row['location'] as String?) ?? '',
      status: (row['status'] as String?) ?? 'offline',
      courseId: row['course_id'] as String,
      courseName: (row['course_name'] as String?) ?? '',
    );
  }

  final String deviceId;
  final String name;
  final String type;
  final String location;
  final String status;
  final String courseId;
  final String courseName;
}

class AiotCommandHistoryItem {
  AiotCommandHistoryItem({
    required this.commandId,
    required this.deviceId,
    required this.deviceName,
    required this.command,
    required this.createdByName,
    required this.createdAt,
    this.deliveredAt,
  });

  factory AiotCommandHistoryItem.fromRow(Map<String, dynamic> row) {
    return AiotCommandHistoryItem(
      commandId: row['command_id'] as String,
      deviceId: row['device_id'] as String,
      deviceName: (row['device_name'] as String?) ?? 'อุปกรณ์',
      command: (row['command'] as Map<String, dynamic>?) ?? {},
      createdByName: (row['created_by_name'] as String?) ?? 'ผู้ใช้',
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String).toLocal()
          : DateTime.now(),
      deliveredAt: row['delivered_at'] != null
          ? DateTime.parse(row['delivered_at'] as String).toLocal()
          : null,
    );
  }

  final String commandId;
  final String deviceId;
  final String deviceName;
  final Map<String, dynamic> command;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? deliveredAt;
}
