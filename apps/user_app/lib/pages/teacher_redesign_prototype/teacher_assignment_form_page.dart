import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../school_admin/school_timetable_page.dart' show SubjectColor;
import 'teacher_airy_kit.dart';
import 'teacher_date_time_sheet.dart' show showTeacherDateTimeSheet;
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

  /// ข้อความผิดพลาดใต้ช่อง "ชื่อใบงาน" — เดิมบอกด้วย snackbar ที่เด้งขึ้นมา
  /// แล้วหายไป โดยไม่ชี้ว่าช่องไหนผิด
  String? _titleError;

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
    _title.addListener(() {
      if (_titleError != null && _title.text.trim().isNotEmpty) {
        setState(() => _titleError = null);
      }
    });
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

  /// ชีตเดียวได้ทั้งวันและเวลา แทน showDatePicker + showTimePicker ของ
  /// Material ที่เป็นกล่อง Android สองกล่องต่อกัน
  Future<DateTime?> _pickDateTime(
    DateTime initial, {
    String title = 'เลือกวันและเวลา',
  }) => showTeacherDateTimeSheet(
    context: context,
    initial: initial,
    accent: SubjectColor.of(widget.courseName).fg,
    title: title,
    first: DateTime(2024),
    last: DateTime(2035, 12, 31),
  );

  Future<void> _pickDue() async {
    final picked = await _pickDateTime(
      _dueAt ??
          DateTime.now()
              .add(const Duration(days: 7))
              .copyWith(hour: 23, minute: 59),
      title: 'กำหนดส่งงาน',
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
      setState(() => _titleError = 'ยังไม่ได้ตั้งชื่อใบงาน');
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
    final leave = await showAiryConfirm(
      context: context,
      title: 'ทิ้งการแก้ไข?',
      message: 'สิ่งที่แก้ไว้จะไม่ถูกบันทึก',
      confirmLabel: 'ทิ้งการแก้ไข',
      cancelLabel: 'แก้ต่อ',
    );
    if (leave == true && mounted) Navigator.pop(context, false);
  }

  Future<void> _unlink(AssignmentSensorDataset d) async {
    final ok = await showAiryConfirm(
      context: context,
      title: 'เอาชุดข้อมูลออก?',
      message:
          '${kMetricThai[d.metric] ?? d.metric} · '
          '${_devices[d.deviceId]?.name ?? 'อุปกรณ์'}\n'
          'นักเรียนจะไม่เห็นกราฟชุดนี้ในใบงานอีก',
      confirmLabel: 'เอาออก',
      cancelLabel: 'ยกเลิก',
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
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _LinkDatasetSheet(
        devices: sensors,
        accent: SubjectColor.of(widget.courseName).fg,
      ),
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
        backgroundColor: const Color(0xFFF7F7FA),
        extendBodyBehindAppBar: true,
        // จำกัดความกว้างทั้งเนื้อหาและแถบล่าง ไม่งั้นบนจอคอมแถวป้าย-ค่า
        // จะยืดเกิน 1,900px จนอ่านเป็นคู่กันไม่ได้
        bottomNavigationBar: AiryContentWidth(
          shrinkHeight: true,
          child: _saveBar(color),
        ),
        appBar: _editAppBar(),
        body: AiryContentWidth(child: _editBody(color, rubricTitle)),
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
            color: Color(0xFFF7F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
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

  /// เนื้อฟอร์มสไตล์ "โปร่ง-ขาว" (2026-09-22 ตามภาพอ้างอิงที่เจ้าของเลือก):
  /// การ์ดขาวเงานุ่ม แถวในการ์ดคั่นด้วยเส้นบาง ป้ายเล็กสีเทาคู่กับค่าตัวหนา
  /// ไอคอนเส้นบางสีเดียว ไม่มีชิปสีและไม่มีพื้นเทารายแถวอีก
  /// หัวสีประจำวิชาด้านบนคงไว้ตามที่เจ้าของสั่ง
  List<Widget> _bodyRows(String rubricTitle) {
    final accent = SubjectColor.of(widget.courseName).fg;
    return [
      const AirySection('ข้อมูล'),
      AiryInput(
        label: 'ชื่อใบงาน',
        controller: _title,
        hint: 'เช่น ใบงานทบทวนบทที่ 1',
        accent: accent,
        big: true,
        errorText: _titleError,
      ),
      AiryInput(
        label: 'คำอธิบาย',
        controller: _instructions,
        hint: 'อธิบายว่าต้องทำอะไร ส่งอย่างไร',
        accent: accent,
        minLines: 2,
        maxLines: 8,
      ),
      const AirySection('การส่งงาน'),
      AiryCard(
        children: [
          AiryRow(
            icon: Icons.event_outlined,
            label: 'กำหนดส่ง',
            value: _dueAt == null ? 'ยังไม่กำหนด' : fmtThaiDateTime(_dueAt!),
            muted: _dueAt == null,
            onTap: _saving ? null : _pickDue,
          ),
          AirySwitchRow(
            icon: Icons.groups_outlined,
            label: 'งานกลุ่ม',
            value: _isGroup ? 'ส่ง 1 ชิ้นต่อกลุ่ม' : 'นักเรียนส่งงานรายคน',
            on: _isGroup,
            accent: accent,
            onChanged: _saving ? null : _toggleGroup,
          ),
          AiryRow(
            icon: Icons.rule_outlined,
            label: 'เกณฑ์การให้คะแนน',
            value: rubricTitle,
            muted: rubricTitle == 'ไม่ใช้',
            onTap: _saving || _rubricsLoading ? null : _pickRubric,
          ),
        ],
      ),
      const AirySection('ชุดข้อมูลเซนเซอร์'),
      if (!_isEdit)
        const AiryCard(
          children: [
            AiryNote('บันทึกใบงานก่อน แล้วค่อยเพิ่มชุดข้อมูลได้จากหน้าแก้ไข'),
          ],
        )
      else
        AiryCard(
          children: [
            if (_datasetsLoading)
              const AiryNote('กำลังโหลด…')
            else if (_datasets.isEmpty)
              const AiryNote('ยังไม่มีชุดข้อมูล'),
            for (final d in _datasets)
              AiryDatasetRow(
                dataset: d,
                deviceName: _devices[d.deviceId]?.name ?? 'อุปกรณ์',
                onRemove: _saving ? null : () => _unlink(d),
              ),
            AiryRow(
              icon: Icons.add_circle_outline_rounded,
              label: 'เพิ่มชุดข้อมูล',
              value: 'เลือกอุปกรณ์และค่าที่จะให้นักเรียนเห็น',
              muted: true,
              accent: accent,
              onTap: _saving ? null : _addDataset,
            ),
          ],
        ),
    ];
  }

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
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _published ? _chipGreenFg : TeacherPalette.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: AiryButton(
                label: _published ? 'บันทึก' : 'มอบหมายให้นักเรียน',
                kind: AiryCta.primary,
                accent: subject.fg,
                onPressed: _saving ? null : (_published ? _save : _assignNow),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────── body widgets (3 แบบ) ───────────────────────────

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
              fontSize: 12,
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
                    fontSize: 12,
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
                  fontSize: 22,
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

/// เขียวสถานะ 'เผยแพร่แล้ว' — สีเดียวที่เหลือจากชุดชิปพาสเทลเดิม
const _chipGreenFg = Color(0xFF107A50);

// วิดเจ็ตชุด "grouped-form" เดิม (_NavRow / _InfoRow / _DatasetRow) ถูกแทนที่
// ด้วยชุด _Airy* ข้างล่างทั้งหมดเมื่อ 2026-09-22

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
              fontSize: 17,
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
                          fontSize: 12,
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
                        fontSize: 15,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
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
  const _LinkDatasetSheet({required this.devices, required this.accent});
  final List<DeviceOption> devices;
  final Color accent;
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

  Future<DateTime?> _pick(DateTime initial) => showTeacherDateTimeSheet(
    context: context,
    initial: initial,
    accent: widget.accent,
    title: 'ช่วงเวลาของข้อมูล',
    first: DateTime(2024),
    last: DateTime(2035, 12, 31),
  );

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsOf(_device);
    final hasRange = _start != null || _end != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E3EA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 4),
              child: Text(
                'เพิ่มชุดข้อมูลเซนเซอร์',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AirySpec.ink,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: Text(
                'นักเรียนจะเห็นกราฟของค่าที่เลือกอยู่ในใบงานนี้',
                style: TextStyle(fontSize: 13, color: AirySpec.label),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AiryCard(
                    children: [
                      AiryRow(
                        icon: Icons.sensors_outlined,
                        label: 'อุปกรณ์',
                        value: _device.name,
                        trailingNote: _device.location,
                        onTap: _pickDevice,
                      ),
                      AiryRow(
                        icon: Icons.show_chart_rounded,
                        label: 'ค่าที่วัด',
                        value: kMetricThai[_metric] ?? _metric,
                        onTap: metrics.length < 2 ? null : _pickMetric,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AiryInput(
                    label: 'ชื่อชุดข้อมูล',
                    optional: true,
                    controller: _label,
                    hint: 'เช่น ค่าฝุ่นช่วงคาบเรียน',
                    accent: widget.accent,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 22, 4, 10),
                    child: Text(
                      'ช่วงเวลาของข้อมูล',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AirySpec.ink,
                      ),
                    ),
                  ),
                  AiryCard(
                    children: [
                      AiryRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'เริ่ม',
                        value: _start == null
                            ? 'ข้อมูลล่าสุด'
                            : fmtThaiDateTime(_start!),
                        muted: _start == null,
                        onTap: () async {
                          final v = await _pick(
                            _start ??
                                DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                          );
                          if (v != null) setState(() => _start = v);
                        },
                      ),
                      AiryRow(
                        icon: Icons.stop_circle_outlined,
                        label: 'สิ้นสุด',
                        value: _end == null
                            ? 'ต่อเนื่องถึงตอนนี้'
                            : fmtThaiDateTime(_end!),
                        muted: _end == null,
                        onTap: () async {
                          final v = await _pick(_end ?? DateTime.now());
                          if (v != null) setState(() => _end = v);
                        },
                      ),
                    ],
                  ),
                  if (hasRange)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _start = null;
                          _end = null;
                        }),
                        style: TextButton.styleFrom(
                          foregroundColor: widget.accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'ล้างช่วงเวลา',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  AiryButton(
                    label: 'เพิ่มชุดข้อมูล',
                    kind: AiryCta.primary,
                    accent: widget.accent,
                    onPressed: () => Navigator.pop(
                      context,
                      _LinkRequest(
                        deviceId: _device.id,
                        metric: _metric,
                        start: _start,
                        end: _end,
                        label: _label.text.trim().isEmpty
                            ? null
                            : _label.text.trim(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AiryButton(
                    label: 'ยกเลิก',
                    kind: AiryCta.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDevice() async {
    final picked = await showModalBottomSheet<DeviceOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _OptionSheet(
        title: 'เลือกอุปกรณ์',
        accent: widget.accent,
        options: [
          for (final d in widget.devices)
            _Option(
              key: d.id,
              title: d.name,
              subtitle: d.location,
              selected: d.id == _device.id,
              value: d,
            ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() {
      _device = picked;
      _metric = _metricsOf(picked).first;
    });
  }

  Future<void> _pickMetric() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _OptionSheet(
        title: 'เลือกค่าที่วัด',
        accent: widget.accent,
        options: [
          for (final m in _metricsOf(_device))
            _Option(
              key: m,
              title: kMetricThai[m] ?? m,
              subtitle: null,
              selected: m == _metric,
              value: m,
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _metric = picked);
  }
}

class _Option<T> {
  const _Option({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.value,
  });
  final String key;
  final String title;
  final String? subtitle;
  final bool selected;
  final T value;
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.accent,
  });
  final String title;
  final List<_Option<T>> options;
  final Color accent;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFDCDBE4),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: TeacherPalette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: o.selected
                        ? Color.alphaBlend(
                            accent.withValues(alpha: 0.06),
                            Colors.white,
                          )
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context, o.value),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: o.selected
                                ? accent
                                : const Color(0xFFEDECF2),
                            width: o.selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: o.selected
                                          ? accent
                                          : TeacherPalette.ink,
                                    ),
                                  ),
                                  if (o.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      o.subtitle!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: TeacherPalette.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (o.selected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 22,
                                color: accent,
                              ),
                          ],
                        ),
                      ),
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
