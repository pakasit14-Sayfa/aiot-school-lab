import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'student_redesign_palette.dart';
import 'student_lessons_page.dart';

/// ข้อมูลจริงต่อวิชาที่แสดงบนการ์ด — เหมือนกับที่ใช้ใน
/// student_course_catalog_page.dart (แบบที่ 1) ทุกฟิลด์ ไม่มีฟิลด์ปลอม
/// ฟิลด์ที่นักเรียนเรียกดูไม่ได้จริง (รหัสวิชา, จำนวนเพื่อนร่วมชั้น) ถูกตัด
/// ออกไปเลย เช่นเดียวกับหมวดหมู่วิชา (เทคโนโลยี/วิทย์/คณิต) ที่ไม่มีสคีมา
/// รองรับจริง เลยตัด filter chip หมวดหมู่ออกด้วย เหลือแค่ค้นหาด้วยข้อความ
class _CourseCardData {
  const _CourseCardData({
    required this.course,
    required this.teacherNames,
    required this.lessonCount,
    required this.submittedCount,
    required this.totalAssignments,
    required this.accentColor,
    required this.accentBg,
    required this.icon,
  });

  final CourseSummary course;
  final String? teacherNames;
  final int lessonCount;
  final int submittedCount;
  final int totalAssignments;
  final Color accentColor;
  final Color accentBg;
  final IconData icon;

  double get progress =>
      totalAssignments == 0 ? 0.0 : submittedCount / totalAssignments;

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final haystack = <String>[
      course.subjectName,
      if (teacherNames != null) teacherNames!,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

class StudentCourseCatalogMinimalPage extends StatefulWidget {
  const StudentCourseCatalogMinimalPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<StudentCourseCatalogMinimalPage> createState() =>
      _StudentCourseCatalogMinimalPageState();
}

class _StudentCourseCatalogMinimalPageState
    extends State<StudentCourseCatalogMinimalPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _loading = true;
  String? _error;
  List<_CourseCardData> _cards = const [];

  static const _iconSet = [
    (
      icon: Icons.memory_rounded,
      accent: Color(0xFF10B981),
      bg: Color(0xFFECFDF5),
    ),
    (
      icon: Icons.bolt_rounded,
      accent: Color(0xFF0284C7),
      bg: Color(0xFFF0F9FF),
    ),
    (
      icon: Icons.calculate_rounded,
      accent: Color(0xFF7C3AED),
      bg: Color(0xFFF5F3FF),
    ),
    (
      icon: Icons.science_rounded,
      accent: Color(0xFF059669),
      bg: Color(0xFFECFDF5),
    ),
    (
      icon: Icons.nature_people_rounded,
      accent: Color(0xFFEA580C),
      bg: Color(0xFFFFF7ED),
    ),
  ];

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
      final courses = (await CourseService.listMyCourses())
          .where((c) => c.isActive)
          .toList();

      final details = await Future.wait(
        courses.map((c) => CourseService.getCourse(c.id)),
      );
      final lessonLists = await Future.wait(
        courses.map((c) => LessonService.listLessons(c.id)),
      );
      final assignmentLists = await Future.wait(
        courses.map((c) => AssignmentService.listAssignments(c.id)),
      );

      final cards = <_CourseCardData>[];
      for (var i = 0; i < courses.length; i++) {
        final publishedLessons = lessonLists[i]
            .where((l) => l.isPublished)
            .toList();

        final publishedAssignments = assignmentLists[i]
            .where((a) => a.isPublished)
            .toList();
        final submissionChecks = await Future.wait(
          publishedAssignments.map(
            (a) => AssignmentService.listMySubmissionVersions(a.id),
          ),
        );
        final submittedCount = submissionChecks
            .where((s) => s.isNotEmpty)
            .length;

        final iconSpec = _iconSet[i % _iconSet.length];
        cards.add(
          _CourseCardData(
            course: courses[i],
            teacherNames: details[i].teacherNames,
            lessonCount: publishedLessons.length,
            submittedCount: submittedCount,
            totalAssignments: publishedAssignments.length,
            accentColor: iconSpec.accent,
            accentBg: iconSpec.bg,
            icon: iconSpec.icon,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isDesktop = screenWidth >= 1024;
                final horizontalPadding = screenWidth < 520 ? 14.0 : 20.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 960 : 680),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMinimalHeader(context),
                        const SizedBox(height: 16),
                        if (_error != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 12),
                        ],
                        _buildCourseList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    return widget.showAppBar
        ? Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              title: const Text(
                'รายวิชาของฉัน',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            body: body,
          )
        : Container(color: const Color(0xFFF8FAFC), child: body);
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }

  Widget _buildMinimalHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'รายวิชาทั้งหมด 📚',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              _loading ? 'กำลังโหลด...' : '${_cards.length} วิชา',
              style: const TextStyle(
                color: SchoolPalette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อวิชาหรือผู้สอน...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: const Color(0xFF64748B),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF10B981),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _cards.where((c) => c.matchesQuery(_searchQuery)).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(
              _cards.isEmpty ? Icons.school_outlined : Icons.search_off_rounded,
              size: 34,
              color: const Color(0xFF94A3B8).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              _cards.isEmpty
                  ? 'ยังไม่ได้ลงทะเบียนวิชาใดเลย'
                  : 'ไม่พบวิชาที่ตรงกับคำค้น',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((card) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MinimalCourseCard(data: card),
        );
      }).toList(),
    );
  }
}

class _MinimalCourseCard extends StatelessWidget {
  const _MinimalCourseCard({required this.data});

  final _CourseCardData data;

  @override
  Widget build(BuildContext context) {
    final pendingCount = data.totalAssignments - data.submittedCount;
    final String badgeLabel;
    final Color badgeColor;
    final Color badgeBg;
    if (data.totalAssignments == 0) {
      badgeLabel = 'ยังไม่มีใบงาน';
      badgeColor = const Color(0xFF64748B);
      badgeBg = const Color(0xFFF1F5F9);
    } else if (pendingCount > 0) {
      badgeLabel = '🔴 $pendingCount งานค้าง';
      badgeColor = const Color(0xFFE11D48);
      badgeBg = const Color(0xFFFFE4E6);
    } else {
      badgeLabel = '🟢 ส่งครบแล้ว';
      badgeColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFECFDF5);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentLessonsPage(
                  courseId: data.course.id,
                  courseName: data.course.subjectName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: data.accentBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: data.accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(data.icon, color: data.accentColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.course.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.teacherNames != null &&
                                data.teacherNames!.isNotEmpty
                            ? '${data.teacherNames} · ${data.lessonCount} บทเรียน'
                            : '${data.lessonCount} บทเรียน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (data.totalAssignments > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: data.progress,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  color: data.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(data.progress * 100).round()}%',
                              style: TextStyle(
                                color: data.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
