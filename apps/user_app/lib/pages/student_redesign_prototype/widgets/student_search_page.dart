import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'student_assignments_page.dart';
import 'student_empty_state.dart';
import 'student_lessons_page.dart';
import 'student_redesign_palette.dart';

/// Full-screen search for the Student lane, iOS-style: a search field with
/// a "ยกเลิก" button, shortcuts while the query is empty, grouped results
/// as you type.
///
/// Replaces the glass dialog that shipped with hardcoded chips ("AIoT",
/// "วิทย์", "ครูสมชาย") which only switched tabs and never searched
/// anything — the owner flagged it on the 2026-09-18 phone review. This
/// page searches the student's real courses and their assignments.
class StudentSearchPage extends StatefulWidget {
  const StudentSearchPage({
    super.key,
    this.onOpenTab,
    this.loadCourses,
    this.loadAssignmentsForCourse,
  });

  /// Shortcut taps switch the shell's bottom tab (1 lessons, 2 tasks,
  /// 3 calendar) after popping this page.
  final ValueChanged<int>? onOpenTab;
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse;

  @override
  State<StudentSearchPage> createState() => _StudentSearchPageState();
}

class _AssignmentHit {
  const _AssignmentHit({required this.assignment, required this.course});
  final AssignmentSummary assignment;
  final CourseSummary course;
}

class _StudentSearchPageState extends State<StudentSearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  bool _loading = true;
  String? _error;
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
      final hits = <_AssignmentHit>[];
      for (final c in courses) {
        try {
          for (final a in await loadAssignments(c.id)) {
            hits.add(_AssignmentHit(assignment: a, course: c));
          }
        } catch (_) {
          // One course failing to list its assignments must not blank the
          // whole index; the course itself still shows up.
        }
      }
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _assignments = hits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลสำหรับค้นหาไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  bool _match(String haystack) =>
      haystack.toLowerCase().contains(_query.trim().toLowerCase());

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

  void _openTab(int index) {
    Navigator.of(context).pop();
    widget.onOpenTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: SchoolPalette.softGreenBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SchoolPalette.glassBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาวิชา หรือใบงาน',
                          hintStyle: const TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: SchoolPalette.muted,
                            size: 20,
                          ),
                          suffixIcon: hasQuery
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: SchoolPalette.muted,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: SchoolPalette.green,
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: SchoolPalette.green,
                      ),
                    )
                  : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: StudentEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: _error!,
                        hint: 'ลองปิดแล้วเปิดค้นหาใหม่อีกครั้ง',
                      ),
                    )
                  : hasQuery
                  ? _buildResults()
                  : _buildShortcuts(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcuts() {
    final shortcuts = [
      (icon: Icons.menu_book_rounded, label: 'บทเรียนของฉัน', tab: 1),
      (icon: Icons.assignment_rounded, label: 'ใบงานและการบ้าน', tab: 2),
      (
        icon: Icons.calendar_month_rounded,
        label: 'ปฏิทิน / ตารางเรียน',
        tab: 3,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _sectionTitle('ไปที่'),
        _card(
          children: [
            for (var i = 0; i < shortcuts.length; i++) ...[
              if (i > 0) _divider(),
              _row(
                icon: shortcuts[i].icon,
                title: shortcuts[i].label,
                onTap: () => _openTab(shortcuts[i].tab),
              ),
            ],
          ],
        ),
        if (_courses.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('รายวิชาของฉัน'),
          _card(
            children: [
              for (var i = 0; i < _courses.length; i++) ...[
                if (i > 0) _divider(),
                _courseRow(_courses[i]),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResults() {
    final courses = _courseHits;
    final tasks = _assignmentHits;
    if (courses.isEmpty && tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: StudentEmptyState(
          icon: Icons.search_off_rounded,
          title: 'ไม่พบ "${_query.trim()}"',
          hint: 'ค้นได้จากชื่อวิชา ระดับชั้น ห้อง หรือชื่อใบงาน',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (courses.isNotEmpty) ...[
          _sectionTitle('รายวิชา (${courses.length})'),
          _card(
            children: [
              for (var i = 0; i < courses.length; i++) ...[
                if (i > 0) _divider(),
                _courseRow(courses[i]),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (tasks.isNotEmpty) ...[
          _sectionTitle('ใบงาน (${tasks.length})'),
          _card(
            children: [
              for (var i = 0; i < tasks.length; i++) ...[
                if (i > 0) _divider(),
                _row(
                  icon: Icons.assignment_outlined,
                  title: tasks[i].assignment.title,
                  subtitle: tasks[i].course.subjectName,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudentAssignmentsPage(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _courseRow(CourseSummary c) {
    final meta = [
      if ((c.gradeLevel ?? '').isNotEmpty) c.gradeLevel!,
      if ((c.room ?? '').isNotEmpty) 'ห้อง ${c.room}',
    ].join(' · ');
    return _row(
      icon: Icons.menu_book_rounded,
      title: c.subjectName,
      subtitle: meta.isEmpty ? null : meta,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              StudentLessonsPage(courseId: c.id, courseName: c.subjectName),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(
      text,
      style: const TextStyle(
        color: SchoolPalette.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SchoolPalette.glassBorder),
    ),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(
    height: 1,
    thickness: 1,
    indent: 54,
    color: SchoolPalette.softGreenBg,
  );

  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
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
                        color: SchoolPalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
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
