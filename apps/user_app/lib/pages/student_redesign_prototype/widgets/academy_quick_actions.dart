import 'dart:ui';
import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_assignments_page.dart';
import 'student_lessons_page.dart';
import 'student_score_page.dart';
import 'student_course_files_page.dart';
import 'student_calendar_page.dart';
import 'student_pretest_posttest_page.dart';
import '../student_safety_page.dart';

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
                  MaterialPageRoute(builder: (_) => const StudentLessonsPage()),
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
                color: const Color(0xFF0284C7),
                bgTint: const Color(0xFFF0F9FF),
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
                color: const Color(0xFFEA580C),
                bgTint: const Color(0xFFFFF7ED),
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
                color: const Color(0xFFD97706),
                bgTint: const Color(0xFFFFFBEB),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentScorePage()),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.quiz_rounded,
                title: 'สอบก่อนเรียนและหลังเรียน',
                subtitle: 'ประเมินผล',
                color: const Color.fromARGB(255, 28, 127, 70),
                bgTint: const Color(0xFFF0FDF4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentPretestPosttestPage(),
                    ),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.auto_stories_rounded,
                title: 'คลังความรู้',
                subtitle: 'สื่อ & เอกสาร',
                color: const Color(0xFF0D9488),
                bgTint: const Color(0xFFF0FDFA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentCourseFilesPage(),
                    ),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.calendar_month_rounded,
                title: 'ปฏิทิน',
                subtitle: 'กิจกรรมโรงเรียน',
                color: const Color(0xFF7C3AED),
                bgTint: const Color(0xFFF5F3FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentCalendarPage(),
                    ),
                  );
                },
              ),
              AcademyActionTile(
                icon: Icons.shield_rounded,
                title: 'แจ้งเหตุ / SOS',
                subtitle: 'ความปลอดภัยห้องเรียน',
                color: const Color(0xFFEF4444),
                bgTint: const Color(0xFFFEF2F2),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentSafetyPage(),
                    ),
                  );
                },
              ),
            ];

            if (isMobile) {
              // Mobile View: 2 columns dynamic rows grid (spacious, zero truncation)
              final List<Widget> rows = [];
              for (int i = 0; i < items.length; i += 2) {
                if (i + 1 < items.length) {
                  rows.add(
                    Row(
                      children: [
                        Expanded(child: items[i]),
                        const SizedBox(width: 10),
                        Expanded(child: items[i + 1]),
                      ],
                    ),
                  );
                } else {
                  rows.add(
                    Row(
                      children: [
                        Expanded(child: items[i]),
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  );
                }
                if (i + 2 < items.length) {
                  rows.add(const SizedBox(height: 10));
                }
              }
              return Column(children: rows);
            }

            // Desktop / Tablet View: 3 columns dynamic rows grid
            final List<Widget> rows = [];
            for (int i = 0; i < items.length; i += 3) {
              final List<Widget> rowItems = [];
              for (int j = 0; j < 3; j++) {
                if (i + j < items.length) {
                  rowItems.add(Expanded(child: items[i + j]));
                } else {
                  rowItems.add(const Expanded(child: SizedBox.shrink()));
                }
                if (j < 2) {
                  rowItems.add(const SizedBox(width: 10));
                }
              }
              rows.add(Row(children: rowItems));
              if (i + 3 < items.length) {
                rows.add(const SizedBox(height: 10));
              }
            }
            return Column(children: rows);
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
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
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFC7C7CC),
                        size: 18,
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
