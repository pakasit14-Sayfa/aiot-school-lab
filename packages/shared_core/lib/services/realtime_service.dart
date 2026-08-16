import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/lesson_model.dart' show DeviceOption;
import '../models/sensor_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Real sensor data via the sensor_latest RPC (see
/// supabase/migrations/20260720010000_sensor_ingest_rpc.sql), polled every
/// [_pollInterval]. Replaces the previous hardcoded mock.
///
/// Devices carry a free-text `location` (e.g. "อาคาร 1/101"); streams match
/// it against the caller's room/building and fall back to every device in
/// the school when nothing matches, so a school with a single sensor sees
/// data on all dashboards.
class RealtimeService {
  static const _pollInterval = Duration(seconds: 5);

  static Future<List<Map<String, dynamic>>> _fetchLatest() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows = await supabase.rpc(
      'sensor_latest',
      params: {'p_token': token},
    );
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Stream<T> _poll<T>(Future<T> Function() fetch) async* {
    while (true) {
      try {
        yield await fetch();
      } catch (_) {
        // Network/server hiccup: keep the last emitted snapshot on screen
        // (StreamBuilder retains it) and retry on the next tick.
      }
      await Future.delayed(_pollInterval);
    }
  }

  /// Latest values for one room, aggregated across the devices whose
  /// location mentions [room] (falling back to the whole school).
  @visibleForTesting
  static SensorModel? modelForRoom(
    List<Map<String, dynamic>> rows,
    String room,
  ) {
    var scoped = rows;
    if (room.isNotEmpty) {
      final matched = rows
          .where((r) => (r['location'] as String? ?? '').contains(room))
          .toList();
      if (matched.isNotEmpty) scoped = matched;
    }
    return _toModel(scoped);
  }

  /// One SensorModel per device, keyed by its location (or name).
  @visibleForTesting
  static Map<String, SensorModel> modelsByDevice(
    List<Map<String, dynamic>> rows,
    String building,
  ) {
    var scoped = rows;
    if (building.isNotEmpty) {
      final matched = rows
          .where((r) => (r['location'] as String? ?? '').contains(building))
          .toList();
      if (matched.isNotEmpty) scoped = matched;
    }

    final byDevice = <String, List<Map<String, dynamic>>>{};
    for (final row in scoped) {
      final location = (row['location'] as String?)?.trim();
      final key = location != null && location.isNotEmpty
          ? location
          : (row['device_name'] as String? ?? '${row['device_id']}');
      byDevice.putIfAbsent(key, () => []).add(row);
    }

    final result = <String, SensorModel>{};
    for (final entry in byDevice.entries) {
      final model = _toModel(entry.value);
      if (model != null) result[entry.key] = model;
    }
    return result;
  }

  static SensorModel? _toModel(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;
    final values = <String, double>{};
    final tsByMetric = <String, DateTime?>{};
    DateTime? updatedAt;

    for (final row in rows) {
      final metric = row['metric'] as String?;
      if (metric == null) continue;
      final ts = DateTime.tryParse(row['ts'] as String? ?? '');

      // When several devices report the same metric, keep the newest value.
      final prevTs = tsByMetric[metric];
      if (!tsByMetric.containsKey(metric) ||
          (ts != null && (prevTs == null || ts.isAfter(prevTs)))) {
        values[metric] = _asDouble(row['value']);
        tsByMetric[metric] = ts;
      }
      if (ts != null && (updatedAt == null || ts.isAfter(updatedAt))) {
        updatedAt = ts;
      }
    }

    return SensorModel(
      pm25: values['pm25'] ?? 0,
      temperature: values['temperature'] ?? 0,
      humidity: values['humidity'] ?? 0,
      lux: values['light_lux'] ?? 0,
      updatedAt: updatedAt,
    );
  }

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  static Stream<SensorModel?> sensorStream({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) {
    return _poll(() async => modelForRoom(await _fetchLatest(), room));
  }

  static Future<SensorModel?> getSensorOnce({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) async {
    return modelForRoom(await _fetchLatest(), room);
  }

  static Stream<Map<String, SensorModel>> buildingSensorStream({
    required String schoolId,
    required String building,
  }) {
    return _poll(() async => modelsByDevice(await _fetchLatest(), building));
  }

  /// Switch control has no backend yet (no relay devices registered) —
  /// kept only so existing call sites compile.
  static Stream<Map<String, bool>> switchStream({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) {
    return Stream.value(const {});
  }

  static Future<void> setSwitch({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
    required String device,
    required bool value,
  }) async {}

  /// STK-11: สั่งเปิด/ปิดอุปกรณ์จริงผ่าน queue_device_command (ดู
  /// supabase/migrations/20260721010000_relay_commands.sql) — เกตเวย์จะ
  /// poll คำสั่งนี้แล้วส่งต่อผ่าน MQTT ให้บอร์ดจริง ไม่ใช่ mock/no-op แบบ
  /// setSwitch ด้านบนอีกต่อไป (เหลือของเดิมไว้เผื่อจุดอื่นยังอ้างอิงอยู่)
  static Future<void> queueDeviceCommand({
    required String deviceId,
    required Map<String, dynamic> command,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'queue_device_command',
      params: {'p_token': token, 'p_device_id': deviceId, 'p_command': command},
    );
  }

  /// STK-9/STK-11: รายชื่ออุปกรณ์จริงในอาคารที่ผู้ดูแลอาคารรับผิดชอบ (ดู
  /// supabase/migrations/20260817000000_facility_manager_device_list.sql)
  /// — สโคปตามอาคารในระดับ SQL แล้ว (BR4) ไม่ต้องกรองซ้ำฝั่ง Flutter
  static Future<List<DeviceOption>> listMyBuildingDevices() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_devices_in_my_building',
              params: {'p_token': token},
            )
            as List;
    return rows
        .map((row) => DeviceOption.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static void enableOffline() {
    // Polling needs no offline setup; readings queue on the gateway side.
  }

  /// Reading history for one device/metric window (LRN-8: lessons embed a
  /// real sensor window via the sensor_history RPC — see
  /// supabase/migrations/20260721020400_sensor_read_scope.sql).
  static Future<List<({DateTime ts, num value})>> getSensorHistory({
    required String deviceId,
    required String metric,
    required DateTime from,
    DateTime? to,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'sensor_history',
              params: {
                'p_token': token,
                'p_device_id': deviceId,
                'p_metric': metric,
                'p_from': from.toUtc().toIso8601String(),
                'p_to': to?.toUtc().toIso8601String(),
              },
            )
            as List;

    return rows
        .cast<Map<String, dynamic>>()
        .map(
          (row) => (
            ts: DateTime.parse(row['ts'] as String).toUtc(),
            value: row['value'] as num,
          ),
        )
        .toList();
  }
}
