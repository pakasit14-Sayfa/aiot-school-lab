// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// STK-2: ดูคะแนน/ผลการเรียนของบุตร (read-only) — BR2 สำคัญที่สุดของหน้านี้:
// เห็นเฉพาะคะแนนที่ครูยืนยันแล้วเท่านั้น (ไม่เห็นคะแนนที่ AI เสนอไว้แต่ครู
// ยังไม่ยืนยัน) ทุกรายวิชาในหน้านี้จึงต้องมีสถานะ "ยืนยันแล้ว" กำกับไว้
// ให้เห็นชัดว่าไม่มีคะแนนดิบ/คะแนนชั่วคราวหลุดมา

import 'package:flutter/material.dart';

import 'parent_shared_widgets.dart';

class _SubjectGradeMock {
  const _SubjectGradeMock({
    required this.subject,
    required this.teacher,
    required this.score,
    required this.maxScore,
    required this.gradeLabel,
  });

  final String subject;
  final String teacher;
  final double score;
  final double maxScore;
  final String gradeLabel;
}

const _mockGrades = [
  _SubjectGradeMock(
    subject: 'AIoT สมาร์ตแล็บ',
    teacher: 'ครูสมชาย สายวิทย์',
    score: 86,
    maxScore: 100,
    gradeLabel: 'ดีเยี่ยม',
  ),
  _SubjectGradeMock(
    subject: 'ฟิสิกส์ประยุกต์',
    teacher: 'ครูวิจิตร แจ่มใส',
    score: 74,
    maxScore: 100,
    gradeLabel: 'ดี',
  ),
  _SubjectGradeMock(
    subject: 'ชีววิทยา',
    teacher: 'ครูปราณี รักเรียน',
    score: 68,
    maxScore: 100,
    gradeLabel: 'พอใช้',
  ),
];

class ParentGradesPage extends StatelessWidget {
  const ParentGradesPage({super.key, required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    final overallPercent =
        _mockGrades.map((g) => g.score / g.maxScore).reduce((a, b) => a + b) /
        _mockGrades.length;

    return ParentMockPageShell(
      title: 'ผลการเรียน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              childName,
              style: const TextStyle(
                color: ParentTheme.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ParentGlassCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: overallPercent,
                          strokeWidth: 5,
                          backgroundColor: ParentTheme.border,
                          valueColor: const AlwaysStoppedAnimation(
                            ParentTheme.primaryTeal,
                          ),
                        ),
                        Text(
                          '${(overallPercent * 100).round()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'คะแนนเฉลี่ยรวม',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: ParentTheme.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'เฉพาะคะแนนที่ครูยืนยันแล้วเท่านั้น',
                          style: TextStyle(
                            color: ParentTheme.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final grade in _mockGrades) ...[
              _GradeRow(grade: grade),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});

  final _SubjectGradeMock grade;

  @override
  Widget build(BuildContext context) {
    return ParentGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: ParentTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  grade.teacher,
                  style: const TextStyle(
                    color: ParentTheme.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: ParentTheme.safeGreen,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ครูยืนยันแล้ว',
                      style: TextStyle(
                        color: ParentTheme.safeGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${grade.score.toStringAsFixed(0)}/${grade.maxScore.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: ParentTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              ParentStatusChip(
                label: grade.gradeLabel,
                color: ParentTheme.primaryTeal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
