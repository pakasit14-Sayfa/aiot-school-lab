class SchoolUtilityRates {
  const SchoolUtilityRates({
    required this.electricityRateThb,
    required this.isElectricityDefault,
    required this.waterRateThb,
    required this.isWaterDefault,
  });

  final double electricityRateThb;
  final bool isElectricityDefault;
  final double waterRateThb;
  final bool isWaterDefault;

  factory SchoolUtilityRates.fromRow(Map<String, dynamic> row) =>
      SchoolUtilityRates(
        electricityRateThb:
            (row['electricity_rate_thb'] as num?)?.toDouble() ?? 4.50,
        isElectricityDefault: row['is_electricity_default'] as bool? ?? true,
        waterRateThb: (row['water_rate_thb'] as num?)?.toDouble() ?? 18.00,
        isWaterDefault: row['is_water_default'] as bool? ?? true,
      );
}

class EnergyUsageSummary {
  const EnergyUsageSummary({
    required this.deviceCount,
    required this.totalKwh,
    required this.electricityRateThb,
    required this.isRateDefault,
    required this.estimatedCostThb,
    required this.disclaimer,
  });

  final int deviceCount;
  final double totalKwh;
  final double electricityRateThb;
  final bool isRateDefault;
  final double estimatedCostThb;
  final String disclaimer;

  factory EnergyUsageSummary.fromRow(Map<String, dynamic> row) =>
      EnergyUsageSummary(
        deviceCount: (row['device_count'] as num?)?.toInt() ?? 0,
        totalKwh: (row['total_kwh'] as num?)?.toDouble() ?? 0.0,
        electricityRateThb:
            (row['electricity_rate_thb'] as num?)?.toDouble() ?? 4.50,
        isRateDefault: row['is_rate_default'] as bool? ?? true,
        estimatedCostThb:
            (row['estimated_cost_thb'] as num?)?.toDouble() ?? 0.0,
        disclaimer: row['disclaimer'] as String? ?? '',
      );
}

class WaterUsageSummary {
  const WaterUsageSummary({
    required this.deviceCount,
    required this.totalM3,
    required this.waterRateThb,
    required this.isRateDefault,
    required this.estimatedCostThb,
    required this.disclaimer,
  });

  final int deviceCount;
  final double totalM3;
  final double waterRateThb;
  final bool isRateDefault;
  final double estimatedCostThb;
  final String disclaimer;

  factory WaterUsageSummary.fromRow(Map<String, dynamic> row) =>
      WaterUsageSummary(
        deviceCount: (row['device_count'] as num?)?.toInt() ?? 0,
        totalM3: (row['total_m3'] as num?)?.toDouble() ?? 0.0,
        waterRateThb: (row['water_rate_thb'] as num?)?.toDouble() ?? 18.00,
        isRateDefault: row['is_rate_default'] as bool? ?? true,
        estimatedCostThb:
            (row['estimated_cost_thb'] as num?)?.toDouble() ?? 0.0,
        disclaimer: row['disclaimer'] as String? ?? '',
      );
}
