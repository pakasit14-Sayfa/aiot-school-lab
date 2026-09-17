import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../controllers/director_overview_controller.dart';
import '../theme/app_palette.dart';
import '../widgets/director_overview_sensors.dart';
import '../widgets/director_workspace_widgets.dart';

class DirectorOverviewPage extends StatefulWidget {
  const DirectorOverviewPage({
    super.key,
    required this.onNavigate,
    this.sensorStreamOverride,
    this.rawReadingsStreamOverride,
    this.controller,
  });
  final ValueChanged<int> onNavigate;
  final Stream<SensorModel?>? sensorStreamOverride;
  final Stream<List<Map<String, dynamic>>>? rawReadingsStreamOverride;
  final DirectorOverviewController? controller;
  @override
  State<DirectorOverviewPage> createState() => _DirectorOverviewPageState();
}

class _DirectorOverviewPageState extends State<DirectorOverviewPage> {
  static const _thaiMonths = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];
  static const _thaiDays = [
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];

  late final DirectorOverviewController controller =
      widget.controller ?? DirectorOverviewController();
  int noticeFilter = 0;
  Timer? _retryTimer;
  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.load();
    });
    _retryTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && controller.loading && AuthService.sessionToken != null) {
        controller.load();
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    controller.removeListener(_refresh);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String date(DateTime d) => '${d.day}/${d.month}/${d.year + 543}';

  String noticeDateTime(DateTime value) {
    final d = value.toLocal();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${date(d)} · $hour:$minute น.';
  }

  String get todayDate {
    final now = DateTime.now();
    return '${_thaiDays[now.weekday - 1]}ที่ ${now.day} ${_thaiMonths[now.month - 1]} พ.ศ. ${now.year + 543}';
  }

  BoxDecoration get whiteCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
    boxShadow: const [
      BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
  );

  @override
  Widget build(BuildContext context) => DirectorWorkspace(
    child: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hero(box.maxWidth),
            const SizedBox(height: 16),
            content(box.maxWidth),
          ],
        ),
      ),
    ),
  );

  Widget hero(double width) {
    final phone = width < 700;
    final smallPhone = width < 520;
    final loaded = controller.loadedAt;
    final loadedText = loaded == null
        ? 'กำลังโหลดข้อมูล'
        : 'อัปเดต ${loaded.hour.toString().padLeft(2, '0')}:${loaded.minute.toString().padLeft(2, '0')} น.';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(phone ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.heroPink, AppPalette.heroPinkDark],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.heroTag,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'ศูนย์ควบคุมสำหรับผู้อำนวยการโรงเรียน',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'ภาพรวมโรงเรียน\nAIoT Smart Lab',
                  style: TextStyle(
                    fontSize: phone ? 23 : 28,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ติดตามนักเรียน ครู เหตุฉุกเฉิน อุปกรณ์ และสภาพแวดล้อมในหน้าเดียว',
                  style: TextStyle(
                    fontSize: phone ? 11 : 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: smallPhone ? 10 : 13,
                    vertical: smallPhone ? 6 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(Colors.white, .18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppPalette.tint(Colors.white, .28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: smallPhone ? 15 : 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          todayDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: smallPhone ? 12 : 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _HeroTag(
                      Icons.cloud_done_rounded,
                      'เชื่อมต่อ Supabase',
                    ),
                    _HeroTag(Icons.schedule_rounded, loadedText),
                    const _HeroTag(Icons.verified_rounded, 'ข้อมูลปัจจุบัน'),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: phone ? 8 : 20),
          Flexible(
            child: Container(
              width: smallPhone ? 90 : (phone ? 150 : 240),
              height: smallPhone ? 90 : (phone ? 150 : 240),
              padding: EdgeInsets.all(smallPhone ? 4 : 8),
              decoration: BoxDecoration(
                color: AppPalette.tint(Colors.white, .12),
                borderRadius: BorderRadius.circular(
                  smallPhone ? 20 : (phone ? 30 : 38),
                ),
              ),
              child: Image.asset(
                'assets/images/robot_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.smart_toy_rounded,
                  size: 84,
                  color: AppPalette.primaryPink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget content(double width) {
    final d = controller.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        overviewHeading(),
        const SizedBox(height: 7),
        Text(
          '${date(DateTime.now())} · ยอดทะเบียนเป็นข้อมูลปัจจุบัน ไม่ใช่ยอดย้อนหลัง',
          style: const TextStyle(fontSize: 11, color: AppPalette.textMuted),
        ),
        const SizedBox(height: 16),
        if (controller.loading)
          stateCard('กำลังโหลดภาพรวม', const LinearProgressIndicator())
        else if (controller.error != null)
          stateCard(
            'โหลดภาพรวมไม่สำเร็จ',
            TextButton(
              onPressed: () => controller.load(),
              child: const Text('ลองอีกครั้ง'),
            ),
          )
        else if (d == null || d.isEmpty)
          stateCard(
            'ยังไม่มีข้อมูลภาพรวม',
            const Text('เมื่อโรงเรียนมีข้อมูล จะแสดงที่นี่'),
          )
        else ...[
          summaries(width, d),
          const SizedBox(height: 16),
          overviewRow(width, d),
          const SizedBox(height: 16),
          resourceRow(width, d),
          const SizedBox(height: 16),
          attendanceRow(width, d),
          const SizedBox(height: 16),
          important(d),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget overviewHeading() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'ภาพรวมข้อมูล',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 2),
      Text(
        'ข้อมูลปัจจุบันของโรงเรียน · แนวโน้มทรัพยากร ${controller.days} วันล่าสุด',
        style: const TextStyle(fontSize: 11, color: AppPalette.textMuted),
      ),
    ],
  );

  Widget stateCard(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: whiteCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget summaries(double width, DirectorOverviewData d) {
    final incidents = d.incidents.fold<int>(0, (n, i) => n + i.totalCount);
    final items = [
      _Summary(
        'นักเรียนทั้งหมด',
        d.counts.containsKey('student') ? '${d.counts['student']}' : '—',
        'คน',
        'นักเรียนที่ใช้งานอยู่',
        Icons.groups_rounded,
        const Color(0xFFE6F7ED),
        const Color(0xFF047857),
        2,
      ),
      _Summary(
        'ครูและบุคลากร',
        d.counts.containsKey('teacher') ? '${d.counts['teacher']}' : '—',
        'คน',
        'ครูในทะเบียนปัจจุบัน',
        Icons.co_present_rounded,
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        3,
      ),
      _Summary(
        'ความปลอดภัย & ฉุกเฉิน',
        '$incidents',
        'เหตุการณ์',
        incidents > 0 ? 'พบรายงานในระบบ' : 'ไม่พบรายงานในระบบ',
        Icons.warning_amber_rounded,
        const Color(0xFFFFE4E6),
        const Color(0xFFBE123C),
        1,
      ),
      _Summary(
        'อุปกรณ์ IoT ในห้องเรียน',
        '${d.devices.length}',
        'จุด',
        'อุปกรณ์ในทะเบียน',
        Icons.sensors_rounded,
        const Color(0xFFF3E8FF),
        const Color(0xFF6D28D9),
        8,
      ),
    ];
    return GridView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width < 520 ? 1 : (width < 900 ? 2 : 4),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: width < 650 ? 142 : 138,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        return InkWell(
          key: ValueKey('overview_summary_$index'),
          borderRadius: BorderRadius.circular(18),
          onTap: index == 0
              ? () => _showStudentAttendanceSummary(context, d)
              : () => widget.onNavigate(item.page),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: item.headerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 15, color: item.headerColor),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.headerColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ดูข้อมูล',
                              style: TextStyle(
                                fontSize: 9.2,
                                fontWeight: FontWeight.w700,
                                color: item.headerColor,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 8,
                              color: item.headerColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -.6,
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
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStudentAttendanceSummary(BuildContext context, DirectorOverviewData d) {
    showDialog<void>(
      context: context,
      builder: (_) => _StudentAttendanceSummaryDialog(
        totalStudents: d.counts['student'],
        rooms: d.studentAttendance,
        todayLabel: _todayLabel,
        onViewReport: () {
          Navigator.of(context).pop();
          widget.onNavigate(3);
        },
      ),
    );
  }

  Widget overviewRow(double width, DirectorOverviewData data) {
    if (width < 1020) {
      return Column(
        children: [learning(data), const SizedBox(height: 16), teachers(data)],
      );
    }
    return SizedBox(
      height: 420,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: learning(data)),
          const SizedBox(width: 16),
          Expanded(child: teachers(data)),
        ],
      ),
    );
  }

  Widget resourceRow(double width, DirectorOverviewData data) {
    final sensors = DirectorOverviewSensors(
      sensorStreamOverride: widget.sensorStreamOverride,
      rawReadingsStreamOverride: widget.rawReadingsStreamOverride,
    );
    if (width < 1020) {
      return Column(
        children: [
          utilities(data, isCompact: true),
          const SizedBox(height: 16),
          sensors,
        ],
      );
    }
    return SizedBox(
      height: 460,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: utilities(data)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: sensors),
        ],
      ),
    );
  }

  /// 2 บล็อกนี้เคยอยู่บนหน้าภาพรวมเวอร์ชัน 7 ก.ย. แต่ตัวเลขเป็นของแต่งขึ้น
  /// (ติดป้าย "ข้อมูลจำลอง") เลยถูกรื้อออกตอนล้างข้อมูลปลอมออกจากหน้านี้
  /// ตอนนี้มี RPC จริงรองรับทั้งคู่แล้ว จึงเอาโครงกลับมาโดยผูกกับข้อมูลจริง
  Widget attendanceRow(double width, DirectorOverviewData d) {
    final a = studentAttendance(d);
    final b = staffAttendance(d);
    if (width < 1020) {
      return Column(children: [a, const SizedBox(height: 16), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  String get _todayLabel {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year + 543}';
  }

  Widget studentAttendance(DirectorOverviewData d) {
    final rooms = d.studentAttendance;
    final students = rooms.fold<int>(0, (n, r) => n + r.studentCount);
    final present = rooms.fold<int>(0, (n, r) => n + r.present);
    final late = rooms.fold<int>(0, (n, r) => n + r.late);
    final absent = rooms.fold<int>(0, (n, r) => n + r.absent);
    final excused = rooms.fold<int>(0, (n, r) => n + r.excused);
    final unknown = rooms.fold<int>(0, (n, r) => n + r.unknown);

    return section([
      header('การเข้าเรียนของนักเรียน', 'เช็กชื่อของวันที่ $_todayLabel', 3),
      const SizedBox(height: 14),
      if (rooms.isEmpty)
        const _AttendanceEmpty(
          icon: Icons.checklist_rtl_rounded,
          message: 'ยังไม่มีการเช็กชื่อของวันนี้',
          hint: 'ตัวเลขจะขึ้นเมื่อครูประจำชั้นบันทึกการเข้าเรียนแล้ว',
        )
      else ...[
        _attendanceHeroLayout(
          hero: _AttendanceHero(
            label: 'มาเรียน',
            icon: Icons.how_to_reg_rounded,
            value: present,
            total: students,
          ),
          chipGrid: _chipGrid([
            _AttendanceChip(
              label: 'สาย',
              value: late,
              color: AppPalette.chartCream,
              icon: Icons.schedule_rounded,
            ),
            _AttendanceChip(
              label: 'ลา',
              value: excused,
              color: AppPalette.chartBlue,
              icon: Icons.event_busy_rounded,
            ),
            _AttendanceChip(
              label: 'ขาด',
              value: absent,
              color: AppPalette.chartPink,
              icon: Icons.person_off_rounded,
            ),
            if (unknown > 0)
              _AttendanceChip(
                label: 'ยังไม่เช็ก',
                value: unknown,
                color: AppPalette.textMuted,
                icon: Icons.help_outline_rounded,
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Text(
          // เดิมใช้ rooms.length เฉยๆ ซึ่งนับ "ห้องที่มีในระบบ" ไม่ใช่ "ห้องที่
          // เช็กชื่อแล้วจริง" — ทุกห้องที่ยังไม่มีใครกดเช็กชื่อเลยก็ถูกนับรวมว่า
          // "เช็กชื่อแล้ว" ไปด้วย ทั้งที่แถวนั้น unknown เท่ากับ studentCount
          // ทั้งห้อง แก้ให้นับเฉพาะห้องที่มีการบันทึกจริงอย่างน้อย 1 คน
          'เช็กชื่อแล้ว ${rooms.where((r) => r.recorded > 0).length} จาก ${rooms.length} ห้อง · นักเรียนรวม $students คน',
          style: const TextStyle(fontSize: 12, color: AppPalette.textMuted),
        ),
      ],
    ]);
  }

  Widget staffAttendance(DirectorOverviewData d) {
    final s = d.staffAttendance;
    return section([
      header('การมาปฏิบัติหน้าที่ของครู', 'ลงเวลาของวันที่ $_todayLabel', 4),
      const SizedBox(height: 14),
      if (s == null)
        const _AttendanceEmpty(
          icon: Icons.lock_outline_rounded,
          message: 'ยังไม่มีข้อมูลการลงเวลา',
          hint: 'ต้องเข้าสู่ระบบด้วยบัญชีที่มีสิทธิ์ดูข้อมูลบุคลากร',
        )
      else if (!s.workHoursConfigured)
        // เคสจริงที่เกิดบ่อย: โรงเรียนยังไม่ตั้งเวลาปฏิบัติงาน ครูจึงลงเวลา
        // ไม่ได้เลย — ต้องบอกสาเหตุ ไม่ใช่โชว์ 0 เฉย ๆ ให้เข้าใจว่าไม่มีใครมา
        const _AttendanceEmpty(
          icon: Icons.schedule_rounded,
          message: 'ยังไม่ได้ตั้งเวลาปฏิบัติงานของโรงเรียน',
          hint: 'ครูจะลงเวลาไม่ได้จนกว่าผู้ดูแลโรงเรียนจะตั้งค่าก่อน',
        )
      else ...[
        // Deliberately not _attendanceHeroLayout — student and staff
        // attendance used to be visually identical (same pink hero+grid,
        // told apart only by reading the header text). Staff gets its own
        // shape too now (wide banner + a horizontal strip of cells below,
        // blue instead of pink) so the two cards read as different sections
        // at a glance, not just a copy-pasted card with different numbers.
        _StaffAttendanceBanner(
          label: 'มาปฏิบัติงาน',
          icon: Icons.how_to_reg_rounded,
          value: s.presentCount,
          total: s.totalStaff,
        ),
        _StaffAttendanceStrip([
          _StaffCell(
            label: 'สาย',
            value: s.lateCount,
            color: AppPalette.chartCream,
          ),
          _StaffCell(
            label: 'ลา',
            value: s.leaveCount,
            color: AppPalette.chartBlue,
          ),
          _StaffCell(
            label: 'ไปราชการ',
            value: s.officialDutyCount,
            color: AppPalette.chartPink3,
          ),
          _StaffCell(
            label: 'ขาด',
            value: s.absentCount,
            color: AppPalette.chartPink,
          ),
          if (s.noRecordCount > 0)
            _StaffCell(
              label: 'ยังไม่ลงเวลา',
              value: s.noRecordCount,
              color: AppPalette.textMuted,
            ),
        ]),
        const SizedBox(height: 12),
        Text(
          'บุคลากรทั้งหมด ${s.totalStaff} คน',
          style: const TextStyle(fontSize: 12, color: AppPalette.textMuted),
        ),
      ],
    ]);
  }

  Widget header(String title, String subtitle, int page) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
      OutlinedButton(
        onPressed: () => widget.onNavigate(page),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: const BorderSide(color: Color(0xFFE5E5EA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'ดูรายงาน',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppPalette.textDark,
          ),
        ),
      ),
    ],
  );

  Widget learning(DirectorOverviewData d) => section([
    header(
      'ภาพรวมตามสายการเรียน',
      'จำนวนผู้เรียน ห้องเรียน และคะแนนที่ยืนยันแล้ว',
      2,
    ),
    const SizedBox(height: 14),
    if (d.tracks.isEmpty)
      const _Empty('ยังไม่มีข้อมูลสายการเรียน')
    else
      _LearningOverviewCards(
        tracks: d.tracks,
        onTap: () => widget.onNavigate(2),
      ),
  ]);

  // พอร์ตโครงสร้าง Container/Row/Column มาจาก _teacherOverviewCard ของเวอร์ชัน
  // 7 ก.ย. ตรง ๆ (ไม่ผ่าน header()/section() ทั่วไปที่ใช้กับการ์ดอื่น) เพื่อให้
  // padding/spacing/สไตล์ปุ่มตรงกับต้นฉบับเป๊ะ ต่างแค่เนื้อหากลุ่มสาระเป็นของจริง
  Widget teachers(DirectorOverviewData d) => Container(
    padding: const EdgeInsets.all(18),
    decoration: whiteCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ภาพรวมครูและการสอน',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.counts.containsKey('teacher')
                        ? 'ครูและบุคลากรทั้งหมด ${d.counts['teacher']} คน • สัดส่วนคาบสอนสัปดาห์นี้จากตารางสอนจริง'
                        : 'ยังไม่มีข้อมูลจำนวนครู',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.onNavigate(3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: const Text(
                  'ดูรายงาน',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (d.teacherWorkload == null || d.teacherWorkload!.isEmpty)
          const _Empty('ยังไม่มีข้อมูลตารางสอนในระบบ')
        else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 145),
            child: _BubbleCluster(bubbles: _workloadBubbles(d.teacherWorkload!)),
          ),
          const SizedBox(height: 10),
          const _DottedLine(),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: _WorkloadLegend(summary: d.teacherWorkload!),
          ),
          // red-team: "จัดครูสอนแทน"/"เตรียมสอน-ประชุม" พึ่งการบันทึกด้วยมือของ
          // ครู/ผู้ดูแล — เลข 0 ต่อเนื่องอาจแปลว่า "ยังไม่มีใครบันทึก" ไม่ใช่
          // "ไม่มีเหตุการณ์จริง" ต้องบอกไว้ตรงๆ ไม่งั้น ผอ. จะเข้าใจผิดว่าระบบ
          // พังหรือไม่มีครูสอนแทนเลยทั้งสัปดาห์
          if (d.teacherWorkload!.substitutionRecorded == 0 ||
              d.teacherWorkload!.prepMeetingCount == 0) ...[
            const SizedBox(height: 6),
            const Text(
              'หมายเหตุ: "จัดครูสอนแทน" และ "เตรียมสอน/ประชุม" นับจากการบันทึกของครู/ผู้ดูแลเอง ตัวเลขต่ำอาจแปลว่ายังไม่มีใครบันทึก ไม่ใช่ไม่มีเหตุการณ์จริง',
              style: TextStyle(fontSize: 8.5, color: AppPalette.textMuted, height: 1.3),
            ),
          ],
        ],
      ],
    ),
  );

  // 4 หมวดคาบสอนจริงของสัปดาห์นี้ — สีคงที่ต่อหมวด (ไม่ใช่สีตามอันดับขนาด)
  // ให้ตรงกับสีของ legend ด้านล่างเสมอไม่ว่าหมวดไหนจะใหญ่กว่ากัน
  List<_WorkloadBubble> _workloadBubbles(TeacherWorkloadSummary w) => [
    _WorkloadBubble(
      count: w.regularPeriods,
      bg: const Color(0xFFEDE9FE),
      text: const Color(0xFF5B21B6),
    ),
    _WorkloadBubble(
      count: w.activityLabPeriods,
      bg: const Color(0xFFDCFCE7),
      text: const Color(0xFF059669),
    ),
    _WorkloadBubble(
      count: w.substitutionRecorded,
      bg: const Color(0xFFFFE4E6),
      text: const Color(0xFFE11D48),
    ),
    _WorkloadBubble(
      count: w.prepMeetingCount,
      bg: const Color(0xFFFEF3C7),
      text: const Color(0xFFD97706),
    ),
  ];

  // isCompact มาจาก breakpoint ระดับหน้า (resourceRow, width<1020) ไม่ใช่ความ
  // กว้างของการ์ดนี้เอง — ตรงกับเวอร์ชัน 7 ก.ย. ที่ _utilityCard(isCompact)
  // รับค่ามาจากผู้เรียกเช่นกัน ก่อนหน้านี้ผมเคยเช็คความกว้างของการ์ดตัวเองแทน
  // (`box.maxWidth < 520`) ซึ่งแทบไม่มีทางจริงเพราะการ์ดนี้มักได้พื้นที่กว้าง
  // เกิน 520 อยู่แล้วแม้หน้าจะแคบ ทำให้ไฟฟ้า/น้ำขึ้นข้างกันเสมอ ต่างจากของเดิม
  // ที่วางซ้อนกันเมื่อทั้งหน้าแคบ
  // ย้ายตัวเลือกช่วงเวลา (รายวัน/สัปดาห์/เดือน) มาไว้ในหัวการ์ดนี้แทนที่จะอยู่
  // บนสุดของหน้า ให้ตรงตำแหน่งกับเวอร์ชัน 7 ก.ย. — ต่างกันแค่ของผมกดแล้วโหลด
  // ข้อมูลจริงจาก backend (controller.load) ส่วนของเดิมกดแล้วสลับชุดข้อมูล
  // จำลองที่ฝังไว้ในโค้ด (selectedUtilityPeriod ไม่เคยยิง RPC จริงเลย)
  Widget utilities(DirectorOverviewData d, {bool isCompact = false}) => section([
    LayoutBuilder(
      builder: (_, box) {
        final titleRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'แนวโน้มการใช้ทรัพยากร',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ข้อมูลไฟฟ้าและน้ำจากวันที่มีค่าบันทึกจริง',
                    style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                  ),
                ],
              ),
            ),
          ],
        );
        final selector = _OverviewPeriodSelector(
          days: controller.days,
          disabled: controller.loading,
          onSelected: (days) => controller.load(period: days),
        );
        return box.maxWidth < 560
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [titleRow, const SizedBox(height: 10), selector],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: titleRow), const SizedBox(width: 8), selector],
              );
      },
    ),
    const SizedBox(height: 14),
    Builder(
      builder: (_) {
        final a = trend(
          'ไฟฟ้า',
          'แนวโน้มการใช้ไฟฟ้า',
          Icons.bolt_rounded,
          d.energy,
          'kWh',
          AppPalette.chartPink,
          fillHeight: !isCompact,
        );
        final b = trend(
          'น้ำ',
          'แนวโน้มการใช้น้ำ',
          Icons.water_drop_rounded,
          d.water,
          'm³',
          AppPalette.chartBlue,
          fillHeight: !isCompact,
        );
        return isCompact
            ? Column(children: [a, const SizedBox(height: 10), b])
            : Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: a),
                    const SizedBox(width: 10),
                    Expanded(child: b),
                  ],
                ),
              );
      },
    ),
  ]);

  Widget trend(
    String title,
    String subtitle,
    IconData icon,
    List<UtilityTrendPoint> points,
    String unit,
    Color color, {
    bool fillHeight = false,
  }) {
    final total = points.fold<double>(0, (n, p) => n + p.value);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, .05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.tint(color, .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.tint(color, .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, color: AppPalette.textMuted),
                    ),
                  ],
                ),
              ),
              if (points.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(color, .12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$title ${points.last.value.toStringAsFixed(points.last.value >= 100 ? 0 : 1)} $unit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (points.isEmpty)
            const _Empty('ยังไม่มีข้อมูลย้อนหลัง')
          else ...[
            Text(
              'รวม ${total.toStringAsFixed(2)} $unit ในวันที่มีข้อมูล',
              style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
            ),
            const SizedBox(height: 10),
            if (fillHeight)
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _UtilityTrendPainter(points, color),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _UtilityTrendPainter(points, color),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget important(DirectorOverviewData d) {
    final unread = d.notices.where((notice) => notice.isUnread).toList();
    final read = d.notices.where((notice) => !notice.isUnread).toList();
    final visible = switch (noticeFilter) {
      1 => unread,
      2 => read,
      _ => d.notices,
    };
    return Container(
      width: double.infinity,
      decoration: whiteCard,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final heading = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 18,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'สิ่งที่ควรทราบวันนี้',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7D6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF6D46B)),
                    ),
                    child: const Text(
                      'ข้อมูลล่าสุด',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A6700),
                      ),
                    ),
                  ),
                ],
              );
              final filters = Wrap(
                spacing: 4,
                runSpacing: 6,
                children: [
                  _NoticeFilterChip(
                    label: 'ทั้งหมด (${d.notices.length})',
                    selected: noticeFilter == 0,
                    onTap: () => setState(() => noticeFilter = 0),
                  ),
                  _NoticeFilterChip(
                    label: 'ต้องติดตาม (${unread.length})',
                    selected: noticeFilter == 1,
                    onTap: () => setState(() => noticeFilter = 1),
                  ),
                  _NoticeFilterChip(
                    label: 'อ่านแล้ว (${read.length})',
                    selected: noticeFilter == 2,
                    onTap: () => setState(() => noticeFilter = 2),
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    const SizedBox(height: 12),
                    filters,
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('overview_notice_view_all'),
                        onPressed: () => widget.onNavigate(10),
                        child: const Text('ดูทั้งหมด'),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  filters,
                  const SizedBox(width: 4),
                  TextButton(
                    key: const ValueKey('overview_notice_view_all'),
                    onPressed: () => widget.onNavigate(10),
                    child: const Text('ดูทั้งหมด'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 5),
          const Text(
            'ข้อความและเหตุการณ์จริงล่าสุดที่ส่งถึงผู้อำนวยการ',
            style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const _Empty('ไม่มีรายการในหมวดนี้')
          else
            for (final notice in visible.take(5))
              _NoticeOverviewCard(
                notice: notice,
                dateText: noticeDateTime(notice.createdAt),
                onTap: () =>
                    widget.onNavigate(_NoticeVisual.from(notice).destination),
              ),
        ],
      ),
    );
  }

  Widget section(
    List<Widget> children, {
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: whiteCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: mainAxisAlignment,
      children: children,
    ),
  );

  // Hero stat on the left, chip grid on the right — stacks instead below
  // 480px. IntrinsicHeight + stretch makes the hero match whatever height
  // the chip grid needs (usually taller, being 2 rows), same technique used
  // for the notifications page's bento header. Safe here for the same
  // reason it was safe there: neither the hero nor the chip grid contains a
  // LayoutBuilder or a Column with its own Expanded/Flexible child, which is
  // what actually breaks under an ancestor IntrinsicHeight.
  Widget _attendanceHeroLayout({required Widget hero, required Widget chipGrid}) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [hero, const SizedBox(height: 10), chipGrid],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: hero),
              const SizedBox(width: 10),
              Expanded(flex: 6, child: chipGrid),
            ],
          ),
        );
      },
    );
  }

  // Pairs chips two-per-row regardless of count (4 or 5, depending on
  // whether an "unknown/no record" chip is present) — a lone odd chip out
  // gets a Spacer instead of stretching to double width, so chip size stays
  // consistent whether the row is full or not.
  Widget _chipGrid(List<Widget> chips) {
    final rows = <Widget>[];
    for (var i = 0; i < chips.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          children: [
            Expanded(child: chips[i]),
            const SizedBox(width: 10),
            if (i + 1 < chips.length)
              Expanded(child: chips[i + 1])
            else
              const Spacer(),
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

// The primary stat of an attendance card ("มาเรียน" / "มาปฏิบัติงาน") —
// pulled out of the old equal-weight grid of cards so it reads as the
// number that matters most, with the rest demoted to _AttendanceChip.
class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({
    required this.label,
    required this.icon,
    required this.value,
    required this.total,
  });

  final String label;
  final IconData icon;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.chartPink2, AppPalette.primaryPinkDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'จาก $total คน',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// The secondary stats beside the hero — small bordered chips instead of the
// old full-size card, so 4-5 of them together read as "detail" rather than
// competing with the hero for attention.
class _AttendanceChip extends StatelessWidget {
  const _AttendanceChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// Wide banner (blue, full width) instead of the student card's tall hero —
// staff attendance never has more than a handful of people (total_staff is
// teacher+school_admin+executive at this school), so giving it the same
// tall square hero as the 6-student card would out-weigh what it's actually
// reporting. Deliberately not rounded on the bottom — _StaffAttendanceStrip
// continues directly underneath it as one continuous shape.
class _StaffAttendanceBanner extends StatelessWidget {
  const _StaffAttendanceBanner({
    required this.label,
    required this.icon,
    required this.value,
    required this.total,
  });

  final String label;
  final IconData icon;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D95C4), Color(0xFF3D5D85)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                'จาก $total คน',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffCell {
  const _StaffCell({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;
}

// The row of cells under _StaffAttendanceBanner — same border radius on the
// bottom corners as the banner has on top, no border between them, so the
// two read as one shape split into a colored header and a data strip.
class _StaffAttendanceStrip extends StatelessWidget {
  const _StaffAttendanceStrip(this.cells);

  final List<_StaffCell> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1.1)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: cells[i].color, shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cells[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${cells[i].value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// "ไม่มีข้อมูล/ยังไม่ได้ตั้งค่า" — dashed border instead of a filled grey box,
// so an empty state reads as empty from its shape alone, not just its text.
class _AttendanceEmpty extends StatelessWidget {
  const _AttendanceEmpty({
    required this.icon,
    required this.message,
    required this.hint,
  });

  final IconData icon;
  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppPalette.softTag,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _OverviewPeriodSelector extends StatelessWidget {
  const _OverviewPeriodSelector({
    required this.days,
    required this.disabled,
    required this.onSelected,
  });

  final int days;
  final bool disabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const periods = [(1, 'รายวัน'), (7, 'สัปดาห์'), (30, 'เดือน')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final period in periods)
            InkWell(
              onTap: disabled ? null : () => onSelected(period.$1),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: days == period.$1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: days == period.$1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period.$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: days == period.$1
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: days == period.$1
                        ? AppPalette.textDark
                        : AppPalette.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoticeFilterChip extends StatelessWidget {
  const _NoticeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFFCBD5E1) : Colors.transparent,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: selected ? AppPalette.textDark : AppPalette.textMuted,
        ),
      ),
    ),
  );
}

class _NoticeOverviewCard extends StatelessWidget {
  const _NoticeOverviewCard({
    required this.notice,
    required this.dateText,
    required this.onTap,
  });

  final AppNotification notice;
  final String dateText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _NoticeVisual.from(notice);
    final statusColor = notice.isUnread
        ? AppPalette.primaryPink
        : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: notice.isUnread
                    ? AppPalette.tint(AppPalette.primaryPink, .55)
                    : const Color(0xFFDCE4EE),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: visual.color.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(visual.icon, size: 18, color: visual.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visual.label,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'การแจ้งเตือนจากระบบ · ${visual.label}',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: .28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            notice.isUnread ? 'ต้องติดตาม' : 'อ่านแล้ว',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
                if (notice.body?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    notice.body!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.45,
                      fontSize: 10,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 11),
                const Divider(height: 1, color: Color(0xFFEEF2F6)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppPalette.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '$dateText · ${notice.category ?? notice.type}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8.8,
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: ValueKey('overview_notice_action_${notice.id}'),
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: visual.color,
                        backgroundColor: visual.color.withValues(alpha: .08),
                        side: BorderSide(
                          color: visual.color.withValues(alpha: .2),
                        ),
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: Icon(visual.actionIcon, size: 11),
                      label: Text(visual.actionLabel),
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

class _NoticeVisual {
  const _NoticeVisual(
    this.label,
    this.icon,
    this.color,
    this.destination,
    this.actionLabel,
    this.actionIcon,
  );

  final String label;
  final IconData icon;
  final Color color;
  final int destination;
  final String actionLabel;
  final IconData actionIcon;

  factory _NoticeVisual.from(AppNotification notice) {
    final value = '${notice.category} ${notice.type}'.toLowerCase();
    if (value.contains('incident') ||
        value.contains('emergency') ||
        value.contains('sos')) {
      return const _NoticeVisual(
        'เหตุการณ์และความปลอดภัย',
        Icons.shield_rounded,
        Color(0xFFE83E68),
        1,
        'ดูเหตุการณ์',
        Icons.warning_amber_rounded,
      );
    }
    if (value.contains('meeting')) {
      return const _NoticeVisual(
        'การประชุม',
        Icons.groups_rounded,
        Color(0xFF7C3AED),
        5,
        'ดูการประชุม',
        Icons.groups_rounded,
      );
    }
    if (value.contains('energy') || value.contains('electric')) {
      return const _NoticeVisual(
        'พลังงาน',
        Icons.bolt_rounded,
        Color(0xFFF59E0B),
        8,
        'ดูทรัพยากร',
        Icons.bolt_rounded,
      );
    }
    if (value.contains('environment') || value.contains('water')) {
      return const _NoticeVisual(
        'สิ่งแวดล้อม',
        Icons.air_rounded,
        Color(0xFF10B981),
        8,
        'ดูสิ่งแวดล้อม',
        Icons.air_rounded,
      );
    }
    if (value.contains('student') || value.contains('support')) {
      return const _NoticeVisual(
        'การดูแลนักเรียน',
        Icons.school_rounded,
        Color(0xFF3B82F6),
        2,
        'ดูข้อมูลนักเรียน',
        Icons.school_rounded,
      );
    }
    return const _NoticeVisual(
      'การแจ้งเตือนทั่วไป',
      Icons.notifications_rounded,
      Color(0xFF64748B),
      10,
      'เปิดการแจ้งเตือน',
      Icons.open_in_new_rounded,
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppPalette.tint(Colors.white, .15),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppPalette.tint(Colors.white, .25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppPalette.softTag,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: AppPalette.textMuted),
    ),
  );
}

class _LearningOverviewCards extends StatelessWidget {
  const _LearningOverviewCards({required this.tracks, required this.onTap});

  final List<LearningTrackOverview> tracks;
  final VoidCallback onTap;

  Color _trackColor(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(0xFF000000 | (int.tryParse(hex, radix: 16) ?? 0x7C3AED));
  }

  @override
  Widget build(BuildContext context) {
    final graded = tracks
        .where((track) => track.avgGradePercent != null)
        .toList();
    final average = graded.isEmpty
        ? null
        : graded.fold<double>(0, (sum, track) => sum + track.avgGradePercent!) /
              graded.length;

    return Column(
      children: [
        for (final track in tracks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LearningTrackCard(
              track: track,
              color: _trackColor(track.color),
              onTap: onTap,
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 15,
                color: Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  average == null
                      ? 'ยังไม่มีคะแนนที่ครูยืนยันแล้วสำหรับคำนวณผลสัมฤทธิ์ภาพรวม'
                      : 'ผลสัมฤทธิ์เฉลี่ยทุกสายการเรียน ${average.toStringAsFixed(1)}% (จากคะแนนที่ครูยืนยันแล้ว)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearningTrackCard extends StatelessWidget {
  const _LearningTrackCard({
    required this.track,
    required this.color,
    required this.onTap,
  });

  final LearningTrackOverview track;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = track.avgGradePercent;
    final roundedScore = score?.round();

    return Material(
      color: color.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .28), width: .9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.school_rounded, size: 14.5, color: color),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: .8,
                      ),
                    ),
                    child: Text(
                      '${track.roomCount} ห้อง • ${track.studentCount} คน',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: color.withValues(alpha: .35),
                          width: .8,
                        ),
                      ),
                      child: Text(
                        '${score.toStringAsFixed(0)}% ผลการเรียน',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 15, color: color),
                ],
              ),
              const SizedBox(height: 6),
              if (roundedScore != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'ผลการเรียนเฉลี่ย (จากคะแนนที่ครูยืนยันแล้ว)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Text(
                      '$roundedScore%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (score! / 100).clamp(0, 1),
                    minHeight: 4.5,
                    color: color,
                    backgroundColor: color.withValues(alpha: .12),
                  ),
                ),
                const SizedBox(height: 6),
              ] else ...[
                const Text(
                  'ยังไม่มีคะแนนที่ครูยืนยันแล้ว',
                  style: TextStyle(fontSize: 9, color: AppPalette.textMuted),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'พฤติกรรมและสิ่งแวดล้อม: ยังไม่มีข้อมูลในระบบ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Text(
                    'แตะดูข้อมูล >',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackLineChart extends StatelessWidget {
  const _TrackLineChart({required this.tracks, required this.onTap});

  final List<LearningTrackOverview> tracks;
  final VoidCallback onTap;

  static const colors = [
    AppPalette.chartPink,
    AppPalette.chartBlue,
    Color(0xFF55BFA0),
    Color(0xFFE2A13A),
    Color(0xFF9B78D0),
  ];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                label: tracks
                    .map(
                      (track) =>
                          '${track.name} ${track.avgGradePercent == null ? 'ยังไม่มีคะแนนยืนยัน' : '${track.avgGradePercent!.toStringAsFixed(1)} เปอร์เซ็นต์'}',
                    )
                    .join(', '),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  height: 235,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPaint(
                    painter: _TrackLinePainter(tracks),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: LayoutBuilder(
                  builder: (context, box) {
                    return Wrap(
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < tracks.length; i++)
                          SizedBox(
                            width: box.maxWidth,
                            child: _TrackLegend(
                              track: tracks[i],
                              color: colors[i % colors.length],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackLinePainter extends CustomPainter {
  const _TrackLinePainter(this.tracks);
  final List<LearningTrackOverview> tracks;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 50.0;
    const top = 12.0;
    const bottom = 24.0;
    final plotWidth = (size.width - left - right).clamp(0.0, 500.0).toDouble();
    final chart = Rect.fromLTRB(
      left,
      top,
      left + plotWidth,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDF3)
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(
      color: AppPalette.textMuted,
      fontSize: 9,
    );
    for (final value in [0, 25, 50, 75, 100]) {
      final y = chart.bottom - chart.height * value / 100;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final label = TextPainter(
        text: TextSpan(text: '$value', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(chart.left - label.width - 7, y - label.height / 2),
      );
    }

    final valid = <Offset>[];
    final validIndexes = <int>[];
    for (var i = 0; i < tracks.length; i++) {
      final score = tracks[i].avgGradePercent;
      if (score == null) continue;
      final x = tracks.length == 1
          ? chart.center.dx
          : chart.left + chart.width * i / (tracks.length - 1);
      valid.add(
        Offset(x, chart.bottom - chart.height * (score / 100).clamp(0, 1)),
      );
      validIndexes.add(i);
    }
    if (valid.isEmpty) return;

    if (valid.length > 1) {
      final path = Path()..moveTo(valid.first.dx, valid.first.dy);
      for (final point in valid.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppPalette.chartPink
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (var i = 0; i < valid.length; i++) {
      final color = _TrackLineChart
          .colors[validIndexes[i] % _TrackLineChart.colors.length];
      canvas.drawCircle(valid[i], 7, Paint()..color = Colors.white);
      canvas.drawCircle(valid[i], 5, Paint()..color = color);
      final score = tracks[validIndexes[i]].avgGradePercent!;
      final label = TextPainter(
        text: TextSpan(
          text: '${score.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(
          (valid[i].dx - label.width / 2).clamp(
            chart.left,
            chart.right - label.width,
          ),
          valid[i].dy - 23,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackLinePainter oldDelegate) =>
      oldDelegate.tracks != tracks;
}

class _UtilityTrendPainter extends CustomPainter {
  const _UtilityTrendPainter(this.points, this.color);
  final List<UtilityTrendPoint> points;
  final Color color;

  static const _weekdayLabel = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 22.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final maxValue = points.fold<double>(
      0,
      (n, p) => p.value > n ? p.value : n,
    );
    final gridMax = maxValue <= 0 ? 1.0 : maxValue;
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDF3)
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(
      color: AppPalette.textMuted,
      fontSize: 9,
    );
    for (var i = 0; i <= 4; i++) {
      final value = gridMax * i / 4;
      final y = chart.bottom - chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final label = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(chart.left - label.width - 6, y - label.height / 2),
      );
    }
    if (points.isEmpty) return;

    final offsets = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          points.length == 1
              ? chart.center.dx
              : chart.left + chart.width * i / (points.length - 1),
          chart.bottom - chart.height * (points[i].value / gridMax).clamp(0, 1),
        ),
    ];

    if (offsets.length > 1) {
      final fillPath = Path()
        ..moveTo(offsets.first.dx, chart.bottom)
        ..lineTo(offsets.first.dx, offsets.first.dy);
      for (final o in offsets.skip(1)) {
        fillPath.lineTo(o.dx, o.dy);
      }
      fillPath
        ..lineTo(offsets.last.dx, chart.bottom)
        ..close();
      canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: .12));

      final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final o in offsets.skip(1)) {
        linePath.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < offsets.length; i++) {
      canvas.drawCircle(offsets[i], 4, Paint()..color = Colors.white);
      canvas.drawCircle(offsets[i], 2.6, Paint()..color = color);

      final showLabel = points.length <= 8 ||
          i == 0 ||
          i == points.length - 1 ||
          i % (points.length / 6).ceil() == 0;
      if (!showLabel) continue;
      final day = points[i].day;
      final dayLabel =
          '${_weekdayLabel[(day.weekday - 1).clamp(0, 6)]} ${day.day}';
      final label = TextPainter(
        text: TextSpan(text: dayLabel, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(
          (offsets[i].dx - label.width / 2).clamp(
            chart.left,
            chart.right - label.width,
          ),
          chart.bottom + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UtilityTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

class _StudentAttendanceSummaryDialog extends StatelessWidget {
  const _StudentAttendanceSummaryDialog({
    required this.totalStudents,
    required this.rooms,
    required this.todayLabel,
    required this.onViewReport,
  });
  final int? totalStudents;
  final List<SchoolHomeroomAttendance> rooms;
  final String todayLabel;
  final VoidCallback onViewReport;

  @override
  Widget build(BuildContext context) {
    final present = rooms.fold<int>(0, (n, r) => n + r.present);
    final absent = rooms.fold<int>(0, (n, r) => n + r.absent);
    final excused = rooms.fold<int>(0, (n, r) => n + r.excused);
    final byGrade = <String, List<SchoolHomeroomAttendance>>{};
    for (final r in rooms) {
      byGrade.putIfAbsent(r.gradeLevel ?? 'ไม่ระบุชั้น', () => []).add(r);
    }
    final grades = byGrade.keys.toList()..sort();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF047857),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'การเข้าเรียนของนักเรียน',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          'สรุปการเข้าเรียนของนักเรียนรายวัน · $todayLabel',
                          style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _dialogStat('ลงทะเบียนทั้งหมด', totalStudents?.toString() ?? '—'),
                  const SizedBox(width: 10),
                  _dialogStat('มาเรียนวันนี้', '$present', color: const Color(0xFF16A34A)),
                  const SizedBox(width: 10),
                  _dialogStat('ขาด/ลา', '${absent + excused}', color: const Color(0xFFD97706)),
                ],
              ),
              const SizedBox(height: 14),
              if (rooms.isEmpty)
                const Text(
                  'ยังไม่มีการเช็กชื่อของวันนี้',
                  style: TextStyle(fontSize: 12, color: AppPalette.textMuted),
                )
              else ...[
                const Text(
                  'สรุปการมาเรียนรายระดับชั้น:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      for (final grade in grades) ...[
                        _gradeRow(grade, byGrade[grade]!),
                        if (grade != grades.last) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onViewReport,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Text(
                        'ดูรายงานการเข้าเรียน >',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('เสร็จสิ้น'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogStat(String label, String value, {Color? color}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color ?? AppPalette.textDark,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _gradeRow(String grade, List<SchoolHomeroomAttendance> group) {
    final total = group.fold<int>(0, (n, r) => n + r.studentCount);
    final present = group.fold<int>(0, (n, r) => n + r.present);
    final late = group.fold<int>(0, (n, r) => n + r.late);
    final absent = group.fold<int>(0, (n, r) => n + r.absent);
    final pct = total <= 0 ? 0.0 : present * 100 / total;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(grade, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text(
                'ลา $late คน · ขาด $absent คน',
                style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
              ),
            ],
          ),
        ),
        Text(
          'มาเรียน $present / $total คน (${pct.toStringAsFixed(1)}%)',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }
}

/// (พื้นหลังพาสเทล, ตัวหนังสือสี) — สีชุดเดียวกับกราฟฟองสบู่เวอร์ชัน 7 ก.ย.
/// เป๊ะ (ม่วง/เขียว/ชมพู/ส้ม) บวกอีก 2 คู่โทนเดียวกันสำหรับกลุ่มสาระที่ 5-6
/// หนึ่งหมวดคาบสอน — สีคงที่ต่อหมวด ไม่ใช่สีตามอันดับขนาดหลังเรียง
class _WorkloadBubble {
  const _WorkloadBubble({required this.count, required this.bg, required this.text});
  final int count;
  final Color bg, text;
}

/// วงกลมทับกันเป็นก้อนเดียว แบบเดียวกับกราฟฟองสบู่เวอร์ชัน 7 ก.ย. — ต่างจาก
/// ของเดิมตรงที่สัดส่วนมาจาก 4 หมวดคาบสอนจริงของสัปดาห์นี้ ไม่ใช่ตัวเลขแต่งขึ้น
class _BubbleCluster extends StatelessWidget {
  const _BubbleCluster({required this.bubbles});
  final List<_WorkloadBubble> bubbles;

  // ตำแหน่งตายตัวต่อ "หมวด" (ไม่ใช่ต่ออันดับขนาด) คัดลอกพิกัดพิกเซลจริงจาก
  // เวอร์ชัน 7 ก.ย. ตรง ๆ (left:10,top:14 / left:148,top:8 / left:144,top:96 /
  // left:236,top:92 บนผ้าใบ 300x180) แล้วแปลงเป็นจุดศูนย์กลาง — ตอนแรกลองใช้
  // สูตรเรียงตามอันดับขนาดแทน แต่หมวดจริงมักมีค่าเท่ากันหลายหมวด (เช่น 1/1/1
  // คาบ) ทำให้เรียงแล้วได้แถวเกือบเป็นเส้นตรง ไม่ใช่ก้อนคลัสเตอร์เหมือนต้นฉบับ
  // — ของจริงควรคงตำแหน่ง "กิจกรรม&แล็บ" ไว้ขวาบนเสมอไม่ว่าค่าจะเท่ากับหมวด
  // อื่นแค่ไหน เพราะแต่ละวงคือหมวดที่มีอัตลักษณ์ตายตัว ไม่ใช่อันดับที่เปลี่ยนได้
  static const _canvasWidth = 300.0;
  static const _canvasHeight = 180.0;
  static const _slotCenters = [
    Offset(82, 86), // สอนในตารางปกติ — ใหญ่ซ้ายล่าง
    Offset(202, 62), // กิจกรรม & แล็บ — ขวาบน ทับหมวดแรกเบาๆ
    Offset(185, 137), // จัดครูสอนแทน — ล่างกลาง ทับทั้งสองหมวดบน
    Offset(260, 116), // เตรียมสอน/ประชุม — ขวาสุด เล็กสุด
  ];

  @override
  Widget build(BuildContext context) {
    final total = bubbles.fold<int>(0, (n, b) => n + b.count);
    if (total == 0) {
      return const _Empty('ยังไม่มีคาบสอนในระบบสัปดาห์นี้');
    }
    final present = <int>[
      for (var i = 0; i < bubbles.length; i++)
        if (bubbles[i].count > 0) i,
    ];
    final maxCount = present.map((i) => bubbles[i].count).reduce((a, b) => a > b ? a : b);
    final sizes = {
      for (final i in present) i: 48.0 + (bubbles[i].count / maxCount).clamp(0.0, 1.0) * 96.0,
    };

    final clusterLeft = present.map((i) => _slotCenters[i].dx - sizes[i]! / 2).reduce((a, b) => a < b ? a : b);
    final clusterRight = present.map((i) => _slotCenters[i].dx + sizes[i]! / 2).reduce((a, b) => a > b ? a : b);
    final clusterTop = present.map((i) => _slotCenters[i].dy - sizes[i]! / 2).reduce((a, b) => a < b ? a : b);
    final clusterBottom = present.map((i) => _slotCenters[i].dy + sizes[i]! / 2).reduce((a, b) => a > b ? a : b);
    final shift = (_canvasWidth - (clusterRight - clusterLeft)) / 2 - clusterLeft;
    final shiftY = (_canvasHeight - (clusterBottom - clusterTop)) / 2 - clusterTop;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: _canvasWidth,
          height: _canvasHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final i in present)
                Positioned(
                  left: _slotCenters[i].dx + shift - sizes[i]! / 2,
                  top: _slotCenters[i].dy + shiftY - sizes[i]! / 2,
                  child: Container(
                    width: sizes[i],
                    height: sizes[i],
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bubbles[i].bg,
                    ),
                    child: Text(
                      '${(bubbles[i].count * 100 / total).round()}%',
                      style: TextStyle(
                        color: bubbles[i].text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                        // สัดส่วน font/ขนาดวงกลม ~0.23 เท่ากับ 4 วงตายตัวของ
                        // เวอร์ชัน 7 ก.ย. (144→32, 108→25, 82→19, 48→13)
                        fontSize: (sizes[i]! * 0.23).clamp(10.0, 34.0),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry({required this.label, required this.value, this.detail, required this.color});
  final String label, value;
  final String? detail;
  final Color color;
  String get line => detail == null ? value : '$value ($detail)';
}

/// ตำนานใต้กราฟฟองสบู่ — ตาราง 2 คอลัมน์คั่นด้วยเส้นประ + ลำดับ 4 หมวดคงที่
/// แบบเดียวกับเวอร์ชัน 7 ก.ย. เป๊ะ (ไม่เรียงตามขนาดเหมือนกราฟฟองสบู่ด้านบน)
/// ต่างแค่ตัวเลขเป็นคาบสอนจริงของสัปดาห์นี้ ไม่ใช่หมวดที่แต่งขึ้น
class _WorkloadLegend extends StatelessWidget {
  const _WorkloadLegend({required this.summary});
  final TeacherWorkloadSummary summary;

  @override
  Widget build(BuildContext context) {
    final entries = [
      _LegendEntry(
        label: 'สอนในตารางปกติ',
        value: '${summary.regularPeriods} คาบ',
        detail: 'ครู ${summary.regularTeacherCount} คน',
        color: const Color(0xFF5B21B6),
      ),
      _LegendEntry(
        label: 'กิจกรรม & แล็บ',
        value: '${summary.activityLabPeriods} คาบ',
        detail: 'ครู ${summary.activityLabTeacherCount} คน',
        color: const Color(0xFF059669),
      ),
      _LegendEntry(
        label: 'จัดครูสอนแทน',
        value: summary.substitutionNeeded == 0
            ? 'ไม่มีคาบที่ต้องจัดครูสอนแทน'
            : '${summary.substitutionRecorded} คาบ',
        detail: summary.substitutionNeeded == 0
            ? null
            : 'บันทึกแล้ว ${summary.substitutionRecorded}/${summary.substitutionNeeded}',
        color: const Color(0xFFE11D48),
      ),
      _LegendEntry(
        label: 'เตรียมสอน/ประชุม',
        value: '${summary.prepMeetingCount} คาบ',
        detail: 'ครู ${summary.prepMeetingTeacherCount} คน',
        color: const Color(0xFFD97706),
      ),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      if (rows.isNotEmpty) {
        rows
          ..add(const SizedBox(height: 6))
          ..add(const _DottedLine(color: Color(0xFFF1F5F9)))
          ..add(const SizedBox(height: 6));
      }
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _legendItem(entries[i])),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < entries.length
                  ? _legendItem(entries[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _legendItem(_LegendEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: entry.color),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: entry.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              entry.line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine({this.color = const Color(0xFFE5E5EA)});
  final Color color;
  static const _dotRadius = 1.2;
  static const _spacing = 5.5;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _dotRadius * 2,
    width: double.infinity,
    child: CustomPaint(painter: _DottedLinePainter(color)),
  );
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    var x = _DottedLine._dotRadius;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, size.height / 2), _DottedLine._dotRadius, paint);
      x += _DottedLine._spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TrackLegend extends StatelessWidget {
  const _TrackLegend({required this.track, required this.color});
  final LearningTrackOverview track;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          '${track.name} · ${track.studentCount} คน · ${track.roomCount} ห้อง',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppPalette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _Summary {
  const _Summary(
    this.title,
    this.value,
    this.unit,
    this.subtitle,
    this.icon,
    this.headerBg,
    this.headerColor,
    this.page,
  );
  final String title, value, unit, subtitle;
  final IconData icon;
  final Color headerBg, headerColor;
  final int page;
}
