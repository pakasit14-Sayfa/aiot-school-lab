import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';
import '../controllers/director_calendar_controller.dart';
import 'meeting_detail_page.dart';

/// Read seams so loading / data / empty / failure can each be driven in a
/// test without a live Supabase client.
typedef CalendarEventsLoader = Future<List<CalendarEventItem>> Function();
typedef SchoolSchedulesLoader = Future<List<SchoolScheduleItem>> Function();

class DirectorAcademicCalendarPage extends StatefulWidget {
  const DirectorAcademicCalendarPage({
    super.key,
    this.loadEvents,
    this.loadSchedules,
    this.loadMeetings,
  });

  final CalendarEventsLoader? loadEvents;
  final SchoolSchedulesLoader? loadSchedules;
  final Future<List<MeetingRecord>> Function()? loadMeetings;

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

  /// Today, resolved once so the grid cannot drift mid-build.
  final DateTime _now = DateTime.now();

  List<_CalendarEvent> events = const [];
  List<SchoolScheduleItem> _schedules = const [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime(_now.year, _now.month);
    selectedDate = DateTime(_now.year, _now.month, _now.day);
    _loadCalendar();
  }

  /// Loads the school's real calendar.
  ///
  /// `_initCalendarEvents()` used to live here: 123 lines building a fixed
  /// August-2026 calendar — "ประชุมฝ่ายบริหาร 09:00-10:30 ห้องประชุม 1",
  /// "ประชุมหัวหน้ากลุ่มสาระ", and the rest — while `_loadSchoolSchedules`
  /// awaited a real RPC and threw the result away inside `catch (_) {}`. The
  /// page therefore looked connected and was not: every date, time, room and
  /// attendee on screen was invented, and it always showed August 2026 no
  /// matter what month it actually was.
  Future<void> _loadCalendar() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      events = const [];
      _schedules = const [];
    });
    try {
      final results = await DirectorCalendarController(
        loadEvents: widget.loadEvents,
        loadSchedules: widget.loadSchedules,
        loadMeetings: widget.loadMeetings,
      ).load();
      if (!mounted) return;
      final calendarRows = results.events;
      setState(() {
        events = [
          ...calendarRows.map(_toCalendarEvent),
          ...results.meetings.map(_toMeetingEvent),
        ]..sort((a, b) => a.date.compareTo(b.date));
        _schedules = results.schedules;
        _loading = false;
      });
    } catch (e) {
      debugPrint('DirectorAcademicCalendarPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  _CalendarEvent _toMeetingEvent(MeetingRecord meeting) {
    String time(DateTime value) =>
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    final end = meeting.endAt;
    return _CalendarEvent(
      date: meeting.startAt,
      time: end == null
          ? time(meeting.startAt)
          : '${time(meeting.startAt)} – ${_sameDate(meeting.startAt, end) ? '' : '${_thaiShortDate(end)} '}${time(end)}',
      title: meeting.title,
      description:
          '${meeting.description ?? ''}\nสถานะ: ${switch (meeting.status) {
            'scheduled' => 'นัดหมายแล้ว',
            'completed' => 'ประชุมเสร็จสิ้น',
            'cancelled' => 'ยกเลิกแล้ว',
            _ => 'ไม่ระบุ',
          }}',
      location: meeting.location ?? 'ไม่ระบุสถานที่',
      category: 'ประชุม',
      color: meeting.status == 'cancelled'
          ? AppPalette.textMuted
          : AppPalette.primaryPink,
      icon: Icons.groups_rounded,
      alertBefore: 'ยังไม่ได้ตั้งค่าการแจ้งเตือน',
      participants:
          '${meeting.attendeeCount} คน · ผู้จัด: ${meeting.organizer ?? 'ไม่ระบุ'}',
      meetingId: meeting.id,
      upcomingEligible: meeting.status == 'scheduled',
    );
  }

  /// `school_events` stores dates only — no time of day, no attendee list, no
  /// organiser — so those fields say so rather than being filled in. The
  /// event_type check constraint is
  /// ('holiday','public_holiday','exam','activity','study'): there is no
  /// meeting type, which is why the invented ประชุม entries could never have
  /// come from the database.
  _CalendarEvent _toCalendarEvent(CalendarEventItem row) {
    final (category, color, icon) = switch (row.eventType) {
      'exam' => ('สอบ', AppPalette.danger, Icons.assignment_rounded),
      'holiday' || 'public_holiday' => (
        'วันหยุด',
        AppPalette.primaryPink,
        Icons.beach_access_rounded,
      ),
      'study' => ('วิชาการ', AppPalette.learningBlue, Icons.school_rounded),
      _ => ('กิจกรรม', AppPalette.success, Icons.celebration_rounded),
    };
    return _CalendarEvent(
      date: row.startDate,
      time: 'ตลอดวัน',
      title: row.title,
      description: row.description ?? '',
      location: row.location ?? 'ไม่ระบุสถานที่',
      category: category,
      color: color,
      icon: icon,
      alertBefore: '',
      participants: '',
    );
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
          if (_loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 24),
          ],
          if (_loadFailed) ...[const SizedBox(height: 12), _loadErrorBanner()],
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
                  Expanded(flex: 5, child: _calendarCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _selectedDateCard()),
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
    // Counted from the loaded calendar. These were the fixed strings '12',
    // '4', '3' and '72' — the last one, "วันเรียนคงเหลือ 72", was a claim
    // about the academic term that nothing in the schema records at all.
    final monthCount = _eventsForMonth(selectedMonth).length;
    final today = DateTime(_now.year, _now.month, _now.day);
    final weekCount = events.where((e) {
      final days = DateTime(
        e.date.year,
        e.date.month,
        e.date.day,
      ).difference(today).inDays;
      return e.upcomingEligible && days >= 0 && days <= 7;
    }).length;
    final examCount = events.where((e) => e.category == 'สอบ').length;

    String figure(int n) => _loading || _loadFailed ? '—' : '$n';

    final items = [
      _CalendarSummary(
        title: 'กิจกรรมเดือนนี้',
        value: figure(monthCount),
        subtitle: 'รวมประชุมและกิจกรรมโรงเรียน',
        icon: Icons.calendar_month_rounded,
        color: AppPalette.softPink,
      ),
      _CalendarSummary(
        title: 'ภายใน 7 วัน',
        value: figure(weekCount),
        subtitle: 'นับจากวันนี้',
        icon: Icons.event_available_rounded,
        color: AppPalette.softBlue,
      ),
      _CalendarSummary(
        title: 'ตารางสอบ',
        value: figure(examCount),
        subtitle: 'ทั้งปฏิทิน',
        icon: Icons.assignment_rounded,
        color: AppPalette.softCream,
      ),
      _CalendarSummary(
        title: 'คาบเรียนต่อสัปดาห์',
        value: figure(_schedules.length),
        subtitle: 'จากตารางสอนทั้งโรงเรียน',
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
                  Icon(item.icon, size: 20, color: AppPalette.textDark),
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
                style: TextStyle(fontSize: 9.5, color: AppPalette.textMuted),
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
                    color: active ? Colors.white : AppPalette.textMuted,
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
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        final today = _sameDate(date, DateTime(2026, 8, 20));

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => selectedDate = date),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: selected ? AppPalette.primaryPinkSoft : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppPalette.primaryPink : AppPalette.border,
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
                          color: today ? Colors.white : AppPalette.textDark,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            dayEvents.isEmpty
                ? 'ไม่มีกิจกรรมในวันนี้'
                : '${dayEvents.length} รายการในวันนี้',
            style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 30),
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
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 3),
          Text(
            'เลือกวันที่อื่นในปฏิทินเพื่อดูรายละเอียด',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, color: AppPalette.textMuted),
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
          border: Border.all(color: AppPalette.tint(event.color, 0.18)),
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
              child: Icon(event.icon, size: 19, color: event.color),
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
        .where(
          (event) =>
              event.category == 'ประชุม' &&
              event.date.year == selectedMonth.year &&
              event.date.month == selectedMonth.month,
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตารางการประชุม',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ประชุมในเดือนที่เลือก ตามสิทธิ์การมองเห็นของคุณ',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          if (meetings.isEmpty)
            Text(
              _loadFailed
                  ? 'โหลดรายการประชุมไม่สำเร็จ'
                  : _loading
                  ? 'กำลังโหลดประชุม'
                  : 'ไม่มีประชุมในเดือนนี้',
            ),
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
                    Container(width: 1, height: 42, color: AppPalette.border),
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

  /// Stated on the page. A calendar that failed to load and a school with no
  /// events look identical otherwise.
  Widget _loadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'โหลดปฏิทินไม่สำเร็จ — หน้านี้อาจไม่แสดงกิจกรรมที่มีอยู่จริง',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _loadCalendar,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _alertsCard() {
    // Derived from the school's own calendar, not written by hand.
    //
    // This was a const list of three warnings — "สอบกลางภาคเริ่มในอีก 4 วัน"
    // and friends — that never changed and referred to nothing. A reminder is
    // only useful if it counts down to a date that exists, so these are built
    // from upcoming entries and disappear when there are none.
    final today = DateTime(_now.year, _now.month, _now.day);
    final alerts =
        events
            .where((e) {
              final d = DateTime(e.date.year, e.date.month, e.date.day);
              final days = d.difference(today).inDays;
              return e.upcomingEligible && days >= 0 && days <= 14;
            })
            .map((e) {
              final days = DateTime(
                e.date.year,
                e.date.month,
                e.date.day,
              ).difference(today).inDays;
              final whenText = days == 0
                  ? 'วันนี้'
                  : (days == 1 ? 'พรุ่งนี้' : 'อีก $days วัน');
              return _CalendarAlert(
                title: '${e.title} — $whenText',
                status: e.category,
                detail: e.description.isNotEmpty
                    ? e.description
                    : 'สถานที่: ${e.location}',
                color: e.color,
                icon: e.icon,
              );
            })
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การแจ้งเตือนปฏิทิน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'เตือนสิ่งที่ผู้บริหารควรดำเนินการล่วงหน้า',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          ...alerts.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.tint(alert.color, 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.tint(alert.color, 0.14)),
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
                    child: Icon(alert.icon, size: 18, color: alert.color),
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
                                color: AppPalette.tint(alert.color, 0.13),
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
              event.upcomingEligible &&
              (event.date.isAfter(_now) || _sameDate(event.date, _now)),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'เรียงตามวันที่ เพื่อช่วยวางแผนการดำเนินงานและเตรียมความพร้อมล่วงหน้า',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
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
                  border: Border.all(color: AppPalette.tint(event.color, 0.12)),
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
                      child: Icon(event.icon, size: 20, color: event.color),
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
          event.date.year == month.year && event.date.month == month.month;

      final filterMatch =
          selectedFilter == 'ทั้งหมด' || event.category == selectedFilter;

      return sameMonth && filterMatch;
    }).toList();
  }

  List<_CalendarEvent> _eventsForDate(DateTime date) {
    return events.where((event) {
      final dateMatch = _sameDate(event.date, date);
      final filterMatch =
          selectedFilter == 'ทั้งหมด' || event.category == selectedFilter;

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
                child: Icon(event.icon, color: event.color),
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
                  _detailRow(Icons.schedule_rounded, 'เวลา', event.time),
                  _detailRow(Icons.place_rounded, 'สถานที่', event.location),
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
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
            if (event.meetingId != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MeetingDetailPage(
                        service: MeetingService(),
                        meetingId: event.meetingId!,
                      ),
                    ),
                  );
                  if (mounted) await _loadCalendar();
                },
                child: const Text('เปิดรายละเอียดประชุม'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppPalette.primaryPink),
          const SizedBox(width: 9),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
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
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
  final String? meetingId;
  final bool upcomingEligible;
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
    this.meetingId,
    this.upcomingEligible = true,
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
