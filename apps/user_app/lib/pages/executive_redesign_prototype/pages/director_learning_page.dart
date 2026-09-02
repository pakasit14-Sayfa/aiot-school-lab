import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorLearningPage extends StatefulWidget {
  const DirectorLearningPage({super.key});

  @override
  State<DirectorLearningPage> createState() => _DirectorLearningPageState();
}

class _DirectorLearningPageState extends State<DirectorLearningPage> {
  String selectedPeriod = 'วันนี้';
  String selectedGrade = 'ทุกระดับชั้น';
  String selectedTrack = 'ทุกสายการเรียน';

  final List<String> periods = const [
    'วันนี้',
    'สัปดาห์นี้',
    'เดือนนี้',
    'ภาคเรียนนี้',
  ];

  final List<String> grades = const [
    'ทุกระดับชั้น',
    'ม.1',
    'ม.2',
    'ม.3',
    'ม.4',
    'ม.5',
    'ม.6',
  ];

  final List<String> tracks = const [
    'ทุกสายการเรียน',
    'วิทย์ - คณิต',
    'สายภาษา',
    'สายทั่วไป',
  ];

  final List<_StudentProgramData> programs = const [
    _StudentProgramData(
      title: 'วิทย์ - คณิต',
      subtitle: 'ม.1 - ม.6',
      icon: Icons.science_rounded,
      color: Color(0xFF0284C7),
      students: 442,
      attendance: 96.4,
      learning: 95.2,
      behavior: 94.8,
      environment: 93.5,
      atRisk: 7,
      averageGpa: 3.62,
      passRate: 98.4,
      description: 'เน้นความเป็นเลิศทางวิทยาศาสตร์ คณิตศาสตร์ และเทคโนโลยี AIoT',
    ),
    _StudentProgramData(
      title: 'สายภาษา',
      subtitle: 'ม.1 - ม.6',
      icon: Icons.translate_rounded,
      color: Color(0xFF8B5CF6),
      students: 398,
      attendance: 94.1,
      learning: 93.0,
      behavior: 91.5,
      environment: 95.2,
      atRisk: 9,
      averageGpa: 3.45,
      passRate: 96.8,
      description: 'มุ่งเน้นทักษะการสื่อสารสากล ภาษาอังกฤษ จีน ญี่ปุ่น และการแลกเปลี่ยนวัฒนธรรม',
    ),
    _StudentProgramData(
      title: 'สายทั่วไป',
      subtitle: 'ม.1 - ม.6',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFD97706),
      students: 408,
      attendance: 92.3,
      learning: 90.4,
      behavior: 89.6,
      environment: 94.0,
      atRisk: 12,
      averageGpa: 3.18,
      passRate: 94.2,
      description: 'บูรณาการทักษะอาชีพ เทคโนโลยี ดนตรี กีฬา และการเรียนรู้ตลอดชีวิต',
    ),
  ];

  final List<_GradeData> gradeData = const [
    _GradeData(
      grade: 'ม.1',
      students: 198,
      rooms: 6,
      attendance: 95.2,
      learning: 92.4,
      behavior: 94.1,
      environment: 93.8,
      absentToday: 10,
      lateToday: 4,
      supportCases: 3,
      homeVisitDone: 96,
      riskCount: 2,
    ),
    _GradeData(
      grade: 'ม.2',
      students: 204,
      rooms: 6,
      attendance: 94.0,
      learning: 93.1,
      behavior: 92.3,
      environment: 95.0,
      absentToday: 12,
      lateToday: 5,
      supportCases: 4,
      homeVisitDone: 94,
      riskCount: 3,
    ),
    _GradeData(
      grade: 'ม.3',
      students: 206,
      rooms: 6,
      attendance: 88.4,
      learning: 94.0,
      behavior: 95.2,
      environment: 94.1,
      absentToday: 25,
      lateToday: 6,
      supportCases: 4,
      homeVisitDone: 98,
      riskCount: 5,
    ),
    _GradeData(
      grade: 'ม.4',
      students: 224,
      rooms: 6,
      attendance: 93.6,
      learning: 92.5,
      behavior: 91.0,
      environment: 94.4,
      absentToday: 16,
      lateToday: 6,
      supportCases: 5,
      homeVisitDone: 91,
      riskCount: 4,
    ),
    _GradeData(
      grade: 'ม.5',
      students: 238,
      rooms: 6,
      attendance: 92.1,
      learning: 91.2,
      behavior: 90.4,
      environment: 92.0,
      absentToday: 19,
      lateToday: 7,
      supportCases: 8,
      homeVisitDone: 88,
      riskCount: 6,
    ),
    _GradeData(
      grade: 'ม.6',
      students: 250,
      rooms: 6,
      attendance: 86.8,
      learning: 96.1,
      behavior: 95.0,
      environment: 96.2,
      absentToday: 35,
      lateToday: 8,
      supportCases: 5,
      homeVisitDone: 95,
      riskCount: 3,
    ),
  ];

  final List<_UrgentCareStudent> urgentStudents = const [
    _UrgentCareStudent(
      id: 'STD-10492',
      name: 'ด.ช. ภานุวัฒน์ วิเศษสุข',
      gradeRoom: 'ม.3/2',
      issue: 'ขาดเรียนต่อเนื่อง 3 วันติด (ไม่มีใบลา)',
      careCategory: 'การมาเรียน',
      riskLevel: 'วิกฤต',
      adviser: 'ครูสมหญิง ใจดี',
      suggestedAction: 'ประสานผู้ปกครองด่วน / ครูประจำชั้นลงพื้นที่เยี่ยมบ้าน',
      time: 'เมื่อ 20 นาทีที่แล้ว',
      color: Color(0xFFE11D48),
    ),
    _UrgentCareStudent(
      id: 'STD-10518',
      name: 'น.ส. พรทิพย์ สุวรรณมาลัย',
      gradeRoom: 'ม.5/4',
      issue: 'คะแนนเก็บวิชาคณิตศาสตร์และเคมีต่ำกว่า 50%',
      careCategory: 'วิชาการ',
      riskLevel: 'เฝ้าระวัง',
      adviser: 'ครูเกรียงศักดิ์ สมบูรณ์',
      suggestedAction: 'จัดสอนเสริมคลินิกวิชาการ / วางแผนปรับผลการเรียน',
      time: 'เมื่อ 1 ชม. ที่แล้ว',
      color: Color(0xFFD97706),
    ),
    _UrgentCareStudent(
      id: 'STD-10602',
      name: 'นาย ธีรภัทร ชาญเจริญ',
      gradeRoom: 'ม.6/1',
      issue: 'มีภาวะเครียดจากการเตรียมสอบเข้ามหาวิทยาลัย',
      careCategory: 'สุขภาพจิต/แนะแนว',
      riskLevel: 'ดูแลพิเศษ',
      adviser: 'ครูกมลพร ปัญญาดี',
      suggestedAction: 'นัดหมายพูดคุยกับครูแนะแนวและผู้เชี่ยวชาญสุขภาพจิต',
      time: 'เมื่อ 2 ชม. ที่แล้ว',
      color: Color(0xFF7C3AED),
    ),
  ];

  final List<_FollowUpItem> followUps = const [
    _FollowUpItem(
      title: 'การขาดเรียนต่อเนื่องกลุ่มเสี่ยง (ม.3 & ม.6)',
      detail:
          'พบ 11 คนขาดเรียนเกิน 3 วันติดต่อกัน โดย ม.3 และ ม.6 มีสัดส่วนสูงสุด ควรให้หัวหน้าระดับชั้นกำชับครูประจำชั้นติดต่อผู้ปกครองทันที',
      status: 'ต้องดูแลด่วน',
      icon: Icons.person_off_rounded,
      color: Color(0xFFE11D48),
      targetCount: '11 คน',
      actionLabel: 'สั่งการครูหัวหน้าระดับ',
    ),
    _FollowUpItem(
      title: 'คลินิกวิชาการและสอนเสริมรายบุคคล',
      detail:
          'มีนักเรียน 9 คนที่มีผลการเรียนต่ำกว่าเกณฑ์ใน 2 รายวิชาขึ้นไป อยู่ระหว่างการจัดโปรแกรมสอนเสริมนอกเวลาและมอบหมายครูพี่เลี้ยง',
      status: 'อยู่ระหว่างดำเนินการ',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF0284C7),
      targetCount: '9 คน',
      actionLabel: 'ดูแผนการสอนเสริม',
    ),
    _FollowUpItem(
      title: 'ความก้าวหน้าโครงการเยี่ยมบ้าน 100%',
      detail:
          'ภาพรวมการเยี่ยมบ้านครบถ้วน 93.8% (ม.1 และ ม.3 ใกล้ครบ 100%) เหลือระดับ ม.5 ที่กำลังเร่งดำเนินการให้เสร็จสิ้นภายในเดือนนี้',
      status: 'คืบหน้าดีเยี่ยม',
      icon: Icons.home_work_rounded,
      color: Color(0xFF059669),
      targetCount: '93.8%',
      actionLabel: 'ดูรายงานเยี่ยมบ้าน',
    ),
    _FollowUpItem(
      title: 'การเฝ้าระวังพฤติกรรมและความปลอดภัย',
      detail:
          'บันทึกเหตุการณ์พฤติกรรมในโรงเรียน 5 กรณี ได้รับการแก้ไขและไกล่เกลี่ยแล้ว 3 กรณี เหลือ 2 กรณีที่กำลังให้คำปรึกษาเชิงบวก',
      status: 'เฝ้าระวังเชิงรุก',
      icon: Icons.shield_rounded,
      color: Color(0xFFD97706),
      targetCount: '2 เคสค้าง',
      actionLabel: 'เปิดบันทึกฝ่ายปกครอง',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _executiveStudentHeader(),
          const SizedBox(height: 14),
          _filterCard(),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _urgentWatchlistSection(),
          const SizedBox(height: 16),
          _programOverviewSection(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1050) {
                return Column(
                  children: [
                    _attendanceOverviewCard(),
                    const SizedBox(height: 16),
                    _studentCareSystemCard(),
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _attendanceOverviewCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _studentCareSystemCard(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _gradeOverviewSection(),
          const SizedBox(height: 16),
          _followUpSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 1. Apple-Style Executive Header
  Widget _executiveStudentHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          final titleContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ศูนย์ภาพรวมและพัฒนานักเรียน',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Executive Student Intelligence • ระบบติดตามและดูแลช่วยเหลือนักเรียนแบบองค์รวม',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

          final badgeContent = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Flexible(
                      child: Text(
                        'นักเรียนทั้งหมด 1,248 คน (ออนไลน์)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFFF8FAFC),
                ),
                onPressed: () {
                  _showMessage('กำลังอัปเดตข้อมูลสถิตินักเรียนล่าสุด...');
                },
                icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0F172A)),
                label: const Text(
                  'รีเฟรช',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleContent,
                const SizedBox(height: 14),
                badgeContent,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleContent),
              const SizedBox(width: 16),
              badgeContent,
            ],
          );
        },
      ),
    );
  }

  // 2. Filter Bar
  Widget _filterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final filtersRow = [
            _filterDropdown(
              label: 'ช่วงเวลาแสดงผล',
              value: selectedPeriod,
              items: periods,
              icon: Icons.calendar_today_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedPeriod = value);
              },
            ),
            _filterDropdown(
              label: 'ระดับชั้นเป้าหมาย',
              value: selectedGrade,
              items: grades,
              icon: Icons.school_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedGrade = value);
              },
            ),
            _filterDropdown(
              label: 'สายการเรียน',
              value: selectedTrack,
              items: tracks,
              icon: Icons.category_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedTrack = value);
              },
            ),
          ];

          if (compact) {
            return Column(
              children: [
                for (int i = 0; i < filtersRow.length; i++) ...[
                  filtersRow[i],
                  if (i != filtersRow.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: filtersRow[0]),
              const SizedBox(width: 12),
              Expanded(child: filtersRow[1]),
              const SizedBox(width: 12),
              Expanded(child: filtersRow[2]),
            ],
          );
        },
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        prefixIcon: Icon(
          icon,
          size: 17,
          color: const Color(0xFF0284C7),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.4),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  // 3. Apple-Style Executive Summary Cards (Header Banner Design)
  Widget _summaryCards() {
    final items = [
      _StudentExecutiveSummary(
        title: 'นักเรียนทั้งหมด',
        value: '1,248',
        unit: 'คน',
        sub: '36 ห้องเรียน • 6 ระดับชั้น',
        badge: 'ออนไลน์ 100%',
        badgeBg: const Color(0xFFE0F2FE),
        badgeTextColor: const Color(0xFF0369A1),
        icon: Icons.groups_rounded,
        headerBg: const Color(0xFFE0F2FE),
        headerColor: const Color(0xFF0284C7),
        onTap: () {
          _showMessage('นักเรียนลงทะเบียนครบ 1,248 คน ทั่วทั้งโรงเรียน');
        },
      ),
      _StudentExecutiveSummary(
        title: 'มาเรียนวันนี้',
        value: '94.2',
        unit: '%',
        sub: 'มา 1,176 • สภาพแวดล้อมพร้อม',
        badge: '✓ สูงกว่าเป้าหมาย',
        badgeBg: const Color(0xFFDCFCE7),
        badgeTextColor: const Color(0xFF15803D),
        icon: Icons.how_to_reg_rounded,
        headerBg: const Color(0xFFDCFCE7),
        headerColor: const Color(0xFF16A34A),
        onTap: () {
          _showMessage('สถิติการมาเรียนวันนี้ 94.2% สูงกว่าเกณฑ์เฉลี่ยมาตรฐาน (90%)');
        },
      ),
      _StudentExecutiveSummary(
        title: 'ขาดเรียน / ลา',
        value: '72',
        unit: 'คน',
        sub: 'ขาดต่อเนื่อง 11 • ลาป่วย 41',
        badge: '⚠️ เฝ้าระวัง 11 คน',
        badgeBg: const Color(0xFFFEE2E2),
        badgeTextColor: const Color(0xFFB91C1C),
        icon: Icons.person_off_rounded,
        headerBg: const Color(0xFFFEE2E2),
        headerColor: const Color(0xFFE11D48),
        onTap: () {
          _showMessage('นักเรียนที่ขาดเรียนต่อเนื่องเกิน 3 วัน อยู่ในรายการเฝ้าระวังด้านล่าง');
        },
      ),
      _StudentExecutiveSummary(
        title: 'มาสายวันนี้',
        value: '27',
        unit: 'คน',
        sub: 'ลดลงจากสัปดาห์ก่อน 8 คน',
        badge: '📉 แนวโน้มดีขึ้น',
        badgeBg: const Color(0xFFFEF3C7),
        badgeTextColor: const Color(0xFFB45309),
        icon: Icons.schedule_rounded,
        headerBg: const Color(0xFFFEF3C7),
        headerColor: const Color(0xFFD97706),
        onTap: () {
          _showMessage('จำนวนนักเรียนมาสาย 27 คน ม.5 มีสัดส่วนสูงสุด');
        },
      ),
      _StudentExecutiveSummary(
        title: 'เคสดูแลช่วยเหลือด่วน',
        value: '23',
        unit: 'เคส',
        sub: 'การเรียน 9 • ขาด 11 • พฤติกรรม 3',
        badge: 'ครูประกบ 100%',
        badgeBg: const Color(0xFFF3E8FF),
        badgeTextColor: const Color(0xFF7E22CE),
        icon: Icons.health_and_safety_rounded,
        headerBg: const Color(0xFFF3E8FF),
        headerColor: const Color(0xFF9333EA),
        onTap: () {
          _showMessage('ระบบดูแลช่วยเหลือนักเรียนมีครูที่ปรึกษาและครูแนะแนวกำกับทุกเคส');
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 1150 ? 5 : (width >= 700 ? 3 : 1);
        const double spacing = 12;
        final double cardWidth = ((width - (spacing * (columns - 1))) / columns).floorToDouble() - 0.5;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: item.headerBg.withValues(alpha: 0.25),
                  splashColor: item.headerColor.withValues(alpha: 0.12),
                  onTap: item.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Colored Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: item.headerBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(item.icon, size: 14, color: item.headerColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: item.headerColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ดูข้อมูล',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: item.headerColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 7,
                                      color: item.headerColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Big Value
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.unit,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Subtitle & Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9.8,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badge,
                                style: TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                  color: item.badgeTextColor,
                                ),
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
          }).toList(),
        );
      },
    );
  }

  // 4. Live Student Care Watchlist (Executive Urgent Intervention Card)
  Widget _urgentWatchlistSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDA4AF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'EXECUTIVE WATCHLIST • เคสนักเรียนที่ผู้อำนวยการควรติดตามด่วนวันนี้',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${urgentStudents.length} เคสต้องดำเนินการ',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'รายชื่อนักเรียนที่มีประเด็นเร่งด่วนด้านการมาเรียน วิชาการ หรือพฤติกรรม เพื่อให้ ผอ. สั่งการและช่วยเหลือทันท่วงที',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: urgentStudents.map(_urgentStudentTile).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgentStudentTile(_UrgentCareStudent student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: student.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: student.color.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final mainInfo = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: student.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  student.riskLevel == 'วิกฤต'
                      ? Icons.warning_rounded
                      : (student.riskLevel == 'เฝ้าระวัง' ? Icons.visibility_rounded : Icons.support_agent_rounded),
                  color: student.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            student.gradeRoom,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: student.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            student.riskLevel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: student.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.issue,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'คำแนะนำ: ${student.suggestedAction} • ครูที่ปรึกษา: ${student.adviser}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(color: student.color.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _showStudentCareModal(student);
                },
                child: Text(
                  'ดูประวัติ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: student.color),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: student.color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _showMessage('ส่งข้อความสั่งการไปยัง ${student.adviser} แล้ว');
                },
                child: const Text(
                  'สั่งการดูแล',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mainInfo,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: mainInfo),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  // 5. Academic & Track Analysis (การวิเคราะห์ตามสายการเรียน)
  Widget _programOverviewSection() {
    final visiblePrograms = selectedTrack == 'ทุกสายการเรียน'
        ? programs
        : programs.where((item) => item.title == selectedTrack).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, size: 20, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การวิเคราะห์ผลการเรียนและสายการเรียน (Academic Program Analytics)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'เปรียบเทียบผลสัมฤทธิ์วิชาการ (GPA), อัตราผ่านเกณฑ์, การมาเรียน และการพัฒนารายสายการเรียน',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width < 600) {
                return Column(
                  children: [
                    for (int i = 0; i < visiblePrograms.length; i++) ...[
                      _modernProgramCard(visiblePrograms[i]),
                      if (i != visiblePrograms.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              final int columns = width >= 900 ? 3 : 2;

              return GridView.builder(
                itemCount: visiblePrograms.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 350,
                ),
                itemBuilder: (context, index) {
                  return _modernProgramCard(visiblePrograms[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _modernProgramCard(_StudentProgramData item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: item.color.withValues(alpha: 0.03),
        splashColor: item.color.withValues(alpha: 0.08),
        onTap: () => _showModernProgramDialog(item),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: item.color.withValues(alpha: 0.25), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, size: 20, color: item.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${item.students} คน • ${item.subtitle}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'GPA ${item.averageGpa}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: item.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('อัตราผ่านเกณฑ์', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
                          Text('${item.passRate}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('กลุ่มเสี่ยง/ดูแล', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
                          Text('${item.atRisk} คน', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE11D48))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _modernProgressRow('มาเรียน', item.attendance, const Color(0xFF0284C7)),
              _modernProgressRow('การเรียน', item.learning, const Color(0xFF8B5CF6)),
              _modernProgressRow('พฤติกรรม', item.behavior, const Color(0xFFD97706)),
              _modernProgressRow('สิ่งแวดล้อม', item.environment, const Color(0xFF059669)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('แตะดูเจาะลึก ม.1 - ม.6', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: item.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernProgressRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '${value.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Left: Attendance Overview Card & Right: Student Care System (5 Pillars)
  Widget _attendanceOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การมาเรียนแยกตามระดับชั้น (Attendance Rate)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'แสดงสถิติการมาเรียนและจุดที่พบอัตราขาด/สายสูงกว่าค่าเกณฑ์ (90%)',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  width: 32,
                  child: _AttendanceYAxis(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: _AttendanceGridLines(),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: gradeData.map((item) {
                          final isSelected = selectedGrade == 'ทุกระดับชั้น' || selectedGrade == item.grade;
                          final isUnderTarget = item.attendance < 90.0;
                          final barColor = isUnderTarget ? const Color(0xFFE11D48) : const Color(0xFF0284C7);

                          return Expanded(
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.35,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.attendance.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: barColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: FractionallySizedBox(
                                          heightFactor: item.attendance / 100,
                                          widthFactor: 0.72,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: barColor,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: barColor.withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(height: 1, color: const Color(0xFFCBD5E1)),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.grade,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF334155),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendDot(const Color(0xFF0284C7), 'ปกติ (≥90%)'),
              _legendDot(const Color(0xFFE11D48), 'ต่ำกว่าเกณฑ์ (<90%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _studentCareSystemCard() {
    final dimensions = [
      _CareDimension(
        title: 'การคัดกรองและประเมิน SDQ',
        progress: 98.4,
        detail: 'คัดกรองครบ 1,228 / 1,248 คน (ปกติ 85%, เสี่ยง 12%, มีปัญหา 3%)',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF0284C7),
      ),
      _CareDimension(
        title: 'โครงการเยี่ยมบ้าน 100%',
        progress: 93.8,
        detail: 'เยี่ยมแล้ว 1,170 หลังคาเรือน (ม.1, ม.3 ครบแล้ว)',
        icon: Icons.home_rounded,
        color: const Color(0xFF059669),
      ),
      _CareDimension(
        title: 'การส่งเสริมและพัฒนาทักษะชีวิต',
        progress: 95.0,
        detail: 'กิจกรรมชมรม กีฬา ดนตรี และนวัตกรรม AIoT',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFD97706),
      ),
      _CareDimension(
        title: 'การให้คำปรึกษาและสุขภาพจิต',
        progress: 89.2,
        detail: 'ดูแล 23 เคส (ให้คำปรึกษาส่วนตัวและประสานผู้ปกครอง)',
        icon: Icons.psychology_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _CareDimension(
        title: 'ทุนการศึกษาและสวัสดิการ',
        progress: 100.0,
        detail: 'จัดสรรทุนปัจจัยพื้นฐานครบ 145 ทุน และอาหารกลางวัน',
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFFE11D48),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_rounded, size: 20, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ระบบดูแลช่วยเหลือนักเรียน (Student Care System)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'การปฏิบัติงาน 5 มิติหลักตามเกณฑ์มาตรฐาน สพฐ.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...dimensions.map(_careDimensionTile),
        ],
      ),
    );
  }

  Widget _careDimensionTile(_CareDimension item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.progress}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: item.color),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Grade Deep Dive (ม.1 - ม.6)
  Widget _gradeOverviewSection() {
    final visibleGrades = selectedGrade == 'ทุกระดับชั้น'
        ? gradeData
        : gradeData.where((item) => item.grade == selectedGrade).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.view_module_rounded, size: 20, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลเจาะลึกรายระดับชั้น (Grade-Level Deep Dive ม.1 - ม.6)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ตรวจสอบจำนวนนักเรียน ห้องเรียน การมาเรียน สถิติขาด/สาย และอัตราเยี่ยมบ้าน',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    for (int i = 0; i < visibleGrades.length; i++) ...[
                      _gradeCard(visibleGrades[i]),
                      if (i != visibleGrades.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              final int columns = constraints.maxWidth < 1080 ? 2 : 3;

              return GridView.builder(
                itemCount: visibleGrades.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 195,
                ),
                itemBuilder: (context, index) {
                  return _gradeCard(visibleGrades[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _gradeCard(_GradeData item) {
    final isAttention = item.attendance < 90.0 || item.supportCases >= 6;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: const Color(0xFF0284C7).withValues(alpha: 0.03),
        onTap: () => _showModernGradeDialog(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isAttention ? const Color(0xFFFFF1F2) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAttention ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isAttention ? const Color(0xFFE11D48) : const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.grade,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.students} คน • ${item.rooms} ห้องเรียน',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'เยี่ยมบ้านแล้ว ${item.homeVisitDone}%',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAttention)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ต้องดูแลด่วน',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _gradeMiniStat('มาเรียน', '${item.attendance.toStringAsFixed(1)}%', item.attendance < 90 ? const Color(0xFFE11D48) : const Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  _gradeMiniStat('ขาด/สาย', '${item.absentToday}/${item.lateToday}', const Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  _gradeMiniStat('เคสดูแล', '${item.supportCases}', const Color(0xFF7C3AED)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('ดูสถิติรายห้อง', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                  Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradeMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // 8. Executive Follow-Up Section (งานติดตามและสั่งการ)
  Widget _followUpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded, size: 20, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อเสนอแนะเชิงบริหารและงานติดตาม (Executive Action Items)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'การขับเคลื่อนการพัฒนานักเรียน สั่งการครูหัวหน้าระดับ และติดตามผู้ปกครอง',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...followUps.map(_followUpTile),
        ],
      ),
    );
  }

  Widget _followUpTile(_FollowUpItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: item.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: item.color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      style: const TextStyle(fontSize: 11, height: 1.45, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionBtn = OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: BorderSide(color: item.color),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              _showMessage('ดำเนินการ: ${item.actionLabel}');
            },
            child: Text(
              item.actionLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item.color),
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: actionBtn),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 14),
              actionBtn,
            ],
          );
        },
      ),
    );
  }

  // 9. Apple-Style Modal Dialogs with BackdropFilter 15%
  void _showStudentCareModal(_UrgentCareStudent student) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StudentCareModal',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 240),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (dialogContext, anim, secondaryAnim) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: student.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.person_rounded, size: 22, color: student.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'รหัสนักเรียน: ${student.id} • ห้อง ${student.gradeRoom} • ครูที่ปรึกษา: ${student.adviser}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: student.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: student.color.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ประเด็นที่ต้องติดตาม: ${student.issue}',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: student.color),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'หมวดหมู่: ${student.careCategory} • แจ้งเตือนเมื่อ: ${student.time}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('มาตรการดำเนินการเร่งด่วน', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(student.suggestedAction, style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF334155))),
                              const SizedBox(height: 16),
                              const Text('ไทม์ไลน์การติดต่อและดูแล', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              _modalTimelineItem('1', 'ระบบตรวจพบการขาดเรียน/ผลคะแนนต่ำกว่าเกณฑ์อัตโนมัติ', '10:15 น.'),
                              _modalTimelineItem('2', 'แจ้งเตือนครูประจำชั้น (${student.adviser}) ในแอปพลิเคชัน', '10:18 น.'),
                              _modalTimelineItem('3', 'ผู้อำนวยการเข้าติดตามและสั่งการเพื่อประสานผู้ปกครอง', 'กำลังดำเนินการ', isCurrent: true),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Bottom
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showMessage('โทรหาครูประจำชั้น (${student.adviser}) แล้ว');
                              },
                              icon: const Icon(Icons.phone_rounded, size: 16),
                              label: const Text('โทรหาครูประจำชั้น'),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                backgroundColor: const Color(0xFF0284C7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showMessage('บันทึกคำสั่งการและมอบหมายงานเรียบร้อย');
                              },
                              child: const Text('เสร็จสิ้น', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modalTimelineItem(String step, String title, String time, {bool isCurrent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isCurrent ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text(time, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showModernProgramDialog(_StudentProgramData item) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ProgramDialog',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim, secondaryAnim) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: item.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'สายการเรียน ${item.title}',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    '${item.description} • นักเรียน ${item.students} คน',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  _programSummaryPill('GPA เฉลี่ย', '${item.averageGpa}', item.color),
                                  _programSummaryPill('อัตราผ่านเกณฑ์', '${item.passRate}%', const Color(0xFF059669)),
                                  _programSummaryPill('การมาเรียน', '${item.attendance}%', const Color(0xFF0284C7)),
                                  _programSummaryPill('นักเรียนที่ต้องดูแล', '${item.atRisk} คน', const Color(0xFFE11D48)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text('การกระจายตัวตามระดับชั้น ม.1 - ม.6', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              for (final g in gradeData)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(g.grade, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          'นักเรียนประมาณ ${(g.students / 3).round()} คน • มาเรียน ${g.attendance}% • เฝ้าระวัง ${g.riskCount} คน',
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      Text('${g.homeVisitDone}% เยี่ยมบ้าน', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              backgroundColor: item.color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('ปิด', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _programSummaryPill(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  void _showModernGradeDialog(_GradeData item) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'GradeDialog',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim, secondaryAnim) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.grade,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ข้อมูลสถิติระดับชั้น ${item.grade}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'นักเรียนทั้งหมด ${item.students} คน • ${item.rooms} ห้องเรียน',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _dialogRow('อัตราการมาเรียน', '${item.attendance}%', item.attendance < 90 ? const Color(0xFFE11D48) : const Color(0xFF0284C7)),
                              _dialogRow('ขาดเรียนวันนี้', '${item.absentToday} คน', const Color(0xFFD97706)),
                              _dialogRow('มาสายวันนี้', '${item.lateToday} คน', const Color(0xFFD97706)),
                              _dialogRow('ผลสัมฤทธิ์การเรียน', '${item.learning}%', const Color(0xFF8B5CF6)),
                              _dialogRow('คะแนนพฤติกรรม', '${item.behavior}%', const Color(0xFF059669)),
                              _dialogRow('การดูแลสภาพแวดล้อม', '${item.environment}%', const Color(0xFF0284C7)),
                              _dialogRow('เคสที่ต้องดูแลใกล้ชิด', '${item.supportCases} เคส', const Color(0xFFE11D48)),
                              _dialogRow('ความก้าวหน้าการเยี่ยมบ้าน', '${item.homeVisitDone}%', const Color(0xFF059669)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              backgroundColor: const Color(0xFF0284C7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('ปิด', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Model Classes
class _StudentExecutiveSummary {
  final String title;
  final String value;
  final String unit;
  final String sub;
  final String badge;
  final Color badgeBg;
  final Color badgeTextColor;
  final IconData icon;
  final Color headerBg;
  final Color headerColor;
  final VoidCallback onTap;

  const _StudentExecutiveSummary({
    required this.title,
    required this.value,
    required this.unit,
    required this.sub,
    required this.badge,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.icon,
    required this.headerBg,
    required this.headerColor,
    required this.onTap,
  });
}

class _StudentProgramData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int students;
  final double attendance;
  final double learning;
  final double behavior;
  final double environment;
  final int atRisk;
  final double averageGpa;
  final double passRate;
  final String description;

  const _StudentProgramData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.students,
    required this.attendance,
    required this.learning,
    required this.behavior,
    required this.environment,
    required this.atRisk,
    required this.averageGpa,
    required this.passRate,
    required this.description,
  });
}

class _GradeData {
  final String grade;
  final int students;
  final int rooms;
  final double attendance;
  final double learning;
  final double behavior;
  final double environment;
  final int absentToday;
  final int lateToday;
  final int supportCases;
  final int homeVisitDone;
  final int riskCount;

  const _GradeData({
    required this.grade,
    required this.students,
    required this.rooms,
    required this.attendance,
    required this.learning,
    required this.behavior,
    required this.environment,
    required this.absentToday,
    required this.lateToday,
    required this.supportCases,
    required this.homeVisitDone,
    required this.riskCount,
  });
}

class _UrgentCareStudent {
  final String id;
  final String name;
  final String gradeRoom;
  final String issue;
  final String careCategory;
  final String riskLevel;
  final String adviser;
  final String suggestedAction;
  final String time;
  final Color color;

  const _UrgentCareStudent({
    required this.id,
    required this.name,
    required this.gradeRoom,
    required this.issue,
    required this.careCategory,
    required this.riskLevel,
    required this.adviser,
    required this.suggestedAction,
    required this.time,
    required this.color,
  });
}

class _CareDimension {
  final String title;
  final double progress;
  final String detail;
  final IconData icon;
  final Color color;

  const _CareDimension({
    required this.title,
    required this.progress,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class _FollowUpItem {
  final String title;
  final String detail;
  final String status;
  final IconData icon;
  final Color color;
  final String targetCount;
  final String actionLabel;

  const _FollowUpItem({
    required this.title,
    required this.detail,
    required this.status,
    required this.icon,
    required this.color,
    required this.targetCount,
    required this.actionLabel,
  });
}

class _AttendanceYAxis extends StatelessWidget {
  const _AttendanceYAxis();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 2, bottom: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('100', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
          Text('75', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
          Text('50', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
          Text('25', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
          Text('0', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _AttendanceGridLines extends StatelessWidget {
  const _AttendanceGridLines();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8, bottom: 29),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }
}
