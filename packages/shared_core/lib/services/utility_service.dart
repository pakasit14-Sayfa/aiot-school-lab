import '../models/utility_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class UtilityService {
  static Future<SchoolUtilityRates?> getSchoolUtilityRates() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_school_utility_rates',
              params: {'p_token': token},
            )
            as List;
    if (rows.isEmpty) return null;
    return SchoolUtilityRates.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<void> setSchoolUtilityRates({
    required double electricityRateThb,
    required double waterRateThb,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'set_school_utility_rates',
      params: {
        'p_token': token,
        'p_electricity_rate_thb': electricityRateThb,
        'p_water_rate_thb': waterRateThb,
      },
    );
  }

  static Future<EnergyUsageSummary?> getEnergyUsageSummary({
    String period = 'month',
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_energy_usage_summary',
              params: {'p_token': token, 'p_period': period},
            )
            as List;
    if (rows.isEmpty) return null;
    return EnergyUsageSummary.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<WaterUsageSummary?> getWaterUsageSummary({
    String period = 'month',
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_water_usage_summary',
              params: {'p_token': token, 'p_period': period},
            )
            as List;
    if (rows.isEmpty) return null;
    return WaterUsageSummary.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<List<UtilityTrendPoint>> getEnergyUsageTrend({
    int days = 7,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return [];
    final rows =
        await supabase.rpc(
              'get_energy_usage_trend',
              params: {'p_token': token, 'p_days': days},
            )
            as List;
    return rows
        .map(
          (r) => UtilityTrendPoint.fromEnergyRow(r as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<List<UtilityTrendPoint>> getWaterUsageTrend({
    int days = 7,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return [];
    final rows =
        await supabase.rpc(
              'get_water_usage_trend',
              params: {'p_token': token, 'p_days': days},
            )
            as List;
    return rows
        .map((r) => UtilityTrendPoint.fromWaterRow(r as Map<String, dynamic>))
        .toList();
  }

  static Future<UtilityEfficiencyScore?> getEnergyEfficiencyScore() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_energy_efficiency_score',
              params: {'p_token': token},
            )
            as List;
    if (rows.isEmpty) return null;
    return UtilityEfficiencyScore.fromEnergyRow(
      rows.first as Map<String, dynamic>,
    );
  }

  static Future<UtilityEfficiencyScore?> getWaterEfficiencyScore() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_water_efficiency_score',
              params: {'p_token': token},
            )
            as List;
    if (rows.isEmpty) return null;
    return UtilityEfficiencyScore.fromWaterRow(
      rows.first as Map<String, dynamic>,
    );
  }
}
