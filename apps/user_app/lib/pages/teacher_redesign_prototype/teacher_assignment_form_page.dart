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

  // Only meaningful when !_isEdit — creating a new assignment walks through
  // this many screens instead of the one flat form edit mode shows. Editing
  // stays a single scroll: the owner asked for "whatever's easiest for the
  // user" and re-walking a wizard just to change one field on an assignment
  // that already exists is friction a first-time create doesn't have.
  int _wizardStep = 0;
  static const _wizardStepCount = 4;

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

  void _wizardNext() {
    if (_wizardStep == 0 && _title.text.trim().isEmpty) {
      _snack('กรุณากรอกชื่อใบงาน', error: true);
      return;
    }
    if (_wizardStep < _wizardStepCount - 1) {
      setState(() => _wizardStep++);
    } else {
      _save();
    }
  }

  void _wizardBack() {
    if (_wizardStep > 0) {
      setState(() => _wizardStep--);
    } else {
      _cancel();
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
  //
  // Two structurally different bodies, not two skins of the same one:
  // creating an assignment walks through 4 focused screens (wizard);
  // editing an existing one stays a single flat scroll so any field is one
  // tap away — no re-walking steps to fix a typo. Both are built from the
  // same underline-field / tinted-row widgets below so they still read as
  // one design language. (owner: 2026-09-21, "เอาที่ง่ายต่อการใช้งาน")

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
      canPop: _isEdit ? !_dirty : (_wizardStep == 0 && !_dirty),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!_isEdit && _wizardStep > 0) {
          setState(() => _wizardStep--);
        } else {
          _cancel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _isEdit ? _editAppBar() : _wizardAppBar(),
        body: _isEdit
            ? _editBody(color, rubricTitle)
            : Column(
                children: [
                  _wizardProgress(),
                  Expanded(child: _wizardStepBody(color.fg, rubricTitle)),
                  _wizardBottomBar(),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _editAppBar() => AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    leading: TextButton(
      onPressed: _saving ? null : _cancel,
      child: const Text('ยกเลิก'),
    ),
    leadingWidth: 84,
    centerTitle: true,
    title: const Text(
      'แก้ไขใบงาน',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: TeacherPalette.ink,
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        // Neither dropping Center() nor switching the shape to StadiumBorder
        // fixed this (reproduced live both times, identical crash) — the
        // real cause is that AppBar.actions hands ElevatedButton an
        // *unbounded* max width, and ButtonStyleButton's internal
        // _RenderInputPadding tries to build a tight BoxConstraints from
        // that Infinity while measuring its minimum tap target size
        // ("BoxConstraints forces an infinite width" from RenderPhysicalShape,
        // every time). A fixed-size SizedBox gives it a finite width before
        // that measurement ever runs.
        child: SizedBox(
          width: 96,
          height: 38,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              disabledBackgroundColor: TeacherPalette.primary.withValues(
                alpha: 0.5,
              ),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: const StadiumBorder(),
            ),
            // styleFrom(textStyle:) *replaces* the button's inherited text
            // style rather than merging into it, which drops the app's font
            // family (the label then renders in the platform default while
            // the rest of the page is in the app font). Style the label.
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'บันทึก',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    ],
  );

  // The colour-coded dot + subject name that used to sit here said one
  // thing (which subject) and nothing about the worksheet being edited.
  // Replaced by a hero card in the subject's own colour that answers the
  // three questions a teacher opens this page with — เผยแพร่แล้วหรือยัง ·
  // ส่งเมื่อไหร่ (และเหลือกี่วัน) · เดี่ยวหรือกลุ่ม — and updates live as
  // the fields below change. Everything under it stays the calm form it
  // already was. (owner: 2026-09-21, "หัวการ์ดสีวิชา + เนื้อเรียบ")
  Widget _editBody(SubjectColor subject, String rubricTitle) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
    children: [
      _AssignmentHeroCard(
        subject: subject,
        subjectName: widget.courseName,
        title: _title,
        published: _published,
        dueAt: _dueAt,
        isGroup: _isGroup,
        datasetCount: _datasets.length,
      ),
      _GroupLabel('ข้อมูล'),
      _TextRow(
        controller: _title,
        hint: 'ชื่อใบงาน',
        label: 'ชื่อใบงาน',
        bold: true,
      ),
      _TextRow(
        controller: _instructions,
        hint: 'คำสั่ง / รายละเอียดงาน',
        label: 'คำอธิบาย',
        maxLines: 6,
      ),
      _GroupLabel('การส่งงาน'),
      _NavRow(
        icon: Icons.event_rounded,
        label: 'กำหนดส่ง',
        value: _dueAt == null ? 'ยังไม่กำหนด' : fmtThaiDateTime(_dueAt!),
        onTap: _saving ? null : _pickDue,
        chipBg: _chipIndigoBg,
        chipFg: _chipIndigoFg,
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
        chipBg: _chipMintBg,
        chipFg: _chipMintFg,
      ),
      _NavRow(
        icon: Icons.rule_rounded,
        label: 'เกณฑ์การให้คะแนน',
        value: rubricTitle,
        onTap: _saving || _rubricsLoading ? null : _pickRubric,
        chipBg: _chipAmberBg,
        chipFg: _chipAmberFg,
      ),
      // การเผยแพร่แยกเป็นหมวดของตัวเอง — อันอื่นแก้ทีหลังได้เสมอ แต่ปุ่มนี้
      // มีผลจริงทันทีที่กดบันทึก (นักเรียนเห็นเลย) — สมควรแยกให้เด่นกว่า
      _GroupLabel('การเผยแพร่'),
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
        highlightWhenOn: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: Text(
          _published
              ? 'นักเรียนในห้องจะเห็นใบงานนี้ทันทีที่บันทึก'
              : 'ฉบับร่าง — นักเรียนยังไม่เห็น',
          style: TextStyle(
            fontSize: 12,
            fontWeight: _published ? FontWeight.w700 : FontWeight.w400,
            color: _published ? _chipGreenFg : TeacherPalette.muted,
          ),
        ),
      ),
      _GroupLabel('ชุดข้อมูลเซนเซอร์'),
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
  );

  // ── wizard (create mode) ──

  PreferredSizeWidget _wizardAppBar() => AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    automaticallyImplyLeading: false,
    leading: TextButton(
      onPressed: _saving ? null : _wizardBack,
      child: Text(_wizardStep == 0 ? 'ยกเลิก' : '‹ ย้อนกลับ'),
    ),
    leadingWidth: 100,
    centerTitle: true,
    title: Text(
      '${_wizardStep + 1} / $_wizardStepCount',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: TeacherPalette.muted,
        letterSpacing: 0.2,
      ),
    ),
  );

  Widget _wizardProgress() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Row(
      children: [
        for (var i = 0; i < _wizardStepCount; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= _wizardStep
                    ? TeacherPalette.primary
                    : const Color(0xFFEDECF5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _stepHeader(Color subjectDot, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 4, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: subjectDot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.courseName,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: TeacherPalette.primary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: TeacherPalette.ink,
            letterSpacing: -0.3,
          ),
        ),
      ],
    ),
  );

  Widget _wizardStepBody(Color subjectDot, String rubricTitle) {
    switch (_wizardStep) {
      case 0:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _stepHeader(subjectDot, 'ชื่อและคำอธิบายใบงาน'),
            _TextRow(
              controller: _title,
              hint: 'ชื่อใบงาน',
              label: 'ชื่อใบงาน',
              bold: true,
            ),
            _TextRow(
              controller: _instructions,
              hint: 'คำสั่ง / รายละเอียดงาน',
              label: 'คำอธิบาย',
              maxLines: 6,
            ),
          ],
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _stepHeader(subjectDot, 'ตั้งค่าการส่งงาน'),
            _NavRow(
              icon: Icons.event_rounded,
              label: 'กำหนดส่ง',
              value: _dueAt == null ? 'ยังไม่กำหนด' : fmtThaiDateTime(_dueAt!),
              onTap: _saving ? null : _pickDue,
              chipBg: _chipIndigoBg,
              chipFg: _chipIndigoFg,
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
              chipBg: _chipMintBg,
              chipFg: _chipMintFg,
            ),
            _NavRow(
              icon: Icons.rule_rounded,
              label: 'เกณฑ์การให้คะแนน',
              value: rubricTitle,
              onTap: _saving || _rubricsLoading ? null : _pickRubric,
              chipBg: _chipAmberBg,
              chipFg: _chipAmberFg,
            ),
          ],
        );
      case 2:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _stepHeader(subjectDot, 'พร้อมเผยแพร่หรือยัง?'),
            _PublishHighlightCard(
              value: _published,
              onChanged: _saving
                  ? null
                  : (v) => setState(() {
                      _published = v;
                      _dirty = true;
                    }),
            ),
          ],
        );
      default:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _stepHeader(subjectDot, 'ชุดข้อมูลเซนเซอร์ & สรุป'),
            const _InfoRow(
              'บันทึกใบงานก่อน แล้วค่อยเพิ่มชุดข้อมูลได้จากหน้าแก้ไข',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              'ชื่อใบงาน',
              _title.text.trim().isEmpty ? '—' : _title.text.trim(),
            ),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            _SummaryRow(
              'กำหนดส่ง',
              _dueAt == null ? 'ยังไม่กำหนด' : fmtThaiDateTime(_dueAt!),
            ),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            _SummaryRow('งานกลุ่ม', _isGroup ? 'ใช่' : 'ไม่ใช่'),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            _SummaryRow('เกณฑ์การให้คะแนน', rubricTitle),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            _SummaryRow('เผยแพร่', _published ? 'ทันทีที่บันทึก' : 'ฉบับร่าง'),
          ],
        );
    }
  }

  Widget _wizardBottomBar() {
    final isLast = _wizardStep == _wizardStepCount - 1;
    const nextLabels = [
      'ถัดไป — การส่งงาน',
      'ถัดไป — การเผยแพร่',
      'ถัดไป — ชุดข้อมูลเซนเซอร์',
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _wizardNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast
                      ? _chipGreenFg
                      : TeacherPalette.primary,
                  disabledBackgroundColor:
                      (isLast ? _chipGreenFg : TeacherPalette.primary)
                          .withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isLast ? 'บันทึกใบงาน' : nextLabels[_wizardStep]),
              ),
            ),
            if (isLast)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'ย้อนกลับไปแก้ไขขั้นไหนก็ได้ก่อนบันทึก',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── hero card ───────────────────────────

