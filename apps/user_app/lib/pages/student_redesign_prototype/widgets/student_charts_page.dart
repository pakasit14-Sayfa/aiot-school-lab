import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_chart_builder_page.dart';
import 'student_empty_state.dart';
import 'student_redesign_palette.dart';
import 'student_sensor_dataset_page.dart';

/// PBL-7 "กราฟของฉัน": the charts this student saved (list_my_charts).
/// A chart stores the query, so opening one re-reads the live readings
/// through the same viewer PBL-6 uses.
class StudentChartsPage extends StatefulWidget {
  const StudentChartsPage({
    super.key,
    this.loadCharts,
    this.deleteChart,
    this.loadDatasets,
    this.createChart,
    this.getSensorHistory,
  });

  final Future<List<SavedChart>> Function()? loadCharts;
  final Future<void> Function(String chartId)? deleteChart;
  // Forwarded to the builder so tests can drive the whole flow.
  final Future<List<ChartableDataset>> Function()? loadDatasets;
  final Future<String> Function({
    required String deviceId,
    required String metric,
    required DateTime timeStart,
    required DateTime timeEnd,
    String chartType,
    String? courseId,
    String? annotation,
  })?
  createChart;
  final Future<List<SensorDataPoint>> Function({
    required String deviceId,
    required String metric,
    required DateTime from,
    DateTime? to,
  })?
  getSensorHistory;

  @override
  State<StudentChartsPage> createState() => _StudentChartsPageState();
}

class _StudentChartsPageState extends State<StudentChartsPage> {
  bool _loading = true;
  String? _error;
  List<SavedChart> _charts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final load = widget.loadCharts ?? ChartService.listMyCharts;
    try {
      final rows = await load();
      if (!mounted) return;
      setState(() {
        _charts = rows;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดกราฟไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  Future<void> _openBuilder() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StudentChartBuilderPage(
          loadDatasets: widget.loadDatasets,
          createChart: widget.createChart,
          getSensorHistory: widget.getSensorHistory,
        ),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _delete(SavedChart c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ลบกราฟนี้?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(c.annotation ?? sensorMetricInfo(c.metric).name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SchoolPalette.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final del = widget.deleteChart ?? ChartService.deleteChart;
    try {
      await del(c.id);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ลบกราฟไม่สำเร็จ')));
    }
  }

  void _open(SavedChart c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentSensorDatasetPage(
          dataset: AssignmentSensorDataset(
            id: c.id,
            deviceId: c.deviceId,
            metric: c.metric,
            timeStart: c.timeStart,
            timeEnd: c.timeEnd,
            label: c.annotation,
          ),
          assignmentTitle: 'กราฟของฉัน · ${c.deviceName}',
          getSensorHistory: widget.getSensorHistory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'กราฟของฉัน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        backgroundColor: SchoolPalette.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text(
          'สร้างกราฟ',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: SchoolPalette.green),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  if (_error != null)
                    StudentEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: _error!,
                      hint: 'ดึงลงเพื่อลองใหม่',
                    )
                  else if (_charts.isEmpty)
                    const StudentEmptyState(
                      icon: Icons.insert_chart_outlined_rounded,
                      title: 'ยังไม่มีกราฟ',
                      hint: 'กด "สร้างกราฟ" เลือกชุดข้อมูลที่ครูให้ แล้วเลือกช่วงเวลาที่อยากวิเคราะห์',
                    )
                  else
                    for (final c in _charts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ChartTile(
                          chart: c,
                          onTap: () => _open(c),
                          onDelete: () => _delete(c),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}

class _ChartTile extends StatelessWidget {
  const _ChartTile({
    required this.chart,
    required this.onTap,
    required this.onDelete,
  });
  final SavedChart chart;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _d(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final info = sensorMetricInfo(chart.metric);
    final title = (chart.annotation ?? '').trim().isNotEmpty
        ? chart.annotation!
        : info.name;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: SchoolPalette.glassBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: SchoolPalette.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${info.name} · ${chart.deviceName} · ${_d(chart.timeStart)} – ${_d(chart.timeEnd)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'ลบ',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: SchoolPalette.muted,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
