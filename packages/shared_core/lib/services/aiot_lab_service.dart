import '../models/aiot_lab_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';
import 'realtime_service.dart';

class AiotLabService {
  static Future<List<AiotLabDeviceItem>> listTeachingKitDevices() async {
    final rows =
        await supabase.rpc(
              'list_teaching_kit_devices',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => AiotLabDeviceItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String> queueTeachingKitCommand({
    required String deviceId,
    required Map<String, dynamic> command,
  }) async {
    final res = await supabase.rpc(
      'queue_teaching_kit_command',
      params: {
        'p_token': AuthService.sessionToken,
        'p_device_id': deviceId,
        'p_command': command,
      },
    );

    return res as String;
  }

  static Future<List<AiotCommandHistoryItem>> listTeachingKitCommandHistory({
    int limit = 20,
  }) async {
    final rows =
        await supabase.rpc(
              'list_teaching_kit_command_history',
              params: {'p_token': AuthService.sessionToken, 'p_limit': limit},
            )
            as List;

    return rows
        .map(
          (row) => AiotCommandHistoryItem.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getLatestSensorReadings() async {
    return RealtimeService.getLatestReadings();
  }

  static Future<List<SensorDataPoint>> getSensorHistory({
    required String deviceId,
    required String metric,
    required DateTime from,
    DateTime? to,
    // 20260920020000: the RPC buckets the window down to this many points
    // (PostgREST would otherwise cut the raw rows at 1,000 silently).
    int maxPoints = 1000,
  }) async {
    final rows =
        await supabase.rpc(
              'sensor_history',
              params: {
                'p_max_points': maxPoints,
                'p_token': AuthService.sessionToken,
                'p_device_id': deviceId,
                'p_metric': metric,
                'p_from': from.toUtc().toIso8601String(),
                if (to != null) 'p_to': to.toUtc().toIso8601String(),
              },
            )
            as List;

    return rows
        .map((r) => SensorDataPoint.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
