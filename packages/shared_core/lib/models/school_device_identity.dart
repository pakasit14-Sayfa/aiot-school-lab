class SchoolDeviceIdentity {
  SchoolDeviceIdentity.fromRow(Map<String, dynamic> row)
    : id = row['id'] as String,
      name = row['name'] as String,
      type = row['type'] as String,
      status = row['status'] as String,
      deviceCode = row['device_code'] as String?,
      kitCode = row['kit_code'] as String?,
      location = row['location'] as String?,
      building = row['building'] as String?,
      room = row['room'] as String?;
  final String id, name, type, status;
  final String? deviceCode, kitCode, location, building, room;
}

/// รายละเอียดอุปกรณ์รายตัว (get_school_device_detail) — ค่าที่อุปกรณ์ยังไม่เคย
/// รายงานเป็น null ให้หน้าบอกว่า "ยังไม่มีข้อมูล" ไม่ใช่ค่าเริ่มต้นแต่ง
class SchoolDeviceDetail {
  const SchoolDeviceDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.effectiveStatus,
    required this.serialNo,
    required this.deviceCode,
    required this.kitCode,
    required this.categoryCode,
    required this.location,
    required this.building,
    required this.room,
    required this.ipAddress,
    required this.firmwareVersion,
    required this.lastSeenAt,
    required this.registeredAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final String effectiveStatus;
  final String? serialNo;
  final String? deviceCode;
  final String? kitCode;
  final String? categoryCode;
  final String? location;
  final String? building;
  final String? room;
  final String? ipAddress;
  final String? firmwareVersion;
  final DateTime? lastSeenAt;
  final DateTime? registeredAt;
  final DateTime? updatedAt;

  factory SchoolDeviceDetail.fromRow(Map<String, dynamic> row) {
    DateTime? ts(Object? v) => v == null ? null : DateTime.parse(v as String);
    return SchoolDeviceDetail(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? '',
      type: (row['type'] as String?) ?? '',
      status: (row['status'] as String?) ?? 'offline',
      effectiveStatus: (row['effective_status'] as String?) ?? 'offline',
      serialNo: row['serial_no'] as String?,
      deviceCode: row['device_code'] as String?,
      kitCode: row['kit_code'] as String?,
      categoryCode: row['category_code'] as String?,
      location: row['location'] as String?,
      building: row['building'] as String?,
      room: row['room'] as String?,
      ipAddress: row['ip_address'] as String?,
      firmwareVersion: row['firmware_version'] as String?,
      lastSeenAt: ts(row['last_seen_at']),
      registeredAt: ts(row['registered_at']),
      updatedAt: ts(row['updated_at']),
    );
  }
}
