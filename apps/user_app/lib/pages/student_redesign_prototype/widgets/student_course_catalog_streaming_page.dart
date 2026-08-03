import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_lessons_page.dart';

class StudentCourseCatalogStreamingPage extends StatefulWidget {
  const StudentCourseCatalogStreamingPage({super.key});

  @override
  State<StudentCourseCatalogStreamingPage> createState() =>
      _StudentCourseCatalogStreamingPageState();
}

class _StudentCourseCatalogStreamingPageState
    extends State<StudentCourseCatalogStreamingPage> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'วิชาทั้งหมด',
    'กำลังเรียนอยู่',
    'ยอดนิยมสูงสุด',
    'วิทยาศาสตร์ & AIoT',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'คอร์สเรียนสตรีมมิ่ง 🍿',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isDesktop = screenWidth >= 1024;
                final horizontalPadding = screenWidth < 520 ? 12.0 : 18.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1080 : 760),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrototypeBanner(context),
                        const SizedBox(height: 14),
                        _buildFeaturedPosterBanner(context),
                        const SizedBox(height: 20),
                        _buildCategoryTabs(),
                        const SizedBox(height: 16),
                        _buildStreamingGrid(screenWidth),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrototypeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.0),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_rounded, size: 15, color: Color(0xFF38BDF8)),
          SizedBox(width: 6),
          Text(
            '🧪 โต๊ะลองงาน · หน้ารวมวิชาแบบที่ 3: Streaming Media Cover Grid 🍿',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPosterBanner(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3310B981),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 0,
            top: 0,
            child: Center(
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/images/mascot_lion_clean.png',
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school_rounded,
                    size: 100,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Text(
                    '🔥 FEATURED COURSE · วิชาฮิตแนะนำประจำสัปดาห์',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'เรียนรู้การวัดค่าฝุ่น PM2.5 และเซนเซอร์สภาพอากาศ',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentLessonsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('▶️ เล่นบทเรียนต่อ (บทที่ 13)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_categories[index]),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12.5,
              ),
              selectedColor: const Color(0xFF38BDF8),
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF334155),
                ),
              ),
              onSelected: (selected) {
                setState(() => _selectedCategoryIndex = index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStreamingGrid(double screenWidth) {
    final courses = [
      const StreamingCourseCardItem(
        title: 'AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
        code: 'AIOT-501',
        teacher: 'ครูสมชาย สายวิทย์',
        progress: 0.60,
        progressText: '60%',
        badgeText: '🔴 2 งานค้าง',
        badgeBg: Color(0xFFE11D48),
        icon: Icons.memory_rounded,
        gradient: [Color(0xFF0F3E33), Color(0xFF10B981)],
      ),
      const StreamingCourseCardItem(
        title: 'ฟิสิกส์ประยุกต์และการทดลอง',
        code: 'PHYS-302',
        teacher: 'ครูวิภาดา วิทยาศาสตร์',
        progress: 0.85,
        progressText: '85%',
        badgeText: '🟢 งานครบ',
        badgeBg: Color(0xFF059669),
        icon: Icons.bolt_rounded,
        gradient: [Color(0xFF0369A1), Color(0xFF0284C7)],
      ),
      const StreamingCourseCardItem(
        title: 'คณิตศาสตร์เพิ่มเติม (สถิติ)',
        code: 'MATH-401',
        teacher: 'ครูอนันต์ คำนวณ',
        progress: 0.40,
        progressText: '40%',
        badgeText: '🔵 กำลังทำ',
        badgeBg: Color(0xFF0284C7),
        icon: Icons.calculate_rounded,
        gradient: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
      ),
      const StreamingCourseCardItem(
        title: 'วิทยาศาสตร์กายภาพและสิ่งแวดล้อม',
        code: 'SCI-204',
        teacher: 'ครูพรทิพย์ อนุรักษ์',
        progress: 0.90,
        progressText: '90%',
        badgeText: '🔴 1 งานค้าง',
        badgeBg: Color(0xFFE11D48),
        icon: Icons.science_rounded,
        gradient: [Color(0xFF047857), Color(0xFF10B981)],
      ),
    ];

    if (screenWidth >= 768) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: courses.map((card) {
          return SizedBox(
            width: (screenWidth >= 1024 ? 1080 : 760) / 2 - 24,
            child: card,
          );
        }).toList(),
      );
    } else {
      return Column(
        children: courses.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: card,
          );
        }).toList(),
      );
    }
  }
}

class StreamingCourseCardItem extends StatelessWidget {
  const StreamingCourseCardItem({
    super.key,
    required this.title,
    required this.code,
    required this.teacher,
    required this.progress,
    required this.progressText,
    required this.badgeText,
    required this.badgeBg,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String code;
  final String teacher;
  final double progress;
  final String progressText;
  final String badgeText;
  final Color badgeBg;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Icon Pattern
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 140,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  teacher,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      progressText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentLessonsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('▶️ เล่นต่อ (เข้าเรียน)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
