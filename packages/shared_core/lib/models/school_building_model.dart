class SchoolBuildingRecord {
  final String id;
  final String schoolId;
  final String name;
  final String code;
  final int floors;
  final int roomsCount;
  final String managerName;
  final int devicesCount;
  final int trainingKitsCount;
  final String status;
  final String note;

  const SchoolBuildingRecord({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.code,
    required this.floors,
    required this.roomsCount,
    required this.managerName,
    required this.devicesCount,
    required this.trainingKitsCount,
    required this.status,
    required this.note,
  });

  factory SchoolBuildingRecord.fromRow(Map<String, dynamic> row) {
    return SchoolBuildingRecord(
      id: row['id']?.toString() ?? '',
      schoolId: row['school_id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      code: row['code']?.toString() ?? '',
      floors: (row['floors'] as num?)?.toInt() ?? 1,
      roomsCount: (row['rooms_count'] as num?)?.toInt() ?? 0,
      managerName: row['manager_name']?.toString() ?? '',
      devicesCount: (row['devices_count'] as num?)?.toInt() ?? 0,
      trainingKitsCount: (row['training_kits_count'] as num?)?.toInt() ?? 0,
      status: row['status']?.toString() ?? 'active',
      note: row['note']?.toString() ?? '',
    );
  }
}

class SchoolRoomRecord {
  final String id;
  final String schoolId;
  final String? buildingId;
  final String buildingName;
  final String name;
  final String code;
  // Nullable — `floor` has no schema-level default, so a genuinely-unset
  // floor must stay null rather than being papered over with a fabricated
  // 'ชั้น 1'. Same for `resourceStatus`: there's no RPC/column anywhere
  // that measures a room's "resource status", so it's always null now
  // instead of a hardcoded 'ปกติ' claiming a health check that never ran.
  final String? floor;
  final String roomType;
  final int capacity;
  final String teacherName;
  final int devicesCount;
  final int trainingKitsCount;
  final String status;
  final String? resourceStatus;

  const SchoolRoomRecord({
    required this.id,
    required this.schoolId,
    this.buildingId,
    required this.buildingName,
    required this.name,
    required this.code,
    this.floor,
    required this.roomType,
    required this.capacity,
    required this.teacherName,
    required this.devicesCount,
    required this.trainingKitsCount,
    required this.status,
    this.resourceStatus,
  });

  factory SchoolRoomRecord.fromRow(Map<String, dynamic> row) {
    return SchoolRoomRecord(
      id: row['id']?.toString() ?? '',
      schoolId: row['school_id']?.toString() ?? '',
      buildingId: row['building_id']?.toString(),
      buildingName: row['building_name']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      code: row['code']?.toString() ?? '',
      floor: row['floor']?.toString(),
      roomType: row['room_type']?.toString() ?? 'ห้องเรียน',
      capacity: (row['capacity'] as num?)?.toInt() ?? 30,
      teacherName: row['teacher_name']?.toString() ?? '',
      devicesCount: (row['devices_count'] as num?)?.toInt() ?? 0,
      trainingKitsCount: (row['training_kits_count'] as num?)?.toInt() ?? 0,
      status: row['status']?.toString() ?? 'active',
      resourceStatus: row['resource_status']?.toString(),
    );
  }
}

class SchoolAdminDashboardSummary {
  final String schoolId;
  final String schoolName;
  final String schoolCode;
  final int studentsCount;
  final int teachersCount;
  final int devicesCount;
  final int devicesOnline;
  final int buildingsCount;
  final int roomsCount;
  final int openAlertsCount;

  const SchoolAdminDashboardSummary({
    required this.schoolId,
    required this.schoolName,
    required this.schoolCode,
    required this.studentsCount,
    required this.teachersCount,
    required this.devicesCount,
    required this.devicesOnline,
    required this.buildingsCount,
    required this.roomsCount,
    required this.openAlertsCount,
  });

  factory SchoolAdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return SchoolAdminDashboardSummary(
      schoolId: json['school_id']?.toString() ?? '',
      schoolName: json['school_name']?.toString() ?? '',
      schoolCode: json['school_code']?.toString() ?? '',
      studentsCount: (json['students_count'] as num?)?.toInt() ?? 0,
      teachersCount: (json['teachers_count'] as num?)?.toInt() ?? 0,
      devicesCount: (json['devices_count'] as num?)?.toInt() ?? 0,
      devicesOnline: (json['devices_online'] as num?)?.toInt() ?? 0,
      buildingsCount: (json['buildings_count'] as num?)?.toInt() ?? 0,
      roomsCount: (json['rooms_count'] as num?)?.toInt() ?? 0,
      openAlertsCount: (json['open_alerts_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SchoolAdminAuditLog {
  final int id;
  final String action;
  final String target;
  final String detail;
  final String actorName;
  final String actorRole;
  final DateTime createdAt;

  const SchoolAdminAuditLog({
    required this.id,
    required this.action,
    required this.target,
    required this.detail,
    required this.actorName,
    required this.actorRole,
    required this.createdAt,
  });

  factory SchoolAdminAuditLog.fromRow(Map<String, dynamic> row) {
    return SchoolAdminAuditLog(
      id: (row['id'] as num?)?.toInt() ?? 0,
      action: row['action']?.toString() ?? '',
      target: row['target']?.toString() ?? '',
      detail: row['detail']?.toString() ?? '',
      actorName: row['actor_name']?.toString() ?? '',
      actorRole: row['actor_role']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
