class SchoolPlatformRecord {
  const SchoolPlatformRecord({
    required this.id,
    required this.schoolCode,
    required this.name,
    required this.province,
    required this.adminEmail,
    required this.packageName,
    required this.status,
    required this.maxUsers,
    required this.maxDevices,
    required this.usersCount,
    required this.devicesTotal,
    required this.devicesOnline,
    required this.buildingsCount,
    required this.roomsCount,
    required this.alertsCount,
    this.licenseExpiresAt,
    this.createdAt,
    this.updatedAt,
    this.lastSyncAt,
  });

  final String id;
  final String schoolCode;
  final String name;
  final String province;
  final String adminEmail;
  final String packageName;
  final String status;
  final int maxUsers;
  final int maxDevices;
  final int usersCount;
  final int devicesTotal;
  final int devicesOnline;
  final int buildingsCount;
  final int roomsCount;
  final int alertsCount;
  final DateTime? licenseExpiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncAt;

  int get licenseDaysLeft {
    if (licenseExpiresAt == null) return 365;
    final diff = licenseExpiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory SchoolPlatformRecord.fromJson(Map<String, dynamic> json) {
    return SchoolPlatformRecord(
      id: json['id']?.toString() ?? '',
      schoolCode: json['school_code']?.toString() ?? '-',
      name: json['name']?.toString() ?? '-',
      province: json['province']?.toString() ?? '-',
      adminEmail: json['admin_email']?.toString() ?? '-',
      packageName: json['package_name']?.toString() ?? 'Basic',
      status: json['status']?.toString() ?? 'active',
      maxUsers: (json['max_users'] as num?)?.toInt() ?? 100,
      maxDevices: (json['max_devices'] as num?)?.toInt() ?? 100,
      usersCount: (json['users_count'] as num?)?.toInt() ?? 0,
      devicesTotal: (json['devices_total'] as num?)?.toInt() ?? 0,
      devicesOnline: (json['devices_online'] as num?)?.toInt() ?? 0,
      buildingsCount: (json['buildings_count'] as num?)?.toInt() ?? 0,
      roomsCount: (json['rooms_count'] as num?)?.toInt() ?? 0,
      alertsCount: (json['alerts_count'] as num?)?.toInt() ?? 0,
      licenseExpiresAt: json['license_expires_at'] != null
          ? DateTime.tryParse(json['license_expires_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.tryParse(json['last_sync_at'].toString())?.toLocal()
          : null,
    );
  }
}

class DeviceControlSchoolRecord {
  const DeviceControlSchoolRecord({
    required this.databaseId,
    required this.schoolCode,
    required this.name,
    required this.province,
    required this.packageName,
    required this.status,
    required this.totalDevices,
    required this.onlineDevices,
    required this.openAlerts,
  });

  final String databaseId;
  final String schoolCode;
  final String name;
  final String province;
  final String packageName;
  final String status;
  final int totalDevices;
  final int onlineDevices;
  final int openAlerts;

  factory DeviceControlSchoolRecord.fromJson(Map<String, dynamic> json) {
    return DeviceControlSchoolRecord(
      databaseId: json['database_id']?.toString() ?? '',
      schoolCode: json['school_code']?.toString() ?? '-',
      name: json['name']?.toString() ?? '-',
      province: json['province']?.toString() ?? 'ไม่ระบุจังหวัด',
      packageName: json['package_name']?.toString() ?? 'Basic',
      status: json['status']?.toString() ?? 'active',
      totalDevices: (json['total_devices'] as num?)?.toInt() ?? 0,
      onlineDevices: (json['online_devices'] as num?)?.toInt() ?? 0,
      openAlerts: (json['open_alerts'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeviceControlItemRecord {
  const DeviceControlItemRecord({
    required this.databaseId,
    required this.schoolId,
    required this.schoolName,
    required this.categoryCode,
    required this.deviceCode,
    required this.name,
    required this.building,
    required this.room,
    required this.status,
    required this.online,
    required this.metadata,
    this.updatedAt,
    this.readingMetric,
    this.readingValue,
    this.readingAt,
  });

  final String databaseId;
  final String schoolId;
  final String schoolName;
  final String categoryCode;
  final String deviceCode;
  final String name;
  final String building;
  final String room;
  final String status;
  final bool online;
  final Map<String, dynamic> metadata;
  final DateTime? updatedAt;
  final String? readingMetric;
  final num? readingValue;
  final DateTime? readingAt;

  String get readingLabel {
    if (readingMetric == null || readingValue == null) return '-';
    return '$readingValue $readingMetric';
  }

  bool get isPoweredOn {
    final power = metadata['power'] ?? metadata['power_status'] ?? metadata['relay_state'];
    if (power is bool) return power;
    if (power is String) return power.toLowerCase() == 'on' || power.toLowerCase() == 'true';
    return false;
  }

  String get controlMode {
    final mode = metadata['mode'] ?? metadata['control_mode'];
    return mode?.toString() ?? 'manual';
  }

  factory DeviceControlItemRecord.fromJson(Map<String, dynamic> json) {
    return DeviceControlItemRecord(
      databaseId: json['database_id']?.toString() ?? '',
      schoolId: json['school_id']?.toString() ?? '',
      schoolName: json['school_name']?.toString() ?? '-',
      categoryCode: json['category_code']?.toString() ?? 'unknown',
      deviceCode: json['device_code']?.toString() ?? '-',
      name: json['name']?.toString() ?? '-',
      building: json['building']?.toString() ?? '-',
      room: json['room']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'offline',
      online: json['online'] as bool? ?? (json['status'] == 'online'),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : <String, dynamic>{},
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
      readingMetric: json['reading_metric']?.toString(),
      readingValue: json['reading_value'] is num
          ? json['reading_value'] as num
          : num.tryParse(json['reading_value']?.toString() ?? ''),
      readingAt: json['reading_ts'] != null
          ? DateTime.tryParse(json['reading_ts'].toString())?.toLocal()
          : null,
    );
  }
}

class DeviceControlApprovalRecord {
  const DeviceControlApprovalRecord({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.deviceId,
    required this.deviceName,
    required this.command,
    required this.requestedBy,
    required this.requesterName,
    required this.status,
    this.reviewedBy,
    this.reviewerName,
    this.reviewedAt,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String schoolName;
  final String deviceId;
  final String deviceName;
  final String command;
  final String requestedBy;
  final String requesterName;
  final String status;
  final String? reviewedBy;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final String? notes;
  final DateTime? createdAt;

  factory DeviceControlApprovalRecord.fromJson(Map<String, dynamic> json) {
    return DeviceControlApprovalRecord(
      id: json['id']?.toString() ?? '',
      schoolId: json['school_id']?.toString() ?? '',
      schoolName: json['school_name']?.toString() ?? '-',
      deviceId: json['device_id']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? '-',
      command: json['command']?.toString() ?? 'power_off',
      requestedBy: json['requested_by']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? 'ผู้ใช้งาน',
      status: json['status']?.toString() ?? 'pending',
      reviewedBy: json['reviewed_by']?.toString(),
      reviewerName: json['reviewer_name']?.toString(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())?.toLocal()
          : null,
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }
}

class DeviceControlPermissionRecord {
  const DeviceControlPermissionRecord({
    required this.email,
    required this.fullName,
    required this.role,
    this.schoolId,
    this.schoolName,
  });

  final String email;
  final String fullName;
  final String role;
  final String? schoolId;
  final String? schoolName;

  factory DeviceControlPermissionRecord.fromJson(Map<String, dynamic> json) {
    return DeviceControlPermissionRecord(
      email: json['email']?.toString() ?? '-',
      fullName: json['full_name']?.toString() ?? '-',
      role: json['role']?.toString() ?? 'viewer',
      schoolId: json['school_id']?.toString(),
      schoolName: json['school_name']?.toString() ?? 'ทุกโรงเรียน',
    );
  }
}

class DeviceControlLogRecord {
  const DeviceControlLogRecord({
    required this.id,
    required this.deviceId,
    required this.schoolId,
    required this.eventType,
    required this.message,
    this.metadata,
    this.createdAt,
  });

  final String id;
  final String deviceId;
  final String schoolId;
  final String eventType;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  factory DeviceControlLogRecord.fromJson(Map<String, dynamic> json) {
    return DeviceControlLogRecord(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      schoolId: json['school_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? 'info',
      message: json['message']?.toString() ?? '',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }
}

class DeviceControlDataModel {
  const DeviceControlDataModel({
    required this.schools,
    required this.devices,
    required this.commands,
    required this.approvals,
    required this.permissions,
    required this.logs,
    required this.currentUserId,
    required this.currentRole,
    this.currentSchoolId,
  });

  final List<DeviceControlSchoolRecord> schools;
  final List<DeviceControlItemRecord> devices;
  final List<Map<String, dynamic>> commands;
  final List<DeviceControlApprovalRecord> approvals;
  final List<DeviceControlPermissionRecord> permissions;
  final List<DeviceControlLogRecord> logs;
  final String currentUserId;
  final String currentRole;
  final String? currentSchoolId;

  factory DeviceControlDataModel.fromJson(Map<String, dynamic> json) {
    return DeviceControlDataModel(
      schools: (json['schools'] as List? ?? [])
          .map((e) => DeviceControlSchoolRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      devices: (json['devices'] as List? ?? [])
          .map((e) => DeviceControlItemRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      commands: (json['commands'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      approvals: (json['approvals'] as List? ?? [])
          .map((e) => DeviceControlApprovalRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      permissions: (json['permissions'] as List? ?? [])
          .map((e) => DeviceControlPermissionRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      logs: (json['logs'] as List? ?? [])
          .map((e) => DeviceControlLogRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentUserId: json['current_user_id']?.toString() ?? '',
      currentRole: json['current_role']?.toString() ?? 'super_admin',
      currentSchoolId: json['current_school_id']?.toString(),
    );
  }
}
