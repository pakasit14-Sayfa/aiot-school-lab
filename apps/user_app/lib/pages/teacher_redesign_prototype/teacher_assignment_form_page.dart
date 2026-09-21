import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../school_admin/school_timetable_page.dart' show SubjectColor;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_rubric_page.dart' show TeacherRubricPage;

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

  /// ชีตเลือกเกณฑ์ — เดิมเป็น ListTile เปล่า ๆ ไม่มีหัวชีต และตอนไม่มีเกณฑ์
  /// เลยจะโชว์บรรทัด "ยังไม่มีเกณฑ์…" ปนเป็นตัวเลือกที่กดไม่ได้ พร้อมบอกให้
  /// "ไปสร้างจากเมนูเกณฑ์การให้คะแนน" ซึ่งเป็นทางตันในชีต — ตอนนี้มีหัวชีต
  /// จริง ที่ว่างเป็นบล็อกของตัวเอง และมีปุ่มเปิดหน้าเกณฑ์ไปสร้างได้เลย
  /// กลับมาแล้วโหลดรายการใหม่ให้อัตโนมัติ
  Future<void> _pickRubric() async {
    final subject = SubjectColor.of(widget.courseName);
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _RubricPickerSheet(
        rubrics: _rubrics,
        selectedId: _rubricId,
        accent: subject.fg,
        onCreate: () async {
          Navigator.pop(ctx);
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TeacherRubricPage()),
          );
          if (!mounted) return;
          setState(() => _rubricsLoading = true);
          await _loadRubrics();
        },
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
  //
  // หน้าเดียวทั้งสร้างและแก้ไข — เคยแยกเป็น wizard 4 ขั้นตอนสร้าง (2026-09-21)
  // แล้วถอยออกตามที่เจ้าของสั่ง: ครูไม่ต้องเรียนรู้สองแบบ และการเดินสี่จอเพื่อ
  // กรอกสามช่องไม่ได้ช่วยอะไรนอกจากเพิ่มจำนวนครั้งที่ต้องกด

  /// โหมด Classroom: ปุ่มหลักมุมขวาบนคือการกระทำ ไม่ใช่สวิตช์ในฟอร์ม
  /// ร่าง → "มอบหมาย" (บันทึก+เผยแพร่) · เผยแพร่แล้ว → "บันทึก"
  /// ส่วนอีกทางอยู่ในเมนู ⋮ (บันทึกร่าง / ยกเลิกการเผยแพร่)
  Future<void> _assignNow() async {
    setState(() => _published = true);
    await _save();
  }

  Future<void> _saveAsDraft() async {
    setState(() => _published = false);
    await _save();
  }

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
        backgroundColor: Color.lerp(color.bg, Colors.white, 0.55),
        extendBodyBehindAppBar: true,
        bottomNavigationBar: _saveBar(color),
        appBar: _editAppBar(),
        body: _editBody(color, rubricTitle),
      ),
    );
  }

  /// แถบบนโปร่งวางทับหัวสีวิชา — เหลือแค่ทางออกซ้ายกับเมนูรองขวา
  /// ปุ่มหลักอยู่แถบล่าง (นิ้วโป้งถึงกว่า และเห็นตลอดเวลาโดยไม่ต้องเลื่อน)
  PreferredSizeWidget _editAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: TextButton(
      onPressed: _saving ? null : _cancel,
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: const Text('ยกเลิก'),
    ),
    leadingWidth: 84,
    centerTitle: true,
    title: Text(
      _isEdit ? 'แก้ไขใบงาน' : 'ใบงานใหม่',
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    actions: [
      PopupMenuButton<String>(
        tooltip: 'ตัวเลือกเพิ่มเติม',
        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
        onSelected: (v) {
          if (v == 'draft' || v == 'unpublish') _saveAsDraft();
        },
        itemBuilder: (_) => [
          if (_published)
            const PopupMenuItem(
              value: 'unpublish',
              child: Text('ยกเลิกการเผยแพร่'),
            )
          else
            const PopupMenuItem(value: 'draft', child: Text('บันทึกร่าง')),
        ],
      ),
      const SizedBox(width: 4),
    ],
  );

  /// สามชั้น: (1) พื้นหลังสีอ่อนของวิชา (2) หัวสีเข้มที่ไหลขึ้นไปใต้แถบ
  /// สถานะ (3) แผ่นขาวมุมมน 26 เลื่อนขึ้นทับหัว 26pt พร้อมเงา — ฟอร์มอยู่บน
  /// แผ่นที่สามแผ่นเดียว ไม่ใช่การ์ดย่อยลอยเป็นชิ้น ๆ
  Widget _editBody(SubjectColor subject, String rubricTitle) => ListView(
    padding: EdgeInsets.zero,
    children: [
      _SubjectHeader(
        subject: subject,
        subjectName: widget.courseName,
        title: _title,
        published: _published,
        dueAt: _dueAt,
        isGroup: _isGroup,
        datasetCount: _datasets.length,
        topPadding: MediaQuery.paddingOf(context).top + kToolbarHeight,
      ),
      Transform.translate(
        offset: const Offset(0, -26),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A101828),
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _bodyRows(rubricTitle),
          ),
        ),
      ),
    ],
  );

  // เนื้อฟอร์ม — ค่าอยู่บรรทัดล่างของชื่อแถวเสมอ ค่ายาวแค่ไหนก็ไม่แย่งที่
  // กับชื่อแถว (ปัญหาเดิมที่ทำให้ "เกณฑ์การให้คะแนน" โดนตัดกลางคำ) และเหลือ
  // ที่พอเขียนผลของสวิตช์เป็นประโยคแทนคำเดียว
  //
  // ไม่มีหมวด "การเผยแพร่" ในฟอร์มแล้ว — การเผยแพร่เป็นผลของปุ่มที่กด ไม่ใช่
  // ค่าที่ตั้งค้างไว้ (วิธีของ Google Classroom ที่ครูคุ้นอยู่แล้ว) ดูแถบล่าง

  List<Widget> _bodyRows(String rubricTitle) => [
    _SectionHead('ข้อมูล'),
    _FilledField(
      controller: _title,
      label: 'ชื่อใบงาน',
      hint: 'เช่น ใบงานทบทวนบทที่ 1',
      bold: true,
    ),
    _FilledField(
      controller: _instructions,
      label: 'คำอธิบาย',
      hint: 'คำสั่ง / รายละเอียดงาน',
      maxLines: 5,
    ),
    _SectionHead('การส่งงาน'),
    _StackRow(
      icon: Icons.event_rounded,
      chipBg: _chipIndigoBg,
      chipFg: _chipIndigoFg,
      label: 'กำหนดส่ง',
      value: _dueAt == null ? 'ยังไม่กำหนด' : fmtThaiDateTime(_dueAt!),
      onTap: _saving ? null : _pickDue,
    ),
    _StackRow(
      icon: Icons.groups_rounded,
      chipBg: _chipMintBg,
      chipFg: _chipMintFg,
      label: 'งานกลุ่ม',
      value: _isGroup ? 'ส่ง 1 ชิ้นต่อกลุ่ม' : 'นักเรียนส่งงานรายคน',
      switchValue: _isGroup,
      onChanged: _saving ? null : _toggleGroup,
    ),
    _StackRow(
      icon: Icons.rule_rounded,
      chipBg: _chipAmberBg,
      chipFg: _chipAmberFg,
      label: 'เกณฑ์การให้คะแนน',
      value: rubricTitle,
      onTap: _saving || _rubricsLoading ? null : _pickRubric,
    ),
    _SectionHead('ชุดข้อมูลเซนเซอร์'),
    // ผูกชุดข้อมูลต้องมี assignment id จริงก่อน — โหมดสร้างจึงบอกตรง ๆ ว่า
    // ให้บันทึกก่อน แทนที่จะโชว์ปุ่มที่กดแล้วไม่เกิดอะไร
    if (!_isEdit)
      const _InfoRow('บันทึกใบงานก่อน แล้วค่อยเพิ่มชุดข้อมูลได้จากหน้าแก้ไข')
    else ...[
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
  ];

  void _toggleGroup(bool v) => setState(() {
    _isGroup = v;
    _dirty = true;
  });

  /// แถบล่าง — ปุ่มหลักเต็มความกว้างในระยะที่นิ้วโป้งถึง พร้อมบรรทัดบอก
  /// สถานะปัจจุบันเหนือปุ่ม อ่านได้ตรงจุดที่กำลังจะกด
  ///
  /// ยังเป็นร่าง → ปุ่มคือ "มอบหมายให้นักเรียน" (บันทึก + เผยแพร่)
  /// มอบหมายแล้ว → ปุ่มคือ "บันทึก" (แก้ไขของที่นักเรียนเห็นอยู่)
  /// อีกทางอยู่ในเมนู ⋯ มุมขวาบน (บันทึกร่าง / ยกเลิกการเผยแพร่)
  Widget _saveBar(SubjectColor subject) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x14101828),
          blurRadius: 18,
          offset: Offset(0, -6),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _published
                      ? Icons.public_rounded
                      : Icons.lock_outline_rounded,
                  size: 15,
                  color: _published ? _chipGreenFg : TeacherPalette.muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _published
                        ? 'นักเรียนในห้องเห็นใบงานนี้อยู่'
                        : (_isEdit
                              ? 'ยังไม่ได้มอบหมาย — นักเรียนยังไม่เห็น'
                              : 'ยังไม่ได้มอบหมาย — บันทึกร่างได้จากเมนู ⋯'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _published ? _chipGreenFg : TeacherPalette.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : (_published ? _save : _assignNow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: subject.fg,
                  disabledBackgroundColor: subject.fg.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                    : Text(
                        _published ? 'บันทึก' : 'มอบหมายให้นักเรียน',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────── body widgets (3 แบบ) ───────────────────────────

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
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

/// ช่องกรอกแบบกล่องพื้นเทา — ป้ายกำกับอยู่นอกกล่องด้านบน ตัวกล่องมุม 16
/// เท่ากับแถวตั้งค่า ทำให้ "ข้อมูล" กับ "การส่งงาน" เป็นภาษาเดียวกัน
class _FilledField extends StatelessWidget {
  const _FilledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.bold = false,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TeacherPalette.muted,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7FB),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: 1,
            style: TextStyle(
              fontSize: bold ? 17 : 15.5,
              height: 1.4,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: TeacherPalette.ink,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB9B8C6)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    ),
  );
}

