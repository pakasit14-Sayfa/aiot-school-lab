import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'student_redesign_palette.dart';
import 'student_lessons_page.dart';
import 'student_assignments_page.dart';
import 'academy_continue_learning_card.dart' show PatternedProgressBar;

class StudentCourseCatalogPage extends StatefulWidget {
  const StudentCourseCatalogPage({
    super.key,
    this.showAppBar = true,
    this.searchPopupTick,
  });

  final bool showAppBar;
  final ValueNotifier<int>? searchPopupTick;

  @override
  State<StudentCourseCatalogPage> createState() =>
      _StudentCourseCatalogPageState();
}

/// ข้อมูลจริงต่อวิชาที่แสดงบนการ์ด — คำนวณจาก CourseService/LessonService/
/// AssignmentService จริง ไม่มีฟิลด์ไหนเป็นค่าปลอม ฟิลด์ที่นักเรียนเรียกดู
/// ไม่ได้จริง (เช่น จำนวนเพื่อนร่วมชั้น — RPC list_course_students ปฏิเสธ
/// role นักเรียนโดยตรง) ถูกตัดออกจากการ์ดไปเลย ไม่ใส่เลขปลอมแทน
class _CourseCardData {
  const _CourseCardData({
    required this.course,
    required this.teacherNames,
    required this.lessonCount,
    required this.nextLessonTitle,
    required this.submittedCount,
    required this.totalAssignments,
    required this.gradient,
  });

  final CourseSummary course;
  final String? teacherNames;
  final int lessonCount;
  final String? nextLessonTitle;
  final int submittedCount;
  final int totalAssignments;
  final List<Color> gradient;

  double get progress =>
      totalAssignments == 0 ? 0.0 : submittedCount / totalAssignments;

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final haystack = <String>[
      course.subjectName,
      if (teacherNames != null) teacherNames!,
      if (nextLessonTitle != null) nextLessonTitle!,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

class _StudentCourseCatalogPageState extends State<StudentCourseCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  int _lastSearchPopupTick = 0;
  bool _isSearchPopupOpen = false;

  bool _loading = true;
  String? _error;
  List<_CourseCardData> _cards = const [];

  static const _gradients = [
    [Color(0xFF0F3E33), Color(0xFF134E4A)],
    [Color(0xFF134E4A), Color(0xFF165042)],
    [Color(0xFF0E4D40), Color(0xFF1B6B57)],
    [Color(0xFF064E3B), Color(0xFF047857)],
  ];

  @override
  void initState() {
    super.initState();
    widget.searchPopupTick?.addListener(_handleExternalSearchRequest);
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
        final published = lessonLists[i].where((l) => l.isPublished).toList();
        published.sort((a, b) {
          final aDate = a.publishedAt ?? DateTime(2000);
          final bDate = b.publishedAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

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

        cards.add(
          _CourseCardData(
            course: courses[i],
            teacherNames: details[i].teacherNames,
            lessonCount: published.length,
            nextLessonTitle: published.isNotEmpty
                ? published.first.title
                : null,
            submittedCount: submittedCount,
            totalAssignments: publishedAssignments.length,
            gradient: _gradients[i % _gradients.length],
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (e) {
      debugPrint('StudentCourseCatalogPage: โหลดรายวิชาไม่สำเร็จ — $e');
      if (!mounted) return;
      setState(() {
        _error = 'โหลดรายวิชาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
        _loading = false;
      });
    }
  }

  void _handleExternalSearchRequest() {
    final tick = widget.searchPopupTick?.value ?? 0;
    if (tick == _lastSearchPopupTick) {
      return;
    }
    _lastSearchPopupTick = tick;
    _showSearchPopup();
  }

  Future<void> _showSearchPopup() async {
    if (!mounted || _isSearchPopupOpen) {
      return;
    }

    _isSearchPopupOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 52,
            bottom: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ค้นหารายวิชาและบทเรียน 🔍',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF334155),
                              tooltip: 'ปิด',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              _clearSearch();
                              Navigator.of(dialogContext).pop();
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('ล้างคำค้น'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _isSearchPopupOpen = false;
  }

  @override
  void dispose() {
    widget.searchPopupTick?.removeListener(_handleExternalSearchRequest);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              title: const Text(
                'วิชาเรียนและบทเรียน',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            )
          : null,
      body: SafeArea(
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
                  final horizontalPadding = screenWidth < 520 ? 12.0 : 16.0;

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1080 : 760,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchableSectionHeader(context),
                          const SizedBox(height: 18),
                          if (_error != null) ...[
                            _buildErrorBanner(),
                            const SizedBox(height: 12),
                          ],
                          _buildCourseGrid(screenWidth),
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
      ),
    );
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

  Widget _buildSearchableSectionHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ห้องเรียนของฉัน',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFA7F3D0)),
                  ),
                ),
                child: Text(
                  _loading ? 'กำลังโหลด...' : '${_cards.length} วิชา',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _searchQuery = value),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintText: 'ค้นหาชื่อวิชาหรือชื่อครูผู้สอน...',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseGrid(double screenWidth) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredCards = _cards
        .where((c) => c.matchesQuery(_searchQuery))
        .toList();

    if (filteredCards.isEmpty) {
      return _EmptyCourseState(hasAnyCourse: _cards.isNotEmpty);
    }

    if (screenWidth >= 768) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: filteredCards.map((card) {
          return SizedBox(
            width: (screenWidth >= 1024 ? 1080 : 760) / 2 - 24,
            child: _CourseClassroomCard(data: card),
          );
        }).toList(),
      );
    }

    return Column(
      children: filteredCards.map((card) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CourseClassroomCard(data: card),
        );
      }).toList(),
    );
  }
}

