import 'package:flutter/material.dart';
import '../../student/course_list_page.dart';
import '../../student/grades_overview_page.dart';
import 'student_redesign_palette.dart';
import 'student_assignments_page.dart';
import 'student_lessons_page.dart';

class AcademyQuickActions extends StatelessWidget {
  const AcademyQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'เมนูด่วน',
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
                  MaterialPageRoute(builder: (_) => const CourseListPage()),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 540;

            final items = [
              AcademyActionTile(
                icon: Icons.menu_book_rounded,
                title: 'บทเรียน',
                subtitle: 'เรียนต่อ 5 บท',
                color: Color(0xFF0284C7),
                bgTint: Color(0xFFF0F9FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentLessonsPage(),
                    ),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.assignment_rounded,
                title: 'ใบงาน',
                subtitle: '2 งานด่วน',
                badgeCount: '2',
                color: Color(0xFFEA580C),
                bgTint: Color(0xFFFFF7ED),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentAssignmentsPage(),
                    ),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.bar_chart_rounded,
                title: 'คะแนน',
                subtitle: 'ยืนยันแล้ว',
                color: Color(0xFFD97706),
                bgTint: Color(0xFFFFFBEB),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GradesOverviewPage(),
                    ),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.quiz_rounded,
                title: 'สอบก่อนเรียนและหลังเรียน',
                subtitle: 'ประเมินผล',
                color: SchoolPalette.green,
                bgTint: Color(0xFFECFDF5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourseListPage()),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.auto_stories_rounded,
                title: 'คลังความรู้',
                subtitle: 'สื่อ & เอกสาร',
                color: Color(0xFF0D9488),
                bgTint: Color(0xFFF0FDFA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourseListPage()),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.calendar_month_rounded,
                title: 'ปฏิทิน',
                subtitle: 'กิจกรรมโรงเรียน',
                color: Color(0xFF7C3AED),
                bgTint: Color(0xFFF5F3FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourseListPage()),
                  );
                },
              ),
            ];

            if (isMobile) {
              // Mobile View: 2 columns x 3 rows (spacious, zero truncation)
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: items[0]),
                      const SizedBox(width: 10),
                      Expanded(child: items[1]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: items[2]),
                      const SizedBox(width: 10),
                      Expanded(child: items[3]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: items[4]),
                      const SizedBox(width: 10),
                      Expanded(child: items[5]),
                    ],
                  ),
                ],
              );
            }

            // Desktop / Tablet View: 3 columns x 2 rows
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: 10),
                    Expanded(child: items[1]),
                    const SizedBox(width: 10),
                    Expanded(child: items[2]),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: items[3]),
                    const SizedBox(width: 10),
                    Expanded(child: items[4]),
                    const SizedBox(width: 10),
                    Expanded(child: items[5]),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class AcademyActionTile extends StatelessWidget {
  const AcademyActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgTint,
    this.badgeCount,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgTint;
  final String? badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap:
              onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('กำลังเปิด: $title'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4.5,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.75),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 12,
                  top: 10,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bgTint,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SchoolPalette.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              if (badgeCount != null) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    badgeCount!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
