import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../notifications_page.dart';
import 'student_empty_state.dart';
import 'student_redesign_palette.dart';
import 'aiot_weather_sensors_card.dart';
import 'school_encouragement_card.dart';
import 'school_utility_trend_card.dart';
import 'academy_quick_actions.dart';
import 'academy_continue_learning_card.dart';
import 'academy_tasks_due_card.dart';

class StudentVariantSchoolHome extends StatefulWidget {
  const StudentVariantSchoolHome({
    super.key,
    this.onViewScore,
    this.loadCourses,
    this.loadGrades,
    this.loadNotifications,
    this.loadLessons,
    this.loadAssignments,
    this.loadSubmissionVersions,
    this.sensorStreamOverride,
    this.rawReadingsStreamOverride,
    this.utilityCardBuilder,
    this.now,
  });

  /// Clock for the greeting; tests pin it, production leaves it null.
  final DateTime Function()? now;

  /// Lets the G-Score summary card open the full "คะแนน" page — the score
  /// snapshot lives on the home page since it updates daily, while the full
  /// breakdown is one tap away instead of living in the main nav.
  final VoidCallback? onViewScore;

  // Injectable seams so widget tests can control every data dependency of
  // _loadRealData() without initializing a real Supabase client. Each
  // defaults to the real service call used in production.
  /// Seams for the two live cards, so the whole home page can be pumped in
  /// a widget test (no realtime subscription, no UtilityService call).
  final Stream<SensorModel?>? sensorStreamOverride;
  final Stream<List<Map<String, dynamic>>>? rawReadingsStreamOverride;
  final Widget Function(double height)? utilityCardBuilder;

  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<CourseGrade>> Function()? loadGrades;
  final Future<List<AppNotification>> Function()? loadNotifications;
  final Future<List<LessonSummary>> Function(String courseId)? loadLessons;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignments;
  final Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadSubmissionVersions;

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
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadGrades = widget.loadGrades ?? GradeService.listMyGrades;
      final loadNotifications =
          widget.loadNotifications ?? NotificationService.listMyNotifications;
      final loadLessons = widget.loadLessons ?? LessonService.listLessons;
      final loadAssignments =
          widget.loadAssignments ?? AssignmentService.listAssignments;
      final loadSubmissionVersions =
          widget.loadSubmissionVersions ??
          AssignmentService.listMySubmissionVersions;

      final results = await Future.wait([
        loadCourses(),
        loadGrades(),
        loadNotifications(),
      ]);
      final courses = (results[0] as List<CourseSummary>)
          .where((c) => c.isActive)
          .toList();
      final grades = results[1] as List<CourseGrade>;
      final notifications = results[2] as List<AppNotification>;

      final lessonLists = await Future.wait(
        courses.map((c) => loadLessons(c.id)),
      );
      final assignmentLists = await Future.wait(
        courses.map((c) => loadAssignments(c.id)),
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
        publishedAssignments.map((e) => loadSubmissionVersions(e.$1.id)),
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
      // ข้อความ exception ดิบไปอยู่ใน log — บนจอนักเรียนต้องเป็นประโยคที่
      // อ่านรู้เรื่อง ไม่ใช่ PostgrestException/StateError ที่บอกอะไรเขาไม่ได้
      debugPrint('StudentVariantSchoolHome: โหลดข้อมูลหน้าแรกไม่สำเร็จ — $e');
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลหน้าแรกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
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
                    SchoolAnnouncementsCard(
                      notification: _latestNotification,
                      onViewed: () {
                        if (mounted) _loadRealData();
                      },
                    ),
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
    // Redesigned 2026-09-18 after the first look on a phone: the old Stack
    // let the mascot overlap the subtitle and pinned a white card by pixel
    // offsets, so on 390pt the text wrapped under the lion. Now it is a
    // plain Column — text and mascot share a Row (no overlap possible) and
    // the progress strip sits inside the gradient instead of floating over
    // it. Same three gradient tones as SchoolPalette.primaryGradient.
    final name = currentUserModel?.name ?? 'นักเรียน';
    final greeting = greetingForHour(
      (widget.now?.call() ?? DateTime.now()).hour,
    );
    final progress = _totalAssignments == 0
        ? 0.0
        : _submittedCount / _totalAssignments;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;
        final mascotSize = isCompact ? 104.0 : 150.0;
        final titleSize = isCompact ? 26.0 : 34.0;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: SchoolPalette.primaryGradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x26165042),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _SchoolHeroPatternPainter()),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 18 : 26,
                  isCompact ? 14 : 20,
                  isCompact ? 14 : 22,
                  isCompact ? 14 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroChip(label: '$greeting 👋'),
                              const SizedBox(height: 8),
                              Text(
                                '$name!',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'มาต่อบทเรียน AIoT และงานทดลองวันนี้กัน',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: isCompact ? 13.5 : 16,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeroMascot(size: mascotSize),
                      ],
                    ),
                    SizedBox(height: isCompact ? 10 : 16),
                    _HeroProgressStrip(
                      progress: progress,
                      lessonCount: _lessonCount,
                      submittedCount: _submittedCount,
                      totalAssignments: _totalAssignments,
                    ),
                  ],
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
              AiotWeatherSensorsCard(
                sensorStreamOverride: widget.sensorStreamOverride,
                rawReadingsStreamOverride: widget.rawReadingsStreamOverride,
              ),
              const SizedBox(height: 16),
              AcademyLearningScoreCard(
                onTap: onViewScore,
                avgPercent: _avgGradePercent,
                gradedCourseCount: _gradedCourseCount,
              ),
              const SizedBox(height: 16),
              const SchoolEncouragementCard(),
              const SizedBox(height: 16),
              widget.utilityCardBuilder?.call(utilityFullWidthHeight) ??
                  SchoolUtilityTrendCard(height: utilityFullWidthHeight),
            ],
          );
        }

        final scoreCardHeight = width >= 1100 ? 238.0 : 232.0;
        final encouragementCardHeight = width >= 1100 ? 192.0 : 186.0;
        // +90 กันการ์ดซ้าย overflow — ตอนนี้เป็น grid 4 แถว 8 ช่อง (PM2.5/
        // แสง/อุณหภูมิ/ความชื้น/AQI/แก๊ส/eCO2/TVOC) แต่ละช่องมีบรรทัด
        // "ออนไลน์ • ... ที่แล้ว" (freshness caption) เพิ่มมาด้วย ทำให้สูงกว่า
        // ตอนคำนวณสูตรนี้ครั้งแรก (ตอนนั้นยังเป็น list 4 แถวไม่มี freshness)
        final sensorCardHeight =
            scoreCardHeight + encouragementCardHeight + columnGap + 90;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: AiotWeatherSensorsCard(
                    height: sensorCardHeight,
                    sensorStreamOverride: widget.sensorStreamOverride,
                    rawReadingsStreamOverride: widget.rawReadingsStreamOverride,
                  ),
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
            widget.utilityCardBuilder?.call(utilityFullWidthHeight) ??
                SchoolUtilityTrendCard(height: utilityFullWidthHeight),
          ],
        );
      },
    );
  }
}

