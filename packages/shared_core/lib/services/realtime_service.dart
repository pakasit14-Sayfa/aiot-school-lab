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

  /// Broadcast so a single stream can back more than one live [StreamBuilder]
  /// — e.g. a [LayoutBuilder] whose `builder` runs more than once per layout
  /// pass (documented Flutter behavior) can otherwise attach two listeners
  /// to what would be a single-subscription stream and crash with "Stream
  /// has already been listened to".
  static Stream<T> _poll<T>(Future<T> Function() fetch) {
    Stream<T> generate() async* {
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

    return generate().asBroadcastStream();
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

    final metricUpdatedAt = <String, DateTime>{
      for (final entry in tsByMetric.entries)
        if (entry.value != null) entry.key: entry.value!,
    };

    return SensorModel(
      pm25: values['pm25'] ?? 0,
      temperature: values['temperature'] ?? 0,
      humidity: values['humidity'] ?? 0,
      lux: values['light_lux'] ?? 0,
      co2: values['co2'] ?? 0,
      tvoc: values['tvoc'] ?? 0,
      updatedAt: updatedAt,
      metricUpdatedAt: metricUpdatedAt,
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

  /// Raw sensor_latest rows, polled the same way as [sensorStream] — for
  /// metrics that aren't tracked fields on [SensorModel] (aqi,
  /// gas_mq2_percent). Fixes a real bug: callers that fetched these once
  /// via [AiotLabService.getLatestSensorReadings] in initState and never
  /// again showed a permanently stale snapshot from whenever the page
  /// first loaded, while the header's freshness dot (computed live from
  /// the stale row's own timestamp) correctly — but misleadingly — kept
  /// counting up ("1 วันที่แล้ว" and climbing) as if the whole app were
  /// broken, when only these two metrics were never being refetched.
  static Stream<List<Map<String, dynamic>>> rawReadingsStream() {
    return _poll(_fetchLatest);
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

  /// รายชื่ออุปกรณ์จริงทั้งหมดในโรงเรียน (ดู
  /// supabase/migrations/20260826020000_rename_list_school_devices.sql)
  static Future<List<DeviceOption>> listSchoolDevices() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc('list_school_devices', params: {'p_token': token})
            as List;
    return rows
        .map((row) => DeviceOption.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static void enableOffline() {
    // Polling needs no offline setup; readings queue on the gateway side.
  }

  /// Which of the 4 "weather" metrics (pm25/temperature/humidity/
  /// light_lux) actually have at least one real reading anywhere in the
  /// caller's school. `SensorModel` defaults an absent metric to 0, which
  /// is indistinguishable from a real 0 reading — callers that need to
  /// show an honest "no data" per metric (not just "no data for this
  /// device at all") should check this set rather than trusting a
  /// non-null `SensorModel` alone.
  static Future<Set<String>> getWeatherMetricsWithData() async {
    final rows = await _fetchLatest();
    return rows
        .map((r) => r['metric'] as String?)
        .whereType<String>()
        .where(
          (m) =>
              m == 'pm25' ||
              m == 'temperature' ||
              m == 'humidity' ||
              m == 'light_lux',
        )
        .toSet();
  }

  /// One-shot snapshot of every device's latest sensor readings, keyed by
  /// device location (or name). A device with zero real readings simply
  /// won't be a key in the returned map — callers should treat that as
  /// "no data yet", not synthesize a fake zero.
  static Future<Map<String, SensorModel>> getAllDeviceSensors() async {
    return modelsByDevice(await _fetchLatest(), '');
  }

  /// Real threshold list for the caller's school (see
  /// supabase/migrations/20260826160000_teacher_aiot_thresholds.sql).
  static Future<List<Map<String, dynamic>>> listThresholds() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc('list_thresholds', params: {'p_token': token})
            as List;
    return rows.cast<Map<String, dynamic>>();
  }

  /// Real threshold upsert (create or update the school-wide threshold for
  /// [metric]) — see set_threshold in the same migration.
  static Future<void> setThreshold({
    required String metric,
    required double min,
    required double max,
    bool isActive = true,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'set_threshold',
      params: {
        'p_token': token,
        'p_metric': metric,
        'p_min': min,
        'p_max': max,
        'p_is_active': isActive,
      },
    );
  }

  /// Real alert list for the caller's school (teacher/school_admin/
  /// super_admin — see list_school_alerts in the same migration).
  static Future<List<Map<String, dynamic>>> listAlerts({String? status}) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_school_alerts',
              params: {'p_token': token, 'p_status': status},
            )
            as List;
    return rows.cast<Map<String, dynamic>>();
  }

  /// Real alert acknowledge (see acknowledge_sensor_alert_for_school_admin
  /// in the same migration — despite the name, teacher is allowed too).
  static Future<void> acknowledgeAlert(String alertId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'acknowledge_sensor_alert_for_school_admin',
      params: {'p_token': token, 'p_alert_id': alertId},
    );
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