/// วันครบกำหนดเทียบกับวันนี้ — นับเป็น "วัน" ตามปฏิทิน ไม่ใช่ 24 ชม.
/// (งานที่ส่ง 23:59 คืนนี้ต้องอ่านว่า "วันนี้" ไม่ใช่ "อีก 0 วัน")
String? dueCountdownLabel(DateTime? due, {DateTime? now}) {
  if (due == null) return null;
  final n = (now ?? DateTime.now()).toLocal();
  final d = due.toLocal();
  final days = DateTime(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime(n.year, n.month, n.day)).inDays;
  if (days == 0) return 'ครบกำหนดวันนี้';
  if (days == 1) return 'อีก 1 วัน';
  if (days > 1) return 'อีก $days วัน';
  if (days == -1) return 'เลยกำหนด 1 วัน';
  return 'เลยกำหนด ${-days} วัน';
}

/// หัวการ์ดสีประจำวิชาของหน้าแก้ไขใบงาน — ชื่อใบงานที่กำลังพิมพ์ สถานะ
/// เผยแพร่/ร่าง กำหนดส่งพร้อมวันที่เหลือ เดี่ยว/กลุ่ม และจำนวนชุดข้อมูล
/// ทุกค่าเป็นสถานะจริงของฟอร์มตอนนั้น ไม่ใช่ค่าที่แต่งไว้ — แก้ข้างล่าง
/// แล้วการ์ดเปลี่ยนทันที
class _AssignmentHeroCard extends StatelessWidget {
  const _AssignmentHeroCard({
    required this.subject,
    required this.subjectName,
    required this.title,
    required this.published,
    required this.dueAt,
    required this.isGroup,
    required this.datasetCount,
  });