/// แถวการ์ดที่วางค่าไว้บรรทัดล่างของชื่อแถว — ค่ายาวแค่ไหนก็ไม่แย่งที่กับ
/// ชื่อแถว (ปัญหาเดิมที่ทำให้ "เกณฑ์การให้คะแนน" โดนตัด) และมีที่พอจะเขียน
/// ผลของสวิตช์เป็นประโยคแทนคำเดียว
class _StackRow extends StatelessWidget {
  const _StackRow({
    required this.icon,
    required this.chipBg,
    required this.chipFg,
    required this.label,
    required this.value,
    this.onTap,
    this.switchValue,
    this.onChanged,
  });
  final IconData icon;
  final Color chipBg;
  final Color chipFg;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: chipFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: TeacherPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: TeacherPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (switchValue != null)
            Switch.adaptive(
              value: switchValue!,
              onChanged: onChanged,
              activeTrackColor: TeacherPalette.primary,
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFC7C7CC),
              ),
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
        child: onTap == null
            ? body
            : InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: body,
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
  const _HeroChip({required this.icon, required this.text, this.solid = false});
  final IconData icon;
  final String text;

  /// ชิป "เลยกำหนด" กลับสี — พื้นขาวตัวแดง เพื่อให้เด้งออกจากชิปอื่นบนหัวสี
  final bool solid;
  @override
  Widget build(BuildContext context) {
    final fg = solid ? const Color(0xFFB3261E) : Colors.white;
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

/// หัวสีประจำวิชาเต็มความกว้าง ไหลขึ้นไปใต้แถบสถานะ — ตอบสามคำถามแรกที่ครู
/// เปิดหน้านี้มาถาม: มอบหมายแล้วหรือยัง · ส่งเมื่อไหร่ เหลือกี่วัน · เดี่ยว
/// หรือกลุ่ม (และผูกเซนเซอร์ไว้กี่ชุด) ทุกค่าเป็น state จริงของฟอร์มตอนนั้น
/// ชื่อใบงานอัปเดตทุกตัวอักษรที่พิมพ์ในช่องข้างล่าง
class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({
    required this.subject,
    required this.subjectName,
    required this.title,
    required this.published,
    required this.dueAt,
    required this.isGroup,
    required this.datasetCount,
    required this.topPadding,
  });

  /// ระยะบน = safe area + ความสูงแถบบน เพราะหัวนี้วาดอยู่ใต้แถบบนที่โปร่ง
  final double topPadding;

  final SubjectColor subject;
  final String subjectName;
  final TextEditingController title;
  final bool published;
  final DateTime? dueAt;
  final bool isGroup;
  final int datasetCount;

  @override
  Widget build(BuildContext context) {
    final overdue = dueAt != null && dueAt!.toLocal().isBefore(DateTime.now());
    final countdown = dueCountdownLabel(dueAt);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 46),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [subject.fg, Color.lerp(subject.fg, subject.bar, 0.45)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  subjectName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HeroStatusPill(published: published, onColor: subject.fg),
            ],
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: title,
            builder: (_, value, _) {
              final t = value.text.trim();
              return Text(
                t.isEmpty ? 'ยังไม่ได้ตั้งชื่อใบงาน' : t,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: t.isEmpty
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
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

// ─────────────────────────── grouped-form widgets ───────────────────────────

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
const _chipGreenFg = Color(0xFF107A50);

// Rows below are each self-contained (own tinted background / underline) —
// no shared card container anymore. Two owner-rejected "ดูแปลกๆ" rounds
// both had a solid grouped-card wrapper; the wizard mockup the owner picked
// has none, so both the wizard and the flat edit-mode form now reuse these
// same standalone rows instead of a card.

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
    final iconBg = accent
        ? TeacherPalette.primary.withValues(alpha: 0.14)
        : const Color(0xFFEDECF5);
    final iconFg = accent ? TeacherPalette.primary : TeacherPalette.muted;
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

// ─────────────────────────── rubric picker ───────────────────────────

class _RubricPickerSheet extends StatelessWidget {
  const _RubricPickerSheet({
    required this.rubrics,
    required this.selectedId,
    required this.accent,
    required this.onCreate,
  });

  final List<RubricModel> rubrics;
  final String? selectedId;
  final Color accent;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCDBE4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 2),
          child: Text(
            'เกณฑ์การให้คะแนน',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: TeacherPalette.ink,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text(
            'ใช้ให้คะแนนใบงานนี้ — เปลี่ยนทีหลังได้',
            style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              _RubricOption(
                icon: Icons.block_rounded,
                title: 'ไม่ใช้เกณฑ์',
                subtitle: 'ให้คะแนนเป็นตัวเลขดิบ',
                selected: selectedId == null,
                accent: accent,
                onTap: () => Navigator.pop(context, ''),
              ),
              for (final r in rubrics)
                _RubricOption(
                  icon: Icons.rule_rounded,
                  title: r.title,
                  subtitle: '${r.criteriaCount} เกณฑ์',
                  selected: selectedId == r.id,
                  accent: accent,
                  onTap: () => Navigator.pop(context, r.id),
                ),
              // ที่ว่างเป็นบล็อกของตัวเอง ไม่ใช่แถวตัวเลือกที่กดไม่ได้
              if (rubrics.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.rule_folder_outlined,
                        size: 30,
                        color: Color(0xFFB0AEBD),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ยังไม่มีเกณฑ์การให้คะแนน',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'สร้างเกณฑ์ไว้หนึ่งชุด แล้วใช้ซ้ำกับใบงานอื่นได้ทั้งเทอม',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: SizedBox(
            height: 48,
            child: rubrics.isEmpty
                ? ElevatedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'สร้างเกณฑ์การให้คะแนน',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text(
                      'จัดการเกณฑ์ทั้งหมด',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: const BorderSide(color: Color(0xFFDDDCE4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

class _RubricOption extends StatelessWidget {
  const _RubricOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected
          ? accent.withValues(alpha: 0.08)
          : const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.16)
                      : const Color(0xFFEDECF5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? accent : TeacherPalette.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Icon(Icons.check_circle_rounded, size: 22, color: accent),
              ],
            ],
          ),
        ),
      ),
    ),
  );
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
