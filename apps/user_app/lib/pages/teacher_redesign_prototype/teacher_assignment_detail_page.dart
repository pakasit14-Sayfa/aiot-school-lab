import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../school_admin/school_timetable_page.dart' show SubjectColor;
import 'teacher_assignment_form_page.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_submission_review_page.dart';

/// One assignment, teacher's view (design agreed 2026-09-21): status +
/// deadline, submitted / pending / graded counts, the instructions, and the
/// whole class roster with who has submitted — tap a submitter to grade.
/// Every number is derived from list_course_students + list_submissions;
/// nothing here is a placeholder.
class TeacherAssignmentDetailPage extends StatefulWidget {
  const TeacherAssignmentDetailPage({
    super.key,
    required this.assignment,
    required this.courseId,
    required this.courseName,
    this.loadStudents,
    this.loadSubmissions,
    this.loadDetail,
    this.unpublish,
    this.publish,
    this.extendDue,
  });

  final AssignmentSummary assignment;
  final String courseId;
  final String courseName;

  // test seams — each defaults to the real service
  final Future<List<CourseStudent>> Function(String courseId)? loadStudents;
  final Future<List<SubmissionRoster>> Function(String assignmentId)?
  loadSubmissions;
  final Future<AssignmentDetail> Function(String assignmentId)? loadDetail;
  final Future<void> Function(String assignmentId)? unpublish;
  final Future<void> Function(String assignmentId)? publish;
  final Future<void> Function(String assignmentId, DateTime dueAt)? extendDue;

  @override
  State<TeacherAssignmentDetailPage> createState() =>
      _TeacherAssignmentDetailPageState();
}

