import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../login_page.dart';
import 'student_redesign_palette.dart';

/// เดิมหน้านี้มี G-Score/GPA/สตรีค/heatmap กิจกรรม 126 วัน/แบดจ์ ทั้งหมด
/// ไม่มี backend รองรับเลย (ไม่มี GScoreService, ไม่มี activity-log service,
/// ไม่มีระบบแบดจ์) ตัดออกทั้งหมด เหลือแค่ข้อมูลจริงที่มี: ชื่อ/อีเมลจาก
/// currentUserModel, ชั้นเรียนจากวิชาที่ลงทะเบียน, จำนวนงานที่ส่งแล้วจาก
/// AssignmentService, คะแนนเฉลี่ยจาก GradeService, และปุ่มออกจากระบบจริง
class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({
    super.key,
    this.onViewScore,
    this.onViewAssignments,
    this.loadCourses,
    this.loadGrades,
    this.loadAssignmentsForCourse,
    this.loadSubmissionVersions,
    this.signOut,
  });

  final VoidCallback? onViewScore;
  final VoidCallback? onViewAssignments;

  /// Read/write seams threaded to the corresponding CourseService/
  /// GradeService/AssignmentService/AuthService static calls in
  /// production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<CourseGrade>> Function()? loadGrades;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse;
  final Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadSubmissionVersions;
  final Future<void> Function()? signOut;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _loading = true;
  String? _error;
  String? _gradeLevel;
  int _submittedCount = 0;
  int _totalAssignments = 0;
  double _avgGradePercent = 0;
  int _gradedCourseCount = 0;

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
      final loadGrades = widget.loadGrades ?? GradeService.listMyGrades;
      final loadAssignments =
          widget.loadAssignmentsForCourse ?? AssignmentService.listAssignments;
      final loadVersions = widget.loadSubmissionVersions ??
          AssignmentService.listMySubmissionVersions;

      final results = await Future.wait([loadCourses(), loadGrades()]);
      final courses = (results[0] as List<CourseSummary>)
          .where((c) => c.isActive)
          .toList();
      final grades = results[1] as List<CourseGrade>;

      final assignmentLists = await Future.wait(
        courses.map((c) => loadAssignments(c.id)),
      );
      final published = <AssignmentSummary>[];
      for (final list in assignmentLists) {
        published.addAll(list.where((a) => a.isPublished));
      }
      final submissionChecks = await Future.wait(
        published.map((a) => loadVersions(a.id)),
      );
      final submittedCount = submissionChecks.where((v) => v.isNotEmpty).length;

      final confirmedGrades = grades.where((g) => g.confirmedAt != null);
      final avgPercent = confirmedGrades.isEmpty
          ? 0.0
          : confirmedGrades.map((g) => g.percent).reduce((a, b) => a + b) /
                confirmedGrades.length;

      if (!mounted) return;
      setState(() {
        _gradeLevel = courses.isEmpty ? null : courses.first.gradeLevel;
        _submittedCount = submittedCount;
        _totalAssignments = published.length;
        _avgGradePercent = avgPercent;
        _gradedCourseCount = confirmedGrades.length;
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

  Future<void> _signOut() async {
    final doSignOut = widget.signOut ?? AuthService.signOut;
    await doSignOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              if (isDesktop) {
                return _ProfileDesktopLayout(
                  state: this,
                  onViewScore: widget.onViewScore,
                  onViewAssignments: widget.onViewAssignments,
                );
              }
              return _ProfileMobileLayout(
                state: this,
                onViewScore: widget.onViewScore,
                onViewAssignments: widget.onViewAssignments,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileMobileLayout extends StatelessWidget {
  const _ProfileMobileLayout({
    required this.state,
    this.onViewScore,
    this.onViewAssignments,
  });

  final _StudentProfilePageState state;
  final VoidCallback? onViewScore;
  final VoidCallback? onViewAssignments;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              if (state._error != null) ...[
                _ErrorBanner(message: state._error!, onRetry: state._load),
                const SizedBox(height: 12),
              ],
              const _ProfileCard(),
              const SizedBox(height: 12),
              _MetricGrid(
                state: state,
                onViewScore: onViewScore,
                onViewAssignments: onViewAssignments,
              ),
              const SizedBox(height: 12),
              _buildMenuSections(context, state),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDesktopLayout extends StatelessWidget {
  const _ProfileDesktopLayout({
    required this.state,
    this.onViewScore,
    this.onViewAssignments,
  });

  final _StudentProfilePageState state;
  final VoidCallback? onViewScore;
  final VoidCallback? onViewAssignments;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state._error != null) ...[
                _ErrorBanner(message: state._error!, onRetry: state._load),
                const SizedBox(height: 12),
              ],
              const _ProfileCard(isDesktop: true),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _MetricGrid(
                      state: state,
                      onViewScore: onViewScore,
                      onViewAssignments: onViewAssignments,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: _buildMenuSections(context, state)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildMenuSections(
  BuildContext context,
  _StudentProfilePageState state,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionCard(
        title: 'ช่วยเหลือ',
        icon: Icons.support_agent_rounded,
        children: const [
          _MenuTile(
            icon: Icons.tips_and_updates_rounded,
            title: 'เคล็ดลับการใช้งาน',
            subtitle: 'เคล็ดลับการใช้งานและการเรียนให้ลื่นขึ้น',
          ),
          _DividerLine(),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            title: 'คำถามที่พบบ่อย',
            subtitle: 'คำถามที่พบบ่อยเกี่ยวกับบัญชีและชั้นเรียน',
          ),
          _DividerLine(),
          _MenuTile(
            icon: Icons.mail_outline_rounded,
            title: 'ติดต่อทีมงาน',
            subtitle: 'ติดต่อทีมงานหรือแจ้งปัญหา',
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'ตั้งค่า',
        icon: Icons.settings_rounded,
        children: [
          const _MenuTile(
            icon: Icons.notifications_rounded,
            title: 'การแจ้งเตือน',
            subtitle: 'เลือกสิ่งที่อยากให้แจ้งเตือน',
          ),
          const _DividerLine(),
          // ยังไม่มีหน้าจริงแสดงสถานะ/ประวัติความยินยอม (CON-3/4/5) —
          // ห้ามทำเป็นแค่ snackbar แล้วคิดว่า flow นี้ผ่านแล้ว
          const _MenuTile(
            icon: Icons.lock_outline_rounded,
            title: 'ความเป็นส่วนตัวและ PDPA',
            subtitle: 'สิทธิ์การใช้ข้อมูลและการยินยอม',
          ),
          const _DividerLine(),
          _MenuTile(
            icon: Icons.logout_rounded,
            title: 'ออกจากระบบ',
            subtitle: 'ออกจากระบบบนอุปกรณ์นี้',
            danger: true,
            onTap: state._signOut,
          ),
        ],
      ),
    ],
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}

/// การ์ดข้อมูลตัวตน — เหลือแค่ชื่อ/อีเมล/ชั้นเรียนที่มีข้อมูลจริงรองรับ
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({this.isDesktop = false});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final avatar = Container(
      width: isDesktop ? 84 : 92,
      height: isDesktop ? 84 : 92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SchoolPalette.deepGreen.withValues(alpha: 0.14),
            SchoolPalette.green.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Icon(
        Icons.person_rounded,
        color: SchoolPalette.deepGreen,
        size: isDesktop ? 42 : 48,
      ),
    );

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user?.name ?? 'นักเรียน',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user?.email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: identity,
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.state,
    this.onViewScore,
    this.onViewAssignments,
  });

  final _StudentProfilePageState state;
  final VoidCallback? onViewScore;
  final VoidCallback? onViewAssignments;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        icon: Icons.grade_rounded,
        iconColor: SchoolPalette.deepGreen,
        label: 'คะแนนเฉลี่ย',
        value: state._loading
            ? '—'
            : '${state._avgGradePercent.toStringAsFixed(0)}%',
        caption: '${state._gradedCourseCount} วิชายืนยันแล้ว',
        percent: state._avgGradePercent / 100,
        onTap: onViewScore,
      ),
      _MetricCard(
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF3B82F6),
        label: 'ส่งงาน',
        value: state._loading
            ? '—'
            : '${state._submittedCount}/${state._totalAssignments}',
        caption: state._gradeLevel != null
            ? 'ชั้น ${state._gradeLevel}'
            : 'ทุกวิชาที่ลงทะเบียน',
        percent: state._totalAssignments == 0
            ? 0
            : state._submittedCount / state._totalAssignments,
        onTap: onViewAssignments,
      ),
    ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.caption,
    required this.percent,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;
  final double percent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTappable = onTap != null;

    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolPalette.glassBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SchoolPalette.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 6,
                          color: const Color(0xFFE8EEF5),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: percent.clamp(0.0, 1.0),
                            child: Container(color: iconColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isTappable)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFB6C0CC),
                              size: 16,
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
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Row(
              children: [
                Icon(icon, size: 15, color: SchoolPalette.deepGreen),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ไม่มี onTap = ยังไม่มีหน้าจริง/ยังไม่ได้ต่อ backend — ปิดการกดไปเลย
    // และบอกไว้ที่ตัวรายการ แทนการปล่อยให้กดได้แล้วค่อยขึ้น snackbar
    final enabled = onTap != null;
    const disabledColor = Color(0xFF9CA9B4);
    final iconColor = !enabled
        ? disabledColor
        : (danger ? const Color(0xFFDC2626) : SchoolPalette.navy);
    final titleColor = !enabled
        ? disabledColor
        : (danger ? const Color(0xFFDC2626) : SchoolPalette.navy);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SchoolPalette.glassBorder),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? subtitle : '$subtitle · ยังไม่เปิดใช้งาน',
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: const Color(0xFF9CA9B4),
                size: enabled ? 22 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 18, thickness: 1, color: Color(0xFFE8EEF3));
  }
}
