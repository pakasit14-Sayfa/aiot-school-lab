import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/parent_common_widgets.dart';

class ParentAcademicCalendarPage extends StatefulWidget {
  const ParentAcademicCalendarPage({super.key});

  @override
  State<ParentAcademicCalendarPage> createState() =>
      _ParentAcademicCalendarPageState();
}

class _ParentAcademicCalendarPageState
    extends State<ParentAcademicCalendarPage> {
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primary = Color(0xFF2867B2);

  DateTime selectedMonth = DateTime(2026, 8);
  DateTime? selectedDate = DateTime(2026, 8, 21);
  String selectedFilter = 'ทั้งหมด';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await Supabase.instance.client
          .from('calendar_events')
          .select()
          .order('start_date', ascending: true);
          
      if (mounted) {
        setState(() {
          events = (response as List).map((row) => _AcademicEvent(
            date: DateTime.parse(row['start_date']),
            endDate: row['end_date'] != null ? DateTime.parse(row['end_date']) : null,
            title: row['title'],
            description: row['description'] ?? '',
            type: _parseEventType(row['event_type']),
            icon: _getEventIcon(_parseEventType(row['event_type'])),
          )).toList();
        });
      }
    } catch (e) {
      print('Error loading calendar events: $e');
    }
  }

  final List<String> filters = const [
    'ทั้งหมด',
    'วันสอบ',
    'กิจกรรม',
    'วันหยุดโรงเรียน',
    'วันหยุดนักขัตฤกษ์',
  ];

  List<_AcademicEvent> events = [];
  
  _AcademicEventType _parseEventType(String type) {
    return switch (type) {
      'exam' => _AcademicEventType.exam,
      'activity' => _AcademicEventType.activity,
      'holiday' => _AcademicEventType.holiday,
      'public_holiday' => _AcademicEventType.publicHoliday,
      _ => _AcademicEventType.study,
    };
  }
  
  IconData _getEventIcon(_AcademicEventType type) {
    return switch (type) {
      _AcademicEventType.exam => Icons.edit_note_rounded,
      _AcademicEventType.activity => Icons.celebration_rounded,
      _AcademicEventType.holiday => Icons.beach_access_rounded,
      _AcademicEventType.publicHoliday => Icons.flag_rounded,
      _AcademicEventType.study => Icons.menu_book_rounded,
    };
  }

  /*
  final List<_AcademicEvent> _mockEvents = [
    _AcademicEvent(
      date: DateTime(2026, 8, 12),
      title: 'วันแม่แห่งชาติ',
      description: 'วันหยุดนักขัตฤกษ์',
      type: _AcademicEventType.publicHoliday,
      icon: Icons.beach_access_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 8, 21),
      title: 'เรียนตามตารางปกติ',
      description: 'เรียนตามตารางประจำวัน',
      type: _AcademicEventType.study,
      icon: Icons.menu_book_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 8, 25),
      title: 'กิจกรรมวันวิทยาศาสตร์',
      description: 'หอประชุมใหญ่ · 09:00–15:00 น.',
      type: _AcademicEventType.activity,
      icon: Icons.science_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 8, 28),
      title: 'ประชุมผู้ปกครองออนไลน์',
      description: 'Google Meet · 18:30 น.',
      type: _AcademicEventType.activity,
      icon: Icons.groups_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 9, 7),
      endDate: DateTime(2026, 9, 11),
      title: 'สอบกลางภาค',
      description: 'สอบตามตารางรายวิชา',
      type: _AcademicEventType.exam,
      icon: Icons.edit_note_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 9, 14),
      title: 'วันหยุดหลังสอบกลางภาค',
      description: 'ไม่มีการเรียนการสอน',
      type: _AcademicEventType.holiday,
      icon: Icons.beach_access_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 9, 18),
      title: 'กิจกรรมแนะแนวการศึกษา',
      description: 'ห้องประชุมอาคาร 2',
      type: _AcademicEventType.activity,
      icon: Icons.explore_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 10, 9),
      title: 'วันเรียนวันสุดท้ายของภาคเรียน',
      description: 'ก่อนเข้าสู่ช่วงสอบปลายภาค',
      type: _AcademicEventType.study,
      icon: Icons.school_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 10, 12),
      endDate: DateTime(2026, 10, 16),
      title: 'สอบปลายภาค',
      description: 'สอบปลายภาคเรียนที่ 1/2569',
      type: _AcademicEventType.exam,
      icon: Icons.fact_check_rounded,
    ),
    _AcademicEvent(
      date: DateTime(2026, 10, 17),
      title: 'ปิดภาคเรียน',
      description: 'เริ่มช่วงปิดภาคเรียน',
      type: _AcademicEventType.holiday,
      icon: Icons.event_available_rounded,
    ),
  ];
  */

  List<_AcademicEvent> get filteredEvents {
    return events.where((event) {
      final matchesFilter = selectedFilter == 'ทั้งหมด' ||
          _filterName(event.type) == selectedFilter;
      return matchesFilter;
    }).toList();
  }

  List<_AcademicEvent> eventsForDate(DateTime date) {
    return filteredEvents.where((event) {
      final end = event.endDate ?? event.date;
      final target = DateTime(date.year, date.month, date.day);
      final start = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      final endDay = DateTime(
        end.year,
        end.month,
        end.day,
      );

      return !target.isBefore(start) && !target.isAfter(endDay);
    }).toList();
  }

  List<_AcademicEvent> get selectedDateEvents {
    if (selectedDate == null) return const [];
    return eventsForDate(selectedDate!);
  }

  List<_AcademicEvent> get upcomingEvents {
    final today = DateTime(2026, 8, 21);
    return filteredEvents
        .where((event) => !event.date.isBefore(today))
        .take(6)
        .toList();
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
                  ParentPageHeader(
                    title: 'ปฏิทินวิชาการ',
                    subtitle:
                        'ติดตามวันสอบ วันหยุด กิจกรรม และกำหนดการสำคัญของบุตรหลาน',
                    icon: Icons.calendar_month_rounded,
                    trailing: _buildChildBadge(),
                  ),
                  const SizedBox(height: 18),

                  _buildTermHero(),

                  const SizedBox(height: 16),

                  _buildSummaryCards(),

                  const SizedBox(height: 16),

                  _buildFilterBar(),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 980) {
                        return Column(
                          children: [
                            _buildCalendarCard(),
                            const SizedBox(height: 14),
                            _buildSelectedDayCard(),
                          ],
                        );
                      }

                      // ห้ามใช้ IntrinsicHeight ตรงนี้ เพราะด้านใน
                      // _buildCalendarCard() มี LayoutBuilder
                      // ซึ่งจะเกิด runtime error บน Flutter Web
                      return SizedBox(
                        height: 610,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _buildCalendarCard(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: _buildSelectedDayCard(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return const Column(
                          children: [
                            _UpcomingAcademicEventsCard(),
                            SizedBox(height: 14),
                            _ImportantAcademicDatesCard(),
                          ],
                        );
                      }

                      return const IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _UpcomingAcademicEventsCard(),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: _ImportantAcademicDatesCard(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  const _ParentReminderCard(),
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
            color: _primary,
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

  Widget _buildTermHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1C5790),
            Color(0xFF2D83C5),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 720;

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ภาคเรียนปัจจุบัน',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .76),
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ภาคเรียนที่ 1 / 2569',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'เปิดเรียน 18 พฤษภาคม 2569 · ปิดภาคเรียน 17 ตุลาคม 2569',
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
                  _AcademicHeroBadge(
                    icon: Icons.today_rounded,
                    text: 'วันนี้ 21 ส.ค. 2569',
                  ),
                  _AcademicHeroBadge(
                    icon: Icons.edit_note_rounded,
                    text: 'กลางภาค 7–11 ก.ย.',
                  ),
                  _AcademicHeroBadge(
                    icon: Icons.event_available_rounded,
                    text: 'ปลายภาค 12–16 ต.ค.',
                  ),
                ],
              ),
            ],
          );

          final right = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'กำหนดการถัดไป',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '22 ส.ค.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'ส่งแบบฝึกหัดคณิตศาสตร์',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 15),
                right,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              SizedBox(
                width: 220,
                child: right,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    const items = [
      _CalendarSummaryData(
        title: 'วันสอบ',
        value: '10 วัน',
        subtitle: 'กลางภาค + ปลายภาค',
        icon: Icons.edit_note_rounded,
        color: Color(0xFFF09A37),
      ),
      _CalendarSummaryData(
        title: 'กิจกรรม',
        value: '3',
        subtitle: 'กิจกรรมที่กำลังจะถึง',
        icon: Icons.celebration_rounded,
        color: Color(0xFF8A65C7),
      ),
      _CalendarSummaryData(
        title: 'หยุดโรงเรียน',
        value: '2 วัน',
        subtitle: 'ปิดภาคเรียน/หยุดพิเศษ',
        icon: Icons.beach_access_rounded,
        color: Color(0xFF18A06F),
      ),
      _CalendarSummaryData(
        title: 'หยุดนักขัตฤกษ์',
        value: '1 วัน',
        subtitle: 'ตามประกาศรัฐบาล',
        icon: Icons.flag_rounded,
        color: Color(0xFFDB5962),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        const gap = 12.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _CalendarSummaryTile(data: item),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
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
              'แสดง',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF7F899A),
              ),
            ),
          ),
          for (final filter in filters)
            ChoiceChip(
              label: Text(
                filter,
                style: const TextStyle(fontSize: 9),
              ),
              selected: selectedFilter == filter,
              onSelected: (_) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _AcademicSectionTitle(
                  icon: Icons.calendar_month_rounded,
                  title: 'ปฏิทินรายเดือน',
                  subtitle: 'เลือกวันที่เพื่อดูรายละเอียด',
                ),
              ),
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
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                ),
              ),
              Text(
                _thaiMonthYear(selectedMonth),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
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
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Row(
            children: [
              _WeekHeader('อา.'),
              _WeekHeader('จ.'),
              _WeekHeader('อ.'),
              _WeekHeader('พ.'),
              _WeekHeader('พฤ.'),
              _WeekHeader('ศ.'),
              _WeekHeader('ส.'),
            ],
          ),
          const SizedBox(height: 7),
          _buildMonthGrid(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 7,
            children: [
              _CalendarLegend(
                label: 'วันสอบ',
                color: Color(0xFFF09A37),
              ),
              _CalendarLegend(
                label: 'กิจกรรม',
                color: Color(0xFF8A65C7),
              ),
              _CalendarLegend(
                label: 'วันหยุดโรงเรียน',
                color: Color(0xFF18A06F),
              ),
              _CalendarLegend(
                label: 'วันหยุดนักขัตฤกษ์',
                color: Color(0xFFDB5962),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
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

    final leadingEmpty = firstDay.weekday % 7;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cellCount = rows * 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 5.0;
        final cellWidth =
            (constraints.maxWidth - (gap * 6)) / 7;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int index = 0; index < cellCount; index++)
              SizedBox(
                width: cellWidth,
                height: constraints.maxWidth < 650 ? 60 : 68,
                child: _buildCalendarCell(
                  index: index,
                  leadingEmpty: leadingEmpty,
                  daysInMonth: daysInMonth,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarCell({
    required int index,
    required int leadingEmpty,
    required int daysInMonth,
  }) {
    final day = index - leadingEmpty + 1;

    if (day < 1 || day > daysInMonth) {
      return const SizedBox();
    }

    final date = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      day,
    );

    final dayEvents = eventsForDate(date);
    final isSelected = selectedDate != null &&
        _sameDay(date, selectedDate!);
    final isToday = _sameDay(
      date,
      DateTime(2026, 8, 21),
    );

    return Material(
      color: isSelected
          ? const Color(0xFFEAF3FF)
          : const Color(0xFFF9FAFC),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {
          setState(() {
            selectedDate = date;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7EAFE1)
                  : const Color(0xFFE9ECF1),
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
                      color: isToday
                          ? _primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: isToday
                            ? Colors.white
                            : const Color(0xFF3F4B5C),
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
                  children: [
                    for (final event in dayEvents.take(3))
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _eventColor(event.type),
                          shape: BoxShape.circle,
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

  Widget _buildSelectedDayCard() {
    final date = selectedDate ?? DateTime(2026, 8, 21);
    final items = selectedDateEvents;

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AcademicSectionTitle(
            icon: Icons.event_note_rounded,
            title: 'รายละเอียดวันที่เลือก',
            subtitle: 'กำหนดการของวัน',
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _fullThaiDate(date),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF8A94A5),
                    size: 30,
                  ),
                  SizedBox(height: 7),
                  Text(
                    'ไม่มีกำหนดการพิเศษ',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'เรียนตามตารางปกติ',
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFF8993A4),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final item in items)
              _SelectedEventTile(event: item),
        ],
      ),
    );
  }

  String _filterName(_AcademicEventType type) {
    return switch (type) {
      _AcademicEventType.exam => 'วันสอบ',
      _AcademicEventType.activity => 'กิจกรรม',
      _AcademicEventType.holiday => 'วันหยุดโรงเรียน',
      _AcademicEventType.publicHoliday => 'วันหยุดนักขัตฤกษ์',
      _AcademicEventType.study => 'ทั้งหมด',
    };
  }

  static Color _eventColor(_AcademicEventType type) {
    return switch (type) {
      _AcademicEventType.exam => const Color(0xFFF09A37),
      _AcademicEventType.activity => const Color(0xFF8A65C7),
      _AcademicEventType.holiday => const Color(0xFF18A06F),
      _AcademicEventType.publicHoliday => const Color(0xFFDB5962),
      _AcademicEventType.study => const Color(0xFF2E83C5),
    };
  }

  static bool _sameDay(DateTime a, DateTime b) {
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

  String _fullThaiDate(DateTime date) {
    const weekdays = [
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
      'อาทิตย์',
    ];

    return '${weekdays[date.weekday - 1]} ${date.day} '
        '${_thaiMonthYear(date)}';
  }
}

// ============================================================================
// UPCOMING EVENTS
// ============================================================================

class _UpcomingAcademicEventsCard extends StatelessWidget {
  const _UpcomingAcademicEventsCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      _UpcomingItem(
        date: '25 ส.ค.',
        title: 'กิจกรรมวันวิทยาศาสตร์',
        detail: 'หอประชุมใหญ่ · 09:00 น.',
        icon: Icons.science_rounded,
        color: Color(0xFF8A65C7),
      ),
      _UpcomingItem(
        date: '28 ส.ค.',
        title: 'ประชุมผู้ปกครองออนไลน์',
        detail: 'Google Meet · 18:30 น.',
        icon: Icons.groups_rounded,
        color: Color(0xFF2E83C5),
      ),
      _UpcomingItem(
        date: '7–11 ก.ย.',
        title: 'สอบกลางภาค',
        detail: 'สอบตามตารางรายวิชา',
        icon: Icons.edit_note_rounded,
        color: Color(0xFFDB5962),
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AcademicSectionTitle(
            icon: Icons.upcoming_rounded,
            title: 'กำหนดการที่กำลังจะถึง',
            subtitle: 'รายการสำคัญที่ผู้ปกครองควรทราบ',
          ),
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 5,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        item.date,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: .08),
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
                            fontSize: 9.5,
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
}

// ============================================================================
// IMPORTANT DATES
// ============================================================================

class _ImportantAcademicDatesCard extends StatelessWidget {
  const _ImportantAcademicDatesCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('18 พ.ค. 2569', 'เปิดภาคเรียน', Color(0xFF18A06F)),
      ('7–11 ก.ย. 2569', 'สอบกลางภาค', Color(0xFFDB5962)),
      ('9 ต.ค. 2569', 'วันเรียนวันสุดท้าย', Color(0xFF2E83C5)),
      ('12–16 ต.ค. 2569', 'สอบปลายภาค', Color(0xFFDB5962)),
      ('17 ต.ค. 2569', 'ปิดภาคเรียน', Color(0xFF8A65C7)),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AcademicSectionTitle(
            icon: Icons.flag_rounded,
            title: 'วันสำคัญของภาคเรียน',
            subtitle: 'กำหนดการหลักของปีการศึกษา',
          ),
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 9.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 8.3,
                      color: Color(0xFF7F899A),
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
// REMINDER
// ============================================================================

class _ParentReminderCard extends StatelessWidget {
  const _ParentReminderCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AcademicSectionTitle(
            icon: Icons.notifications_active_rounded,
            title: 'แจ้งเตือนสำหรับผู้ปกครอง',
            subtitle: 'สิ่งที่ควรเตรียมล่วงหน้า',
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 550
                      ? 2
                      : 1;
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) /
                      columns;

              const items = [
                _ReminderItem(
                  icon: Icons.science_rounded,
                  title: 'กิจกรรมวันวิทยาศาสตร์',
                  detail: 'สัปดาห์หน้า วันอังคาร 25 ส.ค.',
                  color: Color(0xFF18A06F),
                ),
                _ReminderItem(
                  icon: Icons.groups_rounded,
                  title: 'ประชุมผู้ปกครอง',
                  detail: '28 ส.ค. เวลา 18:30 น.',
                  color: Color(0xFF2E83C5),
                ),
                _ReminderItem(
                  icon: Icons.edit_note_rounded,
                  title: 'สอบกลางภาค',
                  detail: 'เหลืออีกประมาณ 2 สัปดาห์',
                  color: Color(0xFFF09A37),
                ),
              ];

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: item,
                    ),
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
// SMALL WIDGETS
// ============================================================================

class _AcademicHeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AcademicHeroBadge({
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

class _AcademicSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AcademicSectionTitle({
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

class _CalendarSummaryTile extends StatelessWidget {
  final _CalendarSummaryData data;

  const _CalendarSummaryTile({
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

class _WeekHeader extends StatelessWidget {
  final String text;

  const _WeekHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF758092),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final String label;
  final Color color;

  const _CalendarLegend({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF7D8798),
          ),
        ),
      ],
    );
  }
}

class _SelectedEventTile extends StatelessWidget {
  final _AcademicEvent event;

  const _SelectedEventTile({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final color = _ParentAcademicCalendarPageState._eventColor(
      event.type,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            event.icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 8.3,
                    color: Color(0xFF677386),
                    height: 1.4,
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

class _ReminderItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  const _ReminderItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: .12),
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
                  detail,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF7F899A),
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
// DATA
// ============================================================================

enum _AcademicEventType {
  exam,
  activity,
  holiday,
  publicHoliday,
  study,
}

class _AcademicEvent {
  final DateTime date;
  final DateTime? endDate;
  final String title;
  final String description;
  final _AcademicEventType type;
  final IconData icon;

  const _AcademicEvent({
    required this.date,
    this.endDate,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
  });
}

class _CalendarSummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CalendarSummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _UpcomingItem {
  final String date;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _UpcomingItem({
    required this.date,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });
}
