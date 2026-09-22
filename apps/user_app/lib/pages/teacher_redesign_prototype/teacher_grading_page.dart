// ตรวจงาน — รายการใบงานทุกวิชาของครู เรียงตามความเร่งด่วน (ออกแบบใหม่
// 2026-09-21 ตามที่เจ้าของเลือก): ชิปกรอง รอตรวจ / เลยกำหนด / ทั้งหมด,
// หมวด "เลยกำหนดส่ง" ก่อน "กำลังเปิดรับ" ก่อน "ฉบับร่าง", แถวกะทัดรัดมี
// ไอคอนวิชาสีตามวิชา, แตะแถวเข้าหน้ารายละเอียดใบงาน
//
// ตัวเลข ส่ง x/y และ รอตรวจ มาจาก list_assignments (20260921010000) —
// เวอร์ชันก่อนนับจาก list_submissions ซึ่งมีแต่คนที่ส่งแล้ว จึงได้
// "ส่งแล้ว 0/0 คน" ตลอด (บั๊กที่เจ้าของเห็นบน iPhone)
//
// การสร้างใบงานย้ายไปอยู่ในหน้าวิชา (แท็บใบงาน) — หน้านี้ไม่มีปุ่มสร้างแล้ว
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../school_admin/school_timetable_page.dart' show SubjectColor;
import 'teacher_assignment_detail_page.dart';
import 'teacher_airy_kit.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

class TeacherGradingPage extends StatefulWidget {
  const TeacherGradingPage({
    super.key,
    this.listMyCourses,
    this.listAssignments,
    this.publishAssignment,
  });

  final Future<List<CourseSummary>> Function()? listMyCourses;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  listAssignments;
  final Future<void> Function(String assignmentId)? publishAssignment;

  @override
  State<TeacherGradingPage> createState() => _TeacherGradingPageState();
}

class _Row {
  const _Row({required this.course, required this.a});
  final CourseSummary course;
  final AssignmentSummary a;

  bool get overdue => a.dueAt != null && a.dueAt!.isBefore(DateTime.now());
  String get roomLabel => course.room ?? course.gradeLevel ?? '';
}

enum _Filter { pending, overdue, all }

