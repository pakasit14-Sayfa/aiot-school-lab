import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/parent_common_widgets.dart';
import 'leave_request_dialog.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  static const Color _navy = Color(0xFF173B69);
  static const Color _bg = Color(0xFFF5F7FB);

  static const String mascotAsset = 'assets/images/mascot_parent.png';

  LinkedStudentItem? _selectedStudent;
  List<Map<String, dynamic>> _assignments = [];
  List<StudentAttendanceItem> _attendanceList = [];
  List<StudentScheduleItem> _scheduleList = [];
  List<Map<String, dynamic>> _sensorReadings = [];
  List<SchoolEventItem> _eventsList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final students = await ParentPortalService.listMyLinkedStudents();
      if (!mounted) return;
      if (students.isNotEmpty) {
        final firstStudent = students.first;
        final assignments = await ParentPortalService.listMyStudentAssignments(
          firstStudent.studentId,
        );
        final attendance = await ParentPortalService.listMyStudentAttendance(
          firstStudent.studentId,
          dateFrom: DateTime.now().subtract(const Duration(days: 90)), // Last 3 months approx
          dateTo: DateTime.now(),
        );
        final schedule = await ParentPortalService.listMyStudentSchedule(
          firstStudent.studentId,
        );
        
        List<Map<String, dynamic>> sensors = [];
        try {
          // Attempt to fetch school sensors
          sensors = await AiotLabService.getLatestSensorReadings();
        } catch (e) {
          sensors = [];
        }

        final events = await ParentPortalService.listSchoolEvents();

        if (mounted) {
          setState(() {
            _selectedStudent = firstStudent;
            _assignments = assignments;
            _attendanceList = attendance;
            _scheduleList = schedule;
            _sensorReadings = sensors;
            _eventsList = events;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading parent dashboard data: $e');
    }
  }

  int get _pendingAssignmentsCount {
    return _assignments.where((a) => a['status'] == 'pending' || a['status'] == 'returned').length;
  }

  String get _todayAttendanceTime {
    final today = DateTime.now();
    final todayRecords = _attendanceList.where((a) => 
      a.classDate.year == today.year && 
      a.classDate.month == today.month && 
      a.classDate.day == today.day
    ).toList();
    if (todayRecords.isEmpty) return 'ยังไม่มีข้อมูล';
    todayRecords.sort((a, b) => a.markedAt.compareTo(b.markedAt));
    final firstScan = todayRecords.first.markedAt.toLocal();
    return '${firstScan.hour.toString().padLeft(2, '0')}:${firstScan.minute.toString().padLeft(2, '0')} น.';
  }

  double get _attendanceRateValue {
    if (_attendanceList.isEmpty) return 0;
    final presentOrLate = _attendanceList.where((a) => a.status == 'present' || a.status == 'late').length;
    return presentOrLate / _attendanceList.length;
  }

  String get _attendanceRate {
    if (_attendanceList.isEmpty) return 'ยังไม่มีข้อมูล';
    return '${(_attendanceRateValue * 100).toStringAsFixed(0)}%';
  }
  
  int get _presentCount => _attendanceList.where((a) => a.status == 'present').length;
  int get _lateCount => _attendanceList.where((a) => a.status == 'late').length;
  int get _excusedCount => _attendanceList.where((a) => a.status == 'excused').length;

  String get _currentSubject {
    if (_scheduleList.isEmpty) return 'ไม่มีเรียน';
    final now = DateTime.now();
    final today = now.weekday; // 1 = Monday, 7 = Sunday
    final todaySchedule = _scheduleList.where((s) => s.dayOfWeek == today).toList();
    if (todaySchedule.isEmpty) return 'ไม่มีเรียน';
    
    for (var s in todaySchedule) {
      // Parse HH:mm from s.startTime and s.endTime
      try {
        final startParts = s.startTime.split(':');
        final endParts = s.endTime.split(':');
        final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
        final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
        if (now.isAfter(start) && now.isBefore(end)) {
          return 'กำลังเรียน${s.subjectName}';
        }
      } catch (_) {}
    }
    return 'พัก / ว่าง';
  }

  String get _currentRoom {
    if (_scheduleList.isEmpty) return 'อยู่ในโรงเรียน';
    final now = DateTime.now();
    final today = now.weekday;
    final todaySchedule = _scheduleList.where((s) => s.dayOfWeek == today).toList();
    for (var s in todaySchedule) {
      try {
        final startParts = s.startTime.split(':');
        final endParts = s.endTime.split(':');
        final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
        final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
        if (now.isAfter(start) && now.isBefore(end)) {
          return 'อยู่ที่ห้อง ${s.room ?? "เรียน"}';
        }
      } catch (_) {}
    }
    return 'อยู่ในโรงเรียน';
  }

  String get _envTemp {
    if (_sensorReadings.isEmpty) return 'N/A';
    final temp = _sensorReadings.where((s) => s['metric'] == 'temperature').firstOrNull;
    if (temp != null) return (temp['value'] as num).toStringAsFixed(1);
    return 'N/A';
  }

  String get _envPm25 {
    if (_sensorReadings.isEmpty) return 'N/A';
    final pm25 = _sensorReadings.where((s) => s['metric'] == 'pm25').firstOrNull;
    if (pm25 != null) return (pm25['value'] as num).toStringAsFixed(0);
    return 'N/A';
  }

  String get _envLux {
    if (_sensorReadings.isEmpty) return 'N/A';
    final lux = _sensorReadings.where((s) => s['metric'] == 'light_lux').firstOrNull;
    if (lux != null) return (lux['value'] as num).toStringAsFixed(0);
    return 'N/A';
  }

  String get _envAqi {
    if (_sensorReadings.isEmpty) return 'N/A';
    final aqi = _sensorReadings.where((s) => s['metric'] == 'aqi').firstOrNull;
    if (aqi != null) return (aqi['value'] as num).toStringAsFixed(0);
    return 'ปกติ'; // default fallback for smoke/gas card if no aqi
  }

  String get _studentNameDisplay {
    if (_selectedStudent != null && _selectedStudent!.firstName.isNotEmpty) {
      return _selectedStudent!.firstName;
    }
    return 'น้องมะลิ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ParentPageHeader(
                    title: 'ภาพรวมผู้ปกครอง',
                    subtitle:
                        'ติดตามข้อมูลสำคัญของบุตรหลานแบบรายวันในหน้าเดียว',
                    icon: Icons.dashboard_rounded,
                  ),
                  const SizedBox(height: 18),

                  // ----------------------------------------------------------
                  // HERO / การ์ดใหญ่ + มาสคอต
                  // ----------------------------------------------------------
                  _buildHeroCard(context),

                  const SizedBox(height: 16),
                  
                  // ----------------------------------------------------------
                  // QUICK ACTIONS (เมนูด่วนแบบ App UI)
                  // ----------------------------------------------------------
                  _buildQuickActions(context),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // QUICK STATUS
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1180
                          ? 3
                          : constraints.maxWidth >= 760
                              ? 3
                              : constraints.maxWidth >= 500
                                  ? 2
                                  : 1;

                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: width,
                            child: _StatusMetricCard(
                              title: 'มาเรียนวันนี้',
                              value: _todayAttendanceTime,
                              subtitle: _todayAttendanceTime == 'ยังไม่มีข้อมูล' ? 'ยังไม่ได้เช็คชื่อ' : 'เช็คชื่อเรียบร้อยแล้ว',
                              icon: Icons.login_rounded,
                              color: const Color(0xFF18A06F),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _StatusMetricCard(
                              title: 'อัตรามาเรียน',
                              value: _attendanceRate,
                              subtitle: 'อิงจากรายวิชาทั้งหมด',
                              icon: Icons.fact_check_rounded,
                              color: const Color(0xFF2E83C5),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _StatusMetricCard(
                              title: 'งานที่ต้องทำ',
                              value: '$_pendingAssignmentsCount งาน',
                              subtitle: 'งานค้างทั้งหมด',
                              icon: Icons.assignment_rounded,
                              color: const Color(0xFF8A65C7),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // ENVIRONMENT SENSOR
                  // Desktop: 4 ค่าเรียงแนวนอน
                  // Mobile: 2 คอลัมน์ x 2 แถว
                  // ----------------------------------------------------------
                  _EnvironmentSensorCard(
                    temp: _envTemp,
                    pm25: _envPm25,
                    lux: _envLux,
                    aqi: _envAqi,
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // TODAY + ATTENDANCE
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 760) {
                        return Column(
                          children: [
                            const _TodayStatusCard(),
                            const SizedBox(height: 14),
                            _AttendanceSummaryCard(
                              rate: _attendanceRate,
                              rateValue: _attendanceRateValue,
                              presentCount: _presentCount,
                              lateCount: _lateCount,
                              excusedCount: _excusedCount,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 6,
                            child: _TodayStatusCard(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 4,
                            child: _AttendanceSummaryCard(
                              rate: _attendanceRate,
                              rateValue: _attendanceRateValue,
                              presentCount: _presentCount,
                              lateCount: _lateCount,
                              excusedCount: _excusedCount,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // LEARNING + SCHEDULE
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            _HomeworkCard(assignments: _assignments),
                            const SizedBox(height: 14),
                            _ScheduleCard(schedule: _scheduleList),
                          ],
                        );
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _HomeworkCard(assignments: _assignments),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: _ScheduleCard(schedule: _scheduleList),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // HOMEWORK + SCHOOL MESSAGE + IMPORTANT ACTIVITY
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 980) {
                        return Column(
                          children: [
                            const _SchoolMessageCard(),
                            const SizedBox(height: 14),
                            _UpcomingActivityCard(events: _eventsList),
                          ],
                        );
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(child: _SchoolMessageCard()),
                            const SizedBox(width: 14),
                            Expanded(child: _UpcomingActivityCard(events: _eventsList)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: mobile ? 310 : 255,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF173B69),
                Color(0xFF215D9E),
                Color(0xFF2E83C5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -90,
                top: -120,
                child: Container(
                  width: 330,
                  height: 330,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Positioned(
                right: 120,
                bottom: -150,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.035),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 20 : 30,
                  mobile ? 22 : 28,
                  mobile ? 20 : 26,
                  mobile ? 18 : 25,
                ),
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroTextSection(context, compact: true),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.center,
                            child: _mascot(height: 145),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: _heroTextSection(context),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _mascot(height: 225),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroTextSection(
    BuildContext context, {
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.family_restroom_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PARENT PORTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!compact)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF42C88A).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF7EE4AE),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'สถานะปกติ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'สวัสดีครับ ผู้ปกครอง',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.80),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'วันนี้น้อง$_studentNameDisplayมาโรงเรียนเรียบร้อยแล้ว',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: compact ? 22 : 30,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'ม.2/1 · เลขที่ 18 · ปีการศึกษา 2569',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 18),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroBadge(
              icon: Icons.login_rounded,
              text: _todayAttendanceTime == 'ยังไม่มีข้อมูล' ? 'ยังไม่ได้เช็คชื่อ' : 'เข้าโรงเรียน $_todayAttendanceTime',
            ),
            _HeroBadge(
              icon: Icons.location_on_rounded,
              text: _todayAttendanceTime == 'ยังไม่มีข้อมูล' ? 'ยังไม่ถึงโรงเรียน' : _currentRoom,
            ),
            _HeroBadge(
              icon: Icons.menu_book_rounded,
              text: _todayAttendanceTime == 'ยังไม่มีข้อมูล' ? 'รอก่อนเข้าเรียน' : _currentSubject,
            ),
          ],
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'ติดต่อครูประจำชั้น',
              filled: true,
              onTap: () => _showMessage(
                context,
                'เปิดเมนูติดต่อครูประจำชั้น',
              ),
            ),
            _HeroActionButton(
              icon: Icons.edit_note_rounded,
              label: 'แจ้งลาเรียน',
              onTap: () => _showMessage(
                context,
                'เปิดแบบฟอร์มแจ้งลาเรียน',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mascot({double height = 200}) {
    return Image.asset(
      'assets/images/mascot_lion_clean.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: height * .78,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.family_restroom_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: height * .42,
              ),
              Positioned(
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MASCOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (
        Icons.edit_note_rounded,
        'แจ้งลาเรียน',
        const Color(0xFF2D82C4)
      ),
      (
        Icons.support_agent_rounded,
        'ติดต่อครู',
        const Color(0xFF17A06F)
      ),
      (
        Icons.draw_rounded,
        'เอกสารยินยอม',
        const Color(0xFF8A65C7)
      ),
      (
        Icons.directions_car_rounded,
        'แจ้งรับกลับ',
        const Color(0xFFF09A37)
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.apps_rounded,
            title: 'เมนูด่วน (Quick Apps)',
            subtitle: 'รวมบริการบ่อยสำหรับผู้ปกครอง',
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final action in actions)
                Expanded(
                  child: _QuickActionAppTile(
                    icon: action.$1,
                    title: action.$2,
                    color: action.$3,
                    onTap: () {
                      if (action.$2 == 'แจ้งลาเรียน') {
                        _showLeaveRequestForm(context);
                      } else {
                        _showMessage(context, 'เปิดเมนู ${action.$2}');
                      }
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLeaveRequestForm(BuildContext context) {
    if (_selectedStudent == null) {
      _showMessage(context, 'ไม่พบข้อมูลนักเรียน (Mock Mode: ทดสอบ UI เปิดได้ปกติแต่บันทึกไม่ได้)');
    }

    showDialog(
      context: context,
      builder: (context) {
        return LeaveRequestFormDialog(
          studentId: _selectedStudent?.studentId,
          onSubmitted: () {
            _showMessage(context, 'ส่งใบลาเรียบร้อยแล้ว รอครูประจำชั้นอนุมัติ');
          },
        );
      },
    );
  }
}

// ============================================================================
// HERO COMPONENTS
// ============================================================================

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: filled
          ? FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF245E9F),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// STATUS METRIC
// ============================================================================

class _StatusMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatusMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7E889A),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E2736),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8C95A5),
                    fontSize: 8.5,
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

// ============================================================================
// ENVIRONMENT SENSOR
// ============================================================================

class _EnvironmentSensorCard extends StatelessWidget {
  final String temp;
  final String pm25;
  final String lux;
  final String aqi;

  const _EnvironmentSensorCard({
    this.temp = 'N/A',
    this.pm25 = 'N/A',
    this.lux = 'N/A',
    this.aqi = 'ปกติ',
  });

  @override
  Widget build(BuildContext context) {
    final sensors = [
      _SensorData(
        icon: Icons.thermostat_rounded,
        title: 'อุณหภูมิ',
        value: temp,
        unit: '°C',
        status: temp == 'N/A' ? 'ไม่มีข้อมูล' : 'ปกติ',
        statusColor: temp == 'N/A' ? const Color(0xFF8A94A5) : const Color(0xFF18A06F),
        iconColor: const Color(0xFFF09A37),
      ),
      _SensorData(
        icon: Icons.blur_on_rounded,
        title: 'ฝุ่น PM2.5',
        value: pm25,
        unit: 'µg/m³',
        status: pm25 == 'N/A' ? 'ไม่มีข้อมูล' : 'อากาศดี',
        statusColor: pm25 == 'N/A' ? const Color(0xFF8A94A5) : const Color(0xFF18A06F),
        iconColor: const Color(0xFF2E83C5),
      ),
      _SensorData(
        icon: Icons.light_mode_rounded,
        title: 'ความเข้มแสง',
        value: lux,
        unit: 'lux',
        status: lux == 'N/A' ? 'ไม่มีข้อมูล' : 'เหมาะสม',
        statusColor: lux == 'N/A' ? const Color(0xFF8A94A5) : const Color(0xFF18A06F),
        iconColor: const Color(0xFFE5A52A),
      ),
      _SensorData(
        icon: Icons.air_rounded,
        title: 'แก๊สและควัน',
        value: aqi == 'N/A' ? 'ไม่มีข้อมูล' : 'ปกติ',
        unit: '',
        status: aqi == 'N/A' ? 'ไม่มีข้อมูล' : 'ไม่พบความผิดปกติ',
        statusColor: aqi == 'N/A' ? const Color(0xFF8A94A5) : const Color(0xFF18A06F),
        iconColor: const Color(0xFF8B5CF6),
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.sensors_rounded,
            title: 'สิ่งแวดล้อมภายในโรงเรียน',
            subtitle: 'ข้อมูลที่ตรวจวัดจากเซนเซอร์ภายในพื้นที่โรงเรียน',
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              // มือถือ = 2 ค่า/แถว
              // คอม = 4 ค่า/แถวเดียว
              final bool mobile = constraints.maxWidth < 650;
              final int columns = mobile ? 2 : 4;
              const double gap = 10;

              final double itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final sensor in sensors)
                    SizedBox(
                      width: itemWidth,
                      child: _SensorValueTile(
                        icon: sensor.icon,
                        title: sensor.title,
                        value: sensor.value,
                        unit: sensor.unit,
                        status: sensor.status,
                        statusColor: sensor.statusColor,
                        iconColor: sensor.iconColor,
                        compact: mobile,
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 14,
                  color: Color(0xFF7F899A),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'อัปเดตจากเซนเซอร์ล่าสุด 10:52 น.',
                    style: TextStyle(
                      fontSize: 8.3,
                      color: Color(0xFF7F899A),
                    ),
                  ),
                ),
                _SensorOnlineBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorValueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final Color iconColor;
  final bool compact;

  const _SensorValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 112 : 105,
      ),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9ECF1),
        ),
      ),
      child: compact
          ? _buildMobileContent()
          : _buildDesktopContent(),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 21,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.7,
                  color: Color(0xFF7D8798),
                ),
              ),
              const SizedBox(height: 2),
              _buildValue(),
              const SizedBox(height: 5),
              _buildStatus(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const Spacer(),
            _buildStatus(),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.2,
            color: Color(0xFF7D8798),
          ),
        ),
        const SizedBox(height: 2),
        _buildValue(),
      ],
    );
  }

  Widget _buildValue() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF202A38),
            ),
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              unit,
              style: TextStyle(
                fontSize: compact ? 7.5 : 8.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7D8798),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: statusColor,
          fontSize: compact ? 6.2 : 7.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SensorOnlineBadge extends StatelessWidget {
  const _SensorOnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFF18A06F),
          ),
          SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(
              color: Color(0xFF169A6E),
              fontSize: 7.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorData {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final Color iconColor;

  const _SensorData({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.iconColor,
  });
}


// ============================================================================
// TODAY
// ============================================================================

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        '07:41',
        'เข้าโรงเรียน',
        'บันทึกการเข้าโรงเรียนเรียบร้อย',
        Icons.login_rounded,
        Color(0xFF18A06F)
      ),
      (
        '09:30',
        'คณิตศาสตร์',
        'กำลังเรียน · ห้อง ม.2/1',
        Icons.calculate_rounded,
        Color(0xFF2E83C5)
      ),
      (
        '10:30',
        'วิทยาศาสตร์',
        'คาบถัดไป · Lab 2',
        Icons.science_rounded,
        Color(0xFF8566C3)
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.timeline_rounded,
            title: 'สถานะของลูกวันนี้',
            subtitle: 'กิจกรรมและสถานะล่าสุด',
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8993A4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.$5.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.$4,
                      size: 17,
                      color: item.$5,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8791A2),
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
    );
  }
}

