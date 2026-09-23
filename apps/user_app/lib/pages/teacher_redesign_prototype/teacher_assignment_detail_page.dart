import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../school_admin/school_timetable_page.dart' show SubjectColor;
import 'teacher_airy_kit.dart';
import 'teacher_assignment_form_page.dart';
import 'teacher_date_time_sheet.dart' show showTeacherDateTimeSheet;
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
    this.deleteAssignment,
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

  /// ลบใบงานถาวร (2026-09-23) — ระบบนี้ลบใบงานไม่ได้เลยมาตลอด สร้างผิดแล้ว
  /// ค้างถาวร ใบที่มีนักเรียนส่งงานแล้วหลังบ้านจะปฏิเสธ
  final Future<void> Function(String assignmentId)? deleteAssignment;

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
            const Divider(height: 1),
            // ลบอยู่ล่างสุดคั่นด้วยเส้น เพราะเป็นอย่างเดียวในเมนูที่ย้อนกลับ
            // ไม่ได้ — ที่เหลือสลับไปมาได้หมด
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: _submitted > 0
                    ? TeacherPalette.muted
                    : const Color(0xFFB91C1C),
              ),
              title: Text(
                'ลบใบงาน',
                style: TextStyle(
                  color: _submitted > 0
                      ? TeacherPalette.muted
                      : const Color(0xFFB91C1C),
                ),
              ),
              subtitle: _submitted > 0
                  ? Text('มีนักเรียนส่งแล้ว $_submitted คน — ใช้ปิดรับงานแทน')
                  : null,
              enabled: _submitted == 0,
              onTap: () => Navigator.of(context).pop('delete'),
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
        case 'delete':
          await _delete();
      }
    } catch (e) {
      debugPrint('assignment detail action failed: $e');
      _snack('ทำรายการไม่สำเร็จ กรุณาลองใหม่', error: true);
    }
  }

  Future<void> _delete() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('ลบใบงานนี้?'),
        content: Text(
          '"${_a.title}" จะถูกลบถาวร พร้อมกับการผูกไฟล์แนบของใบงานนี้\n'
          'ไฟล์ยังอยู่ในคลังความรู้ของวิชา',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ลบใบงาน',
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    try {
      await (widget.deleteAssignment ?? AssignmentService.deleteAssignment)(
        _a.id,
      );
      if (!mounted) return;
      // หน้ารายการรีเฟรชตัวเองหลังหน้านี้ปิด (_openDetail → _loadRealAssignments)
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ลบใบงานไม่สำเร็จ — $e');
      if (!mounted) return;
      // ปุ่มถูกปิดไว้แล้วเมื่อมีคนส่ง แต่จำนวนอาจเปลี่ยนระหว่างเปิดหน้าค้างไว้
      // หลังบ้านจึงเป็นด่านจริง และต้องแปลงข้อความให้บอกทางออก
      final m = RegExp(r'assignment_has_(\d+)').firstMatch('$e');
      _snack(
        m != null
            ? 'ลบไม่ได้ — มีนักเรียนส่งแล้ว ${m.group(1)} คน ใช้ปิดรับงานแทน'
            : 'ลบใบงานไม่สำเร็จ กรุณาลองใหม่',
        error: true,
      );
    }
  }

  Future<void> _extend() async {
    final base = (_a.dueAt ?? DateTime.now()).toLocal();
    final due = await showTeacherDateTimeSheet(
      context: context,
      initial: base.isBefore(DateTime.now()) ? DateTime.now() : base,
      accent: SubjectColor.of(widget.courseName).fg,
      title: 'ขยายเวลาส่ง',
      first: DateTime.now().subtract(const Duration(days: 1)),
      last: DateTime.now().add(const Duration(days: 365)),
    );
    if (due == null || !mounted) return;
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

  /// รายชื่อจัดกลุ่มตามสิ่งที่ครูต้องทำต่อ ไม่ใช่ตามลำดับในห้อง —
  /// รอตรวจก่อน แล้วตรวจแล้ว แล้วยังไม่ส่ง
  List<(CourseStudent, SubmissionRoster?)> _bucket(String kind) {
    final out = <(CourseStudent, SubmissionRoster?)>[];
    for (final st in _students) {
      final sub = _subOf(st.studentId);
      final k = sub == null
          ? 'none'
          : (sub.status == 'submitted' ? 'pending' : 'graded');
      if (k == kind) out.add((st, sub));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final color = SubjectColor.of(widget.courseName);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.courseName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'ตัวเลือก',
            onPressed: _loading ? null : _menu,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : AiryContentWidth(shrinkHeight: true, child: _actionBar(color)),
      body: AiryContentWidth(
        child: _loading
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
                  padding: EdgeInsets.zero,
                  children: [
                    _header(color),
                    Transform.translate(
                      offset: const Offset(0, -26),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _progressCard(),
                            if ((_a.instructions ?? '').trim().isNotEmpty ||
                                (_detail?.sensorDatasets.isNotEmpty ??
                                    false)) ...[
                              const AirySection('โจทย์'),
                              _briefCard(color),
                            ],
                            ..._rosterSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// หัวสีประจำวิชา ชุดเดียวกับหน้าแก้ไขใบงาน — ชื่อใบงานเต็ม ๆ อยู่ตรงนี้
  /// แทนที่จะโดนตัดใน AppBar บรรทัดเดียวแบบเดิม
  Widget _header(SubjectColor color) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.paddingOf(context).top + kToolbarHeight,
      20,
      46,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.fg, Color.lerp(color.fg, color.bar, 0.45)!],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _a.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeadChip(
              text: _a.isPublished ? 'เผยแพร่แล้ว' : 'ฉบับร่าง',
              solid: _a.isPublished,
              solidFg: color.fg,
            ),
            if (_a.dueAt != null)
              _HeadChip(
                icon: _overdue
                    ? Icons.error_outline_rounded
                    : Icons.event_rounded,
                text: _overdue
                    ? 'เลยกำหนด ${_fmtDue(_a.dueAt!.toLocal())}'
                    : 'ส่ง ${_fmtDue(_a.dueAt!.toLocal())}',
                solid: _overdue,
                solidFg: const Color(0xFFB3261E),
              ),
            _HeadChip(
              icon: _a.isGroup ? Icons.groups_rounded : Icons.person_rounded,
              text: _a.isGroup ? 'งานกลุ่ม' : 'งานเดี่ยว',
            ),
          ],
        ),
      ],
    ),
  );

  /// เดิมเป็นกล่องเลขสามใบขนาดเท่ากัน ซึ่งตอนยังไม่มีใครส่งคือเลข 0 เรียงกัน
  /// สามตัว อ่านแล้วไม่ได้ความอะไร — รวมเป็นประโยคเดียวพร้อมแถบสัดส่วน
  Widget _progressCard() {
    final total = _students.length;
    final submitted = _submitted;
    final note = total == 0
        ? 'ยังไม่มีนักเรียนในวิชานี้'
        : submitted == 0
        ? (_overdue ? 'ยังไม่มีใครส่ง — เลยกำหนดแล้ว' : 'ยังไม่มีใครส่ง')
        : _pending > 0
        ? 'มี $_pending ชิ้นรอตรวจ'
              '${total - submitted > 0 ? ' · ยังไม่ส่งอีก ${total - submitted} คน' : ''}'
        : (total - submitted > 0
              ? 'ตรวจครบทุกชิ้นที่ส่งมาแล้ว · ยังไม่ส่งอีก ${total - submitted} คน'
              : 'ตรวจครบทุกคนแล้ว');
    return AiryCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$submitted',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: TeacherPalette.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/ $total คนส่งแล้ว',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 13,
                  color: TeacherPalette.muted,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    // ColoredBox ที่ไม่มีลูกจะสูง 0 ถ้า Row จัดกึ่งกลางตามค่าเริ่มต้น
                    // — แถบเลยหายไปทั้งแถบ ต้อง stretch ให้เต็มความสูง 10
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_graded > 0)
                        Expanded(
                          flex: _graded,
                          child: const ColoredBox(color: Color(0xFF107A50)),
                        ),
                      if (_pending > 0)
                        Expanded(
                          flex: _pending,
                          child: const ColoredBox(color: Color(0xFFEF9F27)),
                        ),
                      if (total - submitted > 0)
                        Expanded(
                          flex: total - submitted,
                          child: const ColoredBox(color: Color(0xFFEDECF5)),
                        ),
                      if (total == 0)
                        const Expanded(
                          child: ColoredBox(color: Color(0xFFEDECF5)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Legend(
                    color: const Color(0xFFEF9F27),
                    label: 'รอตรวจ',
                    value: _pending,
                  ),
                  _Legend(
                    color: const Color(0xFF107A50),
                    label: 'ตรวจแล้ว',
                    value: _graded,
                  ),
                  _Legend(
                    color: const Color(0xFFDEDCE6),
                    label: 'ยังไม่ส่ง',
                    value: total - submitted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _briefCard(SubjectColor color) {
    final brief = (_a.instructions ?? '').trim();
    final datasets =
        _detail?.sensorDatasets ?? const <AssignmentSensorDataset>[];
    return AiryCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (brief.isNotEmpty)
                Text(
                  brief,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: Color(0xFF4B4558),
                  ),
                ),
              for (var i = 0; i < datasets.length; i++) ...[
                Padding(
                  padding: EdgeInsets.only(
                    top: brief.isEmpty && i == 0 ? 0 : 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights_outlined,
                        size: 19,
                        color: AirySpec.label,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ชุดข้อมูลเซนเซอร์',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AirySpec.label,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _metricThai(datasets[i].metric),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AirySpec.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _rosterSection() {
    if (_students.isEmpty) {
      return const [
        AirySection('นักเรียน'),
        AiryCard(
          children: [
            AiryNote(
              'ยังไม่มีนักเรียนในวิชานี้ — นักเรียนเข้าวิชาเมื่อแอดมินจัดตารางเรียน',
            ),
          ],
        ),
      ];
    }
    final out = <Widget>[];
    for (final (kind, label) in const [
      ('pending', 'รอตรวจ'),
      ('graded', 'ตรวจแล้ว'),
      ('none', 'ยังไม่ส่ง'),
    ]) {
      final rows = _bucket(kind);
      if (rows.isEmpty) continue;
      out.add(AirySection(label, count: rows.length));
      out.add(
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Color(0xFFEDECF5)),
                _StudentRow(
                  student: rows[i].$1,
                  submission: rows[i].$2,
                  onTap: rows[i].$2 == null
                      ? null
                      : () => _openSubmission(rows[i].$2!),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (_submitted == 0) {
      out.add(
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: AiryCard(
            children: [
              AiryNote(
                'ยังไม่มีงานส่งเข้ามา — ขยายเวลาส่งได้จากเมนู ⋯ มุมขวาบน',
              ),
            ],
          ),
        ),
      );
    }
    return out;
  }

  /// ปุ่มอยู่ติดจอ ไม่ต้องเลื่อนผ่านรายชื่อทั้งห้องไปหา และปุ่มตรวจงานบอก
  /// จำนวนที่รอตรวจ ถ้าไม่มีอะไรให้ตรวจก็ปิดปุ่มพร้อมบอกเหตุผลแทนที่จะพาไป
  /// เจอหน้าว่าง
  Widget _actionBar(SubjectColor color) {
    final nothingToGrade = _submitted == 0;
    return Container(
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              // สัดส่วน 7:3 แทนความกว้างตายตัว 108 — ที่จอ 360 ปุ่มคงที่ทำให้
              // ปุ่มหลักที่มีทั้งไอคอน ข้อความ และตัวเลข ล้นขอบไป 40pt
              Expanded(
                flex: 7,
                child: AiryButton(
                  label: nothingToGrade
                      ? 'ยังไม่มีงานให้ตรวจ'
                      : (_pending > 0 ? 'ตรวจงาน' : 'ดูงานที่ตรวจแล้ว'),
                  kind: AiryCta.primary,
                  accent: color.fg,
                  onPressed: nothingToGrade ? null : _openGrading,
                  child: nothingToGrade
                      ? null
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.rate_review_outlined, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _pending > 0 ? 'ตรวจงาน' : 'ดูงานที่ตรวจแล้ว',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_pending > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$_pending',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: AiryButton(
                  label: 'แก้ไข',
                  kind: AiryCta.tertiary,
                  onPressed: _openEdit,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 17),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'แก้ไข',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
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

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TeacherPalette.muted,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        '$value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: TeacherPalette.ink,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

class _HeadChip extends StatelessWidget {
  const _HeadChip({
    required this.text,
    this.icon,
    this.solid = false,
    this.solidFg,
  });
  final String text;
  final IconData? icon;
  final bool solid;
  final Color? solidFg;
  @override
  Widget build(BuildContext context) {
    final fg = solid ? (solidFg ?? TeacherPalette.ink) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? Colors.white : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
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
    // สามสถานะ สามสี — ตัวอักษรย่อในวงกลมรับสีเดียวกับป้ายสถานะ จึงกวาดตา
    // เห็นได้ว่าแถวไหนต้องทำอะไรโดยไม่ต้องอ่านป้าย
    final (bg, fg, label) = s == null
        ? (const Color(0xFFF2F1F6), TeacherPalette.muted, 'ยังไม่ส่ง')
        : s.status == 'submitted'
        ? (const Color(0xFFFDF1DE), const Color(0xFFB4650F), 'รอตรวจ')
        : (const Color(0xFFE1F6EC), const Color(0xFF107A50), 'ตรวจแล้ว');
    final name = '${student.firstName} ${student.lastName}'.trim();
    final initial = name.isEmpty ? '?' : name.characters.first;
    final sentAt = s?.submittedAt?.toLocal();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'ไม่ทราบชื่อ' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  // เวลาที่ส่งมาจาก submitted_at จริง — ไม่มีก็ไม่ต้องเดา
                  if (sentAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'ส่ง ${_fmtDue(sentAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Color(0xFFC7C7CC),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
