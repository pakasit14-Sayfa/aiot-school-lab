import 'package:flutter/material.dart';

import 'student_dashboard_models.dart';
import 'student_redesign_palette.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({
    super.key,
    this.onViewScore,
    this.onViewAssignments,
  });

  /// Navigates to the full "คะแนน" tab — wired by the shell so the G-Score
  /// and GPA metric cards can act as "ดูข้อมูลทั้งหมด" buttons.
  final VoidCallback? onViewScore;

  /// Navigates to the full "ใบงาน" tab from the ส่งงาน metric card.
  final VoidCallback? onViewAssignments;

  @override
  Widget build(BuildContext context) {
    const profile = StudentProfileState.mock;
    final participationPercent = profile.taskCompletionPercent;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            if (isDesktop) {
              return _ProfileDesktopLayout(
                profile: profile,
                participationPercent: participationPercent,
                onViewScore: onViewScore,
                onViewAssignments: onViewAssignments,
              );
            }

            return _ProfileMobileLayout(
              profile: profile,
              participationPercent: participationPercent,
              onViewScore: onViewScore,
              onViewAssignments: onViewAssignments,
            );
          },
        ),
      ),
    );
  }
}

class _ProfileMobileLayout extends StatelessWidget {
  const _ProfileMobileLayout({
    required this.profile,
    required this.participationPercent,
    this.onViewScore,
    this.onViewAssignments,
  });

