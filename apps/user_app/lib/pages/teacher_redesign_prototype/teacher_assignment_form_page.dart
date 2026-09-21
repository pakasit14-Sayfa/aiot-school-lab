import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../school_admin/school_timetable_page.dart' show SubjectColor;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;

/// สร้าง / แก้ไขใบงาน — iOS grouped form (design agreed 2026-09-21).
///
/// Replaces the old `_AssignmentFormSheet` bottom sheet for the phone flow:
/// no "ประเภทงาน" field (every worksheet is `worksheet`), the due date is a
/// real DateTime that reaches `create_assignment` / `update_assignment`
/// (the old sheet kept it as display text and never sent it), the status is
/// a switch that maps to publish/unpublish on save, and sensor datasets are
/// listed with a Thai metric name, time range and ✕ (unlink).
///
/// Pops with `true` when something was saved.
class TeacherAssignmentFormPage extends StatefulWidget {
  const TeacherAssignmentFormPage({
    super.key,
    required this.courseId,
    required this.courseName,
    this.existing,
    this.listMyRubrics,
    this.createAssignment,
    this.updateAssignment,
    this.publishAssignment,
    this.unpublishAssignment,
    this.loadAssignmentDetail,
    this.listDevices,
    this.linkSensorDataset,
    this.unlinkSensorDataset,
  });

  final String courseId;
  final String courseName;

  /// null = create new.
  final AssignmentSummary? existing;

  final Future<List<RubricModel>> Function()? listMyRubrics;
  final Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool isGroup,
  })?
  createAssignment;
  final Future<void> Function({
    required String assignmentId,
    String? title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool? isGroup,
  })?
  updateAssignment;
  final Future<void> Function(String assignmentId)? publishAssignment;
  final Future<void> Function(String assignmentId)? unpublishAssignment;
  final Future<AssignmentDetail> Function(String assignmentId)?
  loadAssignmentDetail;
  final Future<List<DeviceOption>> Function()? listDevices;
  final Future<void> Function({
    required String assignmentId,
    required String deviceId,
    required String metric,
    DateTime? timeStart,
    DateTime? timeEnd,
    String? label,
  })?
  linkSensorDataset;
  final Future<void> Function(String datasetId)? unlinkSensorDataset;

  @override
  State<TeacherAssignmentFormPage> createState() =>
      _TeacherAssignmentFormPageState();
}

/// Thai names for the metric enum values a dataset can carry.
const kMetricThai = <String, String>{
  'pm25': 'ฝุ่น PM2.5',
  'aqi': 'ดัชนีคุณภาพอากาศ',
  'co2': 'คาร์บอนไดออกไซด์',
  'tvoc': 'สารระเหย TVOC',
  'temperature': 'อุณหภูมิ',
  'humidity': 'ความชื้น',
  'gas_mq2_percent': 'แก๊สรั่ว',
  'light_lux': 'ความสว่าง',
  'energy_kwh': 'พลังงานไฟฟ้า',
  'power_w': 'กำลังไฟฟ้า',
  'water_flow_lmin': 'อัตราการไหลของน้ำ',
  'water_volume_l': 'ปริมาณน้ำ',
  'water_m3': 'ปริมาณน้ำ (ลบ.ม.)',
};

/// Only the 7 values `link_assignment_sensor_dataset`'s `metric_type` enum
/// accepts (20260715000000_initial_schema.sql).
const _linkableMetrics = {
  'pm25',
  'aqi',
  'temperature',
  'humidity',
  'light_lux',
  'energy_kwh',
  'power_w',
};

const _thaiMonths = [
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

String fmtThaiDateTime(DateTime d) {
  final l = d.toLocal();
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day} ${_thaiMonths[l.month - 1]} ${l.year + 543} · $hh:$mm น.';
}

String _fmtThaiShort(DateTime d) {
  final l = d.toLocal();
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day} ${_thaiMonths[l.month - 1]} $hh:$mm';
}

