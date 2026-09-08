import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'student_lesson_view_page.dart';
import 'student_redesign_palette.dart';

class _LessonWithCourse {
  const _LessonWithCourse({required this.lesson, required this.courseName});

  final LessonSummary lesson;
  final String courseName;
}

class StudentLessonsPage extends StatefulWidget {
  const StudentLessonsPage({
    super.key,
    this.showAppBar = true,
    this.courseId,
    this.courseName,
    this.loadCourses,
    this.listLessons,
  });

  /// false เมื่อฝังเป็นแท็บในเชลล์นำทาง (มี AppBar/title ของตัวเองอยู่แล้ว)
  final bool showAppBar;

  /// ถ้าระบุ จะโหลดบทเรียนเฉพาะวิชานี้วิชาเดียว (มาจากหน้ารายวิชา) ถ้าไม่
  /// ระบุ จะโหลดบทเรียนรวมทุกวิชาที่ลงทะเบียนเหมือนเดิม
  final String? courseId;
  final String? courseName;

  /// Read seams threaded to the corresponding CourseService/LessonService
  /// static calls in production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<LessonSummary>> Function(String courseId)? listLessons;

  @override
  State<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends State<StudentLessonsPage> {
  bool _loading = true;
  String? _error;
  List<_LessonWithCourse> _lessons = const [];

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
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadLessons = widget.listLessons ?? LessonService.listLessons;
      final items = <_LessonWithCourse>[];
      if (widget.courseId != null) {
        final lessons = await loadLessons(widget.courseId!);
        for (final lesson in lessons.where((l) => l.isPublished)) {
          items.add(
            _LessonWithCourse(
              lesson: lesson,
              courseName: widget.courseName ?? '',
            ),
          );
        }
      } else {
        final courses = (await loadCourses())
            .where((c) => c.isActive)
            .toList();
        final lessonLists = await Future.wait(
          courses.map((c) => loadLessons(c.id)),
        );
        for (var i = 0; i < courses.length; i++) {
          for (final lesson in lessonLists[i].where((l) => l.isPublished)) {
            items.add(
              _LessonWithCourse(
                lesson: lesson,
                courseName: courses[i].subjectName,
              ),
            );
          }
        }
      }
      items.sort((a, b) {
        final aDate = a.lesson.publishedAt ?? DateTime(2000);
        final bDate = b.lesson.publishedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _lessons = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลไม่สำเร็จ';
        _loading = false;
      });
    }
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
                final horizontalPadding = screenWidth < 520 ? 14.0 : 16.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 720 : 640),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryHeader(context),
                        const SizedBox(height: 18),
                        if (_error != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 12),
                        ],
                        _buildLessonList(),
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
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: SchoolPalette.ink,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.courseName ?? 'บทเรียนและคอร์สเรียน',
                style: const TextStyle(
                  color: SchoolPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            body: body,
          )
        : body;
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

  Widget _buildSummaryHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, SchoolPalette.deepGreen, 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEFE6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: SchoolPalette.primaryGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4035C99A),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.courseId != null
                      ? 'บทเรียนวิชานี้'
                      : 'บทเรียนทั้งหมดของคุณ',
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _loading
                      ? 'กำลังโหลด...'
                      : '${_lessons.length} บทเรียนที่เปิดสอน',
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SchoolPalette.glassBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 36,
              color: SchoolPalette.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'ยังไม่มีบทเรียนที่เปิดสอน',
              style: TextStyle(
                color: SchoolPalette.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _lessons.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: LessonCard(item: _lessons[i]),
          ),
      ],
    );
  }
}

class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.item});

  final _LessonWithCourse item;

  static String _publishedLabel(DateTime? publishedAt) {
    if (publishedAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(publishedAt);
    if (diff.inDays < 1) return 'เผยแพร่วันนี้';
    if (diff.inDays < 7) return 'เผยแพร่ ${diff.inDays} วันที่แล้ว';
    return 'เผยแพร่ ${publishedAt.day}/${publishedAt.month}/${publishedAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = SchoolPalette.deepGreen;
    final pastelBg = Color.lerp(Colors.white, accentColor, 0.08)!;

    return Container(
      decoration: BoxDecoration(
        color: pastelBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentLessonViewPage(lessonId: item.lesson.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: accentColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _publishedLabel(item.lesson.publishedAt),
                        style: const TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
