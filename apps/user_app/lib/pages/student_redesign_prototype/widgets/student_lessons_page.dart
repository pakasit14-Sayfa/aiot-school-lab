import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_course_files_page.dart' show courseFiles, CourseFileCard;
import 'student_assignments_page.dart' show StudentAssignmentsPage;
import 'student_lesson_content_page.dart' show StudentLessonContentPage;

class StudentLessonsPage extends StatefulWidget {
  const StudentLessonsPage({super.key});

  @override
  State<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends State<StudentLessonsPage> {
  int _selectedTabIndex = 0;

  // 0 = บทเรียนทั้งหมด (ไม่กรอง), 1 = วิดีโอ, 2 = ไฟล์ทั้งหมด (ไฟล์ประกอบวิชา)
  final List<String> _tabs = ['บทเรียน', 'วิดีโอ', 'ไฟล์ทั้งหมด'];

  static const _lessons = <LessonCardItem>[
    LessonCardItem(
      chapterNumber: 'บทที่ 13',
      icon: Icons.play_circle_fill_rounded,
      title: 'การเชื่อมต่อเซนเซอร์วัดค่าฝุ่น PM2.5 และการประมวลผล',
      duration: '45 นาที',
      typeTag: 'วิดีโอ 4K + โมเดล 3D',
      statusLabel: 'กำลังเรียน 65%',
      statusColor: Color(0xFF2563EB),
      statusBg: Color(0xFFEFF6FF),
      progressValue: 0.65,
      gscorePoints: '+15',
      contentType: 1,
      isActive: true,
      hasAssignment: true,
      assignmentTitle:
          'ใบงานที่ 4: การคำนวณและประมวลผลค่าฝุ่น PM2.5 จากเซนเซอร์',
      assignmentDueDateText: 'กำหนดส่ง วันนี้ 23:59 น.',
      assignmentUrgent: true,
      topics: [
        'หลักการทำงานของเซนเซอร์วัดฝุ่น PM2.5 แบบ Optical',
        'การต่อวงจรเซนเซอร์เข้ากับบอร์ด AIoT',
        'การอ่านค่าดิบและแปลงเป็นหน่วย µg/m³',
        'การแสดงผลค่าฝุ่นผ่านโมเดล 3D แบบเรียลไทม์',
      ],
    ),
    LessonCardItem(
      chapterNumber: 'บทที่ 14',
      icon: Icons.description_rounded,
      title: 'การอ่านค่าเซนเซอร์แสงและส่งข้อมูลเรียลไทม์เข้า Dashboard',
      duration: '30 นาที',
      typeTag: 'เอกสาร PDF + โค้ดตัวอย่าง',
      statusLabel: 'บทเรียนถัดไป',
      statusColor: Color(0xFFD97706),
      statusBg: Color(0xFFFFFBEB),
      progressValue: 0.0,
      gscorePoints: '+10',
      contentType: 2,
      hasAssignment: true,
      assignmentTitle: 'ใบงานที่ 5: ส่งข้อมูลค่าแสงเข้า Dashboard แบบเรียลไทม์',
      assignmentDueDateText: 'กำหนดส่ง 8 ส.ค. 2569',
      topics: [
        'การอ่านค่าความเข้มแสงจากเซนเซอร์ LDR/BH1750',
        'การเขียนโค้ดส่งข้อมูลผ่าน WiFi แบบ MQTT',
        'การเชื่อมต่อข้อมูลเข้าสู่ Dashboard แบบเรียลไทม์',
      ],
    ),
    LessonCardItem(
      chapterNumber: 'บทที่ 12',
      icon: Icons.bolt_rounded,
      title: 'การตั้งค่า Microcontroller และการเชื่อมต่อ WiFi อุปกรณ์',
      duration: '50 นาที',
      typeTag: 'อินเทอร์แอคทีฟแล็บ',
      statusLabel: 'เรียนจบแล้ว',
      statusColor: SchoolPalette.deepGreen,
      statusBg: SchoolPalette.softGreenBg,
      progressValue: 1.0,
      gscorePoints: '+20',
      contentType: 0,
      isCompleted: true,
      topics: [
        'โครงสร้างและพินของ Microcontroller ที่ใช้ในชุดแล็บ',
        'การตั้งค่า Firmware และเชื่อมต่อ WiFi',
        'การทดสอบส่งสัญญาณระหว่างอุปกรณ์',
      ],
    ),
    LessonCardItem(
      chapterNumber: 'บทที่ 11',
      icon: Icons.videocam_rounded,
      title: 'พื้นฐานการเขียนโปรแกรมควบคุม Internet of Things',
      duration: '60 นาที',
      typeTag: 'วิดีโอแล็บทดลอง',
      statusLabel: 'เรียนจบแล้ว',
      statusColor: SchoolPalette.deepGreen,
      statusBg: SchoolPalette.softGreenBg,
      progressValue: 1.0,
      gscorePoints: '+20',
      contentType: 1,
      isCompleted: true,
      topics: [
        'แนวคิดพื้นฐานของระบบ IoT และการสื่อสารระหว่างอุปกรณ์',
        'การเขียนโปรแกรมควบคุมอุปกรณ์ผ่านโค้ดตัวอย่าง',
        'การทดลองควบคุมอุปกรณ์จริงในห้องแล็บ',
      ],
    ),
    LessonCardItem(
      chapterNumber: 'บทที่ 10',
      icon: Icons.bar_chart_rounded,
      title: 'สถาปัตยกรรมระบบสมาร์ตสคูลและการแสดงผลข้อมูลสภาพอากาศ',
      duration: '40 นาที',
      typeTag: 'สไลด์บรรยาย',
      statusLabel: 'เรียนจบแล้ว',
      statusColor: SchoolPalette.deepGreen,
      statusBg: SchoolPalette.softGreenBg,
      progressValue: 1.0,
      gscorePoints: '+15',
      contentType: 2,
      isCompleted: true,
      topics: [
        'ภาพรวมสถาปัตยกรรมระบบสมาร์ตสคูล',
        'การไหลของข้อมูลจากเซนเซอร์สู่ระบบแสดงผล',
        'กรณีศึกษาการแสดงผลข้อมูลสภาพอากาศแบบเรียลไทม์',
      ],
    ),
  ];

  List<LessonCardItem> get _visibleLessons {
    if (_selectedTabIndex == 0) return _lessons;
    return _lessons
        .where((item) => item.contentType == _selectedTabIndex)
        .toList();
  }

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
                final horizontalPadding = screenWidth < 520 ? 14.0 : 16.0;

                return ConstrainedBox(
                  // เดิม 1000px บนจอเดสก์ท็อปกว้าง ทำให้ช่องว่างขวามือของ
                  // การ์ด (โดยเฉพาะแถวล่างที่มี Spacer คั่นกลาง) ห่างเกินไป
                  // ลดลงให้ใกล้เคียงความกว้างจอมือถือ/แท็บเล็ตมากขึ้น
                  constraints: BoxConstraints(maxWidth: isDesktop ? 720 : 640),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCourseSummaryHeader(context),
                        const SizedBox(height: 18),
                        _buildContentTypeTabs(),
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

  Widget _buildCourseSummaryHeader(BuildContext context) {
    // พื้นหลังพาสเทลเขียวจาง + วงแหวนความคืบหน้าแทนแถบยาว ให้เข้าธีม
    // "สนุก/เกมมิฟาย" เดียวกับการ์ดบทเรียนพาสเทลด้านล่าง
    const progress = 0.60;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, SchoolPalette.deepGreen, 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEFE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: SchoolPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4035C99A),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'วิชา AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ครูสมชาย สายวิทย์ · รหัสวิชา AIOT-501 · ม.5/1',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // สรุปความคืบหน้าแบบ legend + วงแหวนโดนัท 2 โทนสี ตามตัวอย่าง
          // (Total/Done Projects) — เปลี่ยนเป็น "บทเรียนทั้งหมด/เรียนจบแล้ว"
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LegendDot(
                      color: Color(0xFFBFE0D2),
                      label: 'บทเรียนทั้งหมด',
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '20',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _LegendDot(
                      color: SchoolPalette.deepGreen,
                      label: 'เรียนจบแล้ว',
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '12',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // เงา 2 ชั้น (แน่น+ฟุ้ง) แบบเดียวกับ SoftCard ทั้งแอป
                  // แทนเงาชั้นเดียวที่ดูเบลอเป็นก้อนสี่เหลี่ยมจางๆ
                  boxShadow: [
                    BoxShadow(
                      color: SchoolPalette.deepGreen.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: SchoolPalette.deepGreen.withValues(alpha: 0.16),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFCDE8DA),
                        color: SchoolPalette.deepGreen,
                      ),
                    ),
                    Container(
                      width: 66,
                      height: 66,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDCEFE6),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '60%',
                        style: TextStyle(
                          color: SchoolPalette.deepGreen,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 22),
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? SchoolPalette.deepGreen
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected
                        ? SchoolPalette.deepGreen
                        : SchoolPalette.muted,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLessonList() {
    // แท็บ "ไฟล์ทั้งหมด" โชว์ไฟล์ประกอบวิชาทุกไฟล์ ไม่ใช่บทเรียนที่กรองแล้ว
    if (_selectedTabIndex == 2) {
      return Column(
        children: courseFiles.map((file) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CourseFileCard(file: file),
          );
        }).toList(),
      );
    }

    final items = _visibleLessons;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SchoolPalette.glassBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 36,
              color: SchoolPalette.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'ไม่มีบทเรียนในหมวดนี้',
              style: TextStyle(
                color: SchoolPalette.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // การ์ดพาสเทลสีสันแยกใบต่อบทเรียนอีกครั้ง (ตามตัวอย่างล่าสุด) — เลิกใช้
    // กรอบตารางต่อเนื่อง กลับไปเว้นระยะห่างระหว่างการ์ดแบบมีช่องไฟ
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(padding: const EdgeInsets.only(bottom: 14), child: items[i]),
      ],
    );
  }
}

