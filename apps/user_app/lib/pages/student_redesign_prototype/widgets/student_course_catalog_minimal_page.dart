import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_lessons_page.dart';
import 'student_assignments_page.dart';

class StudentCourseCatalogMinimalPage extends StatefulWidget {
  const StudentCourseCatalogMinimalPage({super.key});

  @override
  State<StudentCourseCatalogMinimalPage> createState() =>
      _StudentCourseCatalogMinimalPageState();
}

class _StudentCourseCatalogMinimalPageState
    extends State<StudentCourseCatalogMinimalPage> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'ทั้งหมด (5)',
    'เทคโนโลยี (2)',
    'วิทย์ (2)',
    'คณิต (1)',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'รายวิชาของฉัน',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isDesktop = screenWidth >= 1024;
                final horizontalPadding = screenWidth < 520 ? 14.0 : 20.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 960 : 680),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrototypeBanner(context),
                        const SizedBox(height: 14),
                        _buildMinimalHeader(context),
                        const SizedBox(height: 16),
                        _buildFilterPills(),
                        const SizedBox(height: 16),
                        _buildMinimalCourseList(),
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
            '🧪 โต๊ะลองงาน · หน้ารวมวิชาแบบที่ 2: Minimalist iOS Clean',
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

  Widget _buildMinimalHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'รายวิชาทั้งหมด 📚',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '5 วิชา · ภาคเรียนที่ 1',
              style: TextStyle(
                color: SchoolPalette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search Box iOS Pill Style
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'ค้นหาวิชา รหัสวิชา หรือผู้สอน...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
            ),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF10B981),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_categories[index]),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12,
              ),
              selectedColor: const Color(0xFF0F172A),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F172A)
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

  Widget _buildMinimalCourseList() {
    final courses = [
      const MinimalCourseCardItem(
        code: 'AIOT-501',
        title: 'วิชา AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
        teacher: 'ครูสมชาย สายวิทย์',
        studentsCount: '32 คน',
        accentColor: Color(0xFF10B981),
        accentBg: Color(0xFFECFDF5),
        icon: Icons.memory_rounded,
        progress: 0.60,
        progressPercent: '60%',
        urgentBadge: '🔴 2 งานค้าง',
        badgeColor: Color(0xFFE11D48),
        badgeBg: Color(0xFFFFE4E6),
      ),
      const MinimalCourseCardItem(
        code: 'PHYS-302',
        title: 'วิชา ฟิสิกส์ประยุกต์และการทดลอง',
        teacher: 'ครูวิภาดา วิทยาศาสตร์',
        studentsCount: '30 คน',
        accentColor: Color(0xFF0284C7),
        accentBg: Color(0xFFF0F9FF),
        icon: Icons.bolt_rounded,
        progress: 0.85,
        progressPercent: '85%',
        urgentBadge: '🟢 ส่งครบแล้ว',
        badgeColor: Color(0xFF059669),
        badgeBg: Color(0xFFECFDF5),
      ),
      const MinimalCourseCardItem(
        code: 'MATH-401',
        title: 'วิชา คณิตศาสตร์เพิ่มเติม (สถิติและพีชคณิต)',
        teacher: 'ครูอนันต์ คำนวณ',
        studentsCount: '35 คน',
        accentColor: Color(0xFF7C3AED),
        accentBg: Color(0xFFF5F3FF),
        icon: Icons.calculate_rounded,
        progress: 0.40,
        progressPercent: '40%',
        urgentBadge: '🔵 1 กำลังทำ',
        badgeColor: Color(0xFF0284C7),
        badgeBg: Color(0xFFE0F2FE),
      ),
      const MinimalCourseCardItem(
        code: 'SCI-204',
        title: 'วิชา วิทยาศาสตร์กายภาพและสิ่งแวดล้อม',
        teacher: 'ครูพรทิพย์ อนุรักษ์',
        studentsCount: '31 คน',
        accentColor: Color(0xFF059669),
        accentBg: Color(0xFFECFDF5),
        icon: Icons.science_rounded,
        progress: 0.90,
        progressPercent: '90%',
        urgentBadge: '🔴 1 งานค้าง',
        badgeColor: Color(0xFFE11D48),
        badgeBg: Color(0xFFFFE4E6),
      ),
      const MinimalCourseCardItem(
        code: 'BIO-105',
        title: 'วิชา ชีววิทยาและการสังเคราะห์แสง',
        teacher: 'ครูนภา ชีวิน',
        studentsCount: '28 คน',
        accentColor: Color(0xFFEA580C),
        accentBg: Color(0xFFFFF7ED),
        icon: Icons.nature_people_rounded,
        progress: 0.75,
        progressPercent: '75%',
        urgentBadge: '⭐ ตรวจแล้ว A+',
        badgeColor: Color(0xFFD97706),
        badgeBg: Color(0xFFFFFBEB),
      ),
    ];

    return Column(
      children: courses.map((card) {
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: card);
      }).toList(),
    );
  }
}

class MinimalCourseCardItem extends StatelessWidget {
  const MinimalCourseCardItem({
    super.key,
    required this.code,
    required this.title,
    required this.teacher,
    required this.studentsCount,
    required this.accentColor,
    required this.accentBg,
    required this.icon,
    required this.progress,
    required this.progressPercent,
    required this.urgentBadge,
    required this.badgeColor,
    required this.badgeBg,
  });

  final String code;
  final String title;
  final String teacher;
  final String studentsCount;
  final Color accentColor;
  final Color accentBg;
  final IconData icon;
  final double progress;
  final String progressPercent;
  final String urgentBadge;
  final Color badgeColor;
  final Color badgeBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentLessonsPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left Icon Pastel Box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(width: 14),
                // Center Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              urgentBadge,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$teacher · $studentsCount',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Compact Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFF1F5F9),
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            progressPercent,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
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
                  color: Color(0xFFCBD5E1),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
