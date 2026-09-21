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
      final courses =
          await (widget.listMyCourses ?? CourseService.listMyCourses)();
      final list = widget.listAssignments ?? AssignmentService.listAssignments;
      final rows = <_Row>[];
      for (final c in courses) {
        final as = await list(c.id);
        rows.addAll(as.map((a) => _Row(course: c, a: a)));
      }
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
      onRefresh: _load,
      activeMenuLabel: 'ตรวจงาน',
      actions: [
        IconButton(
          tooltip: 'กรองตามวิชา',
          onPressed: _rows.isEmpty ? null : _pickCourse,
          icon: Icon(
            Icons.tune_rounded,
            color: _courseFilter == null ? null : TeacherPalette.primary,
          ),
        ),
      ],
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
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(
                  label: 'รอตรวจ $_pendingTotal',
                  active: _filter == _Filter.pending,
                  onTap: () => setState(() => _filter = _Filter.pending),
                ),
                _Chip(
                  label: 'เลยกำหนด $_overdueTotal',
                  active: _filter == _Filter.overdue,
                  onTap: () => setState(() => _filter = _Filter.overdue),
                ),
                _Chip(
                  label: 'ทั้งหมด ${_rows.length}',
                  active: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
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
                  color: const Color(0xFFA32D2D),
                  rows: overdue,
                  onTap: _open,
                ),
              if (open.isNotEmpty)
                _Section(
                  title: 'กำลังเปิดรับ',
                  color: TeacherPalette.muted,
                  rows: open,
                  onTap: _open,
                ),
              if (drafts.isNotEmpty)
                _Section(
                  title: 'ฉบับร่าง',
                  color: TeacherPalette.muted,
                  rows: drafts,
                  onTap: _open,
                  trailing: (r) => TextButton(
                    onPressed: () => _publish(r),
                    child: const Text('เผยแพร่'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? TeacherPalette.ink : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? TeacherPalette.ink : TeacherPalette.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : TeacherPalette.ink,
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TeacherPalette.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _AssignmentRow(
                  r: rows[i],
                  onTap: () => onTap(rows[i]),
                  trailing: trailing?.call(rows[i]),
                ),
                if (i < rows.length - 1)
                  const Divider(
                    height: 1,
                    indent: 52,
                    color: Color(0xFFF1F5F9),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.r, required this.onTap, this.trailing});
  final _Row r;
  final VoidCallback onTap;
  final Widget? trailing;

  String get _meta {
    final a = r.a;
    final parts = <String>[
      r.roomLabel,
      if (a.totalStudents > 0) 'ส่ง ${a.submittedCount}/${a.totalStudents}',
      if (a.pendingGradeCount > 0) 'รอตรวจ ${a.pendingGradeCount}',
      if (a.isPublished && r.overdue)
        'เลย ${DateTime.now().difference(a.dueAt!).inDays} วัน'
      else if (a.dueAt != null)
        'ส่ง ${_fmt(a.dueAt!.toLocal())}',
    ];
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          _SubjectBadge(name: r.course.subjectName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.a.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: TeacherPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TeacherPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          if (r.a.pendingGradeCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${r.a.pendingGradeCount}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF854F0B),
                ),
              ),
            ),
          trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: TeacherPalette.muted,
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
