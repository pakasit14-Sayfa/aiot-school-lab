/// The last state a relay actually reported, as recorded in
/// `device_relay_states`.
///
/// This is the only source of truth for "is this switch on right now".
/// `queue_device_command` merely enqueues an instruction — the gateway polls
/// it, drives the board, and the device calls `ack_device_command`, which is
/// what writes this row. A device that has never acknowledged a command has
/// no row here at all, and that absence is meaningful: it is "unknown", not
/// "off". Rendering a missing row as off is what let the control page show
/// every relay as switched off regardless of what the hardware was doing.
class DeviceRelayState {
  const DeviceRelayState({
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.relayNo,
    required this.state,
    required this.updatedAt,
  });

  final String deviceId;
  final String deviceName;
  final String? location;

  /// Which relay on the board. A device may expose more than one.
  final int relayNo;

  /// The state the device last confirmed.
  final bool state;

  /// When the device confirmed it. Shown to the admin so a stale
  /// confirmation is not mistaken for a live reading.
  final DateTime? updatedAt;

  factory DeviceRelayState.fromRow(Map<String, dynamic> row) {
    return DeviceRelayState(
      deviceId: row['device_id'].toString(),
      deviceName: row['device_name']?.toString() ?? '',
      location: row['location']?.toString(),
      relayNo: (row['relay_no'] as num?)?.toInt() ?? 0,
      state: row['state'] == true,
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
    );
  }
}