// ============================================================================
// ATTENDANCE
// ============================================================================

class _AttendanceSummaryCard extends StatelessWidget {
  final String rate;
  final double rateValue;
  final int presentCount;
  final int lateCount;
  final int excusedCount;

  const _AttendanceSummaryCard({
    this.rate = 'ยังไม่มีข้อมูล',
    this.rateValue = 0,
    this.presentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.fact_check_rounded,
            title: 'สรุปการมาเรียน',
            subtitle: 'ภาคเรียน 1/2569',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rate,
                    style: const TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF18996C),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (rateValue >= 0.8)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ปกติ',
                      style: TextStyle(
                        color: Color(0xFF169A6E),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(
              value: rateValue.isNaN ? 0 : rateValue,
              minHeight: 9,
              backgroundColor: const Color(0xFFEDF0F5),
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF2B8FC2),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _AttendanceBox(
                  value: presentCount.toString(),
                  label: 'มาเรียน',
                  color: const Color(0xFF18A06F),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _AttendanceBox(
                  value: excusedCount.toString(),
                  label: 'ลา',
                  color: const Color(0xFFF09A37),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _AttendanceBox(
                  value: lateCount.toString(),
                  label: 'สาย',
                  color: const Color(0xFFDA5961),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AttendanceBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              color: Color(0xFF7E8898),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LEARNING
// ============================================================================

class _LearningOverviewCard extends StatelessWidget {
  const _LearningOverviewCard();

  @override
  Widget build(BuildContext context) {
    const subjects = [
      ('คณิตศาสตร์', 88, '+5', Color(0xFF2E83C5)),
      ('วิทยาศาสตร์', 91, '+7', Color(0xFF18A06F)),
      ('ภาษาอังกฤษ', 82, '+2', Color(0xFF8A65C7)),
      ('ภาษาไทย', 86, '+3', Color(0xFFF09A37)),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.analytics_rounded,
                  title: 'ภาพรวมการเรียนของลูก',
                  subtitle: 'คะแนนล่าสุดและแนวโน้มรายวิชา',
                ),
              ),
              _SmallChip(text: 'GPA 3.62'),
            ],
          ),
          const SizedBox(height: 14),
          for (final subject in subjects)
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  SizedBox(
                    width: 105,
                    child: Text(
                      subject.$1,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LinearProgressIndicator(
                        value: subject.$2 / 100,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEDF0F5),
                        valueColor: AlwaysStoppedAnimation(
                          subject.$4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${subject.$2}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 26,
                    child: Text(
                      subject.$3,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Color(0xFF169A6E),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDCE9F8),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: Color(0xFF2D76B8),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Insight: วิทยาศาสตร์พัฒนาขึ้นต่อเนื่อง ส่วนภาษาอังกฤษควรเสริม Vocabulary และ Reading เพิ่มอีกเล็กน้อย',
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.55,
                      color: Color(0xFF52647A),
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

// ============================================================================
// SCHEDULE
// ============================================================================

class _ScheduleCard extends StatelessWidget {
  final List<StudentScheduleItem> schedule;
  const _ScheduleCard({this.schedule = const []});

  String _formatDateThai(DateTime date) {
    final days = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์'
    ];
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${days[date.weekday % 7]} ${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.weekday;
    final todaySchedule = schedule.where((s) => s.dayOfWeek == today).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.schedule_rounded,
            title: 'ตารางเรียนวันนี้',
            subtitle: _formatDateThai(now),
          ),
          const SizedBox(height: 13),
          if (todaySchedule.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'ไม่มีตารางเรียนวันนี้',
                  style: TextStyle(
                    color: Color(0xFF8993A4),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            for (final lesson in todaySchedule)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 43,
                      child: Text(
                        lesson.startTime.substring(0, 5),
                        style: const TextStyle(
                          color: Color(0xFF8993A4),
                          fontSize: 8.7,
                        ),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isCurrentLesson(lesson, now)
                            ? const Color(0xFFFF9B3D)
                            : const Color(0xFF63A0DA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  lesson.subjectName,
                                  style: const TextStyle(
                                    color: Color(0xFF333E52),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (_isCurrentLesson(lesson, now)) ...[
                                const SizedBox(width: 6),
                                const _SmallChip(
                                  text: 'กำลังเรียน',
                                  orange: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lesson.room ?? 'ห้องเรียนปกติ',
                            style: const TextStyle(
                              color: Color(0xFF8993A4),
                              fontSize: 8.3,
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
    );
  }

  bool _isCurrentLesson(StudentScheduleItem lesson, DateTime now) {
    try {
      final startParts = lesson.startTime.split(':');
      final endParts = lesson.endTime.split(':');
      final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }
}

// ============================================================================
// HOMEWORK
// ============================================================================

class _HomeworkCard extends StatelessWidget {
  final List<Map<String, dynamic>> assignments;
  const _HomeworkCard({required this.assignments});

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.assignment_rounded,
            title: 'ภาระงานและการบ้าน',
            subtitle: 'รายการงานค้างและกำหนดส่งของแต่ละรายวิชา',
          ),
          const SizedBox(height: 12),
          if (assignments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'ไม่มีภาระงานค้าง',
                  style: TextStyle(color: Color(0xFF8A94A5), fontSize: 10.5),
                ),
              ),
            )
          else
            ...assignments.map((assignment) {
              final title = assignment['title'] as String? ?? 'ไม่มีชื่อ';
              final courseName = assignment['course_name'] as String? ?? '';
              final dueAtStr = assignment['due_at'] as String?;
              final status = assignment['status'] as String? ?? 'pending';
              
              String dueDisplay = 'ไม่มีกำหนด';
              if (dueAtStr != null) {
                final d = DateTime.tryParse(dueAtStr)?.toLocal();
                if (d != null) {
                  dueDisplay = 'ส่ง ${d.day}/${d.month} เวลา ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} น.';
                }
              }

              final isDone = status != 'pending';
              final color = isDone ? const Color(0xFF18A06F) : const Color(0xFFF09A37);
              final statusText = isDone ? 'ส่งแล้ว' : 'รอส่ง';

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFEDF0F4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$courseName: $title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            dueDisplay,
                            style: const TextStyle(
                              fontSize: 8.2,
                              color: Color(0xFF8A94A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                         statusText,
                        style: TextStyle(
                          color: color,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

// ============================================================================
// MESSAGE
// ============================================================================

class _SchoolMessageCard extends StatelessWidget {
  const _SchoolMessageCard();

  @override
  Widget build(BuildContext context) {
    const messages = [
      (
        Icons.person_rounded,
        'ครูประจำชั้น',
        'พรุ่งนี้เตรียมอุปกรณ์วิทยาศาสตร์'
      ),
      (
        Icons.school_rounded,
        'ฝ่ายวิชาการ',
        'สอบกลางภาค 7–11 ก.ย.'
      ),
      (
        Icons.campaign_rounded,
        'ประชาสัมพันธ์',
        'กิจกรรมวันวิทยาศาสตร์'
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.chat_bubble_rounded,
            title: 'ข้อความจากโรงเรียน',
            subtitle: 'ประกาศและข้อความล่าสุด',
          ),
          const SizedBox(height: 12),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      message.$1,
                      size: 18,
                      color: const Color(0xFF2B73B5),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                          ),
                        ),
                        Text(
                          message.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8.3,
                            color: Color(0xFF8993A4),
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
    );
  }
}


// ============================================================================
// IMPORTANT ACTIVITY / SCHEDULE
// ============================================================================

class _UpcomingActivityCard extends StatelessWidget {
  final List<SchoolEventItem> events;
  const _UpcomingActivityCard({this.events = const []});

  String _formatShortDate(DateTime date) {
    final months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.event_rounded,
            title: 'กิจกรรมและกำหนดการสำคัญ',
            subtitle: 'สิ่งที่ผู้ปกครองควรทราบล่วงหน้า',
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'ยังไม่มีกำหนดการใหม่',
                  style: TextStyle(
                    color: Color(0xFF8993A4),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            for (final event in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatShortDate(event.startDate),
                        style: const TextStyle(
                          color: Color(0xFF173B69), // Navy color
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Color(0xFF333E52),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.location ?? 'ไม่ระบุสถานที่',
                            style: const TextStyle(
                              color: Color(0xFF8993A4),
                              fontSize: 8.5,
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
    );
  }
}


// ============================================================================
// COMMON SMALL COMPONENTS
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: const Color(0xFF2867B2),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF202A39),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: Color(0xFF8A94A4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _SmallChip extends StatelessWidget {
  final String text;
  final bool orange;

  const _SmallChip({
    required this.text,
    this.orange = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        orange ? const Color(0xFFDF7C21) : const Color(0xFF2B75B8);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuickActionAppTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionAppTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333E52),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE8EBF1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 7.8,
                        color: Color(0xFF8A94A4),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: Color(0xFF9BA4B2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
