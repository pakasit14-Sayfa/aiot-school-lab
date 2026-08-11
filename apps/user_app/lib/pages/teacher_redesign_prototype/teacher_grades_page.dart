// PROTOTYPE ONLY: "คะแนน" — mock overview of room grades (G-Score, average,
// per-assignment contribution). UI/UX only, mock data, no backend.

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

class _GradeContribution {
  const _GradeContribution({
    required this.title,
    required this.weightPercent,
    required this.avgScore,
    required this.color,
  });

  final String title;
  final double weightPercent;
  final double avgScore;
  final Color color;
}

const _contributions = [
  _GradeContribution(
    title: 'ใบงาน AIoT บทที่ 1-4',
    weightPercent: 0.30,
    avgScore: 0.82,
    color: TeacherPalette.primary,
  ),
  _GradeContribution(
    title: 'โครงงานเซนเซอร์ (PBL)',
    weightPercent: 0.35,
    avgScore: 0.76,
    color: TeacherPalette.skyDeep,
  ),
  _GradeContribution(
    title: 'แบบทดสอบย่อย',
    weightPercent: 0.20,
    avgScore: 0.68,
    color: TeacherPalette.orange,
  ),
  _GradeContribution(
    title: 'การมีส่วนร่วมในชั้นเรียน',
    weightPercent: 0.15,
    avgScore: 0.90,
    color: TeacherPalette.violet,
  ),
];

class TeacherGradesPage extends StatelessWidget {
  const TeacherGradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'คะแนน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = isDesktop ? 3 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isDesktop ? 1.6 : 1.3,
                  children: const [
                    TeacherStatCard(
                      label: 'G-Score เฉลี่ยห้อง',
                      value: '3.4',
                      icon: Icons.workspace_premium_rounded,
                      color: TeacherPalette.primary,
                    ),
                    TeacherStatCard(
                      label: 'คะแนนเฉลี่ย',
                      value: '78%',
                      icon: Icons.bar_chart_rounded,
                      color: TeacherPalette.skyDeep,
                    ),
                    TeacherStatCard(
                      label: 'งานที่มีผลต่อคะแนน',
                      value: '4 รายการ',
                      icon: Icons.checklist_rounded,
                      color: TeacherPalette.violet,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TeacherSectionCard(
              title: 'สัดส่วนคะแนนตามงาน',
              icon: Icons.pie_chart_rounded,
              child: Column(
                children: [
                  for (var i = 0; i < _contributions.length; i++) ...[
                    _ContributionRow(item: _contributions[i]),
                    if (i != _contributions.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TeacherSectionCard(
              title: 'ภาพรวมห้องเรียน',
              icon: Icons.groups_2_rounded,
              child: Column(
                children: const [
                  _RoomGradeRow(room: 'ม.5/1', course: 'AIOT-501', avg: 0.81),
                  Divider(height: 18, color: Color(0xFFE8EEF3)),
                  _RoomGradeRow(room: 'ม.6/2', course: 'PHYS-302', avg: 0.72),
                  Divider(height: 18, color: Color(0xFFE8EEF3)),
                  _RoomGradeRow(room: 'ม.4/3', course: 'BIO-204', avg: 0.85),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.item});

  final _GradeContribution item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              'สัดส่วน ${(item.weightPercent * 100).round()}%',
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'เฉลี่ย ${(item.avgScore * 100).round()}%',
              style: TextStyle(
                color: item.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.avgScore,
            minHeight: 7,
            backgroundColor: const Color(0xFFEAF2F8),
            valueColor: AlwaysStoppedAnimation(item.color),
          ),
        ),
      ],
    );
  }
}

class _RoomGradeRow extends StatelessWidget {
  const _RoomGradeRow({
    required this.room,
    required this.course,
    required this.avg,
  });

  final String room;
  final String course;
  final double avg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                course,
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${(avg * 100).round()}%',
          style: const TextStyle(
            color: TeacherPalette.primary,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
