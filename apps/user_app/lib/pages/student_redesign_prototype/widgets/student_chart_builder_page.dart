import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_empty_state.dart';
import 'student_redesign_palette.dart';
import 'student_sensor_dataset_page.dart';

/// PBL-7 chart builder: pick one of the datasets the student is allowed to
/// read (list_my_sensor_datasets), narrow the window, write a note,
/// preview the real readings, save (create_chart). The server re-checks
/// the window, so the picker can only offer what will be accepted.
class StudentChartBuilderPage extends StatefulWidget {
  const StudentChartBuilderPage({
    super.key,
    this.loadDatasets,
    this.createChart,
    this.getSensorHistory,
  });

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
  State<StudentChartBuilderPage> createState() =>
      _StudentChartBuilderPageState();
}

class _StudentChartBuilderPageState extends State<StudentChartBuilderPage> {
  bool _loading = true;
  String? _error;
  List<ChartableDataset> _datasets = const [];
  ChartableDataset? _picked;
  DateTime? _from;
  DateTime? _to;
  final _note = TextEditingController();
  List<SensorDataPoint>? _preview;
  bool _previewing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final load = widget.loadDatasets ?? ChartService.listMySensorDatasets;
    try {
      final rows = await load();
      if (!mounted) return;
      setState(() {
        _datasets = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดชุดข้อมูลไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  // The dataset's bounds; an open side falls back to the last 24 h.
  DateTime _lower(ChartableDataset d) =>
      d.timeStart ?? DateTime.now().toUtc().subtract(const Duration(hours: 24));
  DateTime _upper(ChartableDataset d) => d.timeEnd ?? DateTime.now().toUtc();

  void _pick(ChartableDataset d) {
    setState(() {
      _picked = d;
      _from = _lower(d);
      _to = _upper(d);
      _preview = null;
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final d = _picked!;
    final base = (start ? _from! : _to!).toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: _lower(d).toLocal(),
      lastDate: _upper(d).toLocal(),
      helpText: start ? 'เริ่ม' : 'สิ้นสุด',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: start ? 'เวลาเริ่ม' : 'เวลาสิ้นสุด',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (time == null || !mounted) return;
    var picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toUtc();
    // Clamp inside the allowed window so create_chart cannot reject it.
    if (picked.isBefore(_lower(d))) picked = _lower(d);
    if (picked.isAfter(_upper(d))) picked = _upper(d);
    setState(() {
      if (start) {
        _from = picked;
        if (!_to!.isAfter(_from!)) _to = _upper(d);
      } else {
        _to = picked;
        if (!_to!.isAfter(_from!)) _from = _lower(d);
      }
      _preview = null;
    });
  }

  Future<void> _runPreview() async {
    final d = _picked!;
    final load = widget.getSensorHistory ?? AiotLabService.getSensorHistory;
    setState(() => _previewing = true);
    try {
      final rows = await load(
        deviceId: d.deviceId,
        metric: d.metric,
        from: _from!,
        to: _to,
      );
      if (!mounted) return;
      setState(() {
        _preview = rows;
        _previewing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ดึงข้อมูลตัวอย่างไม่สำเร็จ')),
      );
    }
  }

  Future<void> _save() async {
    final d = _picked!;
    final create = widget.createChart ?? ChartService.createChart;
    setState(() => _saving = true);
    try {
      await create(
        deviceId: d.deviceId,
        metric: d.metric,
        timeStart: _from!,
        timeEnd: _to!,
        chartType: 'line',
        courseId: d.courseId,
        annotation: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final scoped = e.toString().contains('learning_dataset_required');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scoped
                ? 'ช่วงเวลานี้อยู่นอกชุดข้อมูลที่ครูให้ เลือกช่วงใหม่'
                : 'บันทึกกราฟไม่สำเร็จ ลองใหม่อีกครั้ง',
          ),
        ),
      );
    }
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year + 543} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'สร้างกราฟ',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: SchoolPalette.green),
            )
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: StudentEmptyState(
                icon: Icons.cloud_off_rounded,
                title: _error!,
                hint: 'กลับไปแล้วลองใหม่',
              ),
            )
          : _datasets.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: StudentEmptyState(
                icon: Icons.sensors_off_rounded,
                title: 'ยังไม่มีชุดข้อมูลให้สร้างกราฟ',
                hint: 'กราฟสร้างได้จากชุดข้อมูลที่ครูผูกกับใบงานหรือบทเรียนเท่านั้น — เมื่อครูผูกแล้วจะขึ้นที่นี่',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _step('1', 'เลือกชุดข้อมูล'),
                const SizedBox(height: 8),
                for (final d in _datasets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DatasetChoice(
                      dataset: d,
                      selected: identical(d, _picked),
                      onTap: () => _pick(d),
                    ),
                  ),
                if (_picked != null) ...[
                  const SizedBox(height: 10),
                  _step('2', 'ช่วงเวลาที่จะวิเคราะห์'),
                  const SizedBox(height: 4),
                  Text(
                    'อยู่ในช่วงที่ครูให้: ${_fmt(_lower(_picked!))} – ${_fmt(_upper(_picked!))}',
                    style: const TextStyle(
                      color: SchoolPalette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _timeRow('เริ่ม', _fmt(_from!), () => _pickTime(start: true)),
                  const SizedBox(height: 8),
                  _timeRow(
                    'สิ้นสุด',
                    _fmt(_to!),
                    () => _pickTime(start: false),
                  ),
                  const SizedBox(height: 14),
                  _step('3', 'บันทึกสิ่งที่พบ (ไม่บังคับ)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _note,
                    maxLines: 2,
                    style: const TextStyle(
                      color: SchoolPalette.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'เช่น ฝุ่นสูงช่วง 8–9 โมงตอนรถรับส่งมา',
                      hintStyle: const TextStyle(
                        color: SchoolPalette.muted,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: SchoolPalette.glassBorder,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: SchoolPalette.green,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _previewing ? null : _runPreview,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(
                      _previewing ? 'กำลังดึงข้อมูล…' : 'ดูตัวอย่างกราฟ',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SchoolPalette.deepGreen,
                      side: const BorderSide(color: SchoolPalette.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  if (_preview != null) ...[
                    const SizedBox(height: 10),
                    if (_preview!.isEmpty)
                      const StudentEmptyState(
                        icon: Icons.show_chart_rounded,
                        title: 'ไม่มีข้อมูลในช่วงนี้',
                        hint: 'ลองขยับช่วงเวลา หรือเลือกชุดข้อมูลอื่น',
                      )
                    else
                      Container(
                        height: 200,
                        padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: SchoolPalette.glassBorder),
                        ),
                        child: _PreviewChart(points: _preview!),
                      ),
                    if (_preview!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${_preview!.length} จุดข้อมูล',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'กำลังบันทึก…' : 'บันทึกกราฟ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SchoolPalette.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _step(String n, String text) => Row(
    children: [
      Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: SchoolPalette.ink,
          shape: BoxShape.circle,
        ),
        child: Text(
          n,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SchoolPalette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );

  Widget _timeRow(String label, String value, VoidCallback onTap) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: SchoolPalette.glassBorder, width: 1.2),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: SchoolPalette.green,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: SchoolPalette.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SchoolPalette.muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _DatasetChoice extends StatelessWidget {
  const _DatasetChoice({
    required this.dataset,
    required this.selected,
    required this.onTap,
  });
  final ChartableDataset dataset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = sensorMetricInfo(dataset.metric);
    final title = (dataset.label ?? '').trim().isNotEmpty
        ? dataset.label!
        : info.name;
    return Material(
      color: selected
          ? SchoolPalette.green.withValues(alpha: 0.10)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? SchoolPalette.green : SchoolPalette.glassBorder,
          width: selected ? 1.6 : 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? SchoolPalette.green
                      : SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  dataset.source == 'lesson'
                      ? Icons.menu_book_rounded
                      : Icons.assignment_outlined,
                  size: 18,
                  color: selected ? Colors.white : SchoolPalette.green,
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
                      '${info.name} · ${dataset.deviceName} · ${dataset.source == 'lesson' ? 'บทเรียน' : 'ใบงาน'}: ${dataset.sourceTitle}',
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
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: SchoolPalette.green,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChart extends StatelessWidget {
  const _PreviewChart({required this.points});
  final List<SensorDataPoint> points;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: SchoolPalette.glassBorder, strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
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