  final StudentProfileState profile;
  final double participationPercent;
  final VoidCallback? onViewScore;
  final VoidCallback? onViewAssignments;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              _ProfileCard(profile: profile),
              const SizedBox(height: 12),
              _MetricGrid(
                profile: profile,
                participationPercent: participationPercent,
                onViewScore: onViewScore,
                onViewAssignments: onViewAssignments,
              ),
              const SizedBox(height: 12),
              _ActivityCard(
                yearLabel: 'ปีการศึกษา 2569',
                streakDays: 24,
                participationPercent: participationPercent,
                badgesCount: profile.badgesCount,
                badgeTitle: profile.badgeTitle,
              ),
              const SizedBox(height: 12),
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
                children: const [
                  _MenuTile(
                    icon: Icons.person_rounded,
                    title: 'ข้อมูลส่วนตัว',
                    subtitle: 'แก้ไขชื่อ ห้องเรียน โรงเรียน และรูปโปรไฟล์',
                  ),
                  _DividerLine(),
                  _MenuTile(
                    icon: Icons.notifications_rounded,
                    title: 'การแจ้งเตือน',
                    subtitle: 'เลือกสิ่งที่อยากให้แจ้งเตือน',
                  ),
                  _DividerLine(),
                  // PLACEHOLDER — ยังไม่มี flow จริง (แค่ snackbar ทั่วไปแบบ
                  // เดียวกับเมนูอื่นในหน้านี้) ต่างจากเมนูอื่นตรงที่หัวข้อนี้
                  // พาดพิงสิทธิ์ข้อมูลของผู้เยาว์โดยตรง (CON-3/4/5) ห้าม
                  // rewrite เข้าหน้าจริงโดยคิดว่า flow นี้ผ่านแล้ว ต้องสร้าง
                  // หน้าจริงที่แสดงสถานะ/ประวัติความยินยอมก่อน
                  _MenuTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'ความเป็นส่วนตัวและ PDPA',
                    subtitle: 'สิทธิ์การใช้ข้อมูลและการยินยอม',
                  ),
                  _DividerLine(),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    title: 'ออกจากระบบ',
                    subtitle: 'ออกจากระบบบนอุปกรณ์นี้',
                    danger: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDesktopLayout extends StatelessWidget {
  const _ProfileDesktopLayout({
    required this.profile,
    required this.participationPercent,
    this.onViewScore,
    this.onViewAssignments,
  });

  final StudentProfileState profile;
  final double participationPercent;
  final VoidCallback? onViewScore;
  final VoidCallback? onViewAssignments;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileCard(profile: profile, isDesktop: true),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MetricGrid(
                          profile: profile,
                          participationPercent: participationPercent,
                          onViewScore: onViewScore,
                          onViewAssignments: onViewAssignments,
                        ),
                        const SizedBox(height: 14),
                        _ActivityCard(
                          yearLabel: 'ปีการศึกษา 2569',
                          streakDays: 24,
                          participationPercent: participationPercent,
                          badgesCount: profile.badgesCount,
                          badgeTitle: profile.badgeTitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _SectionCard(
                          title: 'ช่วยเหลือ',
                          icon: Icons.support_agent_rounded,
                          children: const [
                            _MenuTile(
                              icon: Icons.tips_and_updates_rounded,
                              title: 'เคล็ดลับการใช้งาน',
                              subtitle:
                                  'เคล็ดลับการใช้งานและการเรียนให้ลื่นขึ้น',
                            ),
                            _DividerLine(),
                            _MenuTile(
                              icon: Icons.help_outline_rounded,
                              title: 'คำถามที่พบบ่อย',
                              subtitle:
                                  'คำถามที่พบบ่อยเกี่ยวกับบัญชีและชั้นเรียน',
                            ),
                            _DividerLine(),
                            _MenuTile(
                              icon: Icons.mail_outline_rounded,
                              title: 'ติดต่อทีมงาน',
                              subtitle: 'ติดต่อทีมงานหรือแจ้งปัญหา',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'ตั้งค่า',
                          icon: Icons.settings_rounded,
                          children: const [
                            _MenuTile(
                              icon: Icons.person_rounded,
                              title: 'ข้อมูลส่วนตัว',
                              subtitle:
                                  'แก้ไขชื่อ ห้องเรียน โรงเรียน และรูปโปรไฟล์',
                            ),
                            _DividerLine(),
                            _MenuTile(
                              icon: Icons.notifications_rounded,
                              title: 'การแจ้งเตือน',
                              subtitle: 'เลือกสิ่งที่อยากให้แจ้งเตือน',
                            ),
                            _DividerLine(),
                            // PLACEHOLDER — ยังไม่มี flow จริง (แค่ snackbar
                            // ทั่วไปแบบเดียวกับเมนูอื่นในหน้านี้) ต่างจากเมนู
                            // อื่นตรงที่หัวข้อนี้พาดพิงสิทธิ์ข้อมูลของผู้เยาว์
                            // โดยตรง (CON-3/4/5) ห้าม rewrite เข้าหน้าจริง
                            // โดยคิดว่า flow นี้ผ่านแล้ว ต้องสร้างหน้าจริงที่
                            // แสดงสถานะ/ประวัติความยินยอมก่อน
                            _MenuTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'ความเป็นส่วนตัวและ PDPA',
                              subtitle: 'สิทธิ์การใช้ข้อมูลและการยินยอม',
                            ),
                            _DividerLine(),
                            _MenuTile(
                              icon: Icons.logout_rounded,
                              title: 'ออกจากระบบ',
                              subtitle: 'ออกจากระบบบนอุปกรณ์นี้',
                              danger: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unified profile identity card — avatar/name/badge merged with the
/// student detail rows so nothing competes for attention on desktop.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, this.isDesktop = false});

  final StudentProfileState profile;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
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

    final gradeBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFE8CE)),
      ),
      child: Text(
        profile.gradeLabel,
        style: const TextStyle(
          color: SchoolPalette.deepGreen,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
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
                profile.name,
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
                'นักเรียน • ${profile.schoolName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              gradeBadge,
            ],
          ),
        ),
      ],
    );