class _TeacherGradingPageState extends State<TeacherGradingPage> {
  List<_Row> _rows = const [];
  bool _loading = true;
  String? _error;
  _Filter _filter = _Filter.all;
  String? _courseFilter; // course id, null = all

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
      // หน้านี้ถูกเขียนใหม่ทั้งหน้าใน main (3d6a39e) โครงเดิมที่เลนนี้เคย
      // ไล่แก้ perf ไว้หายไปแล้ว — เอาโครงใหม่ของ main มาใช้ แต่คงสิ่งที่
      // e44ce7b แก้ไว้: ห้าม await ทีละแถวในลูป (1+N รอบไป-กลับก่อนจอแรก)
      // คอร์สแต่ละตัวไม่ขึ้นกับตัวอื่น จึงยิงพร้อมกันครั้งเดียว
      final courses =
          await (widget.listMyCourses ?? CourseService.listMyCourses)();
      final list = widget.listAssignments ?? AssignmentService.listAssignments;
      final perCourse = await Future.wait(courses.map((c) => list(c.id)));
      final rows = <_Row>[
        for (var i = 0; i < courses.length; i++)
          for (final a in perCourse[i]) _Row(course: courses[i], a: a),
      ];
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        if (_filter == _Filter.all &&
            rows.any((r) => r.a.pendingGradeCount > 0)) {
          _filter = _Filter.pending;
        }
      });
    } catch (e) {
      debugPrint('TeacherGradingPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'โหลดใบงานไม่สำเร็จ';
      });
    }
  }

  List<_Row> get _visible {
    Iterable<_Row> r = _rows;
    if (_courseFilter != null) r = r.where((x) => x.course.id == _courseFilter);
    switch (_filter) {
      case _Filter.pending:
        r = r.where((x) => x.a.pendingGradeCount > 0);
      case _Filter.overdue:
        r = r.where((x) => x.a.isPublished && x.overdue);
      case _Filter.all:
        break;
    }
    return r.toList();
  }

  int get _pendingTotal => _rows.fold(0, (n, r) => n + r.a.pendingGradeCount);
  int get _overdueTotal =>
      _rows.where((r) => r.a.isPublished && r.overdue).length;

  Future<void> _publish(_Row r) async {
    try {
      await (widget.publishAssignment ?? AssignmentService.publishAssignment)(
        r.a.id,
      );
      await _load();
      final now = _rows.where((x) => x.a.id == r.a.id).firstOrNull;
      if (!mounted) return;
      if (now != null && now.a.isPublished) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เผยแพร่ "${r.a.title}" แล้ว')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เผยแพร่ไม่สำเร็จ ใบงานยังเป็นฉบับร่าง'),
          ),
        );
      }
    } catch (e) {
      debugPrint('publish failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เผยแพร่ไม่สำเร็จ ใบงานยังเป็นฉบับร่าง')),
      );
    }
  }

  Future<void> _open(_Row r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherAssignmentDetailPage(
          assignment: r.a,
          courseId: r.course.id,
          courseName: r.course.subjectName,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _pickCourse() async {
    final courses = {
      for (final r in _rows) r.course.id: r.course,
    }.values.toList();
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'กรองตามวิชา',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              title: const Text('ทุกวิชา'),
              trailing: _courseFilter == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop('__all__'),
            ),
            for (final c in courses)
              ListTile(
                leading: _SubjectBadge(name: c.subjectName),
                title: Text(c.subjectName),
                subtitle: Text(c.room ?? c.gradeLevel ?? ''),
                trailing: _courseFilter == c.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _courseFilter = picked == '__all__' ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ตรวจงาน',
      activeMenuLabel: 'ตรวจงาน',
      // ไอคอนกรองเคยลอยเดี่ยว ๆ กลางหน้าเหนือแถวชิป ไม่มีใครรู้ว่ามันคืออะไร
      // ย้ายลงไปเป็นชิป "ทุกวิชา / <ชื่อวิชา>" ในแถวเดียวกับชิปอื่น
      actions: const [],
      builder: (context, isDesktop) {
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          );
        }
        if (_error != null) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: TeacherPalette.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('ลองใหม่')),
              ],
            ),
          );
        }
        final rows = _visible;
        final overdue = rows
            .where((r) => r.a.isPublished && r.overdue)
            .toList();
        final open = rows.where((r) => r.a.isPublished && !r.overdue).toList();
        final drafts = rows.where((r) => !r.a.isPublished).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวกรองเดิมเป็น Wrap ของชิป 4 อัน ซึ่งพอมีชิปวิชาเพิ่มเข้ามา
            // มันตกไปบรรทัดที่สองเดี่ยว ๆ ดูไม่เป็นแถว — สามตัวแรกเป็นตัวเลือก
            // ที่เลือกได้ทีละอันอยู่แล้ว จึงยุบเป็น segmented control หนึ่งก้อน
            // เต็มความกว้าง ส่วนตัวกรองวิชาเป็นปุ่มเล็กท้ายแถวเดียวกัน
            Row(
              children: [
                Expanded(
                  child: _SegmentedFilter(
                    segments: [
                      (_Filter.pending, 'รอตรวจ', _pendingTotal),
                      (_Filter.overdue, 'เลยกำหนด', _overdueTotal),
                      (_Filter.all, 'ทั้งหมด', _rows.length),
                    ],
                    value: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ),
                if (_rows.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _CourseFilterButton(
                    label: _courseFilter == null
                        ? null
                        : (_rows
                                  .where((r) => r.course.id == _courseFilter)
                                  .map((r) => r.course.subjectName)
                                  .firstOrNull ??
                              'วิชาที่เลือก'),
                    onTap: _pickCourse,
                    onClear: () => setState(() => _courseFilter = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (_rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'ยังไม่มีใบงานในวิชาที่คุณสอน — สร้างได้จากหน้าวิชา แท็บ "ใบงาน"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TeacherPalette.muted),
                  ),
                ),
              )
            else if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    _filter == _Filter.pending
                        ? 'ไม่มีงานรอตรวจ 🎉'
                        : 'ไม่มีใบงานในหมวดนี้',
                    style: const TextStyle(color: TeacherPalette.muted),
                  ),
                ),
              )
            else ...[
              if (overdue.isNotEmpty)
                _Section(
                  title: 'เลยกำหนดส่ง',
                  color: const Color(0xFFD3324A),
                  rows: overdue,
                  onTap: _open,
                ),
              if (open.isNotEmpty)
                _Section(
                  title: 'กำลังเปิดรับ',
                  color: AirySpec.ink,
                  rows: open,
                  onTap: _open,
                ),
              if (drafts.isNotEmpty)
                _Section(
                  title: 'ฉบับร่าง',
                  color: AirySpec.ink,
                  rows: drafts,
                  onTap: _open,
                  trailing: (r) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    // ต้องกำหนดความกว้างด้วย: ลูกของ Row ที่ไม่ใช่ Expanded
                    // ได้ constraint กว้างแบบไม่จำกัด แล้ว ElevatedButton จะ
                    // โยน 'BoxConstraints forces an infinite width' ทั้งเฟรม
                    // (กับดักเดียวกับที่เคยเจอในปุ่มบน AppBar)
                    child: SizedBox(
                      width: 96,
                      height: 34,
                      child: AiryButton(
                        label: 'เผยแพร่',
                        kind: AiryCta.secondary,
                        height: 34,
                        onPressed: () => _publish(r),
                        child: const Text(
                          'เผยแพร่',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// สามตัวเลือกที่เลือกได้ทีละอัน รวมเป็นก้อนเดียวเต็มความกว้าง
class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter({
    required this.segments,
    required this.value,
    required this.onChanged,
  });
  final List<(_Filter, String, int)> segments;
  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        for (final (f, label, count) in segments)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(f),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: f == value ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: f == value
                      ? const [
                          BoxShadow(
                            color: Color(0x14101828),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: f == value
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: f == value ? AirySpec.ink : AirySpec.label,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: f == value
                              ? AirySpec.label
                              : const Color(0xFFB6B4C2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// ตัวกรองวิชา — ยังไม่เลือก = ปุ่มไอคอนเล็ก · เลือกแล้ว = ชิปชื่อวิชาพร้อม ✕
class _CourseFilterButton extends StatelessWidget {
  const _CourseFilterButton({
    required this.label,
    required this.onTap,
    required this.onClear,
  });
  final String? label;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3E1EB)),
          ),
          child: const Icon(
            Icons.tune_rounded,
            size: 19,
            color: AirySpec.label,
          ),
        ),
      );
    }
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: AirySpec.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.close_rounded, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.color,
    required this.rows,
    required this.onTap,
    this.trailing,
  });
  final String title;
  final Color color;
  final List<_Row> rows;
  final void Function(_Row) onTap;
  final Widget Function(_Row)? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${rows.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AirySpec.label,
                ),
              ),
            ),
          ],
        ),
      ),
      AiryCard(
        children: [
          for (final r in rows)
            _AssignmentRow(
              r: r,
              onTap: () => onTap(r),
              trailing: trailing?.call(r),
            ),
        ],
      ),
      const SizedBox(height: 18),
    ],
  );
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.r, required this.onTap, this.trailing});
  final _Row r;
  final VoidCallback onTap;
  final Widget? trailing;

  /// บรรทัดรองเหลือแค่ห้องกับกำหนดส่ง — จำนวนที่ส่งย้ายไปเป็นแถบความคืบหน้า
  /// และสถานะ (เลยกำหนด/รอตรวจ) ย้ายไปเป็นป้ายสี เพราะเป็นสิ่งที่ครูกวาดตาหา
  String get _meta {
    final a = r.a;
    final parts = <String>[
      r.roomLabel,
      if (a.totalStudents > 0) 'ส่ง ${a.submittedCount}/${a.totalStudents}',
      if (a.dueAt != null && !(a.isPublished && r.overdue))
        'กำหนด ${_fmt(a.dueAt!.toLocal())}'
      else if (a.dueAt == null)
        'ไม่มีกำหนดส่ง',
    ];
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  /// ป้ายสถานะ: เลยกำหนดกี่วัน > รอตรวจกี่ชิ้น > (ร่างไม่ต้องมี เพราะอยู่ใน
  /// หมวด 'ฉบับร่าง' อยู่แล้ว)
  String? get _statusLabel {
    final a = r.a;
    if (a.isPublished && r.overdue) {
      return 'เลย ${DateTime.now().difference(a.dueAt!).inDays} วัน';
    }
    if (a.pendingGradeCount > 0) return 'รอตรวจ ${a.pendingGradeCount}';
    return null;
  }

  Color get _statusBg => r.a.isPublished && r.overdue
      ? const Color(0xFFFDECEF)
      : const Color(0xFFFDF1DE);

  Color get _statusFg => r.a.isPublished && r.overdue
      ? const Color(0xFFD3324A)
      : const Color(0xFFB4650F);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
      child: Row(
        children: [
          _SubjectBadge(name: r.course.subjectName),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.a.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AirySpec.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AirySpec.label,
                        ),
                      ),
                    ),
                    // ป้ายสถานะอยู่บรรทัดเดียวกับข้อมูลรอง ไม่ใช่ท้ายแถว —
                    // ท้ายแถวมันเบียดกับปุ่ม/ลูกศรจนชื่อใบงานเหลือที่ครึ่งเดียว
                    if (_statusLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _statusFg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // จำนวนที่ส่งย้ายจากบรรทัดข้อความมาเป็นแถบสัดส่วน — กวาดตา
                // เห็นความคืบหน้าของทั้งลิสต์ได้โดยไม่ต้องอ่านทีละตัวเลข
                // แถบสัดส่วนเปล่า ๆ ใต้บรรทัดรอง — ตัวเลขยังอยู่ในบรรทัด
                // ข้อความ ไม่ต้องมีข้อความซ้ำข้างแถบ (เคยทำแล้วล้นที่จอ 360)
                if (r.a.totalStudents > 0) ...[
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (r.a.submittedCount > 0)
                            Expanded(
                              flex: r.a.submittedCount,
                              child: ColoredBox(
                                color: r.a.pendingGradeCount > 0
                                    ? const Color(0xFFEF9F27)
                                    : const Color(0xFF107A50),
                              ),
                            ),
                          if (r.a.totalStudents - r.a.submittedCount > 0)
                            Expanded(
                              flex: r.a.totalStudents - r.a.submittedCount,
                              child: const ColoredBox(color: Color(0xFFEDECF2)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AirySpec.chevron,
              ),
        ],
      ),
    ),
  );
}

/// Two-letter subject badge in the subject's timetable colour.
class _SubjectBadge extends StatelessWidget {
  const _SubjectBadge({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final c = SubjectColor.of(name);
    final short = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, name.trim().length >= 2 ? 2 : 1);
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        short,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: c.fg,
        ),
      ),
    );
  }
}

String _fmt(DateTime d) {
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
  return '${d.day} ${m[d.month - 1]}';
}
