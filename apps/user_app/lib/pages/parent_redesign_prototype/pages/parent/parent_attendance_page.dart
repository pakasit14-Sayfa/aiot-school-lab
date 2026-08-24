import 'package:flutter/material.dart';
import '../../widgets/parent_common_widgets.dart';

class ParentAttendancePage extends StatefulWidget {
  const ParentAttendancePage({super.key});

  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage> {
  static const Color _bg = Color(0xFFF5F7FB);

  String selectedPeriod = 'เดือนนี้';

  final List<String> periods = const [
    'วันนี้',
    'สัปดาห์นี้',
    'เดือนนี้',
    'เทอมนี้',
  ];

  final List<_AttendanceHistory> history = const [
    _AttendanceHistory(
      date: '21 ส.ค. 2569',
      checkIn: '07:41',
      checkOut: '-',
      status: 'มาเรียน',
      detail: 'ปกติ',
      type: _AttendanceType.present,
    ),
    _AttendanceHistory(
      date: '20 ส.ค. 2569',
      checkIn: '07:36',
      checkOut: '16:18',
      status: 'มาเรียน',
      detail: 'ปกติ',
      type: _AttendanceType.present,
    ),
    _AttendanceHistory(
      date: '19 ส.ค. 2569',
      checkIn: '07:52',
      checkOut: '16:10',
      status: 'มาเรียน',
      detail: 'ปกติ',
      type: _AttendanceType.present,
    ),
    _AttendanceHistory(
      date: '18 ส.ค. 2569',
      checkIn: '-',
      checkOut: '-',
      status: 'ลา',
      detail: 'ลาป่วย',
      type: _AttendanceType.leave,
    ),
    _AttendanceHistory(
      date: '17 ส.ค. 2569',
      checkIn: '07:39',
      checkOut: '16:21',
      status: 'มาเรียน',
      detail: 'ปกติ',
      type: _AttendanceType.present,
    ),
    _AttendanceHistory(
      date: '16 ส.ค. 2569',
      checkIn: '08:12',
      checkOut: '16:14',
      status: 'มาสาย',
      detail: 'สาย 12 นาที',
      type: _AttendanceType.late,
    ),
  ];

  final List<_ClassAttendance> classAttendance = const [
    _ClassAttendance(
      time: '08:30',
      subject: 'ภาษาไทย',
      teacher: 'ครูศิริพร',
      room: 'ม.2/1',
      status: 'เข้าเรียน',
      type: _ClassAttendanceType.present,
    ),
    _ClassAttendance(
      time: '09:30',
      subject: 'คณิตศาสตร์',
      teacher: 'ครูอนุชา',
      room: 'ม.2/1',
      status: 'กำลังเรียน',
      type: _ClassAttendanceType.current,
    ),
    _ClassAttendance(
      time: '10:30',
      subject: 'วิทยาศาสตร์',
      teacher: 'ครูปวีณา',
      room: 'Lab 2',
      status: 'รอเข้าเรียน',
      type: _ClassAttendanceType.upcoming,
    ),
    _ClassAttendance(
      time: '13:00',
      subject: 'ภาษาอังกฤษ',
      teacher: 'Teacher Anna',
      room: 'ม.2/1',
      status: 'รอเข้าเรียน',
      type: _ClassAttendanceType.upcoming,
    ),
    _ClassAttendance(
      time: '14:00',
      subject: 'สังคมศึกษา',
      teacher: 'ครูสมชาย',
      room: 'ม.2/1',
      status: 'รอเข้าเรียน',
      type: _ClassAttendanceType.upcoming,
    ),
  ];

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
                  ParentPageHeader(
                    title: 'การมาเรียน',
                    subtitle:
                        'ติดตามการเข้า–ออกโรงเรียน การเข้าเรียนแต่ละคาบ การลา และการมาสาย',
                    icon: Icons.fact_check_rounded,
                    trailing: _buildChildBadge(),
                  ),
                  const SizedBox(height: 18),

                  _buildTodayHero(),

                  const SizedBox(height: 16),

                  _buildPeriodFilter(),

                  const SizedBox(height: 16),

                  _buildSummaryCards(),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // ROW 1: ไทม์ไลน์วันนี้ + แนวโน้มการมาเรียน
                  // Desktop = แนวนอนและสูงเท่ากัน
                  // Mobile = เรียงลงแนวตั้ง
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 950) {
                        return Column(
                          children: [
                            _buildTodayTimeline(),
                            const SizedBox(height: 14),
                            const _AttendanceTrendCard(),
                          ],
                        );
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildTodayTimeline(),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              flex: 1,
                              child: _AttendanceTrendCard(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // ROW 2: การเข้าเรียนแต่ละคาบวันนี้ + Attendance Insight
                  // Desktop = แนวนอนและสูงเท่ากัน
                  // Mobile = เรียงลงแนวตั้ง
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 950) {
                        return Column(
                          children: [
                            _buildClassAttendanceCard(),
                            const SizedBox(height: 14),
                            const _AttendanceInsightCard(),
                          ],
                        );
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildClassAttendanceCard(),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              flex: 1,
                              child: _AttendanceInsightCard(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildHistoryCard(),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 850) {
                        return const Column(
                          children: [
                            _LeaveSummaryCard(),
                            SizedBox(height: 14),
                            _AttendanceRuleCard(),
                          ],
                        );
                      }

                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _LeaveSummaryCard()),
                          SizedBox(width: 14),
                          Expanded(child: _AttendanceRuleCard()),
                        ],
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

