import 'package:my_first_app/widgets/visible_sensor_stream_builder.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_charts_page.dart';
import 'student_redesign_palette.dart';

/// Full-screen AIoT dashboard for the Student lane.
///
/// Until 2026-09-18 the home card's "ไปหน้า AIoT Dashboard" button opened the
/// shared `AiotDashboardPage` — a Material-blue page from the pre-redesign
/// era that matched no lane and, on a 390pt phone, overflowed every card.
/// This page shows the same eight readings from the same two streams, in the
/// Student palette and in the same tile language as the home card, sized for
/// a phone first.
class StudentAiotDashboardPage extends StatefulWidget {
  const StudentAiotDashboardPage({
    super.key,
    this.sensorStreamOverride,
    this.rawReadingsStreamOverride,
  });

  /// Tests inject streams; production reads RealtimeService.
  final Stream<SensorModel?>? sensorStreamOverride;
  final Stream<List<Map<String, dynamic>>>? rawReadingsStreamOverride;

  @override
  State<StudentAiotDashboardPage> createState() =>
      _StudentAiotDashboardPageState();
}

class _StudentAiotDashboardPageState extends State<StudentAiotDashboardPage> {
  // Cached once — an inline sensorStream(...) inside the outer
  // StreamBuilder's builder would be recreated on every raw-poll tick and
  // never deliver data (same trap documented in aiot_dashboard_page.dart).
  late final Stream<List<Map<String, dynamic>>> _rawStream;
  late final Stream<SensorModel?> _sensorStream;

  @override
  void initState() {
    super.initState();
    _rawStream =
        widget.rawReadingsStreamOverride ?? RealtimeService.rawReadingsStream();
    _sensorStream =
        widget.sensorStreamOverride ??
        RealtimeService.sensorStream(
          schoolId: currentUserModel?.schoolId ?? '',
          building: '',
          floor: '',
          room: '',
        );
  }

  static ({double value, DateTime? ts})? _latestValueOf(
    List<Map<String, dynamic>> rows,
    String metric,
  ) {
    Map<String, dynamic>? latest;
    DateTime? latestTs;
    for (final r in rows) {
      if (r['metric'] != metric) continue;
      final ts = DateTime.tryParse(r['ts'] as String? ?? '');
      if (latest == null ||
          (ts != null && (latestTs == null || ts.isAfter(latestTs)))) {
        latest = r;
        latestTs = ts;
      }
    }
    final v = latest?['value'];
    if (v is! num) return null;
    return (value: v.toDouble(), ts: latestTs);
  }

