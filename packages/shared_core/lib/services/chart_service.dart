import '../models/chart_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// PBL-7: charts over real sensor readings. All four calls are
/// token-authenticated RPCs (20260918020000_charts_rpc.sql); the server
/// enforces the same read scope as sensor_history.
class ChartService {
  static Future<List<ChartableDataset>> listMySensorDatasets() async {
    final rows =
        await supabase.rpc(
              'list_my_sensor_datasets',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map(
          (r) => ChartableDataset.fromRow(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  static Future<String> createChart({
    required String deviceId,
    required String metric,
    required DateTime timeStart,
    required DateTime timeEnd,
    String chartType = 'line',
    String? courseId,
    String? annotation,
  }) async {
    final id = await supabase.rpc(
      'create_chart',
      params: {
        'p_token': AuthService.sessionToken,
        'p_device_id': deviceId,
        'p_metric': metric,
        'p_time_start': timeStart.toUtc().toIso8601String(),
        'p_time_end': timeEnd.toUtc().toIso8601String(),
        'p_chart_type': chartType,
        'p_course_id': courseId,
        'p_annotation': annotation,
      },
    );
    return id as String;
  }

  static Future<List<SavedChart>> listMyCharts() async {
    final rows =
        await supabase.rpc(
              'list_my_charts',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map((r) => SavedChart.fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> deleteChart(String chartId) async {
    await supabase.rpc(
      'delete_chart',
      params: {'p_token': AuthService.sessionToken, 'p_chart_id': chartId},
    );
  }
}
