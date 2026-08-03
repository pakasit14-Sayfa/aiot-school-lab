import 'package:flutter/material.dart';

/// การ์ดวิชาเรียน (Course Card) สำหรับนักเรียน
/// ออกแบบตามหลัก Student-Centric Material 3 & Modern EdTech Gamification
class CourseCard extends StatelessWidget {
  final String courseCode;
  final String courseTitle;
  final String teacherName;
  final int studentCount;
  final int pendingHomeworkCount;
  final int completedLessons;
  final int totalLessons;
  final String currentLessonTitle;
  final String streakBadgeText;
  final String estimatedTimeText;
  final String labStatusText;
  final VoidCallback? onHomeworkTap;
  final VoidCallback? onEnterLessonTap;
  final VoidCallback? onCurrentLessonTap;

  const CourseCard({
    super.key,
    this.courseCode = 'AIOT-501',
    this.courseTitle = 'วิชา AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
    this.teacherName = 'ครูสมชาย สายวิทย์',
    this.studentCount = 32,
    this.pendingHomeworkCount = 2,
    this.completedLessons = 12,
    this.totalLessons = 20,
    this.currentLessonTitle = 'บทที่ 13 การวัดค่าฝุ่น PM2.5',
    this.streakBadgeText = '🔥 เรียน 3 วันติด',
    this.estimatedTimeText = '⏱️ ~15 นาที',
    this.labStatusText = '🟢 แล็บพร้อมใช้',
    this.onHomeworkTap,
    this.onEnterLessonTap,
    this.onCurrentLessonTap,
  });

  double get progressPercentage =>
      totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;

  int get progressPercentInt => (progressPercentage * 100).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------
          // 1. Header Zone: Dark Teal/Forest Green Banner
          // -------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF063E36), Color(0xFF0B473E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Code Pill, Streak Badge & Pending Homework Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Chip Icon Box
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.developer_board_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Course Code Tag Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            courseCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Gamification Streak Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFDE68A).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            streakBadgeText,
                            style: const TextStyle(
                              color: Color(0xFFFEF08A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Urgent Homework Badge
                    if (pendingHomeworkCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFECDD3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE11D48),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$pendingHomeworkCount งานค้างส่ง',
                              style: const TextStyle(
                                color: Color(0xFFBE123C),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Course Title
                Text(
                  courseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle Meta: Teacher & Students + Lab Status
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$teacherName · $studentCount คน',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        labStatusText,
                        style: const TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------
          // 2. Body Zone: Progress & Current Lesson
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ความคืบหน้าการเรียน:',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$progressPercentInt% ($completedLessons/$totalLessons บทเรียน)',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress Bar with Gradient Tint
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressPercentage,
                    minHeight: 11,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 18),

                // Interactive Next Lesson Container (High-converting UI)
                Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onCurrentLessonTap ?? onEnterLessonTap,
                    highlightColor: const Color(0xFFE2E8F0),
                    splashColor: const Color(0xFF059669).withValues(alpha: 0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF059669),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentLessonTitle,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  estimatedTimeText,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'เรียนต่อ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // 3. Action Footer Row
                // -------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Homework Button with Clear Count Badge
                    OutlinedButton.icon(
                      onPressed: onHomeworkTap,
                      icon: const Icon(
                        Icons.assignment_outlined,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                      label: Text(
                        pendingHomeworkCount > 0
                            ? 'ดูการบ้าน ($pendingHomeworkCount)'
                            : 'ดูการบ้าน',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    // Primary Prominent Filled Capsule Button: Enter Class
                    ElevatedButton(
                      onPressed: onEnterLessonTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF063E36),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'เข้าเรียนเลย',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
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