class _TeacherAssignmentFormPageState extends State<TeacherAssignmentFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _instructions;
  DateTime? _dueAt;
  bool _isGroup = false;
  bool _published = false;
  String? _rubricId;

  List<RubricModel> _rubrics = const [];
  bool _rubricsLoading = true;

  List<AssignmentSensorDataset> _datasets = const [];
  Map<String, DeviceOption> _devices = const {};
  bool _datasetsLoading = false;

  bool _saving = false;
  bool _dirty = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _title = TextEditingController(text: a?.title ?? '');
    _instructions = TextEditingController(text: a?.instructions ?? '');
    _dueAt = a?.dueAt?.toLocal();
    _isGroup = a?.isGroup ?? false;
    _published = a?.isPublished ?? false;
    _rubricId = a?.rubricId;
    _title.addListener(_markDirty);
    _instructions.addListener(_markDirty);
    _loadRubrics();
    if (_isEdit) _loadDatasets();
  }

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _loadRubrics() async {
    try {
      final list =
          await (widget.listMyRubrics ?? RubricService.listMyRubrics)();
      if (!mounted) return;
      setState(() {
        _rubrics = list;
        _rubricsLoading = false;
      });
    } catch (e) {
      debugPrint('TeacherAssignmentFormPage: โหลด rubric ไม่สำเร็จ — $e');
      if (mounted) setState(() => _rubricsLoading = false);
    }
  }

  Future<void> _loadDatasets() async {
    final id = widget.existing?.id;
    if (id == null) return;
    setState(() => _datasetsLoading = true);
    try {
      final detail =
          await (widget.loadAssignmentDetail ??
              AssignmentService.getAssignment)(id);
      List<DeviceOption> devices = const [];
      try {
        devices =
            await (widget.listDevices ?? LessonService.listSchoolDevices)();
      } catch (e) {
        debugPrint('TeacherAssignmentFormPage: โหลดอุปกรณ์ไม่สำเร็จ — $e');
      }
      if (!mounted) return;
      setState(() {
        _datasets = detail.sensorDatasets;
        _devices = {for (final d in devices) d.id: d};
        _datasetsLoading = false;
      });
    } catch (e) {
      debugPrint('TeacherAssignmentFormPage: โหลดชุดข้อมูลไม่สำเร็จ — $e');
      if (mounted) setState(() => _datasetsLoading = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? const Color(0xFFB91C1C) : null,
      ),
    );
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _pickDue() async {
    final picked = await _pickDateTime(
      _dueAt ??
          DateTime.now()
              .add(const Duration(days: 7))
              .copyWith(hour: 23, minute: 59),
    );
    if (picked == null) return;
    setState(() {
      _dueAt = picked;
      _dirty = true;
    });
  }

  Future<void> _pickRubric() async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: const Text('ไม่ใช้เกณฑ์การให้คะแนน'),
              trailing: _rubricId == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final r in _rubrics)
              ListTile(
                leading: const Icon(Icons.rule_rounded),
                title: Text(r.title),
                subtitle: Text('${r.criteriaCount} เกณฑ์'),
                trailing: _rubricId == r.id ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, r.id),
              ),
            if (_rubrics.isEmpty && !_rubricsLoading)
              const ListTile(
                title: Text('ยังไม่มีเกณฑ์การให้คะแนนของคุณ'),
                subtitle: Text('สร้างได้จากเมนู เกณฑ์การให้คะแนน'),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    setState(() {
      _rubricId = chosen.isEmpty ? null : chosen;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _snack('กรุณากรอกชื่อใบงาน', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      String id;
      if (_isEdit) {
        id = widget.existing!.id;
        await (widget.updateAssignment ?? AssignmentService.updateAssignment)(
          assignmentId: id,
          title: title,
          instructions: _instructions.text.trim(),
          dueAt: _dueAt,
          rubricId: _rubricId,
          isGroup: _isGroup,
        );
      } else {
        id =
            await (widget.createAssignment ??
                AssignmentService.createAssignment)(
              courseId: widget.courseId,
              type: 'worksheet',
              title: title,
              instructions: _instructions.text.trim(),
              dueAt: _dueAt,
              rubricId: _rubricId,
              isGroup: _isGroup,
            );
      }
      final wasPublished = widget.existing?.isPublished ?? false;
      if (_published && !wasPublished) {
        await (widget.publishAssignment ?? AssignmentService.publishAssignment)(
          id,
        );
      } else if (!_published && wasPublished) {
        await (widget.unpublishAssignment ??
            AssignmentService.unpublishAssignment)(id);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('TeacherAssignmentFormPage: บันทึกไม่สำเร็จ — $e');
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('บันทึกใบงานไม่สำเร็จ กรุณาลองใหม่', error: true);
    }
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      Navigator.pop(context, false);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ทิ้งการแก้ไข?'),
        content: const Text('สิ่งที่แก้ไว้จะไม่ถูกบันทึก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('แก้ต่อ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ทิ้งการแก้ไข',
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context, false);
  }

  Future<void> _unlink(AssignmentSensorDataset d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เอาชุดข้อมูลออก?'),
        content: Text(
          '${kMetricThai[d.metric] ?? d.metric} · ${_devices[d.deviceId]?.name ?? 'อุปกรณ์'}\nนักเรียนจะไม่เห็นกราฟชุดนี้ในใบงานอีก',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'เอาออก',
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await (widget.unlinkSensorDataset ??
          AssignmentService.unlinkSensorDataset)(d.id);
      await _loadDatasets();
      if (mounted) _snack('เอาชุดข้อมูลออกแล้ว');
    } catch (e) {
      debugPrint('TeacherAssignmentFormPage: unlink ล้ม — $e');
      if (mounted) _snack('เอาชุดข้อมูลออกไม่สำเร็จ', error: true);
    }
  }

  Future<void> _addDataset() async {
    final id = widget.existing?.id;
    if (id == null) return;
    List<DeviceOption> devices;
    try {
      devices = await (widget.listDevices ?? LessonService.listSchoolDevices)();
    } catch (e) {
      debugPrint('TeacherAssignmentFormPage: โหลดอุปกรณ์ไม่สำเร็จ — $e');
      if (mounted) _snack('โหลดรายการอุปกรณ์ไม่สำเร็จ', error: true);
      return;
    }
    final sensors = devices
        .where((d) => d.metrics.any(_linkableMetrics.contains))
        .toList();
    if (!mounted) return;
    if (sensors.isEmpty) {
      _snack('โรงเรียนยังไม่มีเซนเซอร์ที่เชื่อมชุดข้อมูลได้');
      return;
    }
    final req = await showModalBottomSheet<_LinkRequest>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LinkDatasetSheet(devices: sensors),
    );
    if (req == null || !mounted) return;
    try {
      await (widget.linkSensorDataset ?? AssignmentService.linkSensorDataset)(
        assignmentId: id,
        deviceId: req.deviceId,
        metric: req.metric,
        timeStart: req.start,
        timeEnd: req.end,
        label: req.label,
      );
      await _loadDatasets();
      if (mounted) _snack('เพิ่มชุดข้อมูลแล้ว');
    } catch (e) {
      debugPrint('TeacherAssignmentFormPage: link ล้ม — $e');
      if (mounted) _snack('เพิ่มชุดข้อมูลไม่สำเร็จ', error: true);
    }
  }

  // ─────────────────────────── UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = SubjectColor.of(widget.courseName);
    final rubricTitle = _rubricId == null
        ? 'ไม่ใช้'
        : (_rubrics
                  .where((r) => r.id == _rubricId)
                  .map((r) => r.title)
                  .firstOrNull ??
              widget.existing?.rubricTitle ??
              'กำลังโหลด…');

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: TextButton(
            onPressed: _saving ? null : _cancel,
            child: const Text('ยกเลิก'),
          ),
          leadingWidth: 84,
          centerTitle: true,
          title: Text(
            _isEdit ? 'แก้ไขใบงาน' : 'ใบงานใหม่',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: TeacherPalette.ink,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'บันทึก',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.fg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.courseName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _GroupLabel('ข้อมูล'),
            _Group(
              children: [
                _TextRow(controller: _title, hint: 'ชื่อใบงาน', bold: true),
                _TextRow(
                  controller: _instructions,
                  hint: 'คำสั่ง / รายละเอียดงาน',
                  maxLines: 6,
                ),
              ],
            ),
            _GroupLabel('การส่งงาน'),
            _Group(
              children: [
                _NavRow(
                  icon: Icons.event_rounded,
                  label: 'กำหนดส่ง',
                  value: _dueAt == null
                      ? 'ยังไม่กำหนด'
                      : fmtThaiDateTime(_dueAt!),
                  onTap: _saving ? null : _pickDue,
                ),
                _SwitchRow(
                  icon: Icons.groups_rounded,
                  label: 'งานกลุ่ม',
                  value: _isGroup,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                          _isGroup = v;
                          _dirty = true;
                        }),
                ),
                _NavRow(
                  icon: Icons.rule_rounded,
                  label: 'เกณฑ์การให้คะแนน',
                  value: rubricTitle,
                  onTap: _saving || _rubricsLoading ? null : _pickRubric,
                ),
                _SwitchRow(
                  icon: Icons.campaign_rounded,
                  label: 'เผยแพร่ให้นักเรียน',
                  value: _published,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                          _published = v;
                          _dirty = true;
                        }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                _published
                    ? 'นักเรียนในห้องจะเห็นใบงานนี้ทันทีที่บันทึก'
                    : 'ฉบับร่าง — นักเรียนยังไม่เห็น',
                style: const TextStyle(
                  fontSize: 12,
                  color: TeacherPalette.muted,
                ),
              ),
            ),
            _GroupLabel('ชุดข้อมูลเซนเซอร์'),
            if (!_isEdit)
              _Group(
                children: const [
                  _InfoRow(
                    'บันทึกใบงานก่อน แล้วค่อยเพิ่มชุดข้อมูลได้จากหน้าแก้ไข',
                  ),
                ],
              )
            else
              _Group(
                children: [
                  if (_datasetsLoading)
                    const _InfoRow('กำลังโหลด…')
                  else if (_datasets.isEmpty)
                    const _InfoRow('ยังไม่มีชุดข้อมูล'),
                  for (final d in _datasets)
                    _DatasetRow(
                      dataset: d,
                      deviceName: _devices[d.deviceId]?.name ?? 'อุปกรณ์',
                      onRemove: _saving ? null : () => _unlink(d),
                    ),
                  _NavRow(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'เพิ่มชุดข้อมูล',
                    value: '',
                    accent: true,
                    onTap: _saving ? null : _addDataset,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── grouped-form widgets ───────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: TeacherPalette.muted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          const Divider(height: 1, indent: 16, color: Color(0xFFE5E5EA)),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.bold = false,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: 1,
      style: TextStyle(
        fontSize: 16,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: TeacherPalette.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final fg = accent ? TeacherPalette.primary : TeacherPalette.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent ? fg : TeacherPalette.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 2,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!accent) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFC7C7CC),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, right: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: TeacherPalette.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: TeacherPalette.ink),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: TeacherPalette.primary,
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, color: TeacherPalette.muted),
    ),
  );
}

