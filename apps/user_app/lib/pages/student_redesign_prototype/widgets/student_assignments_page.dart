import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'งานทั้งหมด (5)',
    '🔴 งานด่วนต้องส่ง (2)',
    '🔵 กำลังทำ (1)',
    '🟢 ตรวจแล้ว (2)',
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
          'ใบงานและการบ้านของฉัน',
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
                        _buildAssignmentList(),
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
            '🧪 โต๊ะลองงาน · หน้าใบงานและการบ้าน (ปรับธีมสีสดใส สรุปงานค้างชัดเจน)',
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
            Color(0xFFE11D48), // Rose Red
            Color(0xFFEA580C), // Vivid Orange
            Color(0xFFF97316), // Coral Amber
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33E11D48),
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
              opacity: 0.25,
              child: Image.asset(
                'assets/images/mascot_lion_clean.png',
                height: 150,
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
                          Icons.assignment_turned_in_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'ศูนย์รวมงานและการบ้าน 📝',
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1F000000), blurRadius: 8),
                      ],
                    ),
                    child: const Text(
                      '🔴 มี 2 งานด่วนวันนี้',
                      style: TextStyle(
                        color: Color(0xFFE11D48),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'สรุปรายการใบงานและการบ้านประจำสัปดาห์ 📋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'โปรดตรวจสอบกำหนดเวลาส่งงานเพื่อไม่ให้พลาดคะแนนสะสม G-Score',
                style: TextStyle(
                  color: Color(0xFFFFEDD5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Stat Summary Chips
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '2 งาน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '🔴 ต้องส่งด่วน',
                            style: TextStyle(
                              color: Color(0xFFFFD6A5),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '1 งาน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '🔵 กำลังทำอยู่',
                            style: TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '2 งาน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '🟢 ตรวจเรียบร้อย',
                            style: TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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
              selectedColor: const Color(0xFFEA580C),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFEA580C)
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

  Widget _buildAssignmentList() {
    final assignments = [
      const AssignmentCardItem(
        subject: 'วิชา AIoT สมาร์ตแล็บ',
        subjectCode: 'AIOT-501',
        title: 'ใบงานที่ 4: การคำนวณและประมวลผลค่าฝุ่น PM2.5 จากเซนเซอร์',
        dueDateText: 'กำหนดส่ง: วันนี้ เวลา 23:59 น. ⏰',
        urgentBadge: '🔴 ต้องส่งด่วนวันนี้',
        badgeColor: Color(0xFFE11D48),
        badgeBg: Color(0xFFFFE4E6),
        statusText: 'ยังไม่ได้ส่ง (เหลืออีก 4 ชม.)',
        statusColor: Color(0xFFE11D48),
        gscorePoints: '⭐ +30 G-Score',
        isUrgent: true,
      ),
      const AssignmentCardItem(
        subject: 'วิชา ฟิสิกส์ประยุกต์',
        subjectCode: 'PHYS-302',
        title: 'รายงานการทดลองที่ 2: การหักเหของแสงผ่านปริซึมแก้ว',
        dueDateText: 'กำหนดส่ง: พรุ่งนี้ 16:00 น.',
        urgentBadge: '🔴 งานค้างส่ง',
        badgeColor: Color(0xFFEA580C),
        badgeBg: Color(0xFFFFF7ED),
        statusText: 'ยังไม่ได้ส่ง',
        statusColor: Color(0xFFEA580C),
        gscorePoints: '⭐ +25 G-Score',
        isUrgent: true,
      ),
      const AssignmentCardItem(
        subject: 'วิชา คณิตศาสตร์เพิ่มเติม',
        subjectCode: 'MATH-401',
        title: 'แบบฝึกหัดเรื่อง: ความน่าจะเป็นและการจัดหมู่สถิติ',
        dueDateText: 'กำหนดส่ง: 5 ส.ค. 2569',
        urgentBadge: '🔵 กำลังทำอยู่',
        badgeColor: Color(0xFF0284C7),
        badgeBg: Color(0xFFE0F2FE),
        statusText: 'ร่างบันทึกไว้แล้ว 50%',
        statusColor: Color(0xFF0284C7),
        gscorePoints: '⭐ +20 G-Score',
      ),
      const AssignmentCardItem(
        subject: 'วิชา วิทยาศาสตร์กายภาพ',
        subjectCode: 'SCI-204',
        title: 'สรุปการวิเคราะห์สภาวะโลกร้อนและก๊าซเรือนกระจก',
        dueDateText: 'ส่งเมื่อ: 28 ก.ค. 2569',
        urgentBadge: '🟢 ตรวจแล้ว (A+)',
        badgeColor: Color(0xFF059669),
        badgeBg: Color(0xFFECFDF5),
        statusText: 'ตรวจแล้ว 🏆 100/100',
        statusColor: Color(0xFF059669),
        gscorePoints: '⭐ +30 G-Score (เต็ม)',
        isCompleted: true,
      ),
      const AssignmentCardItem(
        subject: 'วิชา ชีววิทยา',
        subjectCode: 'BIO-105',
        title: 'ใบงานบันทึกการสังเกตการณ์การสังเคราะห์แสงของพืช',
        dueDateText: 'ส่งเมื่อ: 25 ก.ค. 2569',
        urgentBadge: '🟢 ตรวจแล้ว (A)',
        badgeColor: Color(0xFF059669),
        badgeBg: Color(0xFFECFDF5),
        statusText: 'ตรวจแล้ว 🏆 95/100',
        statusColor: Color(0xFF059669),
        gscorePoints: '⭐ +28 G-Score',
        isCompleted: true,
      ),
    ];

    return Column(
      children: assignments.map((item) {
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: item);
      }).toList(),
    );
  }
}

class AssignmentCardItem extends StatelessWidget {
  const AssignmentCardItem({
    super.key,
    required this.subject,
    required this.subjectCode,
    required this.title,
    required this.dueDateText,
    required this.urgentBadge,
    required this.badgeColor,
    required this.badgeBg,
    required this.statusText,
    required this.statusColor,
    required this.gscorePoints,
    this.isUrgent = false,
    this.isCompleted = false,
  });

  final String subject;
  final String subjectCode;
  final String title;
  final String dueDateText;
  final String urgentBadge;
  final Color badgeColor;
  final Color badgeBg;
  final String statusText;
  final Color statusColor;
  final String gscorePoints;
  final bool isUrgent;
  final bool isCompleted;

  void _showAssignmentSubmitterModal(BuildContext context) {
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
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      urgentBadge,
                      style: TextStyle(
                        color: badgeColor,
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
              const SizedBox(height: 4),
              Text(
                '$subject ($subjectCode) · $dueDateText',
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // File Upload Dropzone Demo Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_upload_rounded,
                      color: Color(0xFFEA580C),
                      size: 44,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'แตะเพื่อเลือกไฟล์ หรือ ถ่ายรูปใบงานส่งครู',
                      style: TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'รองรับรูปถ่าย JPG, PNG หรือไฟล์เอกสาร PDF (ไม่เกิน 25MB)',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('ถ่ายรูปใบงาน'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEA580C),
                            side: const BorderSide(color: Color(0xFFFDBA74)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.attach_file_rounded, size: 16),
                          label: const Text('เลือกไฟล์'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SchoolPalette.ink,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SchoolPalette.ink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ปิดหน้าต่าง'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🎉 ส่งใบงานเรียบร้อยแล้ว! รับ +30 G-Score',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('ยืนยันการส่งงาน'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
          color: isUrgent
              ? badgeColor.withValues(alpha: 0.35)
              : const Color(0xFFF1F5F9),
          width: isUrgent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? badgeColor.withValues(alpha: 0.08)
                : const Color(0x06000000),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showAssignmentSubmitterModal(context),
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
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$subjectCode · $subject',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
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
                        urgentBadge,
                        style: TextStyle(
                          color: badgeColor,
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
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isUrgent
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dueDateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUrgent
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: isUrgent
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
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
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFDBA74),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.upload_file_rounded,
                            size: 13,
                            color: isCompleted
                                ? const Color(0xFF059669)
                                : const Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'ดูผลการตรวจ' : 'กดส่งใบงาน',
                            style: TextStyle(
                              color: isCompleted
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFEA580C),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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
