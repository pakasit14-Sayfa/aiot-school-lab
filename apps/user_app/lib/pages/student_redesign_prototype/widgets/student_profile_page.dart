import 'package:flutter/material.dart';

import 'student_dashboard_models.dart';
import 'student_redesign_palette.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = StudentProfileState.mock;

    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.92),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 14),
                  _DarkActionCard(
                    title: 'Activity Status',
                    leading: const Icon(
                      Icons.run_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    trailing: const _StatusChip(
                      color: Color(0xFF22C55E),
                      label: 'Active',
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Profile connected · ',
                          style: TextStyle(
                            color: Color(0xFFB9BCC6),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'พร้อมใช้งาน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _DarkSection(
                    title: 'PERSONALIZE',
                    children: [
                      _DarkMenuTile(
                        icon: Icons.person_rounded,
                        title: 'Personal Details',
                        subtitle: 'แก้ไขชื่อ ห้องเรียน โรงเรียน และรูปโปรไฟล์',
                      ),
                      _DarkDivider(),
                      _DarkMenuTile(
                        icon: Icons.military_tech_rounded,
                        title: 'Academic Snapshot',
                        subtitle: 'G-Score, GPA, แบดจ์ และความคืบหน้า',
                      ),
                      _DarkDivider(),
                      _DarkMenuTile(
                        icon: Icons.assignment_turned_in_rounded,
                        title: 'Learning Progress',
                        subtitle: 'บทเรียนล่าสุดและงานที่กำลังจะถึงกำหนด',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DarkSection(
                    title: 'DETAILS',
                    children: [
                      _DarkDetailRow(label: 'Student ID', value: 'AIOT-5-012'),
                      _DarkDivider(),
                      _DarkDetailRow(label: 'Class', value: profile.gradeLevel),
                      _DarkDivider(),
                      _DarkDetailRow(
                        label: 'School',
                        value: profile.schoolName,
                      ),
                      _DarkDivider(),
                      _DarkDetailRow(
                        label: 'Advisor',
                        value: 'ครูสมชาย สายวิทย์',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DarkSection(
                    title: 'HELP',
                    children: const [
                      _DarkMenuTile(
                        icon: Icons.tips_and_updates_rounded,
                        title: 'Tips and Tricks',
                        subtitle: 'เคล็ดลับการใช้งานและการเรียนให้ลื่นขึ้น',
                      ),
                      _DarkDivider(),
                      _DarkMenuTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Frequently Asked Questions',
                        subtitle: 'คำถามที่พบบ่อยเกี่ยวกับบัญชีและชั้นเรียน',
                      ),
                      _DarkDivider(),
                      _DarkMenuTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Contact Us',
                        subtitle: 'ติดต่อทีมงานหรือแจ้งปัญหา',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DarkSection(
                    title: 'MEMBERSHIP',
                    children: [_MembershipPanel(profile: profile)],
                  ),
                  const SizedBox(height: 12),
                  _DarkSection(
                    title: 'SETTINGS',
                    children: const [
                      _DarkMenuTile(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        subtitle: 'เลือกสิ่งที่อยากให้แจ้งเตือน',
                      ),
                      _DarkDivider(),
                      _DarkMenuTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy & PDPA',
                        subtitle: 'สิทธิ์การใช้ข้อมูลและการยินยอม',
                      ),
                      _DarkDivider(),
                      _DarkMenuTile(
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
        color: const Color(0xFF17171C),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B3B44), Color(0xFF222227)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
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
              color: Color(0xFFB3B6C3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.verified_rounded,
                  label: profile.gradeLabel,
                  value: 'G-Score ${profile.gscoreValue}/${profile.gscoreMax}',
                  accent: SchoolPalette.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.workspace_premium_rounded,
                  label: profile.gpaLabel,
                  value: 'GPA ${profile.gpa.toStringAsFixed(2)}',
                  accent: const Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF23232A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9BA1AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkActionCard extends StatelessWidget {
  const _DarkActionCard({
    required this.title,
    required this.leading,
    required this.trailing,
    required this.child,
  });

  final String title;
  final Widget leading;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17171C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF26262C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: leading),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF23232A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkSection extends StatelessWidget {
  const _DarkSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF17171C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF8F95A3),
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

class _DarkMenuTile extends StatelessWidget {
  const _DarkMenuTile({
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
    final Color iconColor = danger ? const Color(0xFFF87171) : Colors.white;
    final Color titleColor = danger ? const Color(0xFFFCA5A5) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF23232A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                    color: Color(0xFF9BA1AF),
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

class _DarkDetailRow extends StatelessWidget {
  const _DarkDetailRow({required this.label, required this.value});

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
                color: Color(0xFF8F95A3),
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
                color: Colors.white,
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

class _DarkDivider extends StatelessWidget {
  const _DarkDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 18,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _MembershipPanel extends StatelessWidget {
  const _MembershipPanel({required this.profile});

  final StudentProfileState profile;

  @override
  Widget build(BuildContext context) {
    const learning = ContinueLearningState.mock;
    final tasks = TaskItemState.mockList.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricPill(
                icon: Icons.school_rounded,
                label: 'G-Score',
                value: '${profile.gscoreValue}/${profile.gscoreMax}',
                accent: SchoolPalette.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricPill(
                icon: Icons.star_rounded,
                label: 'GPA',
                value: profile.gpa.toStringAsFixed(2),
                accent: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricPill(
                icon: Icons.menu_book_rounded,
                label: 'บทเรียน',
                value: '${learning.completedLessons}/${learning.totalLessons}',
                accent: const Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricPill(
                icon: Icons.emoji_events_rounded,
                label: 'แบดจ์',
                value: '${profile.badgesCount}',
                accent: const Color(0xFFA78BFA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          learning.courseTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          learning.chapterTitle,
          style: const TextStyle(
            color: Color(0xFF9BA1AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TaskRow(task: task),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF23232A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8F95A3),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final TaskItemState task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF23232A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text(task.avatarEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.dueTimeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9BA1AF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: task.priorityColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              task.priorityLabel,
              style: TextStyle(
                color: task.priorityColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
