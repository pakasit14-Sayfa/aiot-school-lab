import 'package:flutter/material.dart';
import 'student_lessons_page.dart';
import 'student_assignments_page.dart';

class StudentCourseCatalogCarouselPage extends StatefulWidget {
  const StudentCourseCatalogCarouselPage({super.key});

  @override
  State<StudentCourseCatalogCarouselPage> createState() =>
      _StudentCourseCatalogCarouselPageState();
}

class _StudentCourseCatalogCarouselPageState
    extends State<StudentCourseCatalogCarouselPage> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _activePageIndex = 0;
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'วิชาทั้งหมด (5)',
    'กำลังเรียนอยู่ (3)',
    'มีงานต้องส่ง (2)',
  ];

  final List<CarouselCourseItem> _courses = [
    const CarouselCourseItem(
      code: 'AIOT-501',
      title: 'วิชา AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
      teacher: 'ครูสมชาย สายวิทย์',
      studentsCount: '32 คน',
      progress: 0.60,
      progressText: '60%',
      urgentBadge: '🔴 2 งานค้างส่ง',
      badgeBg: Color(0xFFE11D48),
      nextLesson: 'บทที่ 13 การวัดค่าฝุ่น PM2.5',
      gradient: [Color(0xFF0F3E33), Color(0xFF10B981)],
      icon: Icons.memory_rounded,
    ),
    const CarouselCourseItem(
      code: 'PHYS-302',
      title: 'วิชา ฟิสิกส์ประยุกต์และการทดลอง',
      teacher: 'ครูวิภาดา วิทยาศาสตร์',
      studentsCount: '30 คน',
      progress: 0.85,
      progressText: '85%',
      urgentBadge: '🟢 งานส่งครบแล้ว',
      badgeBg: Color(0xFF059669),
      nextLesson: 'บทที่ 18 คลื่นและแสงประยุกต์',
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      icon: Icons.bolt_rounded,
    ),
    const CarouselCourseItem(
      code: 'MATH-401',
      title: 'วิชา คณิตศาสตร์เพิ่มเติม (สถิติและพีชคณิต)',
      teacher: 'ครูอนันต์ คำนวณ',
      studentsCount: '35 คน',
      progress: 0.40,
      progressText: '40%',
      urgentBadge: '🔵 1 งานกำลังทำ',
      badgeBg: Color(0xFF0284C7),
      nextLesson: 'บทที่ 9 การวิเคราะห์ความน่าจะเป็น',
      gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      icon: Icons.calculate_rounded,
    ),
    const CarouselCourseItem(
      code: 'SCI-204',
      title: 'วิชา วิทยาศาสตร์กายภาพและสิ่งแวดล้อม',
      teacher: 'ครูพรทิพย์ อนุรักษ์',
      studentsCount: '31 คน',
      progress: 0.90,
      progressText: '90%',
      urgentBadge: '🔴 1 งานค้างส่ง',
      badgeBg: Color(0xFFE11D48),
      nextLesson: 'บทที่ 19 สภาพภูมิอากาศเมือง',
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      icon: Icons.science_rounded,
    ),
    const CarouselCourseItem(
      code: 'BIO-105',
      title: 'วิชา ชีววิทยาและการสังเคราะห์แสง',
      teacher: 'ครูนภา ชีวิน',
      studentsCount: '28 คน',
      progress: 0.75,
      progressText: '75%',
      urgentBadge: '⭐ ตรวจแล้ว (A+)',
      badgeBg: Color(0xFFD97706),
      nextLesson: 'บทที่ 16 โครงสร้างเซลล์พืช',
      gradient: [Color(0xFFEA580C), Color(0xFFC2410C)],
      icon: Icons.nature_people_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'คอร์สเรียนสไลเดอร์ 🎠',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _buildPrototypeBanner(context),
              ),
              const SizedBox(height: 6),
              _buildHeaderSection(),
              const SizedBox(height: 16),
              // Interactive Course Carousel Slider
              _buildCarouselSlider(),
              const SizedBox(height: 12),
              _buildPageIndicator(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterPills(),
                    const SizedBox(height: 16),
                    _buildQuickSubjectGrid(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
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
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.0),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_rounded, size: 15, color: Color(0xFFEA580C)),
          SizedBox(width: 6),
          Text(
            '🧪 โต๊ะลองงาน · หน้ารวมวิชาแบบที่ 4: Interactive Course Carousel (สไลด์การ์ด App Store Style)',
            style: TextStyle(
              color: Color(0xFFC2410C),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'คอร์สเรียนสัปดาห์นี้ 🎠',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'ปาดเลื่อนสไลด์ซ้าย-ขวาเพื่อเลือกเข้าเรียนรายวิชา',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return SizedBox(
      height: 310,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _courses.length,
        onPageChanged: (index) {
          setState(() => _activePageIndex = index);
        },
        itemBuilder: (context, index) {
          final item = _courses[index];
          final isSelected = index == _activePageIndex;

          return AnimatedScale(
            scale: isSelected ? 1.0 : 0.94,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: item.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.gradient.first.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Watermark Background Icon
                    Positioned(
                      right: -15,
                      bottom: -15,
                      child: Icon(
                        item.icon,
                        size: 170,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                child: Text(
                                  item.code,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: item.badgeBg,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1F000000),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  item.urgentBadge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ผู้สอน: ${item.teacher} · ${item.studentsCount}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Progress Bar Component
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: item.progress,
                                    minHeight: 7,
                                    backgroundColor: Colors.white24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.progressText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const StudentAssignmentsPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.assignment_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text('ดูการบ้าน'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white38,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const StudentLessonsPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 20,
                                  ),
                                  label: const Text('เข้าเรียน'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF0F172A),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_courses.length, (index) {
        final isSelected = index == _activePageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F3E33)
                : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_filters[index]),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12,
              ),
              selectedColor: const Color(0xFF0F3E33),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F3E33)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (selected) {
                setState(() => _selectedFilterIndex = index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickSubjectGrid() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _courses[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.gradient.first.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.gradient.first, size: 22),
            ),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${item.code} · ${item.teacher}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentLessonsPage()),
              );
            },
          ),
        );
      },
    );
  }
}

class CarouselCourseItem {
  const CarouselCourseItem({
    required this.code,
    required this.title,
    required this.teacher,
    required this.studentsCount,
    required this.progress,
    required this.progressText,
    required this.urgentBadge,
    required this.badgeBg,
    required this.nextLesson,
    required this.gradient,
    required this.icon,
  });

  final String code;
  final String title;
  final String teacher;
  final String studentsCount;
  final double progress;
  final String progressText;
  final String urgentBadge;
  final Color badgeBg;
  final String nextLesson;
  final List<Color> gradient;
  final IconData icon;
}
