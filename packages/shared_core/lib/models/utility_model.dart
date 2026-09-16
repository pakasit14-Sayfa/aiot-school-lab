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

class UtilityTrendPoint {
  const UtilityTrendPoint({required this.day, required this.value});

  final DateTime day;
  final double value;

  factory UtilityTrendPoint.fromEnergyRow(Map<String, dynamic> row) =>
      UtilityTrendPoint(
        day: DateTime.parse(row['day'] as String),
        value: (row['total_kwh'] as num?)?.toDouble() ?? 0.0,
      );

  factory UtilityTrendPoint.fromWaterRow(Map<String, dynamic> row) =>
      UtilityTrendPoint(
        day: DateTime.parse(row['day'] as String),
        value: (row['total_m3'] as num?)?.toDouble() ?? 0.0,
      );
}

class UtilityEfficiencyScore {
  const UtilityEfficiencyScore({
    required this.score,
    required this.label,
    required this.current,
    required this.previous,
  });

  /// null = ไม่มีข้อมูลช่วงก่อนหน้าให้เทียบ (เช่นเพิ่งติดตั้งมิเตอร์)
  final double? score;
  final String? label;
  final double current;
  final double previous;

  factory UtilityEfficiencyScore.fromEnergyRow(Map<String, dynamic> row) =>
      UtilityEfficiencyScore(
        score: (row['score'] as num?)?.toDouble(),
        label: row['label'] as String?,
        current: (row['current_kwh'] as num?)?.toDouble() ?? 0.0,
        previous: (row['previous_kwh'] as num?)?.toDouble() ?? 0.0,
      );

  factory UtilityEfficiencyScore.fromWaterRow(Map<String, dynamic> row) =>
      UtilityEfficiencyScore(
        score: (row['score'] as num?)?.toDouble(),
        label: row['label'] as String?,
        current: (row['current_m3'] as num?)?.toDouble() ?? 0.0,
        previous: (row['previous_m3'] as num?)?.toDouble() ?? 0.0,
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

/// การใช้ไฟฟ้า/น้ำ แยกรายอาคาร/ห้อง (get_utility_usage_by_location)
class UtilityLocationUsage {
  const UtilityLocationUsage({
    required this.building,
    required this.room,
    required this.deviceCount,
    required this.total,
  });

  final String building;
  final String room;
  final int deviceCount;
  final double total;

  factory UtilityLocationUsage.fromRow(Map<String, dynamic> row) =>
      UtilityLocationUsage(
        building: (row['building'] as String?) ?? 'ยังไม่ระบุ',
        room: (row['room'] as String?) ?? 'ยังไม่ระบุ',
        deviceCount: (row['device_count'] as num?)?.toInt() ?? 0,
        total: (row['total'] as num?)?.toDouble() ?? 0.0,
      );
}
