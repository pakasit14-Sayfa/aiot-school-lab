import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_empty_state.dart';
import 'student_redesign_palette.dart';

/// PBL-6: the dataset a teacher pinned to an assignment, opened by the
/// student. Loads the real readings for that device/metric/window through
/// `sensor_history` and shows a chart plus min / max / average — the
/// numbers the student will quote in their write-up.
class StudentSensorDatasetPage extends StatefulWidget {
  const StudentSensorDatasetPage({
    super.key,
    required this.dataset,
    required this.assignmentTitle,
    this.getSensorHistory,
  });

  final AssignmentSensorDataset dataset;
  final String assignmentTitle;

  /// Tests inject; production reads AiotLabService.getSensorHistory.
  final Future<List<SensorDataPoint>> Function({
    required String deviceId,
    required String metric,
    required DateTime from,
    DateTime? to,
  })?
  getSensorHistory;

  @override
  State<StudentSensorDatasetPage> createState() =>
      _StudentSensorDatasetPageState();
}

/// Thai name + unit for each metric_type value the backend can return.
({String name, String unit}) sensorMetricInfo(String metric) =>
    switch (metric) {
      'pm25' => (name: 'ฝุ่น PM2.5', unit: 'µg/m³'),
      'aqi' => (name: 'AQI-UBA (ENS160)', unit: '/ 5'),
      'temperature' => (name: 'อุณหภูมิ', unit: '°C'),
      'humidity' => (name: 'ความชื้น', unit: '%RH'),
      'light_lux' => (name: 'ความเข้มแสง', unit: 'lux'),
      'co2' => (name: 'eCO2', unit: 'ppm'),
      'tvoc' => (name: 'TVOC', unit: 'ppb'),
      'energy_kwh' => (name: 'พลังงานไฟฟ้า', unit: 'kWh'),
      'power_w' => (name: 'กำลังไฟฟ้า', unit: 'W'),
      'water_flow_lmin' => (name: 'อัตราการไหลน้ำ', unit: 'L/min'),
      'water_volume_l' => (name: 'ปริมาณน้ำ', unit: 'L'),
      _ => (name: metric, unit: ''),
    };

String _fmtDate(DateTime d) {
  final l = d.toLocal();
  return '${l.day}/${l.month}/${l.year + 543} '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

class _StudentSensorDatasetPageState extends State<StudentSensorDatasetPage> {
  bool _loading = true;
  String? _error;
  List<SensorDataPoint> _points = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final load = widget.getSensorHistory ?? AiotLabService.getSensorHistory;
    final ds = widget.dataset;
    // No window from the teacher → the last 24 hours.
    final from =
        ds.timeStart ?? DateTime.now().subtract(const Duration(hours: 24));
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await load(
        deviceId: ds.deviceId,
        metric: ds.metric,
        from: from,
        to: ds.timeEnd,
      );
      if (!mounted) return;
      setState(() {
        _points = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลเซนเซอร์ไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = widget.dataset;
    final info = sensorMetricInfo(ds.metric);
    final title = (ds.label ?? '').trim().isNotEmpty ? ds.label! : info.name;
    return Scaffold(
      backgroundColor: SchoolPalette.softGreenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ชุดข้อมูลเซนเซอร์',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: SchoolPalette.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assignmentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SchoolPalette.cream,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(
                        Icons.sensors_rounded,
                        '${info.name} (${info.unit})',
                      ),
                      _chip(
                        Icons.schedule_rounded,
                        ds.timeStart == null
                            ? '24 ชั่วโมงล่าสุด'
                            : '${_fmtDate(ds.timeStart!)} – ${ds.timeEnd == null ? 'ตอนนี้' : _fmtDate(ds.timeEnd!)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: SchoolPalette.green),
                ),
              )
            else if (_error != null)
              StudentEmptyState(
                icon: Icons.cloud_off_rounded,
                title: _error!,
                hint: 'ดึงลงเพื่อลองใหม่',
              )
            else if (_points.isEmpty)
              const StudentEmptyState(
                icon: Icons.show_chart_rounded,
                title: 'ไม่มีข้อมูลในช่วงเวลานี้',
                hint: 'อุปกรณ์อาจไม่ได้ส่งค่าในช่วงที่ครูกำหนด แจ้งครูเพื่อปรับช่วงเวลา',
              )
            else ...[
              _StatsRow(points: _points, unit: info.unit),
              const SizedBox(height: 12),
              Container(
                height: 240,
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SchoolPalette.glassBorder),
                ),
                child: _DatasetChart(points: _points),
              ),
              const SizedBox(height: 10),
              Text(
                '${_points.length} จุดข้อมูล · ${_fmtDate(_points.first.ts)} – ${_fmtDate(_points.last.ts)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: SchoolPalette.cream),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.points, required this.unit});
  final List<SensorDataPoint> points;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    String f(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return Row(
      children: [
        _stat('ต่ำสุด', f(min), unit, SchoolPalette.blue),
        const SizedBox(width: 8),
        _stat('เฉลี่ย', f(avg), unit, SchoolPalette.green),
        const SizedBox(width: 8),
        _stat('สูงสุด', f(max), unit, SchoolPalette.orange),
      ],
    );
  }

  Widget _stat(String label, String value, String unit, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SchoolPalette.glassBorder),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _DatasetChart extends StatelessWidget {
  const _DatasetChart({required this.points});
  final List<SensorDataPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: SchoolPalette.glassBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (points.length / 4).clamp(1, 1e9).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                final t = points[i].ts.toLocal();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: SchoolPalette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: SchoolPalette.green,
            barWidth: 2.5,
            dotData: FlDotData(show: points.length <= 40),
            belowBarData: BarAreaData(
              show: true,
              color: SchoolPalette.green.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
