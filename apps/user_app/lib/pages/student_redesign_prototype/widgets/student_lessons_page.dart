import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';

class StudentLessonsPage extends StatefulWidget {
  const StudentLessonsPage({super.key});

  @override
  State<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends State<StudentLessonsPage> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'บทเรียนทั้งหมด (20)',
    'กำลังเรียน (3)',
    'เรียนจบแล้ว (12)',
    'สื่อการสอน & เอกสาร (5)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'บทเรียนและคอร์สเรียน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
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
                final horizontalPadding = screenWidth < 520 ? 12.0 : 16.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 720),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVibrantHeroHeader(context),
                        const SizedBox(height: 16),
                        _buildFilterPills(),
                        const SizedBox(height: 16),
                        _buildLessonList(),
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
            '🧪 โต๊ะลองงาน · หน้าบทเรียน (ธีมสีสดใสพรีเมียม สบายตาน่าเรียน)',
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

  Widget _buildVibrantHeroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D9488), // Deep Teal
            Color(0xFF059669), // Emerald
            Color(0xFF10B981), // Bright Mint Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3310B981),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.28,
              child: Image.asset(
                'assets/images/mascot_lion_clean.png',
                height: 155,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          Column(
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
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'รหัสวิชา: AIOT-501 · ม.5/1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF08A),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1F000000), blurRadius: 8),
                      ],
                    ),
                    child: const Text(
                      '🌟 คอร์สยอดนิยม ภาคเรียนที่ 1',
                      style: TextStyle(
                        color: Color(0xFF854D0E),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'วิชา AIoT สมาร์ตแล็บเพื่อการเรียนรู้ 🤖',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ผู้สอน: ครูสมชาย สายวิทย์ · เรียนรู้เซนเซอร์ สภาพอากาศ และการเขียนโปรแกรม',
                style: TextStyle(
                  color: Color(0xFFECFDF5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Progress Bar Component with Glow
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'ความคืบหน้าการเรียนวิชานี้',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '60% (12/20 บทเรียนสำเร็จ)',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        value: 0.60,
                        minHeight: 9,
                        backgroundColor: Colors.white24,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📄 เปิดเอกสารแผนการสอนประจำวิชา'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text('ดาวน์โหลดแผนการสอน'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎥 กำลังโหลดวิดีโอแนะนำรายวิชา 4K'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 18,
                      color: Color(0xFF065F46),
                    ),
                    label: const Text('วิดีโอแนะนำวิชา'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF065F46),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
                color: isSelected ? Colors.white : SchoolPalette.ink,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12.5,
              ),
              selectedColor: const Color(0xFF059669),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF059669)
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

  Widget _buildLessonList() {
    final lessons = [
      const LessonCardItem(
        chapterNumber: 'บทที่ 13',
        title: 'การเชื่อมต่อเซนเซอร์วัดค่าฝุ่น PM2.5 และการประมวลผล',
        duration: '45 นาที',
        typeTag: 'วิดีโอ 4K + โมเดล 3D 🧊',
        statusText: 'กำลังเรียน 🔵 (65%)',
        statusColor: Color(0xFF0284C7),
        statusBg: Color(0xFFE0F2FE),
        progressValue: 0.65,
        gscorePoints: '⭐ +15 G-Score',
        isActive: true,
      ),
      const LessonCardItem(
        chapterNumber: 'บทที่ 14',
        title: 'การอ่านค่าเซนเซอร์แสงและส่งข้อมูลเรียลไทม์เข้า Dashboard',
        duration: '30 นาที',
        typeTag: 'เอกสาร PDF + โค้ดตัวอย่าง 💻',
        statusText: 'บทเรียนถัดไป 🟠',
        statusColor: Color(0xFFD97706),
        statusBg: Color(0xFFFFFBEB),
        progressValue: 0.0,
        gscorePoints: '⭐ +10 G-Score',
      ),
      const LessonCardItem(
        chapterNumber: 'บทที่ 12',
        title: 'การตั้งค่า Microcontroller และการเชื่อมต่อ WiFi อุปกรณ์',
        duration: '50 นาที',
        typeTag: 'อินเทอร์แอคทีฟแล็บ ⚡',
        statusText: 'เรียนจบแล้ว 🟢 100%',
        statusColor: Color(0xFF059669),
        statusBg: Color(0xFFECFDF5),
        progressValue: 1.0,
        gscorePoints: '⭐ +20 G-Score',
        isCompleted: true,
      ),
      const LessonCardItem(
        chapterNumber: 'บทที่ 11',
        title: 'พื้นฐานการเขียนโปรแกรมควบคุม Internet of Things',
        duration: '60 นาที',
        typeTag: 'วิดีโอแล็บทดลอง 🎥',
        statusText: 'เรียนจบแล้ว 🟢 100%',
        statusColor: Color(0xFF059669),
        statusBg: Color(0xFFECFDF5),
        progressValue: 1.0,
        gscorePoints: '⭐ +20 G-Score',
        isCompleted: true,
      ),
      const LessonCardItem(
        chapterNumber: 'บทที่ 10',
        title: 'สถาปัตยกรรมระบบสมาร์ตสคูลและการแสดงผลข้อมูลสภาพอากาศ',
        duration: '40 นาที',
        typeTag: 'สไลด์บรรยาย 📊',
        statusText: 'เรียนจบแล้ว 🟢 100%',
        statusColor: Color(0xFF059669),
        statusBg: Color(0xFFECFDF5),
        progressValue: 1.0,
        gscorePoints: '⭐ +15 G-Score',
        isCompleted: true,
      ),
    ];

    return Column(
      children: lessons.map((item) {
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: item);
      }).toList(),
    );
  }
}

class LessonCardItem extends StatelessWidget {
  const LessonCardItem({
    super.key,
    required this.chapterNumber,
    required this.title,
    required this.duration,
    required this.typeTag,
    required this.statusText,
    required this.statusColor,
    required this.statusBg,
    required this.progressValue,
    required this.gscorePoints,
    this.isActive = false,
    this.isCompleted = false,
  });

  final String chapterNumber;
  final String title;
  final String duration;
  final String typeTag;
  final String statusText;
  final Color statusColor;
  final Color statusBg;
  final double progressValue;
  final String gscorePoints;
  final bool isActive;
  final bool isCompleted;

  void _showLessonViewerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chapterNumber,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      gscorePoints,
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    duration,
                    style: const TextStyle(
                      color: SchoolPalette.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              // Video Player Placeholder Box
              Container(
                width: double.infinity,
                height: 185,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: Color(0xFF10B981),
                      size: 56,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'เครื่องเล่นวิดีโอ 4K และสื่อมัลติมีเดีย',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📄 ดาวน์โหลดเอกสาร PDF สำเร็จ!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('ดาวน์โหลด PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SchoolPalette.ink,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('▶️ เริ่มเข้าเรียน: $title'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('เข้าสู่บทเรียน'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? statusColor.withValues(alpha: 0.45)
              : const Color(0xFFF1F5F9),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? statusColor.withValues(alpha: 0.1)
                : const Color(0x06000000),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showLessonViewerModal(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chapterNumber,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typeTag,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        gscorePoints,
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'กดเพื่อเข้าเรียน',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF059669),
                      size: 18,
                    ),
                  ],
                ),
                if (progressValue > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
