import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_assignments_page.dart';
import 'student_lessons_page.dart';
import 'student_redesign_palette.dart';

/// Body of the Student search popup (the glass dialog opened from the
/// magnifier in the app bar).
///
/// Until 2026-09-18 the field in that popup searched nothing — `query` only
/// toggled the clear button — and the chips under it were invented labels.
/// This body keeps the popup's look and makes it real: an empty query shows
/// shortcuts to real tabs; typing filters the student's courses
/// (`listMyCourses`) and their assignments (`listAssignments`) and lists
/// the hits right inside the popup.
class StudentSearchPopup extends StatefulWidget {
  const StudentSearchPopup({
    super.key,
    required this.onClose,
    required this.onOpenTab,
    required this.onOpenScore,
    this.loadCourses,
    this.loadAssignmentsForCourse,
  });

  final VoidCallback onClose;

  /// 1 lessons, 2 tasks, 3 calendar — the shell switches its bottom tab.
  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenScore;
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse;

  @override
  State<StudentSearchPopup> createState() => _StudentSearchPopupState();
}

class _AssignmentHit {
  const _AssignmentHit({required this.assignment, required this.course});
  final AssignmentSummary assignment;
  final CourseSummary course;
}

class _StudentSearchPopupState extends State<StudentSearchPopup> {
  final _controller = TextEditingController();
  String _query = '';
  bool _loading = true;
  bool _failed = false;
  List<CourseSummary> _courses = const [];
  List<_AssignmentHit> _assignments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
    final loadAssignments =
        widget.loadAssignmentsForCourse ?? AssignmentService.listAssignments;
    try {
      final courses = await loadCourses();
      // One RPC per course, awaited in the loop — the search box stayed empty
      // for N sequential round trips. They are independent.
      final assignmentsPerCourse = await Future.wait(
        courses.map((c) async {
          try {
            return await loadAssignments(c.id);
          } catch (_) {
            // A course whose assignments fail to list still shows up itself.
            return const <AssignmentSummary>[];
          }
        }),
      );
      final hits = <_AssignmentHit>[];
      for (var i = 0; i < courses.length; i++) {
        for (final a in assignmentsPerCourse[i]) {
          hits.add(_AssignmentHit(assignment: a, course: courses[i]));
        }
      }
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _assignments = hits;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  bool _match(String s) =>
      s.toLowerCase().contains(_query.trim().toLowerCase());

  List<CourseSummary> get _courseHits => _courses
      .where(
        (c) =>
            _match(c.subjectName) ||
            _match(c.gradeLevel ?? '') ||
            _match(c.room ?? ''),
      )
      .toList();

  List<_AssignmentHit> get _assignmentHits => _assignments
      .where((h) => _match(h.assignment.title) || _match(h.course.subjectName))
      .toList();

  void _go(VoidCallback then) {
    widget.onClose();
    then();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ค้นหารายวิชาและบทเรียน',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Material(
              color: const Color(0xFFF1F5F9),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onClose,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE1E7EF)),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'ค้นหาวิชา ระดับชั้น ห้อง หรือชื่อใบงาน',
              hintStyle: const TextStyle(
                color: Color(0xFF8A97A8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8A97A8),
                  size: 19,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: Color(0xFF8A97A8),
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (!hasQuery)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Chip(
                label: 'บทเรียน',
                onTap: () => _go(() => widget.onOpenTab(1)),
              ),
              _Chip(
                label: 'ใบงาน',
                onTap: () => _go(() => widget.onOpenTab(2)),
              ),
              _Chip(
                label: 'ปฏิทิน',
                onTap: () => _go(() => widget.onOpenTab(3)),
              ),
              _Chip(label: 'คะแนน', onTap: () => _go(widget.onOpenScore)),
            ],
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: _buildResults(context),
          ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: SchoolPalette.green,
            ),
          ),
        ),
      );
    }
    if (_failed) {
      return const _Note('โหลดข้อมูลสำหรับค้นหาไม่สำเร็จ — ลองปิดแล้วเปิดใหม่');
    }
    final courses = _courseHits;
    final tasks = _assignmentHits;
    if (courses.isEmpty && tasks.isEmpty) {
      return _Note('ไม่พบ "${_query.trim()}"');
    }
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        if (courses.isNotEmpty) ...[
          _Section('รายวิชา (${courses.length})'),
          for (final c in courses)
            _ResultRow(
              icon: Icons.menu_book_rounded,
              title: c.subjectName,
              subtitle: [
                if ((c.gradeLevel ?? '').isNotEmpty) c.gradeLevel!,
                if ((c.room ?? '').isNotEmpty) 'ห้อง ${c.room}',
              ].join(' · '),
              onTap: () => _go(
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentLessonsPage(
                      courseId: c.id,
                      courseName: c.subjectName,
                    ),
                  ),
                ),
              ),
            ),
        ],
        if (tasks.isNotEmpty) ...[
          _Section('ใบงาน (${tasks.length})'),
          for (final h in tasks)
            _ResultRow(
              icon: Icons.assignment_outlined,
              title: h.assignment.title,
              subtitle: h.course.subjectName,
              onTap: () => _go(
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StudentAssignmentsPage(),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: Color(0xFFD9E1EA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF243447),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
    child: Text(
      text,
      style: const TextStyle(
        color: SchoolPalette.muted,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: SchoolPalette.muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: SchoolPalette.green),
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
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SchoolPalette.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