/// Small colored dot + label, used above each big number in the course
/// header's legend (matches the "Total/Done Projects" reference layout).
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: SchoolPalette.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class LessonCardItem extends StatelessWidget {
  const LessonCardItem({
    super.key,
    required this.chapterNumber,
    required this.icon,
    required this.title,
    required this.duration,
    required this.typeTag,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.progressValue,
    required this.gscorePoints,
    required this.contentType,
    this.isActive = false,
    this.isCompleted = false,
    this.hasAssignment = false,
    this.assignmentTitle,
    this.assignmentDueDateText,
    this.assignmentUrgent = false,
    this.topics = const [],
  });

  final String chapterNumber;
  final IconData icon;
  final String title;
  final String duration;
  final String typeTag;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final double progressValue;
  final String gscorePoints;
  final int contentType;
  final String? assignmentTitle;
  final String? assignmentDueDateText;
  final bool assignmentUrgent;
  final bool isActive;
  final bool isCompleted;
  final bool hasAssignment;
  final List<String> topics;

  void _openRelatedAssignment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentAssignmentsPage()),
    );
  }

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
                  if (hasAssignment) ...[
                    const SizedBox(width: 8),
                    _AssignmentLinkChip(
                      onTap: () => _openRelatedAssignment(context),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _LessonPreviewBox(
                icon: icon,
                accentColor: statusColor,
                typeTag: typeTag,
                duration: duration,
                gscorePoints: gscorePoints,
                topics: topics,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ดาวน์โหลดเอกสาร PDF สำเร็จ'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('ดาวน์โหลด PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SchoolPalette.navy,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentLessonContentPage(
                              chapterNumber: chapterNumber,
                              title: title,
                              typeTag: typeTag,
                              contentType: contentType,
                              icon: icon,
                              accentColor: statusColor,
                              duration: duration,
                              gscorePoints: gscorePoints,
                              topics: topics,
                              hasAssignment: hasAssignment,
                              assignmentTitle: assignmentTitle,
                              assignmentDueDateText: assignmentDueDateText,
                              assignmentUrgent: assignmentUrgent,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('เข้าสู่บทเรียน'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SchoolPalette.deepGreen,
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
    // การ์ดพาสเทลตามตัวอย่างล่าสุด — พื้นหลังสีอ่อนไล่โทนตามสถานะ, ไอคอน
    // ใหญ่ในวงกลมซ้าย, จุด/วงกลมสถานะมุมบน, ปุ่มลูกศรวงกลมมุมล่างขวา
    final pastelBg = Color.lerp(Colors.white, statusColor, 0.08)!;
    return Container(
      decoration: BoxDecoration(
        color: pastelBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showLessonViewerModal(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // วงกลมกลวง = สถานะกำลังเรียนอยู่ตอนนี้, วงกลมทึบ =
                    // เรียนจบแล้ว — จุดสังเกตแบบ radio เดียวกับตัวอย่าง
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isCompleted ? statusColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor, width: 1.6),
                      ),
                    ),
                    const Spacer(),
                    // วงแหวน + % แยกอยู่นอกวงแหวน (ไม่ยัดตัวเลขไว้ข้างใน
                    // เหมือนที่ลองแล้วมีปัญหาล้นตอน 100%) เปลี่ยนเป็น 🎉
                    // แทนตัวเลขเมื่อเรียนจบ ให้รู้สึกเหมือนได้รางวัล
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        value: progressValue.clamp(0.0, 1.0),
                        strokeWidth: 2.5,
                        backgroundColor: statusColor.withValues(alpha: 0.18),
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCompleted ? '🎉' : '${(progressValue * 100).round()}%',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SchoolPalette.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$typeTag · $duration',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SchoolPalette.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          // ป้าย "มีใบงาน" กลับมาโชว์บนหน้าการ์ดอีกครั้ง
                          // (เดิมโชว์แค่ตอนกดเข้า modal) ให้นักเรียนรู้
                          // ล่วงหน้าโดยไม่ต้องกดเข้าไปดูทีละบท
                          if (hasAssignment) ...[
                            const SizedBox(height: 8),
                            _AssignmentLinkChip(
                              onTap: () => _openRelatedAssignment(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        // "Created by" ในตัวอย่าง — ของเราไม่มีครูต่อบท
                        // แยกกัน เลยใช้ chapterNumber + G-Score แทน
                        '$chapterNumber · สอนโดย ครูสมชาย · ⭐$gscorePoints',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Links a lesson to its related homework in the Assignments page — so
/// students don't have to leave the lesson to notice a task is attached.
/// Swaps the lesson-viewer preview to match what the lesson actually is —
/// a video player mock for video lessons, a document mock for files, and
/// a plain lab callout for interactive lessons, instead of always showing
/// a "video player" box even for a PDF-only lesson.
/// "Insights card" style summary — an outer soft card that frames a nested
/// white stat card, replacing the old fake video-player mock with a real
/// summary of progress/duration/G-Score for the lesson.
/// Shows what the lesson actually covers — the list of topics — instead of
/// restating progress/duration/G-Score that the student already saw on the
/// card before tapping in.
class _LessonPreviewBox extends StatelessWidget {
  const _LessonPreviewBox({
    required this.icon,
    required this.accentColor,
    required this.typeTag,
    required this.duration,
    required this.gscorePoints,
    required this.topics,
  });

  final IconData icon;
  final Color accentColor;
  final String typeTag;
  final String duration;
  final String gscorePoints;
  final List<String> topics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SchoolPalette.softGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'เนื้อหาที่จะได้เรียน',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < topics.length; i++) ...[
                  _TopicRow(index: i + 1, text: topics[i], color: accentColor),
                  if (i != topics.length - 1) const SizedBox(height: 10),
                ],
                if (topics.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEFF3F1)),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: SchoolPalette.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$gscorePoints G-Score',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
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

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.index,
    required this.text,
    required this.color,
  });

  final int index;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Text(
              text,
              style: const TextStyle(
                color: SchoolPalette.navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssignmentLinkChip extends StatelessWidget {
  const _AssignmentLinkChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // เดิมชิปนี้เล็ก ไม่มีขอบ ตัวหนังสือ 10px แล้วก็ไปเบียดอยู่ข้าง
    // _GScoreChip ที่มีขอบและตัวหนา — ทำให้แทบมองไม่เห็นว่ามีบทเรียน
    // ไหนมีใบงานผูกอยู่บ้าง ตอนนี้ให้น้ำหนักภาพเท่า G-Score chip แล้ว
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                size: 13,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 4),
              Text(
                'มีใบงาน',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// G-Score reward chip — uses a real star icon instead of an emoji glyph
/// so it renders consistently across platforms/fonts.
