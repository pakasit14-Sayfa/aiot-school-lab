import '../models/device_schedule_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class DeviceScheduleService {
  static Future<List<DeviceSchedule>> listSchedules({String? deviceId}) async {
    final rows =
        await supabase.rpc(
              'list_device_schedules',
              params: {
                'p_token': AuthService.sessionToken,
                'p_device_id': deviceId,
              },
            )
            as List;

    return rows
        .map((row) => DeviceSchedule.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String> createSchedule({
    required String deviceId,
    required String label,
    required Map<String, dynamic> command,
    required List<int> daysOfWeek,
    required String timeOfDay,
  }) async {
    final res = await supabase.rpc(
      'create_device_schedule',
      params: {
        'p_token': AuthService.sessionToken,
        'p_device_id': deviceId,
        'p_label': label.trim(),
        'p_command': command,
        'p_days_of_week': daysOfWeek,
        'p_time_of_day': timeOfDay,
      },
    );

    return res.toString();
  }

  static Future<void> toggleSchedule({
    required String scheduleId,
    required bool enabled,
  }) async {
    await supabase.rpc(
      'toggle_device_schedule',
      params: {
        'p_token': AuthService.sessionToken,
        'p_schedule_id': scheduleId,
        'p_enabled': enabled,
      },
    );
  }

  static Future<void> deleteSchedule({required String scheduleId}) async {
    await supabase.rpc(
      'delete_device_schedule',
      params: {
        'p_token': AuthService.sessionToken,
        'p_schedule_id': scheduleId,
      },
    );
  }
}
