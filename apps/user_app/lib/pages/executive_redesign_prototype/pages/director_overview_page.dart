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
    border: Border.all(color: AppPalette.border),
    boxShadow: [
      BoxShadow(
        color: AppPalette.tint(Colors.black, .025),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
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
        if (width < 620) ...[
          overviewHeading(),
          const SizedBox(height: 10),
          _OverviewPeriodSelector(
            days: controller.days,
            disabled: controller.loading,
            onSelected: (days) => controller.load(period: days),
          ),
        ] else
          Row(
            children: [
              Expanded(child: overviewHeading()),
              _OverviewPeriodSelector(
                days: controller.days,
                disabled: controller.loading,
                onSelected: (days) => controller.load(period: days),
              ),
            ],
          ),
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
          onTap: () => widget.onNavigate(item.page),
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
        children: [utilities(data), const SizedBox(height: 16), sensors],
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
          message: 'ยังไม่มีการเช็กชื่อของวันนี้',
          hint: 'ตัวเลขจะขึ้นเมื่อครูประจำชั้นบันทึกการเข้าเรียนแล้ว',
        )
      else ...[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AttendanceStat(
              label: 'มาเรียน',
              value: present,
              total: students,
              color: AppPalette.chartPink2,
            ),
            _AttendanceStat(label: 'สาย', value: late, color: AppPalette.chartCream),
            _AttendanceStat(label: 'ลา', value: excused, color: AppPalette.chartBlue),
            _AttendanceStat(label: 'ขาด', value: absent, color: AppPalette.chartPink),
            if (unknown > 0)
              _AttendanceStat(
                label: 'ยังไม่เช็ก',
                value: unknown,
                color: AppPalette.textMuted,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'เช็กชื่อแล้ว ${rooms.length} ห้อง · นักเรียนรวม $students คน',
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
          message: 'ยังไม่มีข้อมูลการลงเวลา',
          hint: 'ต้องเข้าสู่ระบบด้วยบัญชีที่มีสิทธิ์ดูข้อมูลบุคลากร',
        )
      else if (!s.workHoursConfigured)
        // เคสจริงที่เกิดบ่อย: โรงเรียนยังไม่ตั้งเวลาปฏิบัติงาน ครูจึงลงเวลา
        // ไม่ได้เลย — ต้องบอกสาเหตุ ไม่ใช่โชว์ 0 เฉย ๆ ให้เข้าใจว่าไม่มีใครมา
        const _AttendanceEmpty(
          message: 'ยังไม่ได้ตั้งเวลาปฏิบัติงานของโรงเรียน',
          hint: 'ครูจะลงเวลาไม่ได้จนกว่าผู้ดูแลโรงเรียนจะตั้งค่าก่อน',
        )
      else ...[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AttendanceStat(
              label: 'มาปฏิบัติงาน',
              value: s.presentCount,
              total: s.totalStaff,
              color: AppPalette.chartPink2,
            ),
            _AttendanceStat(label: 'สาย', value: s.lateCount, color: AppPalette.chartCream),
            _AttendanceStat(label: 'ลา', value: s.leaveCount, color: AppPalette.chartBlue),
            _AttendanceStat(
              label: 'ไปราชการ',
              value: s.officialDutyCount,
              color: AppPalette.chartPink3,
            ),
            _AttendanceStat(label: 'ขาด', value: s.absentCount, color: AppPalette.chartPink),
            if (s.noRecordCount > 0)
              _AttendanceStat(
                label: 'ยังไม่ลงเวลา',
                value: s.noRecordCount,
                color: AppPalette.textMuted,
              ),
          ],
        ),
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
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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

  Widget teachers(DirectorOverviewData d) => section([
    header(
      'ภาพรวมครูและการสอน',
      'ข้อมูลบุคลากรที่ยืนยันได้จากทะเบียนโรงเรียน',
      3,
    ),
    const SizedBox(height: 14),
    _TeacherCircle(
      count: d.counts['teacher'],
      onTap: () => widget.onNavigate(3),
    ),
    const SizedBox(height: 12),
    const _Empty('ยังไม่มีข้อมูลยืนยันสัดส่วนการเข้าสอน สอนแทน และเตรียมสอน'),
    const SizedBox(height: 8),
    Wrap(
      children: [
        TextButton(
          onPressed: () => widget.onNavigate(3),
          child: const Text('ดูบุคลากร'),
        ),
        TextButton(
          onPressed: () => widget.onNavigate(4),
          child: const Text('ดูตารางห้องเรียน'),
        ),
      ],
    ),
  ]);

  Widget utilities(DirectorOverviewData d) => section([
    header(
      'แนวโน้มการใช้ทรัพยากร',
      'ข้อมูลไฟฟ้าและน้ำจากวันที่มีค่าบันทึกจริง',
      8,
    ),
    const SizedBox(height: 14),
    LayoutBuilder(
      builder: (_, box) {
        final a = trend('ไฟฟ้า', d.energy, 'kWh', AppPalette.chartPink);
        final b = trend('น้ำ', d.water, 'm³', AppPalette.chartBlue);
        return box.maxWidth < 520
            ? Column(children: [a, const SizedBox(height: 10), b])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: a),
                  const SizedBox(width: 10),
                  Expanded(child: b),
                ],
              );
      },
    ),
  ]);

  Widget trend(
    String title,
    List<UtilityTrendPoint> points,
    String unit,
    Color color,
  ) {
    final total = points.fold<double>(0, (n, p) => n + p.value);
    final max = points.fold<double>(0, (n, p) => p.value > n ? p.value : n);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (points.isEmpty)
            const _Empty('ยังไม่มีข้อมูลย้อนหลัง')
          else ...[
            Text(
              'รวม ${total.toStringAsFixed(2)} $unit ในวันที่มีข้อมูล',
              style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
            ),
            const SizedBox(height: 10),
            for (final p in points.take(7))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: LinearProgressIndicator(
                  value: max <= 0 ? 0 : (p.value / max).clamp(0, 1),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                  backgroundColor: AppPalette.tint(color, .15),
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

  Widget section(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: whiteCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _AttendanceStat extends StatelessWidget {
  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
    this.total,
  });

  final String label;
  final int value;
  final int? total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                t == null ? 'คน' : 'จาก $t คน',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceEmpty extends StatelessWidget {
  const _AttendanceEmpty({required this.message, required this.hint});

  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppPalette.softTag,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
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

class _TeacherCircle extends StatelessWidget {
  const _TeacherCircle({required this.count, required this.onTap});
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      height: 155,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF55D6AE).withValues(alpha: .86),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF55D6AE).withValues(alpha: .20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.co_present_rounded,
                color: Color(0xFF276A59),
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                count == null ? 'ไม่มีข้อมูล' : '$count คน',
                style: const TextStyle(
                  color: Color(0xFF244C44),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'ครูในทะเบียน',
                style: TextStyle(
                  color: Color(0xFF356A60),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
