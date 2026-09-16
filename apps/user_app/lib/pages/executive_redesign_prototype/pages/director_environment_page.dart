import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

/// Read seams so loading / data / empty / failure can each be driven in a
/// test without a live Supabase client.
typedef EnvUtilityLoader = Future<List<Object?>> Function();

class DirectorEnvironmentPage extends StatefulWidget {
  const DirectorEnvironmentPage({super.key, this.loadAll});

  /// Returns the seven results in the same order as the production reads:
  /// energy summary, water summary, energy trend, water trend, energy score,
  /// water score, sensor rows.
  final EnvUtilityLoader? loadAll;

  @override
  State<DirectorEnvironmentPage> createState() =>
      _DirectorEnvironmentPageState();
}

class _DirectorEnvironmentPageState extends State<DirectorEnvironmentPage> {
  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;
  List<UtilityTrendPoint> _energyTrend = [];
  List<UtilityTrendPoint> _waterTrend = [];
  UtilityEfficiencyScore? _energyScore;
  UtilityEfficiencyScore? _waterScore;
  List<Map<String, dynamic>> _sensorReadings = [];
  bool _loading = true;
  bool _loadFailed = false;

  /// School-wide mean for one `sensor_latest` metric, or null when no device
  /// reported it. Returning 0 instead would be a reading, and PM2.5 of 0 is a
  /// very different claim from "nothing is measuring PM2.5".
  double? _averageMetric(String metric) {
    final values = _sensorReadings
        .where((r) => r['metric'] == metric)
        .map((r) => double.tryParse('${r['value']}'))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// The last 7 days from `get_*_usage_trend`, as chart bars.
  ///
  /// The weekly charts were const lists (จ 820, อ 910, …) with a matching
  /// hand-written "เฉลี่ย ~880 kWh/วัน" subtitle, while the two trend results
  /// this page fetches sat unused. An empty list renders as no chart rather
  /// than as a week of flat zeroes.
  List<_BarData> _trendBars(List<UtilityTrendPoint> points) {
    const dayNames = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return [
      for (final p in points)
        _BarData(
          dayNames[(p.day.weekday - 1) % 7],
          p.value.round(),
          muted: p.day.weekday >= DateTime.saturday,
        ),
    ];
  }

  /// Month-to-date cost scaled to a full month.
  ///
  /// Deliberately the simplest thing that is defensible: cost so far divided
  /// by the days elapsed, times the days in the month. Returns null when no
  /// meter reported, so the card says so instead of projecting from nothing.
  double? _monthEndProjection(int deviceCount, double? costSoFar) {
    if (deviceCount <= 0 || costSoFar == null) return null;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (now.day <= 0) return costSoFar;
    return costSoFar / now.day * daysInMonth;
  }

  String _dayAverage(List<UtilityTrendPoint> points) {
    if (points.isEmpty) return '—';
    final mean =
        points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
    return mean.toStringAsFixed(mean >= 100 ? 0 : 1);
  }

  String _periodTotal(List<UtilityTrendPoint> points) {
    if (points.isEmpty) return '—';
    final total = points.map((p) => p.value).reduce((a, b) => a + b);
    return total.toStringAsFixed(0);
  }

  /// The busiest day in the loaded window. There is no hourly data anywhere in
  /// the schema, so the old "ใช้ไฟสูงสุดช่วง 13.50 น." peak-hour claim is
  /// replaced by the peak *day*, which the trend RPC can actually support.
  String _peakDayLabel(List<UtilityTrendPoint> points) {
    if (points.isEmpty) return '—';
    final peak = points.reduce((a, b) => a.value >= b.value ? a : b);
    return '${peak.day.day}/${peak.day.month}';
  }

  String _peakDayValue(List<UtilityTrendPoint> points, String unit) {
    if (points.isEmpty) return 'ยังไม่มีข้อมูล';
    final peak = points.reduce((a, b) => a.value >= b.value ? a : b);
    return '${peak.value.toStringAsFixed(0)} $unit';
  }

  String _trendAverage(List<UtilityTrendPoint> points, String unit) {
    if (points.isEmpty) return 'ยังไม่มีข้อมูลย้อนหลัง';
    final mean =
        points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
    return 'เฉลี่ย ~${mean.toStringAsFixed(0)} $unit/วัน';
  }

  /// Failure stated on the page. Every figure here used to be a fixed string,
  /// so a backend that was unreachable rendered identically to one that was
  /// working.
  Widget _loadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'โหลดข้อมูลการใช้ทรัพยากรไม่สำเร็จ — ตัวเลขที่แสดงอาจไม่เป็นปัจจุบัน',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _loadUtilityData,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  /// The period these figures cover, from today rather than a fixed
  /// "1 - 21 ส.ค. 2569" that never changed.
  String get _periodSubtitle {
    final now = DateTime.now();
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return 'เดือนนี้ (1 - ${now.day} ${months[now.month - 1]} ${now.year + 543})';
  }

  static const _thShortMonths = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  /// "อัปเดตล่าสุด" for a detail dialog — the newest day the trend actually
  /// has, not a frozen "21 ส.ค. 2569" left over from the mock. Empty trend
  /// (no rows fetched yet) says so honestly instead of a fake date.
  String _lastUpdatedLabel(List<UtilityTrendPoint> points) {
    if (points.isEmpty) return 'ยังไม่มีข้อมูล';
    final d = points.last.day;
    return '${d.day} ${_thShortMonths[d.month - 1]} ${d.year + 543}';
  }

  /// Period-over-period change, stated only when the backend could compute
  /// it. `UtilityEfficiencyScore.score` is null when there is not enough
  /// history to compare, and a percentage invented in its place would be a
  /// claim about a trend nobody measured.
  String _trendText(UtilityEfficiencyScore? score) {
    if (score == null || score.previous <= 0) return 'ยังเทียบเดือนก่อนไม่ได้';
    final change = (score.current - score.previous) / score.previous * 100;
    final direction = change <= 0 ? '-' : '+';
    return '$direction${change.abs().toStringAsFixed(1)}% จากเดือนก่อน';
  }

  bool _trendIsUp(UtilityEfficiencyScore? score) {
    if (score == null || score.previous <= 0) return false;
    return score.current > score.previous;
  }

  /// One row per place that actually reported, grouped by the device's
  /// location. Replaces a const list of five invented zones.
  List<_ZoneAir> get _liveZones {
    final byLocation = <String, List<Map<String, dynamic>>>{};
    for (final row in _sensorReadings) {
      final loc = (row['location'] as String?)?.trim();
      final key = (loc == null || loc.isEmpty)
          ? (row['device_name'] as String? ?? 'ไม่ระบุตำแหน่ง')
          : loc;
      byLocation.putIfAbsent(key, () => []).add(row);
    }

    String show(List<Map<String, dynamic>> rows, String metric, String unit) {
      final v = rows
          .where((r) => r['metric'] == metric)
          .map((r) => double.tryParse('${r['value']}'))
          .whereType<double>()
          .toList();
      if (v.isEmpty) return '—';
      final mean = v.reduce((a, b) => a + b) / v.length;
      return '${mean.toStringAsFixed(0)}$unit';
    }

    final zones = <_ZoneAir>[];
    for (final entry in byLocation.entries) {
      final pm = show(entry.value, 'pm25', '');
      // Air-quality banding follows Thailand's PM2.5 guidance; a location that
      // never reported PM2.5 gets no verdict rather than a green one.
      final pmValue = double.tryParse(pm);
      final (label, color) = pmValue == null
          ? ('ยังไม่มีข้อมูล', AppPalette.textMuted)
          : pmValue <= 37.5
          ? ('ดี', AppPalette.success)
          : pmValue <= 75
          ? ('ปานกลาง', AppPalette.warning)
          : ('ควรระวัง', AppPalette.danger);
      zones.add(
        _ZoneAir(
          entry.key,
          pm,
          show(entry.value, 'co2', ''),
          show(entry.value, 'temperature', '°C'),
          label,
          color,
        ),
      );
    }
    zones.sort((a, b) => a.zone.compareTo(b.zone));
    return zones;
  }

  @override
  void initState() {
    super.initState();
    _loadUtilityData();
  }

  Future<void> _loadUtilityData() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final results =
          await (widget.loadAll?.call() ??
              Future.wait<Object?>([
                UtilityService.getEnergyUsageSummary(period: 'month'),
                UtilityService.getWaterUsageSummary(period: 'month'),
                UtilityService.getEnergyUsageTrend(days: 7),
                UtilityService.getWaterUsageTrend(days: 7),
                UtilityService.getEnergyEfficiencyScore(),
                UtilityService.getWaterEfficiencyScore(),
                AiotLabService.getLatestSensorReadings(),
              ]));
      if (!mounted) return;
      setState(() {
        _energySummary = results[0] as EnergyUsageSummary?;
        _waterSummary = results[1] as WaterUsageSummary?;
        _energyTrend = results[2] as List<UtilityTrendPoint>;
        _waterTrend = results[3] as List<UtilityTrendPoint>;
        _energyScore = results[4] as UtilityEfficiencyScore?;
        _waterScore = results[5] as UtilityEfficiencyScore?;
        _sensorReadings = results[6] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      // `catch (_) {}` hid every failure, and because the page rendered fixed
      // numbers regardless, a broken backend looked exactly like a working one.
      debugPrint('DirectorEnvironmentPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }
  // ---------------------------------------------------------------------------
  // MOCK DATA
  // ---------------------------------------------------------------------------

  /// ค่าล่าสุดต่อ metric จาก sensor_latest จริง — ไม่ใช่ mock แล้ว (ต่างจาก
  /// electricityBreakdown/zones ด้านล่างที่ยังเป็น mock อยู่). ถ้า metric ไหน
  /// ไม่มีข้อมูลจริงเลย จะไม่โชว์การ์ดนั้น ดีกว่าโชว์ตัวเลขปลอม.
  Map<String, dynamic> get _latestByMetric {
    final byMetric = <String, Map<String, dynamic>>{};
    for (final r in _sensorReadings) {
      final metric = r['metric'] as String?;
      if (metric == null) continue;
      final ts = DateTime.tryParse(r['ts'] as String? ?? '');
      final prev = byMetric[metric];
      final prevTs = prev == null
          ? null
          : DateTime.tryParse(prev['ts'] as String? ?? '');
      if (prev == null ||
          (ts != null && (prevTs == null || ts.isAfter(prevTs)))) {
        byMetric[metric] = r;
      }
    }
    return byMetric;
  }

  bool _isStale(String metric) {
    final ts = DateTime.tryParse(
      (_latestByMetric[metric]?['ts'] as String?) ?? '',
    );
    if (ts == null) return true;
    return DateTime.now().toUtc().difference(ts.toUtc()) >
        const Duration(minutes: 10);
  }

  static String _fmt(dynamic v, {int decimals = 1}) {
    if (v is num) return v.toStringAsFixed(decimals);
    return '$v';
  }

  List<_SensorReading> get sensors {
    final latest = _latestByMetric;
    final items = <_SensorReading>[];

    void addIfPresent({
      required String metric,
      required IconData icon,
      required String name,
      required String Function(dynamic v) formatValue,
      required String unit,
      String Function(dynamic v)? detail,
    }) {
      if (!latest.containsKey(metric)) return;
      final v = latest[metric]!['value'];
      final stale = _isStale(metric);
      items.add(
        _SensorReading(
          icon: icon,
          name: name,
          value: formatValue(v),
          unit: unit,
          status: stale ? 'เซนเซอร์ไม่ทำงาน' : 'ค่าล่าสุดจากเซนเซอร์จริง',
          statusColor: stale ? AppPalette.textMuted : AppPalette.success,
          location: 'เซนเซอร์ห้องทดลอง',
          detail: detail?.call(v) ?? (stale ? 'ไม่มีข้อมูลใหม่ >10 นาที' : ''),
        ),
      );
    }

    addIfPresent(
      metric: 'temperature',
      icon: Icons.thermostat_rounded,
      name: 'อุณหภูมิ',
      formatValue: (v) => _fmt(v),
      unit: '°C',
      detail: (_) => latest.containsKey('humidity')
          ? 'ความชื้นสัมพัทธ์ ${_fmt(latest['humidity']!['value'], decimals: 0)}%'
          : '',
    );
    addIfPresent(
      metric: 'pm25',
      icon: Icons.blur_on_rounded,
      name: 'ฝุ่น PM2.5',
      formatValue: (v) => _fmt(v),
      unit: 'µg/m³',
    );
    addIfPresent(
      metric: 'light_lux',
      icon: Icons.light_mode_rounded,
      name: 'ความเข้มแสง',
      formatValue: (v) => _fmt(v, decimals: 0),
      unit: 'lux',
    );
    // ห้ามเขียนเป็น "LPG X ppm" — ค่านี้คือ % ช่วงสัญญาณ ADC ดิบของเซนเซอร์
    // MQ-2 ไม่ใช่ %ความเข้มข้นแก๊สจริง จนกว่าจะ calibrate เป็น ppm (แพทเทิร์น
    // เดียวกับ teacher_aiot_lab_page.dart)
    addIfPresent(
      metric: 'gas_mq2_percent',
      icon: Icons.local_fire_department_rounded,
      name: 'แก๊ส/ควัน (MQ-2)',
      formatValue: (v) => _fmt(v),
      unit: '% สัญญาณดิบ',
      detail: (_) => 'ยังไม่ calibrate เป็น ppm จริง',
    );
    addIfPresent(
      metric: 'aqi',
      icon: Icons.air_rounded,
      name: 'คุณภาพอากาศรวม (AQI)',
      formatValue: (v) => _fmt(v, decimals: 0),
      unit: 'AQI',
    );

    return items;
  }

  /// The one rate figure the system actually holds.
  ///
  /// This was a five-row tariff table — user class, energy charge to four
  /// decimal places, the current Ft, a monthly service charge, VAT — none of
  /// which exists anywhere in the schema. `school_settings` stores a single
  /// `electricity_rate_thb`, and `get_school_utility_rates` returns it along
  /// with `is_electricity_default`, which says whether it is the school's own
  /// figure or the system fallback. Showing that flag matters: a default rate
  /// makes every cost on this page an estimate built on an estimate.
  List<_RateRef> get electricityRates {
    final energy = _energySummary;
    if (energy == null) {
      return const [_RateRef('อัตราค่าไฟ', 'ยังไม่มีข้อมูล')];
    }
    return [
      _RateRef(
        'อัตราค่าไฟที่ใช้คำนวณ',
        '${energy.electricityRateThb.toStringAsFixed(2)} บาท/หน่วย',
      ),
      _RateRef(
        'ที่มาของอัตรา',
        energy.isRateDefault
            ? 'อัตรากลางของระบบ (ยังไม่ได้ตั้งค่าของโรงเรียน)'
            : 'อัตราที่โรงเรียนตั้งไว้',
      ),
    ];
  }

  List<_RateRef> get waterRates {
    final water = _waterSummary;
    if (water == null) {
      return const [_RateRef('อัตราค่าน้ำ', 'ยังไม่มีข้อมูล')];
    }
    return [
      _RateRef(
        'อัตราค่าน้ำที่ใช้คำนวณ',
        '${water.waterRateThb.toStringAsFixed(2)} บาท/ลบ.ม.',
      ),
      _RateRef(
        'ที่มาของอัตรา',
        water.isRateDefault
            ? 'อัตรากลางของระบบ (ยังไม่ได้ตั้งค่าของโรงเรียน)'
            : 'อัตราที่โรงเรียนตั้งไว้',
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'สิ่งแวดล้อมและทรัพยากรโรงเรียน',
            subtitle:
                'ติดตามการใช้น้ำ ใช้ไฟ ค่าใช้จ่ายโดยประมาณ พร้อมการคาดการณ์ด้วย AI และคุณภาพสิ่งแวดล้อมภายในโรงเรียนแบบเรียลไทม์',
          ),
          const SizedBox(height: 14),
          if (_loading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 14),
          ],
          if (_loadFailed) ...[_loadErrorBanner(), const SizedBox(height: 14)],
          _summaryCards(),
          const SizedBox(height: 16),
          _aiInsightCard(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Usage, cost and the period-over-period trend all come from
              // the RPCs now. They were '18,450 kWh', '฿82,150' and
              // '+6.2% จากเดือนก่อน' — fixed strings under a subtitle that
              // named a fixed date range, "1 - 21 ส.ค. 2569", regardless of
              // today. The per-building breakdown is dropped entirely: no RPC
              // aggregates usage by building, and `devices.building` is null
              // on every row, so those six buildings could only be invented.
              final energyReal = (_energySummary?.deviceCount ?? 0) > 0
                  ? _energySummary
                  : null;
              final waterReal = (_waterSummary?.deviceCount ?? 0) > 0
                  ? _waterSummary
                  : null;

              final electricity = _utilityCard(
                title: 'การใช้ไฟฟ้า',
                subtitle: _periodSubtitle,
                icon: Icons.bolt_rounded,
                color: AppPalette.behaviorYellow,
                usage: energyReal?.totalKwh.toStringAsFixed(0) ?? '—',
                usageUnit: 'kWh',
                estCost: energyReal?.estimatedCostThb.toStringAsFixed(0) ?? '—',
                trendText: _trendText(_energyScore),
                trendUp: _trendIsUp(_energyScore),
                breakdown: const [],
                onTap: () => _showElectricityDetail(context),
              );

              final water = _utilityCard(
                title: 'การใช้น้ำ',
                subtitle: _periodSubtitle,
                icon: Icons.water_drop_rounded,
                color: AppPalette.learningBlue,
                usage: waterReal?.totalM3.toStringAsFixed(0) ?? '—',
                usageUnit: 'ลบ.ม.',
                estCost: waterReal?.estimatedCostThb.toStringAsFixed(0) ?? '—',
                trendText: _trendText(_waterScore),
                trendUp: _trendIsUp(_waterScore),
                breakdown: const [],
                onTap: () => _showWaterDetail(context),
              );

              if (constraints.maxWidth < 980) {
                return Column(
                  children: [electricity, const SizedBox(height: 16), water],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: electricity),
                    const SizedBox(width: 16),
                    Expanded(child: water),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _airQualitySection(),
          const SizedBox(height: 16),
          _rateReferenceCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY CARDS
  // ---------------------------------------------------------------------------

  Widget _summaryCards() {
    // Built from what was actually loaded. Every one of these used to be a
    // fixed string — ฿82,150, 18,450 kWh, 640 ลบ.ม., PM2.5 38, CO₂ 720 —
    // while the six UtilityService results and the sensor readings sat in
    // fields the page never read. `deviceCount` separates "measured, and it
    // was zero" from "nothing is metering": the RPC sums with
    // `coalesce(sum(...), 0)`, so a school with no meters still gets a
    // well-formed row of zeroes.
    final energy = (_energySummary?.deviceCount ?? 0) > 0
        ? _energySummary
        : null;
    final water = (_waterSummary?.deviceCount ?? 0) > 0 ? _waterSummary : null;

    String figure(String? text) =>
        text ?? (_loadFailed ? 'โหลดไม่สำเร็จ' : 'ยังไม่มีข้อมูล');

    final items = [
      _EnvSummary(
        title: 'ค่าไฟเดือนนี้ (ประมาณ)',
        value: figure(
          energy == null
              ? null
              : '฿${energy.estimatedCostThb.toStringAsFixed(0)}',
        ),
        subtitle: energy == null
            ? 'ยังไม่มีมิเตอร์ที่ส่งค่า'
            : 'จากมิเตอร์ ${energy.deviceCount} จุด',
        icon: Icons.bolt_rounded,
        color: AppPalette.softCream,
      ),
      _EnvSummary(
        title: 'ค่าน้ำเดือนนี้ (ประมาณ)',
        value: figure(
          water == null
              ? null
              : '฿${water.estimatedCostThb.toStringAsFixed(0)}',
        ),
        subtitle: water == null
            ? 'ยังไม่มีมิเตอร์ที่ส่งค่า'
            : 'จากมิเตอร์ ${water.deviceCount} จุด',
        icon: Icons.water_drop_rounded,
        color: AppPalette.softBlue,
      ),
      _EnvSummary(
        title: 'ใช้ไฟฟ้า',
        value: figure(energy?.totalKwh.toStringAsFixed(0)),
        subtitle: 'kWh',
        icon: Icons.electric_meter_rounded,
        color: AppPalette.softPink,
      ),
      _EnvSummary(
        title: 'ใช้น้ำ',
        value: figure(water?.totalM3.toStringAsFixed(0)),
        subtitle: 'ลบ.ม.',
        icon: Icons.opacity_rounded,
        color: AppPalette.softMint,
      ),
      _EnvSummary(
        title: 'PM2.5 เฉลี่ย',
        value: figure(_averageMetric('pm25')?.toStringAsFixed(0)),
        subtitle: 'µg/m³',
        icon: Icons.blur_on_rounded,
        color: AppPalette.softPink2,
      ),
      _EnvSummary(
        title: 'CO₂ เฉลี่ย',
        value: figure(_averageMetric('co2')?.toStringAsFixed(0)),
        subtitle: 'ppm',
        icon: Icons.co2_rounded,
        color: AppPalette.softTag,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;
        if (constraints.maxWidth < 700) {
          columns = 2;
        } else if (constraints.maxWidth < 1120) {
          columns = 3;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            // Was 126/116. The values are no longer short fixed numbers —
            // an unmetered school shows "ยังไม่มีข้อมูล" and a failed load
            // shows "โหลดไม่สำเร็จ", both of which need a second line.
            mainAxisExtent: columns == 2 ? 138 : 128,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(Colors.white, 0.82),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.2,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // Long words like "ยังไม่มีข้อมูล" are not figures and
                      // should not be typeset as one.
                      fontSize: item.value.length > 9 ? 12 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.2,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AI INSIGHT CARD
  // ---------------------------------------------------------------------------

  Widget _aiInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF3FC), Color(0xFFFBEDF3)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.tint(Colors.black, 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.border),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppPalette.primaryPink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประมาณการค่าใช้จ่ายสิ้นเดือน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'คิดจากยอดใช้จริงถึงวันนี้ เทียบสัดส่วนวันในเดือน',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppPalette.border),
                ),
                child: const Text(
                  'ประมาณการเชิงเส้น',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.primaryPinkDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;

              // Was "AI คาดการณ์" with ฿118,400 / ฿18,600 / ฿137,000, a
              // ±% for each, and "ความมั่นใจ 92%" — presented as a model
              // trained on twelve months of history. There is no model, no
              // history beyond the 7-day trend, and no basis for a confidence
              // figure. What can honestly be done is scale the month-to-date
              // cost by how much of the month has passed, and say that is what
              // it is.
              final energyProj = _monthEndProjection(
                _energySummary?.deviceCount ?? 0,
                _energySummary?.estimatedCostThb,
              );
              final waterProj = _monthEndProjection(
                _waterSummary?.deviceCount ?? 0,
                _waterSummary?.estimatedCostThb,
              );
              final totalProj = (energyProj == null && waterProj == null)
                  ? null
                  : (energyProj ?? 0) + (waterProj ?? 0);

              String baht(double? v) =>
                  v == null ? 'ยังไม่มีข้อมูล' : '฿${v.toStringAsFixed(0)}';

              final estimates = [
                _aiEstimateBox(
                  'ค่าไฟ (ประมาณ)',
                  baht(energyProj),
                  'สิ้นเดือน',
                  AppPalette.behaviorYellow,
                ),
                _aiEstimateBox(
                  'ค่าน้ำ (ประมาณ)',
                  baht(waterProj),
                  'สิ้นเดือน',
                  AppPalette.learningBlue,
                ),
                _aiEstimateBox(
                  'รวมทั้งหมด',
                  baht(totalProj),
                  'สิ้นเดือน',
                  AppPalette.textMuted,
                ),
              ];

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < estimates.length; i++) ...[
                      estimates[i],
                      if (i != estimates.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < estimates.length; i++) ...[
                    Expanded(child: estimates[i]),
                    if (i != estimates.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'ข้อเสนอแนะการประหยัดพลังงาน',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 10),
          // Three "AI" recommendations used to render here, each asserting a
          // specific observation — "AI พบว่าอาคาร 2 เปิดแอร์ก่อนเข้าเรียน 40
          // นาที". Nothing in this system watches an individual appliance's
          // runtime, so the analysis it claimed to have done never happened.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            decoration: BoxDecoration(
              color: AppPalette.pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ยังไม่มีระบบวิเคราะห์การใช้พลังงานรายอุปกรณ์ '
              'จึงยังไม่มีข้อเสนอแนะที่อ้างอิงข้อมูลจริงได้',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppPalette.textMuted),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppPalette.tint(Colors.white, 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppPalette.textMuted,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'ตัวเลขเป็นการคาดคะเนค่าใช้จ่ายเบื้องต้น คำนวณจากปริมาณการใช้ไฟฟ้าและน้ำ '
                    'ในปัจจุบัน ร่วมกับอัตราค่าบริการและประวัติการใช้ย้อนหลัง 7 วัน '
                    'จึงอาจคลาดเคลื่อนจากบิลจริง',
                    style: TextStyle(
                      fontSize: 8.6,
                      height: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiEstimateBox(
    String label,
    String value,
    String tag,
    Color tagColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tag,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: tagColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UTILITY (ELECTRICITY / WATER) CARD
  // ---------------------------------------------------------------------------

  Widget _utilityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String usage,
    required String usageUnit,
    required String estCost,
    required String trendText,
    required bool trendUp,
    required List<_UsageBreakdown> breakdown,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppPalette.tint(color, 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(color, 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          fontSize: 8.6,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 14, color: color),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                usage,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  usageUnit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.tint(
                    trendUp ? AppPalette.danger : AppPalette.success,
                    0.10,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: trendUp ? AppPalette.danger : AppPalette.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 8.6,
                        fontWeight: FontWeight.w700,
                        color: trendUp ? AppPalette.danger : AppPalette.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppPalette.tint(color, 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 18, color: color),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'ค่าใช้จ่ายโดยประมาณ (รวม Ft + VAT)',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '฿$estCost',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'สัดส่วนการใช้งานตามพื้นที่',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...breakdown.map((row) => _usageRow(row, color)),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: card,
    );
  }

  Widget _usageRow(_UsageBreakdown row, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                row.value,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: row.progress,
              minHeight: 7,
              backgroundColor: AppPalette.softTag,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ELECTRICITY DETAIL (แตะการ์ดการใช้ไฟเพื่อดูรายละเอียด)
  // ---------------------------------------------------------------------------

  void _showElectricityDetail(BuildContext context) {
    _showUtilityDetail(
      context,
      title: 'การใช้ไฟฟ้า • รายละเอียด',
      headerIcon: Icons.bolt_rounded,
      color: AppPalette.behaviorYellow,
      // The per-building breakdown and the "อาคารที่ใช้ไฟมากที่สุด" ranking
      // are gone: no RPC aggregates usage by building and `devices.building`
      // is null on every row, so both could only ever have been invented.
      // Daily/weekly averages and the peak day now come from the real trend.
      breakdown: const [],
      avgDay: _dayAverage(_energyTrend),
      avgDaySub: 'kWh/วัน',
      avgWeek: _periodTotal(_energyTrend),
      avgWeekSub: 'kWh • 7 วันล่าสุด',
      peakTime: _peakDayLabel(_energyTrend),
      peakSub: _peakDayValue(_energyTrend, 'kWh'),
      topLabel: 'แยกรายอาคาร',
      topName: 'ยังไม่มีข้อมูล',
      topValue: '—',
      topShare: 'ต้องระบุอาคารให้อุปกรณ์มิเตอร์ก่อน',
      weeklyTitle: 'การใช้ไฟ 7 วันล่าสุด',
      weeklySubtitle:
          'หน่วย kWh ต่อวัน • ${_trendAverage(_energyTrend, 'kWh')}',
      hourlyTitle: 'การใช้ไฟรายชั่วโมงวันนี้',
      hourlySubtitle: 'ยังไม่มีข้อมูลรายชั่วโมง',
      peakNote: '',
      rankTitle: 'อันดับพื้นที่ใช้ไฟสูงสุด',
      note:
          'หมายเหตุ: ค่าใช้จ่ายเป็นการประมาณจากหน่วยที่มิเตอร์รายงาน × '
          'อัตราค่าไฟของโรงเรียน ไม่ใช่ใบแจ้งหนี้จริง',
      weekly: _trendBars(_energyTrend),
      hourly: const [],
      updatedLabel: _lastUpdatedLabel(_energyTrend),
    );
  }

  void _showWaterDetail(BuildContext context) {
    _showUtilityDetail(
      context,
      title: 'การใช้น้ำ • รายละเอียด',
      headerIcon: Icons.water_drop_rounded,
      color: AppPalette.learningBlue,
      breakdown: const [],
      avgDay: _dayAverage(_waterTrend),
      avgDaySub: 'ลบ.ม./วัน',
      avgWeek: _periodTotal(_waterTrend),
      avgWeekSub: 'ลบ.ม. • 7 วันล่าสุด',
      // ไม่มี RPC ไหนแยกการใช้น้ำรายอาคาร/รายชั่วโมงเลย ตัวเลข peak time เดิม
      // (12.10 น., "ช่วงพักเที่ยง") และอันดับพื้นที่ใช้น้ำเป็นของแต่งขึ้นทั้งคู่
      // — ใช้แพตเทิร์นเดียวกับ _showElectricityDetail: peak มาจากวันที่ใช้
      // มากสุดในเทรนด์จริง 7 วัน ส่วนแยกอาคาร/ชั่วโมงยังไม่มีข้อมูลจึงบอกตรงๆ
      peakTime: _peakDayLabel(_waterTrend),
      peakSub: _peakDayValue(_waterTrend, 'ลบ.ม.'),
      topLabel: 'พื้นที่ใช้น้ำมากที่สุด',
      topName: 'ยังไม่มีข้อมูล',
      topValue: '—',
      topShare: 'ต้องแยกมิเตอร์น้ำรายอาคารก่อน',
      weeklyTitle: 'การใช้น้ำ 7 วันล่าสุด',
      weeklySubtitle:
          'หน่วย ลบ.ม. ต่อวัน • ${_trendAverage(_waterTrend, 'ลบ.ม.')}',
      hourlyTitle: 'การใช้น้ำรายชั่วโมงวันนี้',
      hourlySubtitle: 'ยังไม่มีข้อมูลรายชั่วโมง',
      peakNote: '',
      rankTitle: 'อันดับพื้นที่ใช้น้ำสูงสุด',
      // "ข้อมูลจากมิเตอร์น้ำแยกโซน" ถูกตัดออก — ไม่มีมิเตอร์น้ำแยกโซนจริงใน
      // ระบบ (_waterTrend เป็นเทรนด์รวมของทั้งโรงเรียน ไม่ใช่รายโซน)
      note:
          'หมายเหตุ: ตัวเลขค่าใช้จ่ายเป็นการคาดคะเนเบื้องต้นจากหน่วยการใช้จริง '
          '× อัตราค่าน้ำ + ค่าบริการ + VAT ไม่ใช่ใบแจ้งหนี้จริง',
      weekly: _trendBars(_waterTrend),
      hourly: const [],
      updatedLabel: _lastUpdatedLabel(_waterTrend),
    );
  }

  void _showUtilityDetail(
    BuildContext context, {
    required String title,
    required IconData headerIcon,
    required Color color,
    required List<_BarData> weekly,
    required List<_BarData> hourly,
    required List<_UsageBreakdown> breakdown,
    required String avgDay,
    required String avgDaySub,
    required String avgWeek,
    required String avgWeekSub,
    required String peakTime,
    required String peakSub,
    required String topLabel,
    required String topName,
    required String topValue,
    required String topShare,
    required String weeklyTitle,
    required String weeklySubtitle,
    required String hourlyTitle,
    required String hourlySubtitle,
    required String peakNote,
    required String rankTitle,
    required String note,
    required String updatedLabel,
  }) {
    final ranked = [...breakdown]
      ..sort((a, b) => b.progress.compareTo(a.progress));

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(color, 0.14),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(headerIcon, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'ข้อมูลเชิงลึกจาก 7 วันล่าสุด • อัปเดต $updatedLabel',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final boxes = [
                                _statBox(
                                  Icons.calendar_today_rounded,
                                  'ค่าเฉลี่ยต่อวัน',
                                  avgDay,
                                  avgDaySub,
                                  color,
                                ),
                                _statBox(
                                  Icons.date_range_rounded,
                                  'ค่าเฉลี่ยต่อสัปดาห์',
                                  avgWeek,
                                  avgWeekSub,
                                  AppPalette.environmentGreen,
                                ),
                                _statBox(
                                  Icons.schedule_rounded,
                                  'ช่วงใช้งานสูงสุด',
                                  peakTime,
                                  peakSub,
                                  AppPalette.primaryPink,
                                ),
                              ];

                              if (constraints.maxWidth < 560) {
                                return Column(
                                  children: [
                                    for (int i = 0; i < boxes.length; i++) ...[
                                      boxes[i],
                                      if (i != boxes.length - 1)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  for (int i = 0; i < boxes.length; i++) ...[
                                    Expanded(child: boxes[i]),
                                    if (i != boxes.length - 1)
                                      const SizedBox(width: 10),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppPalette.tint(color, 0.09),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppPalette.tint(color, 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events_rounded,
                                    color: color,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topLabel,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppPalette.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        topName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      topValue,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      topShare,
                                      style: const TextStyle(
                                        fontSize: 8.6,
                                        color: AppPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _chartCard(
                            weeklyTitle,
                            weeklySubtitle,
                            weekly,
                            color,
                          ),
                          const SizedBox(height: 14),
                          _chartCard(
                            hourlyTitle,
                            hourlySubtitle,
                            hourly,
                            color,
                            peakNote: peakNote,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            rankTitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (int i = 0; i < ranked.length; i++)
                            _rankRow(i + 1, ranked[i]),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.tint(
                                AppPalette.primaryPink,
                                0.06,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              note,
                              style: const TextStyle(
                                fontSize: 8.8,
                                height: 1.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statBox(
    IconData icon,
    String label,
    String value,
    String sub,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppPalette.tint(color, 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 8.2,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    String title,
    String subtitle,
    List<_BarData> bars,
    Color color, {
    String? peakNote,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 12),
          _barChart(bars, color),
          if (peakNote != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.push_pin_rounded,
                  size: 13,
                  color: AppPalette.primaryPink,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    peakNote,
                    style: const TextStyle(
                      fontSize: 8.8,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.primaryPinkDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _barChart(List<_BarData> bars, Color color) {
    // A school with no trend rows yet (brand-new, or the RPC genuinely
    // returned nothing) used to crash this dialog with `Bad state: No
    // element` from `.reduce` on an empty list — found while fixing the
    // water-detail dialog's fake peak/top-building values, same code path.
    if (bars.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'ยังไม่มีข้อมูลย้อนหลังให้แสดงกราฟ',
            style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
          ),
        ),
      );
    }
    final maxVal = bars
        .map((b) => b.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${bar.value}',
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: (bar.value / maxVal) * 96,
                      decoration: BoxDecoration(
                        color: bar.muted ? AppPalette.tint(color, 0.4) : color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bar.label,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rankRow(int rank, _UsageBreakdown row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppPalette.primaryPink
                  : AppPalette.tint(AppPalette.primaryPink, 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: rank == 1 ? Colors.white : AppPalette.primaryPinkDark,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.value,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AIR QUALITY SECTION
  // ---------------------------------------------------------------------------

  Widget _airQualitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'คุณภาพสิ่งแวดล้อมภายในโรงเรียน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ข้อมูลจากเซ็นเซอร์ IoT อุณหภูมิ ฝุ่น PM แสง แก๊ส/ควัน และ CO₂ อัปเดตทุก 1 นาที',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 3;
              if (constraints.maxWidth < 560) {
                columns = 2;
              } else if (constraints.maxWidth < 900) {
                columns = 3;
              }

              return GridView.builder(
                itemCount: sensors.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 138,
                ),
                itemBuilder: (context, index) {
                  return _sensorCard(sensors[index]);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'เปรียบเทียบตามพื้นที่',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'PM2.5 (µg/m³) • CO₂ (ppm) • อุณหภูมิ',
            style: TextStyle(fontSize: 9, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 10),
          _zoneHeaderRow(),
          const SizedBox(height: 4),
          // Was a const list of five invented zones with fixed PM2.5/CO₂/temp
          // readings, sitting next to sensor data the page had already
          // fetched and never used.
          if (_liveZones.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  _loadFailed
                      ? 'โหลดข้อมูลเซนเซอร์ไม่สำเร็จ'
                      : 'ยังไม่มีเซนเซอร์ที่ส่งค่าคุณภาพอากาศ',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
            )
          else
            ..._liveZones.map(_zoneRow),
        ],
      ),
    );
  }

  Widget _sensorCard(_SensorReading sensor) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.tint(sensor.statusColor, 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(sensor.icon, size: 18, color: sensor.statusColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.tint(sensor.statusColor, 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sensor.status,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: sensor.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            sensor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  sensor.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (sensor.unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    sensor.unit,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sensor.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _zoneHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: const [
          Expanded(
            flex: 4,
            child: Text(
              'พื้นที่',
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PM2.5',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CO₂',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'อุณหภูมิ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'สถานะ',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneRow(_ZoneAir zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.tint(zone.color, 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.tint(zone.color, 0.13)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              zone.zone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              zone.pm25,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              zone.co2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              zone.temp,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.tint(zone.color, 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  zone.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: zone.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RATE REFERENCE CARD
  // ---------------------------------------------------------------------------

  Widget _rateReferenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.tint(AppPalette.primaryPink, 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: AppPalette.primaryPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อ้างอิงการคำนวณค่าใช้จ่าย',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'อัตราที่ AI ใช้ประมาณการค่าน้ำ-ค่าไฟ',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final electric = _rateBlock(
                'อัตราค่าไฟฟ้า',
                Icons.bolt_rounded,
                AppPalette.behaviorYellow,
                electricityRates,
              );
              final water = _rateBlock(
                'อัตราค่าน้ำประปา',
                Icons.water_drop_rounded,
                AppPalette.learningBlue,
                waterRates,
              );

              if (constraints.maxWidth < 720) {
                return Column(
                  children: [electric, const SizedBox(height: 12), water],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: electric),
                  const SizedBox(width: 12),
                  Expanded(child: water),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.tint(AppPalette.primaryPink, 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'หมายเหตุ: ค่าใช้จ่ายคำนวณจากหน่วยที่มิเตอร์รายงาน × อัตราค่าไฟ/ค่าน้ำ '
              'ที่บันทึกไว้ในระบบเท่านั้น ไม่ได้รวมค่า Ft ค่าบริการรายเดือน หรือ VAT '
              'จึงต่างจากบิลจริง และไม่ใช่ใบแจ้งหนี้',
              style: TextStyle(
                fontSize: 8.8,
                height: 1.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateBlock(
    String title,
    IconData icon,
    Color color,
    List<_RateRef> rates,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rates.map(
            (rate) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      rate.label,
                      style: const TextStyle(
                        fontSize: 8.8,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Text(
                      rate.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------

class _EnvSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _EnvSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _UsageBreakdown {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _UsageBreakdown(this.label, this.value, this.progress, this.color);
}

class _SensorReading {
  final IconData icon;
  final String name;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final String location;
  final String detail;

  const _SensorReading({
    required this.icon,
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.location,
    required this.detail,
  });
}

class _ZoneAir {
  final String zone;
  final String pm25;
  final String co2;
  final String temp;
  final String status;
  final Color color;

  const _ZoneAir(
    this.zone,
    this.pm25,
    this.co2,
    this.temp,
    this.status,
    this.color,
  );
}

class _RateRef {
  final String label;
  final String value;

  const _RateRef(this.label, this.value);
}

class _BarData {
  final String label;
  final int value;
  final bool muted;

  const _BarData(this.label, this.value, {this.muted = false});
}
