import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorAcademicCalendarPage extends StatefulWidget {
  const DirectorAcademicCalendarPage({super.key});

  @override
  State<DirectorAcademicCalendarPage> createState() =>
      _DirectorAcademicCalendarPageState();
}

class _DirectorAcademicCalendarPageState
    extends State<DirectorAcademicCalendarPage> {
  late DateTime selectedMonth;
  late DateTime selectedDate;
  String selectedFilter = 'ทั้งหมด';

  final List<String> filters = const [
    'ทั้งหมด',
    'วิชาการ',
    'ประชุม',
    'สอบ',
    'กิจกรรม',
    'วันหยุด',
  ];

  late final List<_CalendarEvent> events;

  @override
  void initState() {
    super.initState();
    _initCalendarEvents();
    _loadSchoolSchedules();
  }

  Future<void> _loadSchoolSchedules() async {
    try {
      await ExecutiveService.listAllSchoolSchedules();
    } catch (_) {}
  }

  void _initCalendarEvents() {
    selectedMonth = DateTime(2026, 8);
    selectedDate = DateTime(2026, 8, 20);

    events = [
      _CalendarEvent(
        date: DateTime(2026, 8, 20),
        time: '09:00 - 10:30',
        title: 'ประชุมฝ่ายบริหาร',
        description:
            'ประชุมติดตามภาพรวมการมาเรียน การใช้ทรัพยากร เหตุฉุกเฉิน และสถานะการดำเนินงานประจำสัปดาห์',
        location: 'ห้องประชุม 1',
        category: 'ประชุม',
        color: AppPalette.primaryPink,
        icon: Icons.groups_rounded,
        alertBefore: 'แจ้งเตือนก่อน 30 นาที',
        participants: 'ผู้อำนวยการ / รองผู้อำนวยการ / หัวหน้าฝ่าย',
      ),
      _CalendarEvent(
        date: DateTime(2026, 8, 20),
        time: '13:00 - 15:00',
        title: 'ประชุมหัวหน้ากลุ่มสาระ',
        description:
            'สรุปผลการสอน ปัญหาการเรียนของนักเรียน และวางแผนการจัดกิจกรรมเสริมในแต่ละกลุ่มสาระ',
        location: 'ห้องวิชาการ',
        category: 'ประชุม',
        color: AppPalette.learningBlue,
        icon: Icons.co_present_rounded,
        alertBefore: 'แจ้งเตือนก่อน 1 ชั่วโมง',
        participants: 'หัวหน้ากลุ่มสาระ 8 กลุ่ม',
      ),
      _CalendarEvent(
        date: DateTime(2026, 8, 21),
        time: '08:30 - 12:00',
        title: 'นิเทศการสอนภายใน',
        description:
            'ติดตามการจัดการเรียนการสอนในระดับ ม.1 - ม.6 และบันทึกผลการนิเทศเพื่อใช้ในการพัฒนาการสอน',
        location: 'อาคารเรียน 1 - 3',
        category: 'วิชาการ',
        color: AppPalette.environmentGreen,
        icon: Icons.fact_check_rounded,
        alertBefore: 'แจ้งเตือนก่อน 1 วัน',
        participants: 'ฝ่ายวิชาการ / ครูผู้สอน',
      ),
      _CalendarEvent(
        date: DateTime(2026, 8, 24),
        time: '08:00 - 16:00',
        title: 'สอบกลางภาค ม.1 - ม.3',
        description:
            'ดำเนินการสอบกลางภาคระดับมัธยมศึกษาตอนต้น ตรวจสอบห้องสอบ กรรมการคุมสอบ และความพร้อมของนักเรียน',
        location: 'อาคารเรียน 1 และ 2',
        category: 'สอบ',
        color: AppPalette.warning,
        icon: Icons.edit_note_rounded,
        alertBefore: 'แจ้งเตือนก่อน 3 วัน',
        participants: 'นักเรียน ม.1 - ม.3 / ครูคุมสอบ',
      ),
      _CalendarEvent(
        date: DateTime(2026, 8, 25),
        time: '08:00 - 16:00',
        title: 'สอบกลางภาค ม.4 - ม.6',
        description:
            'ดำเนินการสอบกลางภาคระดับมัธยมศึกษาตอนปลาย พร้อมตรวจสอบตารางสอบ ห้องสอบ และนักเรียนขาดสอบ',
        location: 'อาคารเรียน 2 และ 3',
        category: 'สอบ',
        color: AppPalette.warning,
        icon: Icons.edit_note_rounded,
        alertBefore: 'แจ้งเตือนก่อน 3 วัน',
        participants: 'นักเรียน ม.4 - ม.6 / ครูคุมสอบ',
      ),
      _CalendarEvent(
        date: DateTime(2026, 8, 28),
        time: '13:00 - 16:00',
        title: 'กิจกรรมแนะแนวการศึกษาต่อ',
        description:
            'แนะแนวเส้นทางการศึกษาต่อสำหรับนักเรียน ม.6 แยกตามสายวิทย์-คณิต สายภาษา และสายทั่วไป',
        location: 'หอประชุมใหญ่',
        category: 'กิจกรรม',
        color: AppPalette.chartPink,
        icon: Icons.school_rounded,
        alertBefore: 'แจ้งเตือนก่อน 1 วัน',
        participants: 'นักเรียน ม.6 / ครูแนะแนว',
      ),
      _CalendarEvent(
        date: DateTime(2026, 9, 1),
        time: '09:00 - 11:00',
        title: 'ประชุมคณะกรรมการสถานศึกษา',
        description:
            'รายงานผลการดำเนินงานประจำเดือน งบประมาณ ผลการเรียน ความปลอดภัย และแผนพัฒนาโรงเรียน',
        location: 'ห้องประชุมใหญ่',
        category: 'ประชุม',
        color: AppPalette.primaryPink,
        icon: Icons.groups_2_rounded,
        alertBefore: 'แจ้งเตือนก่อน 2 วัน',
        participants: 'คณะกรรมการสถานศึกษา',
      ),
      _CalendarEvent(
        date: DateTime(2026, 9, 5),
        time: 'ตลอดวัน',
        title: 'วันหยุดกิจกรรมโรงเรียน',
        description:
            'งดการเรียนการสอนตามปฏิทินโรงเรียน ระบบยังคงติดตามความปลอดภัยและทรัพยากรตามปกติ',
        location: 'ทั้งโรงเรียน',
        category: 'วันหยุด',
        color: AppPalette.chartCream,
        icon: Icons.event_busy_rounded,
        alertBefore: 'แจ้งเตือนก่อน 2 วัน',
        participants: 'นักเรียน / ครู / บุคลากร',
      ),
      _CalendarEvent(
        date: DateTime(2026, 9, 10),
        time: '15:00 - 16:30',
        title: 'ประชุมสรุปผลกลางภาค',
        description:
            'สรุปผลการสอบกลางภาค วิเคราะห์นักเรียนที่ต้องได้รับการดูแลเพิ่มเติม และกำหนดแนวทางพัฒนาผลสัมฤทธิ์',
        location: 'ห้องวิชาการ',
        category: 'วิชาการ',
        color: AppPalette.learningBlue,
        icon: Icons.analytics_rounded,
        alertBefore: 'แจ้งเตือนก่อน 1 วัน',
        participants: 'ฝ่ายวิชาการ / หัวหน้ากลุ่มสาระ',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'ปฏิทินวิชาการและการประชุม',
            subtitle:
                'ติดตามปฏิทินโรงเรียน ตารางประชุม การสอบ กิจกรรม และการแจ้งเตือนสำคัญในหน้าเดียว',
          ),
          const SizedBox(height: 16),
          _summaryCards(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1000;

              if (compact) {
                return Column(
                  children: [
                    _calendarCard(),
                    const SizedBox(height: 16),
                    _selectedDateCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _calendarCard(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _selectedDateCard(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;

              if (compact) {
                return Column(
                  children: [
                    _meetingScheduleCard(),
                    const SizedBox(height: 16),
                    _alertsCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _meetingScheduleCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _alertsCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _upcomingAcademicEventsCard(),
        ],
      ),
    );
  }

  Widget _summaryCards() {
    const items = [
      _CalendarSummary(
        title: 'กิจกรรมเดือนนี้',
        value: '12',
        subtitle: 'วิชาการ / สอบ / กิจกรรม',
        icon: Icons.calendar_month_rounded,
        color: AppPalette.softPink,
      ),
      _CalendarSummary(
        title: 'ประชุมสัปดาห์นี้',
        value: '4',
        subtitle: 'เหลืออีก 2 รายการ',
        icon: Icons.groups_rounded,
        color: AppPalette.softBlue,
      ),
      _CalendarSummary(
        title: 'แจ้งเตือนสำคัญ',
        value: '3',
        subtitle: 'ต้องติดตามภายใน 7 วัน',
        icon: Icons.notifications_active_rounded,
        color: AppPalette.softCream,
      ),
      _CalendarSummary(
        title: 'วันเรียนคงเหลือ',
        value: '72',
        subtitle: 'ภาคเรียนปัจจุบัน',
        icon: Icons.school_rounded,
        color: AppPalette.softPink2,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 700 ? 2 : 4;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 130,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: AppPalette.textDark,
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textDark,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.8,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _calendarCard() {
    final visibleEvents = _eventsForMonth(selectedMonth);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _calendarHeader(),
          const SizedBox(height: 14),
          _filterBar(),
          const SizedBox(height: 16),
          _weekHeader(),
          const SizedBox(height: 6),
          _monthGrid(visibleEvents),
        ],
      ),
    );
  }

  Widget _calendarHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'เดือนก่อนหน้า',
          onPressed: () {
            setState(() {
              selectedMonth = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              );
            });
          },
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _thaiMonthYear(selectedMonth),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'ภาคเรียนที่ 1 / 2569',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              selectedMonth = DateTime(2026, 8);
              selectedDate = DateTime(2026, 8, 20);
            });
          },
          child: const Text('วันนี้'),
        ),
        IconButton(
          tooltip: 'เดือนถัดไป',
          onPressed: () {
            setState(() {
              selectedMonth = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
              );
            });
          },
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _filterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final active = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => setState(() => selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppPalette.primaryPink
                      : AppPalette.primaryPinkSoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : AppPalette.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _weekHeader() {
    const days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Row(
      children: days
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _monthGrid(List<_CalendarEvent> visibleEvents) {
    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final leadingEmpty = firstDay.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cellCount = rows * 7;

    return GridView.builder(
      itemCount: cellCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 76,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leadingEmpty + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(
          selectedMonth.year,
          selectedMonth.month,
          dayNumber,
        );

        final dayEvents = visibleEvents
            .where((event) => _sameDate(event.date, date))
            .toList();

        final selected = _sameDate(selectedDate, date);
        final today = _sameDate(
          date,
          DateTime(2026, 8, 20),
        );

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => selectedDate = date),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: selected
                  ? AppPalette.primaryPinkSoft
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppPalette.primaryPink
                    : AppPalette.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 23,
                      height: 23,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: today
                            ? AppPalette.primaryPink
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: today
                              ? Colors.white
                              : AppPalette.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (dayEvents.isNotEmpty)
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: dayEvents.take(3).map((event) {
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: event.color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectedDateCard() {
    final dayEvents = _eventsForDate(selectedDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _thaiFullDate(selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dayEvents.isEmpty
                ? 'ไม่มีกิจกรรมในวันนี้'
                : '${dayEvents.length} รายการในวันนี้',
            style: const TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (dayEvents.isEmpty)
            _emptySelectedDate()
          else
            ...dayEvents.map(_selectedEventTile),
        ],
      ),
    );
  }

  Widget _emptySelectedDate() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: AppPalette.primaryPinkSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 34,
            color: AppPalette.primaryPink,
          ),
          SizedBox(height: 8),
          Text(
            'วันนี้ยังไม่มีรายการ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'เลือกวันที่อื่นในปฏิทินเพื่อดูรายละเอียด',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedEventTile(_CalendarEvent event) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showEventDetail(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.tint(event.color, 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPalette.tint(event.color, 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                event.icon,
                size: 19,
                color: event.color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.time,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: event.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.location,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _meetingScheduleCard() {
    final meetings = events
        .where((event) => event.category == 'ประชุม')
        .take(4)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตารางการประชุม',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'รายการประชุมสำคัญของฝ่ายบริหารและครู',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...meetings.map((event) {
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showEventDetail(event),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.tint(event.color, 0.07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Column(
                        children: [
                          Text(
                            '${event.date.day}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: event.color,
                            ),
                          ),
                          Text(
                            _shortThaiMonth(event.date.month),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42,
                      color: AppPalette.border,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 11.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${event.time} • ${event.location}',
                            style: const TextStyle(
                              fontSize: 9.3,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppPalette.textMuted,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _alertsCard() {
    final alerts = [
      const _CalendarAlert(
        title: 'สอบกลางภาคเริ่มในอีก 4 วัน',
        detail:
            'ตรวจสอบตารางสอบ ห้องสอบ กรรมการคุมสอบ และรายชื่อนักเรียนให้เรียบร้อย',
        status: 'ควรเตรียมการ',
        icon: Icons.edit_note_rounded,
        color: AppPalette.warning,
      ),
      const _CalendarAlert(
        title: 'ประชุมฝ่ายบริหารวันนี้ 09:00 น.',
        detail:
            'ระบบจะแจ้งเตือนซ้ำก่อนเริ่มประชุม 30 นาที พร้อมสรุปข้อมูล Dashboard ที่เกี่ยวข้อง',
        status: 'วันนี้',
        icon: Icons.groups_rounded,
        color: AppPalette.primaryPink,
      ),
      const _CalendarAlert(
        title: 'นิเทศการสอนพรุ่งนี้',
        detail:
            'ฝ่ายวิชาการควรตรวจสอบรายชื่อห้องเรียนและครูที่เข้ารับการนิเทศ',
        status: 'พรุ่งนี้',
        icon: Icons.fact_check_rounded,
        color: AppPalette.learningBlue,
      ),
      const _CalendarAlert(
        title: 'ใกล้วันส่งผลการเรียนกลางภาค',
        detail:
            'แจ้งหัวหน้ากลุ่มสาระติดตามครูผู้สอนที่ยังบันทึกคะแนนไม่ครบ',
        status: 'ติดตาม',
        icon: Icons.notifications_active_rounded,
        color: AppPalette.environmentGreen,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การแจ้งเตือนปฏิทิน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เตือนสิ่งที่ผู้บริหารควรดำเนินการล่วงหน้า',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...alerts.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.tint(alert.color, 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppPalette.tint(alert.color, 0.14),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      alert.icon,
                      size: 18,
                      color: alert.color,
                    ),
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
                                alert.title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.tint(
                                  alert.color,
                                  0.13,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                alert.status,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: alert.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.detail,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.4,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _upcomingAcademicEventsCard() {
    final upcoming = events
        .where(
          (event) =>
              event.date.isAfter(DateTime(2026, 8, 20)) ||
              _sameDate(event.date, DateTime(2026, 8, 20)),
        )
        .take(6)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายการวิชาการที่กำลังจะมาถึง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เรียงตามวันที่ เพื่อช่วยวางแผนการดำเนินงานและเตรียมความพร้อมล่วงหน้า',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...upcoming.map((event) {
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showEventDetail(event),
              child: Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.tint(event.color, 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppPalette.tint(event.color, 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        event.icon,
                        size: 20,
                        color: event.color,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_thaiShortDate(event.date)} • ${event.time} • ${event.location}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.tint(event.color, 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category,
                        style: TextStyle(
                          fontSize: 8.8,
                          fontWeight: FontWeight.w700,
                          color: event.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<_CalendarEvent> _eventsForMonth(DateTime month) {
    return events.where((event) {
      final sameMonth =
          event.date.year == month.year &&
          event.date.month == month.month;

      final filterMatch =
          selectedFilter == 'ทั้งหมด' ||
          event.category == selectedFilter;

      return sameMonth && filterMatch;
    }).toList();
  }

  List<_CalendarEvent> _eventsForDate(DateTime date) {
    return events.where((event) {
      final dateMatch = _sameDate(event.date, date);
      final filterMatch =
          selectedFilter == 'ทั้งหมด' ||
          event.category == selectedFilter;

      return dateMatch && filterMatch;
    }).toList();
  }

  void _showEventDetail(_CalendarEvent event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.tint(event.color, 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  event.icon,
                  color: event.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    Icons.calendar_today_rounded,
                    'วันที่',
                    _thaiFullDate(event.date),
                  ),
                  _detailRow(
                    Icons.schedule_rounded,
                    'เวลา',
                    event.time,
                  ),
                  _detailRow(
                    Icons.place_rounded,
                    'สถานที่',
                    event.location,
                  ),
                  _detailRow(
                    Icons.people_alt_rounded,
                    'ผู้เกี่ยวข้อง',
                    event.participants,
                  ),
                  _detailRow(
                    Icons.notifications_active_rounded,
                    'การแจ้งเตือน',
                    event.alertBefore,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'รายละเอียด',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppPalette.primaryPink,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _thaiMonthYear(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} ${date.year + 543}';
  }

  String _shortThaiMonth(int month) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return months[month - 1];
  }

  String _thaiShortDate(DateTime date) {
    return '${date.day} ${_shortThaiMonth(date.month)} ${date.year + 543}';
  }

  String _thaiFullDate(DateTime date) {
    const weekdays = [
      'วันจันทร์',
      'วันอังคาร',
      'วันพุธ',
      'วันพฤหัสบดี',
      'วันศุกร์',
      'วันเสาร์',
      'วันอาทิตย์',
    ];

    return '${weekdays[date.weekday - 1]}ที่ ${date.day} '
        '${_shortThaiMonth(date.month)} ${date.year + 543}';
  }
}

class _CalendarEvent {
  final DateTime date;
  final String time;
  final String title;
  final String description;
  final String location;
  final String category;
  final Color color;
  final IconData icon;
  final String alertBefore;
  final String participants;

  const _CalendarEvent({
    required this.date,
    required this.time,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.color,
    required this.icon,
    required this.alertBefore,
    required this.participants,
  });
}

class _CalendarSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CalendarSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _CalendarAlert {
  final String title;
  final String detail;
  final String status;
  final IconData icon;
  final Color color;

  const _CalendarAlert({
    required this.title,
    required this.detail,
    required this.status,
    required this.icon,
    required this.color,
  });
}