class _DatasetRow extends StatelessWidget {
  const _DatasetRow({
    required this.dataset,
    required this.deviceName,
    required this.onRemove,
  });
  final AssignmentSensorDataset dataset;
  final String deviceName;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) {
    final d = dataset;
    final range = d.timeStart == null && d.timeEnd == null
        ? 'ข้อมูลล่าสุด'
        : '${d.timeStart == null ? '…' : _fmtThaiShort(d.timeStart!)} – ${d.timeEnd == null ? 'ตอนนี้' : _fmtThaiShort(d.timeEnd!)}';
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4, top: 8, bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.sensors_rounded,
            size: 20,
            color: TeacherPalette.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.label?.trim().isNotEmpty == true
                      ? d.label!
                      : (kMetricThai[d.metric] ?? d.metric),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TeacherPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${kMetricThai[d.metric] ?? d.metric} · $deviceName · $range',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TeacherPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'เอาออก',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: TeacherPalette.muted,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── link sheet ───────────────────────────

class _LinkRequest {
  const _LinkRequest({
    required this.deviceId,
    required this.metric,
    this.start,
    this.end,
    this.label,
  });
  final String deviceId;
  final String metric;
  final DateTime? start;
  final DateTime? end;
  final String? label;
}

class _LinkDatasetSheet extends StatefulWidget {
  const _LinkDatasetSheet({required this.devices});
  final List<DeviceOption> devices;
  @override
  State<_LinkDatasetSheet> createState() => _LinkDatasetSheetState();
}

class _LinkDatasetSheetState extends State<_LinkDatasetSheet> {
  late DeviceOption _device = widget.devices.first;
  late String _metric = _metricsOf(_device).first;
  DateTime? _start;
  DateTime? _end;
  final _label = TextEditingController();

  List<String> _metricsOf(DeviceOption d) =>
      d.metrics.where(_linkableMetrics.contains).toList();

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const Text(
              'เพิ่มชุดข้อมูลเซนเซอร์',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _device.id,
              decoration: const InputDecoration(labelText: 'อุปกรณ์'),
              items: [
                for (final d in widget.devices)
                  DropdownMenuItem(
                    value: d.id,
                    child: Text(
                      d.location == null ? d.name : '${d.name} · ${d.location}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                final d = widget.devices.firstWhere((x) => x.id == id);
                setState(() {
                  _device = d;
                  _metric = _metricsOf(d).first;
                });
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(_device.id),
              initialValue: _metric,
              decoration: const InputDecoration(labelText: 'ค่าที่วัด'),
              items: [
                for (final m in _metricsOf(_device))
                  DropdownMenuItem(value: m, child: Text(kMetricThai[m] ?? m)),
              ],
              onChanged: (m) => setState(() => _metric = m ?? _metric),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'ชื่อชุดข้อมูล (ไม่บังคับ)',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('เริ่ม'),
              subtitle: Text(
                _start == null ? 'ไม่กำหนด' : fmtThaiDateTime(_start!),
              ),
              onTap: () async {
                final v = await _pick(
                  _start ?? DateTime.now().subtract(const Duration(days: 1)),
                );
                if (v != null) setState(() => _start = v);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop_rounded),
              title: const Text('สิ้นสุด'),
              subtitle: Text(_end == null ? 'ตอนนี้' : fmtThaiDateTime(_end!)),
              onTap: () async {
                final v = await _pick(_end ?? DateTime.now());
                if (v != null) setState(() => _end = v);
              },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _LinkRequest(
                  deviceId: _device.id,
                  metric: _metric,
                  start: _start,
                  end: _end,
                  label: _label.text.trim().isEmpty ? null : _label.text.trim(),
                ),
              ),
              child: const Text('เพิ่มชุดข้อมูล'),
            ),
          ],
        ),
      ),
    );
  }
}