  final SubjectColor subject;
  final String subjectName;
  final TextEditingController title;
  final bool published;
  final DateTime? dueAt;
  final bool isGroup;
  final int datasetCount;

  @override
  Widget build(BuildContext context) {
    // ไล่เฉดจากสีเข้มของวิชาไปหาสีแท่งของวิชาแค่ 45% — พอให้เห็นว่าเป็นสี
    // ของวิชานั้นจริง แต่ยังเข้มพอให้ตัวหนังสือขาวอ่านออกครบทั้ง 8 คู่สี
    // (คู่สีส้ม/เหลืองจะสว่างเกินถ้าไล่ไปจนสุด)
    final top = subject.fg;
    final bottom = Color.lerp(subject.fg, subject.bar, 0.45)!;
    final overdue =
        dueAt != null && dueAt!.toLocal().isBefore(DateTime.now());
    final countdown = dueCountdownLabel(dueAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: subject.fg.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    subjectName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HeroStatusPill(published: published, onColor: subject.fg),
            ],
          ),
          const SizedBox(height: 14),
          // ชื่อใบงานอัปเดตทุกตัวอักษรที่พิมพ์ในช่องข้างล่าง — ฟอร์มตั้ง
          // _dirty แค่ครั้งแรกครั้งเดียว จึงต้องฟัง controller ตรงนี้เอง
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: title,
            builder: (_, value, _) {
              final t = value.text.trim();
              return Text(
                t.isEmpty ? 'ยังไม่ได้ตั้งชื่อใบงาน' : t,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: t.isEmpty
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.event_rounded,
                text: dueAt == null
                    ? 'ยังไม่กำหนดส่ง'
                    : 'ส่ง ${_fmtThaiShort(dueAt!)} น.',
              ),
              if (countdown != null)
                _HeroChip(
                  icon: overdue
                      ? Icons.error_outline_rounded
                      : Icons.schedule_rounded,
                  text: countdown,
                  solid: overdue,
                  solidFg: const Color(0xFFB3261E),
                ),
              _HeroChip(
                icon: isGroup ? Icons.groups_rounded : Icons.person_rounded,
                text: isGroup ? 'งานกลุ่ม' : 'งานเดี่ยว',
              ),
              if (datasetCount > 0)
                _HeroChip(
                  icon: Icons.sensors_rounded,
                  text: 'เซนเซอร์ $datasetCount ชุด',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({required this.published, required this.onColor});
  final bool published;
  final Color onColor;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: published ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      border: published
          ? null
          : Border.all(color: Colors.white.withValues(alpha: 0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: published ? const Color(0xFF107A50) : Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          published ? 'เผยแพร่แล้ว' : 'ฉบับร่าง',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: published ? onColor : Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.text,
    this.solid = false,
    this.solidFg,
  });
  final IconData icon;
  final String text;
  final bool solid;
  final Color? solidFg;
  @override
  Widget build(BuildContext context) {
    final fg = solid ? (solidFg ?? const Color(0xFFB3261E)) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? Colors.white : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: solid ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ],
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
    // Was a small muted all-purpose caption (13px); bumped to read as an
    // actual section heading — the reference apps use a bold sentence-case
    // title ("Goals"), not an uppercase micro-label, between groups.
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        color: TeacherPalette.ink,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// Pastel icon-chip tints, one per row purpose — owner asked for a look
// "between Apple and Android", pointing at reference apps that colour-code
// row icons by category instead of repeating one flat grey/primary icon on
// every row. Kept local to this file rather than added to TeacherPalette:
// this is one page's chip treatment, not a lane-wide palette decision.
const _chipIndigoBg = Color(0xFFEDEFFE);
const _chipIndigoFg = Color(0xFF4F55D6);
const _chipMintBg = Color(0xFFE3F7EF);
const _chipMintFg = Color(0xFF0E7A57);
const _chipAmberBg = Color(0xFFFDF1DE);
const _chipAmberFg = Color(0xFFB4650F);
const _chipPinkBg = Color(0xFFFCE8F3);
const _chipPinkFg = Color(0xFFC23B87);
const _chipGreenBg = Color(0xFFE1F6EC);
const _chipGreenFg = Color(0xFF107A50);

// Rows below are each self-contained (own tinted background / underline) —
// no shared card container anymore. Two owner-rejected "ดูแปลกๆ" rounds
// both had a solid grouped-card wrapper; the wizard mockup the owner picked
// has none, so both the wizard and the flat edit-mode form now reuse these
// same standalone rows instead of a card.

class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.bold = false,
    this.label,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool bold;
  final String? label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TeacherPalette.muted,
                letterSpacing: 0.2,
              ),
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFEDECF5), width: 2),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: 1,
            style: TextStyle(
              fontSize: bold ? 17 : 16,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: TeacherPalette.ink,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 10),
            ),
          ),
        ),
      ],
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
    this.chipBg,
    this.chipFg,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool accent;
  final Color? chipBg;
  final Color? chipFg;
  @override
  Widget build(BuildContext context) {
    final fg = accent ? TeacherPalette.primary : TeacherPalette.ink;
    final iconBg =
        chipBg ??
        (accent
            ? TeacherPalette.primary.withValues(alpha: 0.14)
            : const Color(0xFFEDECF5));
    final iconFg =
        chipFg ?? (accent ? TeacherPalette.primary : TeacherPalette.muted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: iconFg),
                ),
                const SizedBox(width: 12),
                // ทั้งสองฝั่งเคยเป็น Flexible คู่กัน (ชื่อแถว 1 : ค่า 2) ซึ่ง
                // แบ่งพื้นที่ตามสัดส่วนตายตัว ไม่สนว่าอีกฝั่งใช้จริงแค่ไหน —
                // "เกณฑ์การให้คะแนน" จึงโดนตัดเป็น "เกณฑ์การใ…" ทั้งที่ค่า
                // คือ "ไม่ใช้" สั้นนิดเดียว ตอนนี้ชื่อแถวกินตามความกว้างจริง
                // (ไม่เกิน 62% กันแถวชื่อยาวผิดปกติ) แล้วค่าได้ที่เหลือทั้งหมด
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, c) => Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: c.maxWidth * 0.62,
                          ),
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, color: fg),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
    this.chipBg,
    this.chipFg,
    this.highlightWhenOn = false,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? chipBg;
  final Color? chipFg;
  // Publishing takes effect the moment this switch flips (students see the
  // assignment immediately on save) — a plain small switch undersold that
  // compared to every other row here, which are all safe to change and
  // revisit later. Turning the whole row green while on gives it the
  // visual weight the action actually has.
  final bool highlightWhenOn;
  @override
  Widget build(BuildContext context) {
    final live = highlightWhenOn && value;
    final iconBg = live ? _chipGreenBg : (chipBg ?? const Color(0xFFEDECF5));
    final iconFg = live ? _chipGreenFg : (chipFg ?? TeacherPalette.muted);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: live
            ? _chipGreenBg.withValues(alpha: 0.55)
            : const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(left: 14, right: 10, top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: live ? FontWeight.w700 : FontWeight.w400,
                color: live ? _chipGreenFg : TeacherPalette.ink,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: live ? _chipGreenFg : TeacherPalette.primary,
          ),
        ],
      ),
    );
  }
}

/// The dedicated, high-emphasis card for the "publish" decision on the
/// wizard's own step — everything else in the form is safe to change later,
/// this one goes live for students the moment save succeeds.
class _PublishHighlightCard extends StatelessWidget {
  const _PublishHighlightCard({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeacherPalette.primary,
          TeacherPalette.primary.withValues(alpha: 0.82),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'เผยแพร่ให้นักเรียน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: Colors.white,
              activeThumbColor: TeacherPalette.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value
              ? 'เปิดไว้ = นักเรียนในห้องจะเห็นใบงานนี้ทันทีที่กดบันทึกในขั้นถัดไป'
              : 'ปิดไว้ = บันทึกเป็นฉบับร่าง เผยแพร่ทีหลังได้',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

/// Key/value line for the wizard's last-step "confirm before you save"
/// summary.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.k, this.v);
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(
              fontSize: 14,
              color: TeacherPalette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(16),
    ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 14, right: 4, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _chipPinkBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 17,
              color: _chipPinkFg,
            ),
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
