import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_assignments_page.dart';

class AcademyTasksDueCard extends StatelessWidget {
  const AcademyTasksDueCard({super.key});

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
              child: const Row(
                children: [
                  Text(
                    'ดูทั้งหมด (3)',
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
        const TaskItemTile(
          title: 'ใบงานทดลอง AIoT เซนเซอร์วัดแสง',
          subject: 'วิชา AIoT สมาร์ตแล็บ (ม.5/1)',
          dueDate: 'ส่งวันนี้ 16:30 น. (เหลือ 3 ชม.)',
          urgencyColor: Color(0xFFE11D48),
          urgencyBg: Color(0xFFFFE4E6),
          subjectIcon: Icons.memory_rounded,
          navigateToCourses: true,
        ),
        const SizedBox(height: 10),
        const TaskItemTile(
          title: 'สรุปผลกิจกรรมการวัดค่า PM2.5 ในห้องเรียน',
          subject: 'วิชา วิทยาศาสตร์กายภาพ',
          dueDate: 'ส่งวันนี้ ภายใน 23:59 น.',
          urgencyColor: Color(0xFFEA580C),
          urgencyBg: Color(0xFFFFEDD5),
          subjectIcon: Icons.science_rounded,
          navigateToCourses: true,
        ),
        const SizedBox(height: 10),
        const TaskItemTile(
          title: 'แบบฝึกหัดทบทวนบทที่ 3 การวิเคราะห์ข้อมูล',
          subject: 'วิชา คณิตศาสตร์เพิ่มเติม',
          dueDate: 'กำหนดส่ง พรุ่งนี้ 12:00 น.',
          urgencyColor: Color(0xFF0284C7),
          urgencyBg: Color(0xFFE0F2FE),
          subjectIcon: Icons.calculate_rounded,
          navigateToCourses: true,
        ),
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