  // Same thresholds as SensorModel.freshnessOf, for the two raw metrics
  // (aqi / gas_mq2_percent) that are not fields on SensorModel.
  static SensorFreshness _freshnessOf(DateTime? ts) {
    if (ts == null) return SensorFreshness.noData;
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age <= const Duration(minutes: 2)) return SensorFreshness.live;
    if (age <= const Duration(minutes: 10)) return SensorFreshness.delayed;
    return SensorFreshness.offline;
  }

  static String _relativeTimeLabel(DateTime? ts) {
    if (ts == null) return 'ไม่มีข้อมูล';
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age.inSeconds < 60) return 'เมื่อสักครู่';
    if (age.inMinutes < 60) return '${age.inMinutes} นาทีที่แล้ว';
    if (age.inHours < 24) return '${age.inHours} ชม.ที่แล้ว';
    return '${age.inDays} วันที่แล้ว';
  }

  // ENS160 AQI-UBA is a 1–5 index (German UBA), not the 0–500 EPA scale —
  // confirmed with the firmware author 2026-08-31.
  static String _aqiUbaLabel(double level) => switch (level.round()) {
    1 => 'ดีมาก',
    2 => 'ดี',
    3 => 'ปานกลาง',
    4 => 'แย่',
    5 => 'ไม่ปลอดภัย',
    _ => 'ไม่ทราบระดับ',
  };

  static SensorLevel _aqiUbaSensorLevel(double value) {
    final rounded = value.round();
    if (rounded <= 2) return SensorLevel.good;
    if (rounded == 3) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  static Color _levelColor(SensorLevel level) => switch (level) {
    SensorLevel.good => SchoolPalette.green,
    SensorLevel.moderate => SchoolPalette.orange,
    SensorLevel.danger => SchoolPalette.danger,
  };

  static String _levelLabel(SensorLevel level) => switch (level) {
    SensorLevel.good => 'ปกติ',
    SensorLevel.moderate => 'ปานกลาง',
    SensorLevel.danger => 'เกินเกณฑ์',
  };

  static String _overallLabel(SensorLevel level) => switch (level) {
    SensorLevel.good => 'คุณภาพอากาศดี',
    SensorLevel.moderate => 'คุณภาพอากาศปานกลาง',
    SensorLevel.danger => 'คุณภาพอากาศแย่',
  };

  static String _overallHint(SensorLevel level) => switch (level) {
    SensorLevel.good => 'ทุกค่าที่วัดได้อยู่ในเกณฑ์ปกติ',
    SensorLevel.moderate => 'มีบางค่าอยู่ระดับปานกลาง ควรเปิดระบายอากาศ',
    SensorLevel.danger => 'มีค่าที่เกินเกณฑ์ แจ้งครูประจำชั้นให้ตรวจสอบ',
  };

  List<_Reading> _readings(
    SensorModel sensor,
    ({double value, DateTime? ts})? aqi,
    ({double value, DateTime? ts})? gas,
  ) {
    bool has(String m) => sensor.metricUpdatedAt.containsKey(m);
    _Reading fromModel({
      required String metric,
      required String title,
      required IconData icon,
      required String value,
      required String unit,
      required SensorLevel level,
    }) {
      final present = has(metric);
      return _Reading(
        title: title,
        icon: icon,
        value: present ? value : '—',
        unit: present ? unit : '',
        level: present ? level : null,
        levelLabel: present ? _levelLabel(level) : 'ไม่มีข้อมูล',
        freshness: present
            ? sensor.freshnessOf(metric)
            : SensorFreshness.noData,
        timeLabel: present ? sensor.relativeTimeLabel(metric) : null,
      );
    }

    return [
      fromModel(
        metric: 'pm25',
        title: 'PM2.5',
        icon: Icons.air_rounded,
        value: sensor.pm25.toStringAsFixed(0),
        unit: 'µg/m³',
        level: sensor.pm25Level,
      ),
      fromModel(
        metric: 'light_lux',
        title: 'ความเข้มแสง',
        icon: Icons.wb_sunny_rounded,
        value: sensor.lux.toStringAsFixed(0),
        unit: 'lux',
        level: sensor.luxLevel,
      ),
      fromModel(
        metric: 'temperature',
        title: 'อุณหภูมิ',
        icon: Icons.thermostat_rounded,
        value: sensor.temperature.toStringAsFixed(1),
        unit: '°C',
        level: sensor.tempLevel,
      ),
      fromModel(
        metric: 'humidity',
        title: 'ความชื้น',
        icon: Icons.water_drop_rounded,
        value: sensor.humidity.toStringAsFixed(0),
        unit: '%RH',
        level: sensor.humidityLevel,
      ),
      _Reading(
        title: 'AQI-UBA (ENS160)',
        icon: Icons.eco_rounded,
        value: aqi != null ? aqi.value.toStringAsFixed(0) : '—',
        unit: aqi != null ? '/ 5' : '',
        level: aqi != null ? _aqiUbaSensorLevel(aqi.value) : null,
        levelLabel: aqi != null ? _aqiUbaLabel(aqi.value) : 'ไม่มีข้อมูล',
        freshness: _freshnessOf(aqi?.ts),
        timeLabel: aqi != null ? _relativeTimeLabel(aqi.ts) : null,
      ),
      // MQ-2 has no calibrated threshold yet — raw percent, no level tint.
      _Reading(
        title: 'แก๊ส/ควัน (MQ-2)',
        icon: Icons.local_fire_department_rounded,
        value: gas != null ? gas.value.toStringAsFixed(0) : '—',
        unit: gas != null ? '% (ดิบ)' : '',
        level: null,
        levelLabel: gas != null ? 'ยังไม่มีเกณฑ์' : 'ไม่มีข้อมูล',
        freshness: _freshnessOf(gas?.ts),
        timeLabel: gas != null ? _relativeTimeLabel(gas.ts) : null,
      ),
      fromModel(
        metric: 'co2',
        title: 'eCO2 (ประมาณการ)',
        icon: Icons.cloud_outlined,
        value: sensor.co2.toStringAsFixed(0),
        unit: 'ppm',
        level: sensor.co2Level,
      ),
      fromModel(
        metric: 'tvoc',
        title: 'TVOC',
        icon: Icons.science_outlined,
        value: sensor.tvoc.toStringAsFixed(0),
        unit: 'ppb',
        level: sensor.tvocLevel,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolPalette.softGreenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AIoT Dashboard',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: VisibleSensorStreamBuilder<List<Map<String, dynamic>>>(
          stream: _rawStream,
          builder: (context, rawSnapshot) {
            final rawRows = rawSnapshot.data ?? const <Map<String, dynamic>>[];
            final aqi = _latestValueOf(rawRows, 'aqi');
            final gas = _latestValueOf(rawRows, 'gas_mq2_percent');
            return VisibleSensorStreamBuilder<SensorModel?>(
              stream: _sensorStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: SchoolPalette.green,
                    ),
                  );
                }
                final sensor = snapshot.data;
                if (sensor == null) {
                  return const _EmptyState();
                }
                final readings = _readings(sensor, aqi, gas);
                final online = readings
                    .where(
                      (r) =>
                          r.freshness == SensorFreshness.live ||
                          r.freshness == SensorFreshness.delayed,
                    )
                    .length;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _HeroCard(
                      level: sensor.overallLevel,
                      title: _overallLabel(sensor.overallLevel),
                      hint: _overallHint(sensor.overallLevel),
                      onlineCount: online,
                      totalCount: readings.length,
                      updatedLabel: _relativeTimeLabel(sensor.updatedAt),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ค่าเซนเซอร์ทั้งหมด',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: SchoolPalette.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${readings.length} รายการ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SchoolPalette.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 138,
                          ),
                      itemCount: readings.length,
                      itemBuilder: (_, i) => _ReadingTile(
                        reading: readings[i],
                        levelColor: _levelColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // PBL-7 entry: the student's own charts.
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentChartsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.insert_chart_outlined_rounded, size: 18),
                      label: const Text('กราฟของฉัน'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SchoolPalette.deepGreen,
                        side: const BorderSide(color: SchoolPalette.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _Legend(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Reading {
  const _Reading({
    required this.title,
    required this.icon,
    required this.value,
    required this.unit,
    required this.level,
    required this.levelLabel,
    required this.freshness,
    required this.timeLabel,
  });
  final String title;
  final IconData icon;
  final String value;
  final String unit;
  final SensorLevel? level;
  final String levelLabel;
  final SensorFreshness freshness;
  final String? timeLabel;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.level,
    required this.title,
    required this.hint,
    required this.onlineCount,
    required this.totalCount,
    required this.updatedLabel,
  });
  final SensorLevel level;
  final String title;
  final String hint;
  final int onlineCount;
  final int totalCount;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) {
    final (chipColor, chipIcon) = switch (level) {
      SensorLevel.good => (SchoolPalette.mint, Icons.check_circle_rounded),
      SensorLevel.moderate => (SchoolPalette.yellow, Icons.error_rounded),
      SensorLevel.danger => (SchoolPalette.danger, Icons.warning_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: SchoolPalette.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: chipColor.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chipIcon, size: 14, color: chipColor),
                    const SizedBox(width: 5),
                    const Text(
                      'สภาพแวดล้อมโดยรวม',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(
                icon: Icons.sensors_rounded,
                label: 'ออนไลน์ $onlineCount/$totalCount เซนเซอร์',
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _HeroStat(
                  icon: Icons.schedule_rounded,
                  label: 'อัปเดต $updatedLabel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SchoolPalette.cream),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading, required this.levelColor});
  final _Reading reading;
  final Color Function(SensorLevel) levelColor;

  @override
  Widget build(BuildContext context) {
    final level = reading.level;
    final color = level != null ? levelColor(level) : SchoolPalette.muted;
    final isDanger = level == SensorLevel.danger;
    final isOnline =
        reading.freshness == SensorFreshness.live ||
        reading.freshness == SensorFreshness.delayed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDanger ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDanger ? 0.6 : 0.35),
          width: isDanger ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(reading.icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reading.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: SchoolPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  reading.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                if (reading.unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      reading.unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: SchoolPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  reading.levelLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (reading.timeLabel != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: reading.freshness.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isOnline
                        ? 'ออนไลน์ • ${reading.timeLabel}'
                        : 'ไม่ออนไลน์ • ${reading.timeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: reading.freshness.color,
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
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ความหมายของสี',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: SchoolPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          _legendRow(SchoolPalette.green, 'ปกติ', 'ค่าอยู่ในเกณฑ์ที่ปลอดภัย'),
          _legendRow(
            SchoolPalette.orange,
            'ปานกลาง',
            'ควรเปิดหน้าต่าง/ระบายอากาศ',
          ),
          _legendRow(
            SchoolPalette.danger,
            'เกินเกณฑ์',
            'แจ้งครูประจำชั้นให้ตรวจสอบ',
          ),
          _legendRow(
            SchoolPalette.muted,
            'ไม่มีข้อมูล / ไม่ออนไลน์',
            'เซนเซอร์ไม่ได้ส่งค่ามาเกิน 10 นาที',
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: SchoolPalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SchoolPalette.glassBorder),
              ),
              child: const Icon(
                Icons.sensors_off_rounded,
                color: SchoolPalette.muted,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ยังไม่มีข้อมูลเซนเซอร์',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: SchoolPalette.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'โรงเรียนยังไม่มีอุปกรณ์ AIoT ที่ส่งค่ามา\nหรือกำลังรอ Technician ติดตั้ง',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: SchoolPalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