/// The "ข่าวสารประกาศโรงเรียน" section: header "ดูทั้งหมด" button and the
/// latest-announcement card, both of which open the real [NotificationsPage]
/// and report back via [onViewed] so the parent can run its own canonical
/// reload. Extracted into its own widget (instead of living inline on
/// StudentVariantSchoolHome's state) so both entry points are testable
/// without mounting the page's other real-time/device cards.
class SchoolAnnouncementsCard extends StatelessWidget {
  const SchoolAnnouncementsCard({
    super.key,
    required this.notification,
    required this.onViewed,
  });

  final AppNotification? notification;

  /// Called after the pushed [NotificationsPage] route has been popped —
  /// i.e. only once navigation has actually completed, never optimistically.
  final VoidCallback onViewed;

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  Future<void> _openInbox(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    onViewed();
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _openInbox(context),
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
          const StudentEmptyState(
            icon: Icons.campaign_rounded,
            title: 'ยังไม่มีประกาศ',
            hint: 'ข่าวสารจากโรงเรียนจะแสดงที่นี่',
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _openInbox(context),
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
                                notification!.title,
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
                              _timeAgo(notification!.createdAt),
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (notification!.body != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            notification!.body!,
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

  /// Opens the full "คะแนน" page (StudentScorePage — real GradeService/
  /// G-Score data).
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

/// Same buckets as the login page's greeting so the two screens never
/// disagree about the time of day.
String greetingForHour(int hour) {
  if (hour < 12) return 'สวัสดีตอนเช้า';
  if (hour < 17) return 'สวัสดีตอนบ่าย';
  return 'สวัสดีตอนเย็น';
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SchoolPalette.cream,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroMascot extends StatelessWidget {
  const _HeroMascot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget img(String asset, {Widget Function(BuildContext)? fallback}) =>
        Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: fallback == null
              ? null
              : (context, error, stackTrace) => fallback(context),
        );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: img(
        'assets/images/mascot_lion_anim.png',
        fallback: (_) => img(
          'assets/images/mascot_lion_anim.gif',
          fallback: (_) => img('assets/images/mascot_lion_clean.png'),
        ),
      ),
    );
  }
}

class _HeroProgressStrip extends StatelessWidget {
  const _HeroProgressStrip({
    required this.progress,
    required this.lessonCount,
    required this.submittedCount,
    required this.totalAssignments,
  });

  /// 0.0–1.0, submitted/total assignments across all courses.
  final double progress;
  final int lessonCount;
  final int submittedCount;
  final int totalAssignments;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    color: SchoolPalette.yellow,
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ความคืบหน้าการเรียน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _HeroStat(
                      icon: Icons.menu_book_rounded,
                      label: '$lessonCount บทเรียน',
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _HeroStat(
                        icon: Icons.task_alt_rounded,
                        label: 'ส่งแล้ว $submittedCount/$totalAssignments',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: SchoolPalette.cream),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
