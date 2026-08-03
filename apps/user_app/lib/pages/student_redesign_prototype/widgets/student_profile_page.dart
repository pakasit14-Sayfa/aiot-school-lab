import 'package:flutter/material.dart';

import 'student_dashboard_models.dart';
import 'student_redesign_palette.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = StudentProfileState.mock;
    final participationPercent = (profile.submittedTasks / profile.totalTasks)
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 14),
                  _MetricGrid(
                    children: [
                      _MetricCard(
                        icon: Icons.verified_rounded,
                        iconColor: SchoolPalette.green,
                        label: 'G-Score',
                        value: '${profile.gscoreValue}/${profile.gscoreMax}',
                        caption: profile.gradeLabel,
                      ),
                      _MetricCard(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'GPA',
                        value: profile.gpa.toStringAsFixed(2),
                        caption: profile.gpaLabel,
                      ),
                      _MetricCard(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'ส่งงาน',
                        value:
                            '${profile.submittedTasks}/${profile.totalTasks}',
                        caption: 'ครบแล้ว ${profile.submittedTasks} งาน',
                      ),
                      _MetricCard(
                        icon: Icons.trending_up_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        label: 'การมีส่วนร่วม',
                        value: '${(participationPercent * 100).round()}%',
                        caption: 'สม่ำเสมอระดับดี',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ActivityCard(
                    yearLabel: 'ปีการศึกษา 2569',
                    streakDays: 24,
                    participationPercent: participationPercent,
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'DETAILS',
                    children: [
                      _DetailRow(label: 'Student ID', value: 'AIOT-5-012'),
                      _DividerLine(),
                      _DetailRow(label: 'Class', value: profile.gradeLevel),
                      _DividerLine(),
                      _DetailRow(label: 'School', value: profile.schoolName),
                      _DividerLine(),
                      const _DetailRow(
                        label: 'Advisor',
                        value: 'ครูสมชาย สายวิทย์',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'HELP',
                    children: const [
                      _MenuTile(
                        icon: Icons.tips_and_updates_rounded,
                        title: 'Tips and Tricks',
                        subtitle: 'เคล็ดลับการใช้งานและการเรียนให้ลื่นขึ้น',
                      ),
                      _DividerLine(),
                      _MenuTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Frequently Asked Questions',
                        subtitle: 'คำถามที่พบบ่อยเกี่ยวกับบัญชีและชั้นเรียน',
                      ),
                      _DividerLine(),
                      _MenuTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Contact Us',
                        subtitle: 'ติดต่อทีมงานหรือแจ้งปัญหา',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'SETTINGS',
                    children: const [
                      _MenuTile(
                        icon: Icons.person_rounded,
                        title: 'Personal Details',
                        subtitle: 'แก้ไขชื่อ ห้องเรียน โรงเรียน และรูปโปรไฟล์',
                      ),
                      _DividerLine(),
                      _MenuTile(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        subtitle: 'เลือกสิ่งที่อยากให้แจ้งเตือน',
                      ),
                      _DividerLine(),
                      _MenuTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy & PDPA',
                        subtitle: 'สิทธิ์การใช้ข้อมูลและการยินยอม',
                      ),
                      _DividerLine(),
                      _MenuTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign out',
                        subtitle: 'ออกจากระบบบนอุปกรณ์นี้',
                        danger: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final StudentProfileState profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE4EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF2FB), Color(0xFFD9E6F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD9E2EC)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF334155),
              size: 52,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${profile.gradeLevel} • ${profile.schoolName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Text(
              profile.gradeLabel,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.42,
      children: children,
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
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.yearLabel,
    required this.streakDays,
    required this.participationPercent,
  });

  final String yearLabel;
  final int streakDays;
  final double participationPercent;

  @override
  Widget build(BuildContext context) {
    final levels = _buildHeatmapLevels();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EAF1)),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'การมีส่วนร่วมในการเรียน',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE4EAF1)),
                ),
                child: Text(
                  yearLabel,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'สรุปการใช้งานและการเรียนต่อเนื่องของนักเรียน',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ParticipationStat(
                label: 'วันต่อเนื่อง',
                value: '$streakDays วัน',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _ParticipationStat(
                label: 'สม่ำเสมอ',
                value: '${(participationPercent * 100).round()}%',
                icon: Icons.bar_chart_rounded,
                color: SchoolPalette.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HeatmapGrid(levels: levels),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Less',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              for (final color in _heatmapLegendColors)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                ),
              const Spacer(),
              const Text(
                'More',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'เป้าหมายปีนี้: เก็บ G-Score 92+ และส่งงานครบ',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipationStat extends StatelessWidget {
  const _ParticipationStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4EAF1)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            .clamp(10.0, 20.0);

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
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EAF1)),
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
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
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
    final iconColor = danger
        ? const Color(0xFFDC2626)
        : const Color(0xFF334155);
    final titleColor = danger
        ? const Color(0xFFDC2626)
        : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4EAF1)),
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
                    color: Color(0xFF64748B),
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
            color: Color(0xFF7C808E),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
  return base;
}

const List<Color> _heatmapColors = <Color>[
  Color(0xFFF1F5F9),
  Color(0xFFDDF4E8),
  Color(0xFFB9EFCF),
  Color(0xFF67D68D),
  Color(0xFF2EA85B),
];

const List<Color> _heatmapLegendColors = <Color>[
  Color(0xFFF1F5F9),
  Color(0xFFDDF4E8),
  Color(0xFFB9EFCF),
  Color(0xFF67D68D),
  Color(0xFF2EA85B),
];
