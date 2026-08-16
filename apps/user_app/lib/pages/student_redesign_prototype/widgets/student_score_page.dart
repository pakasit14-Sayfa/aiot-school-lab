import 'package:flutter/material.dart';

import 'student_dashboard_models.dart';
import 'student_redesign_palette.dart';

/// UI-only prototype for the student "คะแนน" tab.
/// Deliberately separates academic subject grades ("คะแนนเรียน") from the
/// behavioral / participation G-Score so the two concepts never blur.
class StudentScorePage extends StatelessWidget {
  const StudentScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = StudentProfileState.mock;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'คะแนนของฉัน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        // Align(topCenter) not Center() — Center() vertically centers the
        // whole scroll view when content is shorter than the viewport,
        // making the page look like it "shrinks to the middle" instead of
        // staying pinned to the top.
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 18,
                    16,
                    isDesktop ? 24 : 18,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ScoreSummaryRow(profile: profile, isWide: isDesktop),
                      const SizedBox(height: 16),
                      isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: _SubjectGradesCard()),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _GScoreTrendCard(profile: profile),
                                      const SizedBox(height: 16),
                                      _BadgeGridCard(profile: profile),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SubjectGradesCard(),
                                const SizedBox(height: 16),
                                _GScoreTrendCard(profile: profile),
                                const SizedBox(height: 16),
                                _BadgeGridCard(profile: profile),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScoreSummaryRow extends StatelessWidget {
  const _ScoreSummaryRow({required this.profile, required this.isWide});

  final StudentProfileState profile;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final gpaCard = _SummaryHeroCard(
      title: 'คะแนนเรียน (GPA)',
      subtitle: 'ค่าเฉลี่ยผลการเรียนสะสมทุกวิชา',
      value: profile.gpa.toStringAsFixed(2),
      valueSuffix: '/ 4.00',
      percent: (profile.gpa / 4.0).clamp(0.0, 1.0),
      badgeText: profile.gpaLabel,
      icon: Icons.menu_book_rounded,
      accent: const Color(0xFF3B82F6),
    );

    final gscoreCard = _SummaryHeroCard(
      title: 'G-Score (พฤติกรรม)',
      subtitle: profile.gscorePendingValue > 0
          ? 'วัดจากวินัย การมีส่วนร่วม และความรับผิดชอบ · '
                'รอครูยืนยันอีก ${profile.gscorePendingValue} คะแนน'
          : 'วัดจากวินัย การมีส่วนร่วม และความรับผิดชอบ',
      value: '${profile.gscoreValue}',
      valueSuffix: '/ ${profile.gscoreMax}',
      percent: profile.gscorePercent,
      badgeText: profile.gradeLabel,
      icon: Icons.verified_rounded,
      accent: SchoolPalette.deepGreen,
    );

    if (!isWide) {
      return Column(
        children: [gscoreCard, const SizedBox(height: 12), gpaCard],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: gscoreCard),
        const SizedBox(width: 14),
        Expanded(child: gpaCard),
      ],
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueSuffix,
    required this.percent,
    required this.badgeText,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String value;
  final String valueSuffix;
  final double percent;
  final String badgeText;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 7,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(icon, color: accent, size: 26),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      valueSuffix,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
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

class _SubjectGrade {
  const _SubjectGrade({
    required this.subject,
    required this.teacher,
    required this.grade,
    required this.percent,
    required this.color,
  });

  final String subject;
  final String teacher;
  final String grade;
  final double percent;
  final Color color;
}

const _subjectGrades = <_SubjectGrade>[
  _SubjectGrade(
    subject: 'AIoT สมาร์ตแล็บ',
    teacher: 'ครูสมชาย สายวิทย์',
    grade: '4.0',
    percent: 1.0,
    color: SchoolPalette.deepGreen,
  ),
  _SubjectGrade(
    subject: 'คณิตศาสตร์เพิ่มเติม',
    teacher: 'ครูวิภา จันทร์เพ็ญ',
    grade: '3.5',
    percent: 0.875,
    color: Color(0xFF3B82F6),
  ),
  _SubjectGrade(
    subject: 'ฟิสิกส์ประยุกต์',
    teacher: 'ครูอนุชา ทองดี',
    grade: '3.5',
    percent: 0.875,
    color: Color(0xFF8B5CF6),
  ),
  _SubjectGrade(
    subject: 'ภาษาอังกฤษเพื่อการสื่อสาร',
    teacher: 'ครูนภัสสร ทิพย์วงศ์',
    grade: '4.0',
    percent: 1.0,
    color: Color(0xFFF59E0B),
  ),
  _SubjectGrade(
    subject: 'ชีววิทยาและสิ่งแวดล้อม',
    teacher: 'ครูสมชาย สายวิทย์',
    grade: '3.75',
    percent: 0.9375,
    color: Color(0xFF06B6D4),
  ),
];

class _SubjectGradesCard extends StatelessWidget {
  const _SubjectGradesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              const Text(
                'คะแนนเรียนรายวิชา',
                style: TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${_subjectGrades.length} วิชา',
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _subjectGrades.length; i++) ...[
            _SubjectGradeRow(grade: _subjectGrades[i]),
            if (i != _subjectGrades.length - 1)
              const Divider(height: 20, color: Color(0xFFE8EEF3)),
          ],
        ],
      ),
    );
  }
}

class _SubjectGradeRow extends StatelessWidget {
  const _SubjectGradeRow({required this.grade});

  final _SubjectGrade grade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: grade.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            grade.grade,
            style: TextStyle(
              color: grade.color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                grade.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                grade.teacher,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 5,
                  color: const Color(0xFFE8EEF5),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: grade.percent.clamp(0.0, 1.0),
                    child: Container(color: grade.color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GScoreTrendCard extends StatelessWidget {
  const _GScoreTrendCard({required this.profile});

  final StudentProfileState profile;

  static const _trend = <double>[0.62, 0.7, 0.68, 0.8, 0.86, 0.92];
  static const _trendLabels = <String>[
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: SchoolPalette.deepGreen,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'แนวโน้ม G-Score รายเดือน',
                  style: TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _trend.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == _trend.length - 1 ? 0 : 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: _trend[i],
                                widthFactor: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: i == _trend.length - 1
                                        ? SchoolPalette.deepGreen
                                        : SchoolPalette.deepGreen.withValues(
                                            alpha: 0.28,
                                          ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _trendLabels[i],
                            style: const TextStyle(
                              color: SchoolPalette.muted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

class _BadgeGridCard extends StatelessWidget {
  const _BadgeGridCard({required this.profile});

  final StudentProfileState profile;

  static const _badges = <(IconData, String, Color)>[
    (Icons.military_tech_rounded, 'ผู้เชี่ยวชาญ AIoT', Color(0xFFF59E0B)),
    (Icons.eco_rounded, 'นักอนุรักษ์สิ่งแวดล้อม', SchoolPalette.deepGreen),
    (Icons.bolt_rounded, 'ส่งงานตรงเวลา 10 ครั้ง', Color(0xFF3B82F6)),
    (Icons.groups_rounded, 'ผู้นำทีมโครงงาน', Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'แบดจ์และความสำเร็จ',
                  style: TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${profile.badgesCount} รวม',
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final (icon, label, color) = _badges[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
