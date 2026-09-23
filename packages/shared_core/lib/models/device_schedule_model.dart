class DeviceSchedule {
  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceLocation;
  final String schoolId;
  final String label;
  final Map<String, dynamic> command;
  final List<int> daysOfWeek;
  final String timeOfDay;
  final bool enabled;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;

  const DeviceSchedule({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceLocation,
    required this.schoolId,
    required this.label,
    required this.command,
    required this.daysOfWeek,
    required this.timeOfDay,
    required this.enabled,
    required this.createdBy,
    required this.createdAt,
    this.lastTriggeredAt,
  });

  factory DeviceSchedule.fromRow(Map<String, dynamic> row) {
    final rawDays = row['days_of_week'] as List? ?? [];
    final days = rawDays.map((d) => (d as num).toInt()).toList();

    return DeviceSchedule(
      id: row['id'] as String,
      deviceId: row['device_id'] as String,
      deviceName: row['device_name'] as String? ?? 'อุปกรณ์',
      deviceLocation: row['device_location'] as String? ?? '',
      schoolId: row['school_id'] as String,
      label: row['label'] as String? ?? '',
      command: Map<String, dynamic>.from(row['command'] as Map? ?? {}),
      daysOfWeek: days,
      timeOfDay: row['time_of_day'] as String,
      enabled: row['enabled'] as bool? ?? true,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastTriggeredAt: row['last_triggered_at'] != null
          ? DateTime.parse(row['last_triggered_at'] as String)
          : null,
    );
  }

  String get actionLabel {
    final act = command['action']?.toString().toLowerCase();
    if (act == 'on') return 'เปิดเครื่อง';
    if (act == 'off') return 'ปิดเครื่อง';
    return act ?? 'คำสั่ง';
  }

  String get timeFormatted {
    final parts = timeOfDay.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]} น.';
    }
    return '$timeOfDay น.';
  }

  String get daysFormatted {
    const dayNames = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
    if (daysOfWeek.length == 7) return 'ทุกวัน';
    if (daysOfWeek.length == 5 &&
        daysOfWeek.contains(1) &&
        daysOfWeek.contains(2) &&
        daysOfWeek.contains(3) &&
        daysOfWeek.contains(4) &&
        daysOfWeek.contains(5)) {
      return 'จันทร์ - ศุกร์';
    }
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted
        .map(
          (d) => (d >= 0 && d < dayNames.length) ? dayNames[d] : d.toString(),
        )
        .join(', ');
  }
}