    final details = <Widget>[
      const _DetailRow(
        icon: Icons.badge_outlined,
        label: 'Student ID',
        value: 'AIOT-5-012',
      ),
      _DetailRow(
        icon: Icons.class_outlined,
        label: 'ชั้นเรียน',
        value: profile.gradeLevel,
      ),
      _DetailRow(
        icon: Icons.account_balance_outlined,
        label: 'โรงเรียน',
        value: profile.schoolName,
      ),
      const _DetailRow(
        icon: Icons.support_agent_outlined,
        label: 'ครูที่ปรึกษา',
        value: 'ครูสมชาย สายวิทย์',
      ),
    ];

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
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: identity),
                Container(
                  width: 1,
                  height: 96,
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  color: SchoolPalette.glassBorder,
                ),
                Expanded(
                  flex: 6,
                  child: Wrap(
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < details.length; i += 2)
                        Row(
                          children: [
                            Expanded(child: details[i]),
                            const SizedBox(width: 14),
                            Expanded(
                              child: i + 1 < details.length
                                  ? details[i + 1]
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 18),
                const Divider(height: 1, color: SchoolPalette.glassBorder),
                const SizedBox(height: 14),
                for (var i = 0; i < details.length; i++) ...[
                  details[i],
                  if (i != details.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.profile,
    required this.participationPercent,
    this.onViewScore,
    this.onViewAssignments,
  });

  final StudentProfileState profile;
  final double participationPercent;
  final VoidCallback? onViewScore;
  final VoidCallback? onViewAssignments;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        icon: Icons.verified_rounded,
        iconColor: SchoolPalette.deepGreen,
        label: 'G-Score',
        value: '${profile.gscoreValue}/${profile.gscoreMax}',
        caption: profile.gradeLabel,
        percent: profile.gscorePercent,
        onTap: onViewScore,
      ),
      _MetricCard(
        icon: Icons.star_rounded,
        iconColor: const Color(0xFFF59E0B),
        label: 'GPA',
        value: profile.gpa.toStringAsFixed(2),
        caption: profile.gpaLabel,
        percent: (profile.gpa / 4.0).clamp(0.0, 1.0),
        onTap: onViewScore,
      ),
      _MetricCard(
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF3B82F6),
        label: 'ส่งงาน',
        value: '${profile.submittedTasks}/${profile.totalTasks}',
        caption: 'ครบแล้ว ${profile.submittedTasks} งาน',
        percent: profile.taskCompletionPercent,
        onTap: onViewAssignments,
      ),
      _MetricCard(
        icon: Icons.trending_up_rounded,
        iconColor: const Color(0xFF8B5CF6),
        label: 'การมีส่วนร่วม',
        value: '${(participationPercent * 100).round()}%',
        caption: 'สม่ำเสมอระดับดี',
        percent: participationPercent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        if (isNarrow) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var index = 0; index < cards.length; index += 2) {
          rows.add(
            Row(
              children: [
                Expanded(child: cards[index]),
                const SizedBox(width: 10),
                Expanded(child: cards[index + 1]),
              ],
            ),
          );
          if (index + 2 < cards.length) {
            rows.add(const SizedBox(height: 10));
          }
        }

        return Column(children: rows);
      },
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.yearLabel,
    required this.streakDays,
    required this.participationPercent,
    required this.badgesCount,
    required this.badgeTitle,
  });

  final String yearLabel;
  final int streakDays;
  final double participationPercent;
  final int badgesCount;
  final String badgeTitle;

  @override
  Widget build(BuildContext context) {
    final levels = _buildHeatmapLevels();
    final percent = (participationPercent * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final isVeryWide = constraints.maxWidth >= 1080;

        final summaryPanel = _ActivitySummaryPanel(
          yearLabel: yearLabel,
          streakDays: streakDays,
          participationPercent: participationPercent,
        );
        final heatmapPanel = _ActivityHeatmapPanel(
          percent: percent,
          levels: levels,
        );
        final achievementPanel = _AchievementSummaryPanel(
          badgesCount: badgesCount,
          badgeTitle: badgeTitle,
        );

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
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
              const Text(
                'ภาพรวมการมีส่วนร่วม',
                style: TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (isVeryWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: summaryPanel),
                    const SizedBox(width: 14),
                    Expanded(flex: 5, child: heatmapPanel),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: achievementPanel),
                  ],
                )
              else if (isWide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: summaryPanel),
                    const SizedBox(width: 14),
                    Expanded(flex: 6, child: heatmapPanel),
                  ],
                ),
                const SizedBox(height: 14),
                achievementPanel,
              ] else ...[
                summaryPanel,
                const SizedBox(height: 14),
                heatmapPanel,
                const SizedBox(height: 14),
                achievementPanel,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActivitySummaryPanel extends StatelessWidget {
  const _ActivitySummaryPanel({
    required this.yearLabel,
    required this.streakDays,
    required this.participationPercent,
  });

  final String yearLabel;
  final int streakDays;
  final double participationPercent;

  @override
  Widget build(BuildContext context) {
    final percent = (participationPercent * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SchoolPalette.softGreenBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'สรุปพฤติกรรมการเรียน',
                  style: TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SchoolPalette.glassBorder),
                ),
                child: Text(
                  yearLabel,
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'การมีส่วนร่วมปีนี้',
            style: TextStyle(
              color: SchoolPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent%',
            style: const TextStyle(
              color: SchoolPalette.navy,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              color: const Color(0xFFE8EEF5),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: participationPercent.clamp(0, 1),
                child: Container(color: SchoolPalette.deepGreen),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CompactActivityValue(
                  label: 'วันต่อเนื่อง',
                  value: '$streakDays วัน',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _CompactActivityValue(
                  label: 'ส่งงาน',
                  value: '18/20',
                  color: Color(0xFF3B82F6),
                  icon: Icons.assignment_turned_in_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityHeatmapPanel extends StatelessWidget {
  const _ActivityHeatmapPanel({required this.percent, required this.levels});

  final int percent;
  final List<int> levels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ความสม่ำเสมอรายวัน',
                  style: TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$percent% สม่ำเสมอ',
                style: const TextStyle(
                  color: SchoolPalette.deepGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _HeatmapGrid(levels: levels),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'น้อย',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              for (final color in _heatmapLegendColors)
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                ),
              const Spacer(),
              const Text(
                'มาก',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Achievement / badge summary — third dashboard-style panel next to the
/// participation summary and heatmap.
class _AchievementSummaryPanel extends StatelessWidget {
  const _AchievementSummaryPanel({
    required this.badgesCount,
    required this.badgeTitle,
  });

  final int badgesCount;
  final String badgeTitle;

  @override
  Widget build(BuildContext context) {
    const medalColors = [
      Color(0xFFF59E0B),
      SchoolPalette.deepGreen,
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE9BE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ความสำเร็จ',
            style: TextStyle(
              color: SchoolPalette.navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$badgesCount แบดจ์',
                      style: const TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      badgeTitle,
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
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < medalColors.length; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == 3 ? 0 : 8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: medalColors[i].withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: medalColors[i].withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: medalColors[i],
                      size: 15,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactActivityValue extends StatelessWidget {
  const _CompactActivityValue({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.levels});

  final List<int> levels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 12;
        final cellSize = ((constraints.maxWidth - (columns - 1) * 4) / columns)
            .clamp(9.0, 13.0);

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: levels
              .map(
                (level) => Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: _heatmapColors[level],
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                ),
              )
              .toList(),
        );
      },
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final iconColor = danger ? const Color(0xFFDC2626) : SchoolPalette.navy;
    final titleColor = danger ? const Color(0xFFDC2626) : SchoolPalette.navy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                danger ? 'ออกจากระบบ (ตัวอย่างเท่านั้น)' : 'กำลังเปิด: $title',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
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
                      subtitle,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA9B4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: SchoolPalette.deepGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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

List<int> _buildHeatmapLevels() {
  const base = <int>[
    0,
    1,
    0,
    2,
    1,
    3,
    1,
    2,
    0,
    1,
    2,
    3,
    1,
    2,
    3,
    2,
    1,
    4,
    2,
    3,
    1,
    2,
    3,
    4,
    0,
    1,
    2,
    1,
    3,
    4,
    2,
    1,
    3,
    2,
    4,
    4,
    1,
    0,
    2,
    3,
    2,
    4,
    1,
    2,
    3,
    3,
    2,
    4,
    0,
    2,
    1,
    3,
    4,
    3,
    2,
    1,
    2,
    4,
    3,
    4,
    1,
    2,
    3,
    2,
    4,
    4,
    2,
    3,
    1,
    2,
    3,
    4,
    0,
    1,
    2,
    2,
    3,
    4,
    1,
    2,
    3,
    4,
    2,
    4,
  ];
  return List<int>.generate(126, (index) => base[index % base.length]);
}

const List<Color> _heatmapColors = <Color>[
  Color(0xFFF1F5F9),
  Color(0xFFDDF4E8),
  Color(0xFFB9EFCF),
  Color(0xFF67D68D),
  SchoolPalette.deepGreen,
];

const List<Color> _heatmapLegendColors = <Color>[
  Color(0xFFF1F5F9),
  Color(0xFFDDF4E8),
  Color(0xFFB9EFCF),
  Color(0xFF67D68D),
  SchoolPalette.deepGreen,
];