  Widget _buildChildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE1E6EE),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.face_rounded,
            color: Color(0xFF2867B2),
            size: 18,
          ),
          SizedBox(width: 7),
          Text(
            'น้องมะลิ · ม.2/1',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D5A95),
            Color(0xFF2E83C5),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 720;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สถานะวันนี้',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'น้องมะลิมาโรงเรียนเรียบร้อยแล้ว',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ศุกร์ 21 สิงหาคม 2569',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroAttendanceBadge(
                    icon: Icons.login_rounded,
                    text: 'เข้าโรงเรียน 07:41 น.',
                  ),
                  _HeroAttendanceBadge(
                    icon: Icons.location_on_rounded,
                    text: 'อาคารเรียน ม.2',
                  ),
                  _HeroAttendanceBadge(
                    icon: Icons.schedule_rounded,
                    text: 'ไม่มาสาย',
                  ),
                ],
              ),
            ],
          );

          final status = Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withValues(alpha: .14),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เวลาเรียนวันนี้',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '08:30–15:50',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Color(0xFF8BE3B2),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'สถานะปกติ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 15),
                status,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 20),
              SizedBox(
                width: 220,
                child: status,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return ParentCard(
      padding: const EdgeInsets.all(13),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text(
              'ช่วงข้อมูล',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF7D8798),
              ),
            ),
          ),
          for (final period in periods)
            ChoiceChip(
              label: Text(
                period,
                style: const TextStyle(fontSize: 9),
              ),
              selected: selectedPeriod == period,
              onSelected: (_) {
                setState(() {
                  selectedPeriod = period;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    const data = [
      _AttendanceSummaryData(
        title: 'อัตรามาเรียน',
        value: '96%',
        subtitle: '48 จาก 50 วัน',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF18A06F),
      ),
      _AttendanceSummaryData(
        title: 'มาสาย',
        value: '1 ครั้ง',
        subtitle: 'รวม 12 นาที',
        icon: Icons.schedule_rounded,
        color: Color(0xFFF09A37),
      ),
      _AttendanceSummaryData(
        title: 'ลา',
        value: '2 วัน',
        subtitle: 'ป่วย 1 · กิจ 1',
        icon: Icons.event_busy_rounded,
        color: Color(0xFF8A65C7),
      ),
      _AttendanceSummaryData(
        title: 'ขาดเรียน',
        value: '0 วัน',
        subtitle: 'ไม่พบการขาดเรียน',
        icon: Icons.cancel_rounded,
        color: Color(0xFFDB5962),
      ),
      _AttendanceSummaryData(
        title: 'เข้าเรียนครบคาบ',
        value: '98%',
        subtitle: '49 จาก 50 คาบล่าสุด',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF2E83C5),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 5
            : constraints.maxWidth >= 760
                ? 3
                : constraints.maxWidth >= 500
                    ? 2
                    : 1;

        const gap = 12.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in data)
              SizedBox(
                width: width,
                child: _AttendanceSummaryTile(data: item),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTodayTimeline() {
    const timeline = [
      _TimelineItem(
        time: '07:41',
        title: 'เข้าโรงเรียน',
        detail: 'ตรวจพบการเข้าโรงเรียนเรียบร้อย',
        icon: Icons.login_rounded,
        color: Color(0xFF18A06F),
      ),
      _TimelineItem(
        time: '08:26',
        title: 'ถึงอาคารเรียน',
        detail: 'อยู่ในพื้นที่อาคารเรียน ม.2',
        icon: Icons.location_on_rounded,
        color: Color(0xFF2E83C5),
      ),
      _TimelineItem(
        time: '08:30',
        title: 'เข้าเรียนคาบแรก',
        detail: 'ภาษาไทย · ห้อง ม.2/1',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF8A65C7),
      ),
      _TimelineItem(
        time: '09:30',
        title: 'คาบปัจจุบัน',
        detail: 'คณิตศาสตร์ · กำลังเรียน',
        icon: Icons.calculate_rounded,
        color: Color(0xFFF09A37),
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttendanceSectionTitle(
            icon: Icons.timeline_rounded,
            title: 'ไทม์ไลน์วันนี้',
            subtitle: 'ติดตามการเข้าโรงเรียนและการเข้าเรียน',
          ),
          const SizedBox(height: 14),
          for (final item in timeline)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 45,
                    child: Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF8791A2),
                      ),
                    ),
                  ),
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 9.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.detail,
                          style: const TextStyle(
                            fontSize: 8.2,
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

  Widget _buildClassAttendanceCard() {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttendanceSectionTitle(
            icon: Icons.class_rounded,
            title: 'การเข้าเรียนแต่ละคาบวันนี้',
            subtitle: 'ดูว่านักเรียนเข้าเรียนครบตามตารางหรือไม่',
          ),
          const SizedBox(height: 14),
          for (final item in classAttendance)
            _ClassAttendanceRow(item: item),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttendanceSectionTitle(
            icon: Icons.history_rounded,
            title: 'ประวัติการมาเรียนย้อนหลัง',
            subtitle: 'เวลาเข้า–ออกโรงเรียน และสถานะประจำวัน',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    for (final item in history) ...[
                      _MobileHistoryCard(item: item),
                      const SizedBox(height: 9),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'วันที่',
                            style: _AttendanceTableHeader.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'เข้า',
                            style: _AttendanceTableHeader.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ออก',
                            style: _AttendanceTableHeader.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'สถานะ',
                            style: _AttendanceTableHeader.style,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'รายละเอียด',
                            style: _AttendanceTableHeader.style,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final item in history)
                    _HistoryTableRow(item: item),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CLASS ATTENDANCE ROW
// ============================================================================

class _ClassAttendanceRow extends StatelessWidget {
  final _ClassAttendance item;

  const _ClassAttendanceRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      _ClassAttendanceType.present => const Color(0xFF18A06F),
      _ClassAttendanceType.current => const Color(0xFFF09A37),
      _ClassAttendanceType.upcoming => const Color(0xFF7E889A),
      _ClassAttendanceType.absent => const Color(0xFFDB5962),
    };

    final icon = switch (item.type) {
      _ClassAttendanceType.present => Icons.check_circle_rounded,
      _ClassAttendanceType.current => Icons.play_circle_fill_rounded,
      _ClassAttendanceType.upcoming => Icons.schedule_rounded,
      _ClassAttendanceType.absent => Icons.cancel_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEDF0F4),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 47,
            child: Text(
              item.time,
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF8993A4),
              ),
            ),
          ),
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.teacher} · ${item.room}',
                  style: const TextStyle(
                    fontSize: 8.2,
                    color: Color(0xFF8993A4),
                  ),
                ),
              ],
            ),
          ),
          _AttendanceStatusBadge(
            text: item.status,
            color: color,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TREND CARD
// ============================================================================

class _AttendanceTrendCard extends StatelessWidget {
  const _AttendanceTrendCard();

  @override
  Widget build(BuildContext context) {
    const weeks = [
      ('สัปดาห์ 1', .100, '100%'),
      ('สัปดาห์ 2', .100, '100%'),
      ('สัปดาห์ 3', .080, '80%'),
      ('สัปดาห์ 4', .100, '100%'),
      ('สัปดาห์ 5', .100, '100%'),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttendanceSectionTitle(
            icon: Icons.trending_up_rounded,
            title: 'แนวโน้มการมาเรียน',
            subtitle: 'อัตราการมาเรียนรายสัปดาห์',
          ),
          const SizedBox(height: 15),
          for (final week in weeks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      week.$1,
                      style: const TextStyle(
                        fontSize: 8.8,
                        color: Color(0xFF687486),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: week.$2,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDF0F5),
                        valueColor: AlwaysStoppedAnimation(
                          week.$2 >= .95
                              ? const Color(0xFF18A06F)
                              : const Color(0xFFF09A37),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 35,
                    child: Text(
                      week.$3,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 8.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF2E83C5),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'สัปดาห์ที่ 3 มีการลาป่วย 1 วัน จึงทำให้อัตราการมาเรียนลดลงชั่วคราว',
                    style: TextStyle(
                      fontSize: 8.5,
                      height: 1.45,
                      color: Color(0xFF55677D),
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
// INSIGHT CARD
// ============================================================================

class _AttendanceInsightCard extends StatelessWidget {
  const _AttendanceInsightCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttendanceSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'Attendance Insight',
            subtitle: 'ประเด็นที่ผู้ปกครองควรติดตาม',
          ),
          const SizedBox(height: 14),
          const _AttendanceInsightItem(
            icon: Icons.check_circle_rounded,
            title: 'ภาพรวมดี',
            description:
                'อัตรามาเรียน 96% และไม่มีการขาดเรียนโดยไม่แจ้งลา',
            color: Color(0xFF18A06F),
          ),
          const SizedBox(height: 10),
          const _AttendanceInsightItem(
            icon: Icons.schedule_rounded,
            title: 'เคยมาสาย 1 ครั้ง',
            description:
                'วันที่ 16 ส.ค. มาสาย 12 นาที แต่ไม่พบพฤติกรรมมาสายต่อเนื่อง',
            color: Color(0xFFF09A37),
          ),
          const SizedBox(height: 10),
          const _AttendanceInsightItem(
            icon: Icons.menu_book_rounded,
            title: 'เข้าเรียนเกือบครบทุกคาบ',
            description:
                '50 คาบล่าสุด เข้าเรียนครบ 49 คาบ คิดเป็น 98%',
            color: Color(0xFF2E83C5),
          ),
          const SizedBox(height: 10),
          const _AttendanceInsightItem(
            icon: Icons.shield_rounded,
            title: 'ไม่พบเหตุผิดปกติ',
            description:
                'ไม่มีการออกนอกพื้นที่โรงเรียนระหว่างเวลาเรียนโดยไม่มีเหตุผล',
            color: Color(0xFF8A65C7),
          ),
        ],
      ),
    );
  }
}

class _AttendanceInsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _AttendanceInsightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 8.3,
                    color: Color(0xFF657286),
                    height: 1.45,
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
// LEAVE SUMMARY
// ============================================================================

class _LeaveSummaryCard extends StatelessWidget {
  const _LeaveSummaryCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttendanceSectionTitle(
            icon: Icons.event_busy_rounded,
            title: 'สรุปการลา',
            subtitle: 'รายการลาที่ได้รับการบันทึก',
          ),
          const SizedBox(height: 13),
          const Row(
            children: [
              Expanded(
                child: _LeaveMetric(
                  value: '1',
                  label: 'ลาป่วย',
                  color: Color(0xFF8A65C7),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LeaveMetric(
                  value: '1',
                  label: 'ลากิจ',
                  color: Color(0xFFF09A37),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LeaveMetric(
                  value: '0',
                  label: 'ขาด',
                  color: Color(0xFFDB5962),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'การลาทั้งหมดได้รับการแจ้งจากผู้ปกครองและได้รับการอนุมัติแล้ว',
            style: TextStyle(
              fontSize: 8.5,
              color: Color(0xFF7F899A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RULE CARD
// ============================================================================

class _AttendanceRuleCard extends StatelessWidget {
  const _AttendanceRuleCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttendanceSectionTitle(
            icon: Icons.rule_rounded,
            title: 'เกณฑ์การมาเรียน',
            subtitle: 'ใช้เป็นข้อมูลประกอบการติดตาม',
          ),
          const SizedBox(height: 13),
          const _RuleLine(
            label: 'มาเรียนปกติ',
            value: 'ก่อน 08:00 น.',
            color: Color(0xFF18A06F),
          ),
          const SizedBox(height: 9),
          const _RuleLine(
            label: 'มาสาย',
            value: 'หลัง 08:00 น.',
            color: Color(0xFFF09A37),
          ),
          const SizedBox(height: 9),
          const _RuleLine(
            label: 'ต้องแจ้งลา',
            value: 'ก่อนเริ่มเรียน',
            color: Color(0xFF8A65C7),
          ),
          const SizedBox(height: 9),
          const _RuleLine(
            label: 'เฝ้าระวัง',
            value: 'มาเรียนต่ำกว่า 80%',
            color: Color(0xFFDB5962),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HISTORY
// ============================================================================

class _HistoryTableRow extends StatelessWidget {
  final _AttendanceHistory item;

  const _HistoryTableRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      _AttendanceType.present => const Color(0xFF18A06F),
      _AttendanceType.leave => const Color(0xFF8A65C7),
      _AttendanceType.late => const Color(0xFFF09A37),
      _AttendanceType.absent => const Color(0xFFDB5962),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEDF0F4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.date,
              style: const TextStyle(fontSize: 9.3),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.checkIn,
              style: const TextStyle(
                fontSize: 9.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.checkOut,
              style: const TextStyle(
                fontSize: 9.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _AttendanceStatusBadge(
                text: item.status,
                color: color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.detail,
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF7E8899),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHistoryCard extends StatelessWidget {
  final _AttendanceHistory item;

  const _MobileHistoryCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      _AttendanceType.present => const Color(0xFF18A06F),
      _AttendanceType.leave => const Color(0xFF8A65C7),
      _AttendanceType.late => const Color(0xFFF09A37),
      _AttendanceType.absent => const Color(0xFFDB5962),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE8EBF1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _AttendanceStatusBadge(
                text: item.status,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _MobileHistoryValue(
                  label: 'เข้า',
                  value: item.checkIn,
                ),
              ),
              Expanded(
                child: _MobileHistoryValue(
                  label: 'ออก',
                  value: item.checkOut,
                ),
              ),
              Expanded(
                child: _MobileHistoryValue(
                  label: 'รายละเอียด',
                  value: item.detail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMALL COMPONENTS
// ============================================================================

class _HeroAttendanceBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroAttendanceBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: .13),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSummaryTile extends StatelessWidget {
  final _AttendanceSummaryData data;

  const _AttendanceSummaryTile({
    required this.data,
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
              color: data.color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              data.icon,
              size: 21,
              color: data.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF7F899A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    fontSize: 7.8,
                    color: Color(0xFF8C95A5),
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

class _AttendanceSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AttendanceSectionTitle({
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
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 8.3,
                  color: Color(0xFF8993A4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceStatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _AttendanceStatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7.3,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LeaveMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _LeaveMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF7F899A),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RuleLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 8.8,
              color: Color(0xFF697486),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 8.8,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MobileHistoryValue extends StatelessWidget {
  final String label;
  final String value;

  const _MobileHistoryValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 7.5,
            color: Color(0xFF8C95A5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AttendanceTableHeader {
  static const TextStyle style = TextStyle(
    fontSize: 8.4,
    fontWeight: FontWeight.w800,
    color: Color(0xFF687486),
  );
}

// ============================================================================
// DATA MODELS
// ============================================================================

class _AttendanceSummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AttendanceSummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _TimelineItem {
  final String time;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _TimelineItem({
    required this.time,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

enum _AttendanceType {
  present,
  leave,
  late,
  absent,
}

class _AttendanceHistory {
  final String date;
  final String checkIn;
  final String checkOut;
  final String status;
  final String detail;
  final _AttendanceType type;

  const _AttendanceHistory({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.detail,
    required this.type,
  });
}

enum _ClassAttendanceType {
  present,
  current,
  upcoming,
  absent,
}

class _ClassAttendance {
  final String time;
  final String subject;
  final String teacher;
  final String room;
  final String status;
  final _ClassAttendanceType type;

  const _ClassAttendance({
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.status,
    required this.type,
  });
}
