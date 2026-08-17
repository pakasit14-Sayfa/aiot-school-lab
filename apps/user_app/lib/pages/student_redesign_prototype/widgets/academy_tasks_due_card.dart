import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_assignments_page.dart';

class UpcomingTask {
  const UpcomingTask({
    required this.title,
    required this.courseLabel,
    required this.dueAt,
  });

  final String title;
  final String courseLabel;
  final DateTime dueAt;
}

class AcademyTasksDueCard extends StatelessWidget {
  const AcademyTasksDueCard({super.key, required this.tasks});

  /// Top upcoming (by dueAt) published assignments across all courses —
  /// caller already limits this to a small number (e.g. 3).
  final List<UpcomingTask> tasks;

  static ({Color color, Color bg}) _urgencyFor(DateTime dueAt) {
    final hoursLeft = dueAt.difference(DateTime.now()).inHours;
    if (hoursLeft <= 24) {
      return (color: const Color(0xFFE11D48), bg: const Color(0xFFFFE4E6));
    }
    if (hoursLeft <= 72) {
      return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFEDD5));
    }
    return (color: const Color(0xFF0284C7), bg: const Color(0xFFE0F2FE));
  }

  static String _formatDue(DateTime dueAt) {
    final now = DateTime.now();
    final diff = dueAt.difference(now);
    final sameDay =
        dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day;
    final timeLabel =
        '${dueAt.hour.toString().padLeft(2, '0')}:${dueAt.minute.toString().padLeft(2, '0')} น.';
    if (diff.isNegative) return 'เลยกำหนดส่งแล้ว';
    if (sameDay) return 'ส่งวันนี้ $timeLabel';
    if (diff.inDays <= 1) return 'ส่งพรุ่งนี้ $timeLabel';
    return 'กำหนดส่งอีก ${diff.inDays} วัน';
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
                'งานที่กำลังจะมาถึง',
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
                  MaterialPageRoute(
                    builder: (_) => const StudentAssignmentsPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: SchoolPalette.green,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    'ดูทั้งหมด (${tasks.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          const SoftCard(
            padding: EdgeInsets.all(16),
            child: Text(
              'ไม่มีงานใกล้ครบกำหนดตอนนี้',
              style: TextStyle(color: SchoolPalette.muted, fontSize: 12.5),
            ),
          )
        else
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final task = tasks[i];
                final urgency = _urgencyFor(task.dueAt);
                return TaskItemTile(
                  title: task.title,
                  subject: task.courseLabel,
                  dueDate: _formatDue(task.dueAt),
                  urgencyColor: urgency.color,
                  urgencyBg: urgency.bg,
                  subjectIcon: Icons.assignment_rounded,
                  navigateToCourses: true,
                );
              },
            ),
          ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class TaskItemTile extends StatelessWidget {
  const TaskItemTile({
    super.key,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.urgencyColor,
    required this.urgencyBg,
    required this.subjectIcon,
    this.navigateToCourses = false,
    this.onTap,
  });

  final String title;
  final String subject;
  final String dueDate;
  final Color urgencyColor;
  final Color urgencyBg;
  final IconData subjectIcon;
  final bool navigateToCourses;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap:
            onTap ??
            () {
              if (navigateToCourses) {
                // การ์ดนี้คืองานค้างส่ง กดแล้วควรไปหน้าใบงาน ไม่ใช่หน้า
                // รายวิชาที่ไม่เกี่ยวข้องกันเลย (บั๊กเดิม)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentAssignmentsPage(),
                  ),
                );
              }
            },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: urgencyColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(subjectIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              // Middle Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: urgencyColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dueDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: urgencyColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC7C7CC),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
