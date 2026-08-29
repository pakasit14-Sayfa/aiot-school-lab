import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../notifications_page.dart';
import 'student_redesign_palette.dart';
import 'aiot_weather_sensors_card.dart';
import 'school_encouragement_card.dart';
import 'school_utility_trend_card.dart';
import 'academy_quick_actions.dart';
import 'academy_continue_learning_card.dart';
import 'academy_tasks_due_card.dart';
import 'learning_progress_card.dart';

class StudentVariantSchoolHome extends StatefulWidget {
  const StudentVariantSchoolHome({super.key, this.onViewScore});

  /// Lets the G-Score summary card open the full "คะแนน" page — the score
  /// snapshot lives on the home page since it updates daily, while the full
  /// breakdown is one tap away instead of living in the main nav.
  final VoidCallback? onViewScore;

  @override
  State<StudentVariantSchoolHome> createState() =>
      _StudentVariantSchoolHomeState();
}

class _StudentVariantSchoolHomeState extends State<StudentVariantSchoolHome> {
  bool _loading = true;
  String? _error;

  int _lessonCount = 0;
  int _submittedCount = 0;
  int _totalAssignments = 0;
  String? _continueCourseLabel;
  String? _continueLessonTitle;
  double _continueProgress = 0;
  int _continuePublished = 0;
  int _continueTotal = 0;
  List<UpcomingTask> _upcomingTasks = const [];
  double _avgGradePercent = 0;
  int _gradedCourseCount = 0;
  AppNotification? _latestNotification;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CourseService.listMyCourses(),
        GradeService.listMyGrades(),
        NotificationService.listMyNotifications(),
      ]);
      final courses = (results[0] as List<CourseSummary>)
          .where((c) => c.isActive)
          .toList();
      final grades = results[1] as List<CourseGrade>;
      final notifications = results[2] as List<AppNotification>;

      final lessonLists = await Future.wait(
        courses.map((c) => LessonService.listLessons(c.id)),
      );
      final assignmentLists = await Future.wait(
        courses.map((c) => AssignmentService.listAssignments(c.id)),
      );

      var lessonCount = 0;
      String? continueCourseLabel;
      String? continueLessonTitle;
      var continuePublished = 0;
      var continueTotal = 0;
      DateTime? latestPublishedAt;
      for (var i = 0; i < courses.length; i++) {
        final course = courses[i];
        final lessons = lessonLists[i];
        final published = lessons.where((l) => l.isPublished).toList();
        lessonCount += published.length;
        for (final lesson in published) {
          final publishedAt = lesson.publishedAt;
          if (publishedAt != null &&
              (latestPublishedAt == null ||
                  publishedAt.isAfter(latestPublishedAt))) {
            latestPublishedAt = publishedAt;
            continueCourseLabel = course.gradeLevel != null
                ? '${course.subjectName} • ${course.gradeLevel}'
                : course.subjectName;
            continueLessonTitle = lesson.title;
            continuePublished = published.length;
            continueTotal = lessons.length;
          }
        }
      }
      final continueProgress = continueTotal == 0
          ? 0.0
          : continuePublished / continueTotal;

      final publishedAssignments = <(AssignmentSummary, CourseSummary)>[];
      for (var i = 0; i < courses.length; i++) {
        for (final a in assignmentLists[i].where((a) => a.isPublished)) {
          publishedAssignments.add((a, courses[i]));
        }
      }

      final submissionChecks = await Future.wait(
        publishedAssignments.map(
          (e) => AssignmentService.listMySubmissionVersions(e.$1.id),
        ),
      );

      var submittedCount = 0;
      final upcoming = <UpcomingTask>[];
      for (var i = 0; i < publishedAssignments.length; i++) {
        final submitted = submissionChecks[i].isNotEmpty;
        if (submitted) submittedCount++;
        final (assignment, course) = publishedAssignments[i];
        final dueAt = assignment.dueAt;
        if (!submitted && dueAt != null) {
          upcoming.add(
            UpcomingTask(
              title: assignment.title,
              courseLabel: course.subjectName,
              dueAt: dueAt,
            ),
          );
        }
      }
      upcoming.sort((a, b) => a.dueAt.compareTo(b.dueAt));

      final avgPercent = grades.isEmpty
          ? 0.0
          : grades.map((g) => g.percent).reduce((a, b) => a + b) /
                grades.length;

      if (!mounted) return;
      setState(() {
        _lessonCount = lessonCount;
        _submittedCount = submittedCount;
        _totalAssignments = publishedAssignments.length;
        _continueCourseLabel = continueCourseLabel;
        _continueLessonTitle = continueLessonTitle;
        _continueProgress = continueProgress;
        _continuePublished = continuePublished;
        _continueTotal = continueTotal;
        _upcomingTasks = upcoming.take(3).toList();
        _avgGradePercent = avgPercent;
        _gradedCourseCount = grades.length;
        _latestNotification = notifications.isEmpty
            ? null
            : notifications.first;
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = screenWidth >= 1024;
            final horizontalPadding = screenWidth < 520 ? 12.0 : 16.0;
            final sectionGap = screenWidth < 520 ? 14.0 : 18.0;
            final afterSummaryGap = screenWidth < 520 ? 8.0 : 10.0;

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1180 : 720),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(context),
                    SizedBox(height: afterSummaryGap),
                    if (_error != null) ...[
                      _buildErrorBanner(context),
                      SizedBox(height: sectionGap),
                    ],
                    _buildTopSectionGrid(
                      context,
                      onViewScore: widget.onViewScore,
                    ),
                    SizedBox(height: sectionGap),
                    AcademyQuickActions(
                      lessonCount: _lessonCount,
                      dueAssignmentCount: _upcomingTasks.length,
                    ),
                    SizedBox(height: sectionGap),
                    AcademyContinueLearningCard(
                      courseLabel: _continueCourseLabel,
                      lessonTitle: _continueLessonTitle,
                      progress: _continueProgress,
                      publishedLessonCount: _continuePublished,
                      totalLessonCount: _continueTotal,
                    ),
                    SizedBox(height: sectionGap),
                    AcademyTasksDueCard(tasks: _upcomingTasks),
                    SizedBox(height: sectionGap),
                    _buildAnnouncementsCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
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
          TextButton(
            onPressed: _loading ? null : _loadRealData,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 430;
        final mascotSize = isCompact ? 176.0 : 220.0;
        final textRight = isCompact ? 132.0 : 210.0;
        final titleSize = isCompact ? 31.0 : 38.0;

        return SizedBox(
          height: isCompact ? 262 : 286,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F3E33),
                        Color(0xFF165042),
                        Color(0xFF2A6B58),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26165042),
                        blurRadius: 22,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: CustomPaint(painter: _SchoolHeroPatternPainter()),
                ),
              ),
              Positioned(
                right: isCompact ? -8 : 18,
                top: isCompact ? 14 : 2,
                child: SizedBox(
                  width: mascotSize,
                  height: mascotSize,
                  child: Image.asset(
                    'assets/images/mascot_lion_anim.png',
                    width: mascotSize,
                    height: mascotSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/mascot_lion_anim.gif',
                        width: mascotSize,
                        height: mascotSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/mascot_lion_clean.png',
                            width: mascotSize,
                            height: mascotSize,
                            fit: BoxFit.contain,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                left: 24,
                right: textRight,
                top: isCompact ? 34 : 38,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดีตอนเช้า,',
                      style: TextStyle(
                        color: SchoolPalette.cream,
                        fontSize: isCompact ? 19 : 23,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${currentUserModel?.name ?? 'นักเรียน'}!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'มาต่อบทเรียน AIoT และงานทดลองวันนี้กัน',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: isCompact ? 15 : 17,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                bottom: 26,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isCompact ? 304 : 360,
                    minWidth: isCompact ? 288 : 328,
                  ),
                  child: LearningProgressCard(
                    progress: _totalAssignments == 0
                        ? 0
                        : _submittedCount / _totalAssignments,
                    lessonCount: _lessonCount,
                    submittedCount: _submittedCount,
                    totalAssignments: _totalAssignments,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSectionGrid(
    BuildContext context, {
    VoidCallback? onViewScore,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTwoColumn = width >= 900;
        final columnGap = width >= 1100 ? 18.0 : 14.0;

        // การ์ดพลังงาน/น้ำ ย้ายออกมาเป็นแถวเต็มความกว้างของตัวเอง (ไม่ใช่ถูก
        // บีบเป็นช่องที่ 3 ในคอลัมน์ขวาแคบๆ อีกต่อไป) เพราะมีกราฟเทรนด์ 7 วัน
        // ที่ต้องการพื้นที่แนวนอนมากพอจะอ่านง่าย — บีบให้สูงแค่ ~160px
        // แนวตั้งมันพอดูได้ แต่แนวนอนที่ถูกบีบไปด้วยเพราะอยู่คอลัมน์ขวาทำให้
        // กราฟอ่านยาก
        final utilityFullWidthHeight = width >= 1100 ? 260.0 : 230.0;

        if (!isTwoColumn) {
          return Column(
            children: [
              const AiotWeatherSensorsCard(),
              const SizedBox(height: 16),
              AcademyLearningScoreCard(
                onTap: onViewScore,
                avgPercent: _avgGradePercent,
                gradedCourseCount: _gradedCourseCount,
              ),
              const SizedBox(height: 16),
              const SchoolEncouragementCard(),
              const SizedBox(height: 16),
              SchoolUtilityTrendCard(height: utilityFullWidthHeight),
            ],
          );
        }

        final scoreCardHeight = width >= 1100 ? 238.0 : 232.0;
        final encouragementCardHeight = width >= 1100 ? 192.0 : 186.0;
        // +16 กันการ์ดซ้าย (4 แถวเซนเซอร์ + ปุ่ม) overflow เล็กน้อย — แต่ละ
        // แถวมีบรรทัด "อัปเดต ... ที่แล้ว" เพิ่มมาแล้ว (freshness caption)
        // ทำให้สูงกว่าตอนคำนวณสูตรนี้ครั้งแรกนิดหน่อย
        final sensorCardHeight =
            scoreCardHeight + encouragementCardHeight + columnGap + 16;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: AiotWeatherSensorsCard(height: sensorCardHeight),
                ),
                SizedBox(width: columnGap),
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: scoreCardHeight,
                        child: AcademyLearningScoreCard(
                          onTap: onViewScore,
                          avgPercent: _avgGradePercent,
                          gradedCourseCount: _gradedCourseCount,
                        ),
                      ),
                      SizedBox(height: columnGap),
                      SizedBox(
                        height: encouragementCardHeight,
                        child: SchoolEncouragementCard(
                          height: encouragementCardHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: columnGap),
            SchoolUtilityTrendCard(height: utilityFullWidthHeight),
          ],
        );
      },
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  Widget _buildAnnouncementsCard(BuildContext context) {
    final notification = _latestNotification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ข่าวสารประกาศโรงเรียน',
                style: TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: SchoolPalette.green,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text(
                    'ดูทั้งหมด',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (notification == null)
          const SoftCard(
            padding: EdgeInsets.all(16),
            child: Text(
              'ยังไม่มีประกาศ',
              style: TextStyle(color: SchoolPalette.muted, fontSize: 12.5),
            ),
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            child: SoftCard(
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x337C3AED),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SchoolPalette.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Text(
                              _timeAgo(notification.createdAt),
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (notification.body != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            notification.body!,
                            maxLines: 2,
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
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AcademyLearningScoreCard extends StatelessWidget {
  const AcademyLearningScoreCard({
    super.key,
    this.onTap,
    required this.avgPercent,
    required this.gradedCourseCount,
  });

  /// Opens the full "คะแนน" page — still mock/out of scope this pass.
  final VoidCallback? onTap;

  /// Real average from GradeService.listMyGrades(). G-Score/GPA/badges have
  /// no backend anywhere in the system (checked shared_core services) so
  /// this card shows the one real grade metric available instead.
  final double avgPercent;
  final int gradedCourseCount;

  @override
  Widget build(BuildContext context) {
    final content = SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: SchoolPalette.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x6643AC60),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'คะแนนและผลการเรียน',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SchoolPalette.muted,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (gradedCourseCount == 0)
            const Text(
              'ยังไม่มีคะแนนที่ยืนยันแล้ว',
              style: TextStyle(color: SchoolPalette.muted, fontSize: 12.5),
            )
          else
            Row(
              children: [
                Expanded(
                  child: LearningScoreTile(
                    icon: Icons.military_tech_rounded,
                    label: 'คะแนนเฉลี่ยทุกวิชา',
                    value: '${avgPercent.toStringAsFixed(0)}%',
                    status: avgPercent >= 80 ? 'ระดับดีเยี่ยม' : 'ระดับปกติ',
                    color: const Color(0xFF0284C7),
                    bgTint: const Color(0xFFE0F2FE),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LearningScoreTile(
                    icon: Icons.grade_rounded,
                    label: 'รายวิชาที่มีคะแนน',
                    value: '$gradedCourseCount วิชา',
                    status: 'ยืนยันแล้ว',
                    color: const Color(0xFF059669),
                    bgTint: const Color(0xFFD1FAE5),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: content,
    );
  }
}

class LearningScoreTile extends StatelessWidget {
  const LearningScoreTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.color,
    required this.bgTint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color color;
  final Color bgTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolHeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.3;

    for (var x = -size.height; x < size.width; x += 92) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.58, size.height),
        linePaint,
      );
    }

    final glowPaint = Paint()
      ..color = SchoolPalette.yellow.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      44,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.86),
      56,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