class _EmptyCourseState extends StatelessWidget {
  const _EmptyCourseState({required this.hasAnyCourse});

  final bool hasAnyCourse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasAnyCourse ? Icons.search_off_rounded : Icons.school_outlined,
            color: const Color(0xFF94A3B8),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            hasAnyCourse
                ? 'ไม่พบรายวิชาที่ตรงกับคำค้น'
                : 'ยังไม่ได้ลงทะเบียนวิชาใดเลย',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (hasAnyCourse) ...[
            const SizedBox(height: 4),
            const Text(
              'ลองค้นหาด้วยชื่อวิชาหรือชื่อครูผู้สอน',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseClassroomCard extends StatelessWidget {
  const _CourseClassroomCard({required this.data});

  final _CourseCardData data;

  @override
  Widget build(BuildContext context) {
    final course = data.course;
    final pendingCount = data.totalAssignments - data.submittedCount;
    final String badgeLabel;
    final Color badgeBg;
    final Color badgeText;
    if (data.totalAssignments == 0) {
      badgeLabel = 'ยังไม่มีใบงาน';
      badgeBg = const Color(0xFFF1F5F9);
      badgeText = const Color(0xFF64748B);
    } else if (pendingCount > 0) {
      badgeLabel = '🔴 $pendingCount งานค้างส่ง';
      badgeBg = const Color(0xFFFFE4E6);
      badgeText = const Color(0xFFE11D48);
    } else {
      badgeLabel = '🟢 งานส่งครบแล้ว';
      badgeBg = const Color(0xFFECFDF5);
      badgeText = const Color(0xFF059669);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _openLessons(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      course.subjectName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    if (data.teacherNames != null &&
                        data.teacherNames!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data.teacherNames!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.totalAssignments > 0) ...[
                      const Text(
                        'ใบงานที่ส่งแล้ว',
                        style: TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFEDF1F5)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${(data.progress * 100).round()}%',
                              style: const TextStyle(
                                color: Color(0xFF0F3E33),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PatternedProgressBar(
                                progress: data.progress,
                                height: 9,
                                backgroundColor: const Color(0xFFE2E8F0),
                                fillColor: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${data.submittedCount}/${data.totalAssignments}',
                              style: const TextStyle(
                                color: Color(0xFF0F3E33),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF059669),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.nextLessonTitle ??
                                  'ยังไม่มีบทเรียนที่เผยแพร่',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SchoolPalette.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (data.lessonCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${data.lessonCount} บท',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentAssignmentsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_outlined, size: 15),
                          label: const Text('ดูใบงาน'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SchoolPalette.ink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => _openLessons(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'เข้าเรียน',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLessons(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentLessonsPage(
          courseId: data.course.id,
          courseName: data.course.subjectName,
        ),
      ),
    );
  }
}