class _TeacherAssignmentDetailPageState
    extends State<TeacherAssignmentDetailPage> {
  bool _loading = true;
  String? _error;
  List<CourseStudent> _students = const [];
  List<SubmissionRoster> _submissions = const [];
  AssignmentDetail? _detail;
  late AssignmentSummary _a = widget.assignment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students =
          await (widget.loadStudents ?? CourseService.listCourseStudents)(
            widget.courseId,
          );
      final subs =
          await (widget.loadSubmissions ?? AssignmentService.listSubmissions)(
            _a.id,
          );
      AssignmentDetail? detail;
      try {
        detail = await (widget.loadDetail ?? AssignmentService.getAssignment)(
          _a.id,
        );
      } catch (e) {
        debugPrint('assignment detail: get_assignment failed — $e');
      }
      if (!mounted) return;
      setState(() {
        _students = students;
        _submissions = subs;
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      debugPrint('assignment detail load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'โหลดข้อมูลใบงานไม่สำเร็จ กรุณาลองใหม่';
      });
    }
  }

  SubmissionRoster? _subOf(String studentId) =>
      _submissions.where((s) => s.studentId == studentId).firstOrNull;

  int get _submitted =>
      _students.where((s) => _subOf(s.studentId) != null).length;
  int get _pending => _submissions.where((s) => s.status == 'submitted').length;
  int get _graded => _submissions.where((s) => s.status != 'submitted').length;

  bool get _overdue => _a.dueAt != null && _a.dueAt!.isBefore(DateTime.now());

  Future<void> _menu() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.more_time_rounded),
              title: const Text('ขยายเวลาส่ง'),
              onTap: () => Navigator.of(context).pop('extend'),
            ),
            if (_a.isPublished)
              ListTile(
                leading: const Icon(Icons.lock_clock_outlined),
                title: const Text('ปิดรับงาน (กลับเป็นฉบับร่าง)'),
                subtitle: const Text(
                  'นักเรียนจะไม่เห็นใบงานนี้ งานที่ส่งแล้วยังอยู่',
                ),
                onTap: () => Navigator.of(context).pop('unpublish'),
              )
            else
              ListTile(
                leading: const Icon(Icons.publish_rounded),
                title: const Text('เผยแพร่ใบงาน'),
                onTap: () => Navigator.of(context).pop('publish'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || v == null) return;
    try {
      switch (v) {
        case 'extend':
          await _extend();
        case 'unpublish':
          await (widget.unpublish ?? AssignmentService.unpublishAssignment)(
            _a.id,
          );
          setState(() => _a = _a.copyWith(status: 'draft'));
          _snack('ปิดรับงานแล้ว');
        case 'publish':
          await (widget.publish ?? AssignmentService.publishAssignment)(_a.id);
          setState(() => _a = _a.copyWith(status: 'published'));
          _snack('เผยแพร่แล้ว');
      }
    } catch (e) {
      debugPrint('assignment detail action failed: $e');
      _snack('ทำรายการไม่สำเร็จ กรุณาลองใหม่', error: true);
    }
  }

  Future<void> _extend() async {
    final base = (_a.dueAt ?? DateTime.now()).toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(DateTime.now()) ? DateTime.now() : base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    final due = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await (widget.extendDue ??
        (id, d) => AssignmentService.updateAssignment(
          assignmentId: id,
          dueAt: d,
        ))(_a.id, due);
    setState(() => _a = _a.copyWith(dueAt: due.toUtc()));
    _snack('กำหนดส่งใหม่ ${_fmtDue(due)}');
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? const Color(0xFFB91C1C) : null,
      ),
    );
  }

  Future<void> _openEdit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherAssignmentFormPage(
          courseId: widget.courseId,
          courseName: widget.courseName,
          existing: _a,
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  void _openGrading() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherSubmissionRosterPage(
          assignmentId: _a.id,
          courseId: widget.courseId,
          worksheetTitle: _a.title,
          courseLabel: widget.courseName,
        ),
      ),
    ).then((_) => _load());
  }

  void _openSubmission(SubmissionRoster s) => _openGrading();

  @override
  Widget build(BuildContext context) {
    final color = SubjectColor.of(widget.courseName);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: color.bar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _a.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'ตัวเลือก',
            onPressed: _menu,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Pill(
                        label: _a.isPublished ? 'เผยแพร่' : 'ฉบับร่าง',
                        bg: _a.isPublished
                            ? const Color(0xFFE1F5EE)
                            : const Color(0xFFFAEEDA),
                        fg: _a.isPublished
                            ? const Color(0xFF085041)
                            : const Color(0xFF633806),
                      ),
                      if (_a.dueAt != null)
                        _Pill(
                          label: _overdue
                              ? 'เลยกำหนด ${_fmtDue(_a.dueAt!.toLocal())}'
                              : 'ส่ง ${_fmtDue(_a.dueAt!.toLocal())}',
                          bg: _overdue
                              ? const Color(0xFFFCEBEB)
                              : const Color(0xFFF1EFE8),
                          fg: _overdue
                              ? const Color(0xFF791F1F)
                              : const Color(0xFF444441),
                        ),
                      if (_a.isGroup)
                        const _Pill(
                          label: 'งานกลุ่ม',
                          bg: Color(0xFFEEEDFE),
                          fg: Color(0xFF3C3489),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '$_submitted',
                          label: 'ส่งแล้ว /${_students.length}',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _Stat(
                          value: '$_pending',
                          label: 'รอตรวจ',
                          bg: _pending > 0 ? const Color(0xFFFAEEDA) : null,
                          fg: _pending > 0 ? const Color(0xFF633806) : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _Stat(value: '$_graded', label: 'ตรวจแล้ว'),
                      ),
                    ],
                  ),
                  if ((_a.instructions ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _a.instructions!.trim(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: TeacherPalette.ink,
                      ),
                    ),
                  ],
                  if (_detail != null &&
                      _detail!.sensorDatasets.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final d in _detail!.sensorDatasets)
                          _Pill(
                            label: 'เซนเซอร์ · ${_metricThai(d.metric)}',
                            bg: const Color(0xFFE6F1FB),
                            fg: const Color(0xFF0C447C),
                            icon: Icons.sensors_rounded,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'นักเรียน ${_students.length} คน',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_students.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'ยังไม่มีนักเรียนในวิชานี้ — นักเรียนเข้าวิชาเมื่อแอดมินจัดตารางเรียน',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: TeacherPalette.muted),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: TeacherPalette.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _students.length; i++) ...[
                            _StudentRow(
                              student: _students[i],
                              submission: _subOf(_students[i].studentId),
                              onTap: _subOf(_students[i].studentId) == null
                                  ? null
                                  : () => _openSubmission(
                                      _subOf(_students[i].studentId)!,
                                    ),
                            ),
                            if (i < _students.length - 1)
                              const Divider(
                                height: 1,
                                indent: 44,
                                color: Color(0xFFF1F5F9),
                              ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _openGrading,
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            size: 18,
                          ),
                          label: const Text('ตรวจงาน'),
                          style: FilledButton.styleFrom(
                            backgroundColor: TeacherPalette.primary,
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('แก้ไข'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

String _fmtDue(DateTime d) {
  const m = [
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
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.day} ${m[d.month - 1]} ${two(d.hour)}:${two(d.minute)}';
}

String _metricThai(String metric) {
  switch (metric) {
    case 'temperature':
      return 'อุณหภูมิ';
    case 'humidity':
      return 'ความชื้น';
    case 'pm25':
      return 'PM2.5';
    case 'light_lux':
      return 'แสง';
    case 'aqi':
      return 'AQI';
    case 'energy_kwh':
      return 'พลังงาน';
    case 'power_w':
      return 'กำลังไฟ';
    default:
      return metric;
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.bg, this.fg});
  final String value;
  final String label;
  final Color? bg;
  final Color? fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: bg ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: bg == null ? TeacherPalette.border : Colors.transparent,
      ),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: fg ?? TeacherPalette.ink,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: fg?.withValues(alpha: 0.85) ?? TeacherPalette.muted,
          ),
        ),
      ],
    ),
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.submission,
    this.onTap,
  });
  final CourseStudent student;
  final SubmissionRoster? submission;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = submission;
    final (dot, text, color) = s == null
        ? (const Color(0xFFB4B2A9), 'ยังไม่ส่ง', TeacherPalette.muted)
        : s.status == 'submitted'
        ? (const Color(0xFFEF9F27), 'รอตรวจ', const Color(0xFF854F0B))
        : (const Color(0xFF1D9E75), 'ตรวจแล้ว', const Color(0xFF0F6E56));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${student.firstName} ${student.lastName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TeacherPalette.ink,
                ),
              ),
            ),
            Text(text, style: TextStyle(fontSize: 12, color: color)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: TeacherPalette.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
