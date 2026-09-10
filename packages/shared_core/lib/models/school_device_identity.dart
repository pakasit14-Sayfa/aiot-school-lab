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
