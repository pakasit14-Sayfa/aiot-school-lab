import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/parent_common_widgets.dart';

typedef ParentCalendarLoader = Future<List<CalendarEventItem>> Function();

class ParentAcademicCalendarPage extends StatefulWidget {
  final ParentCalendarLoader? eventsLoader;
  final DateTime Function()? now;

  const ParentAcademicCalendarPage({super.key, this.eventsLoader, this.now});

  @override
  State<ParentAcademicCalendarPage> createState() =>
      _ParentAcademicCalendarPageState();
}

class _ParentAcademicCalendarPageState
    extends State<ParentAcademicCalendarPage> {
  static const _bg = Color(0xFFF5F7FB);
  static const _primary = Color(0xFF2867B2);
  static const _empty = 'ยังไม่มีข้อมูล';

  late DateTime _selectedMonth;
  late DateTime _selectedDate;
  String _selectedFilter = 'ทั้งหมด';
  List<CalendarEventItem> _events = const [];
  bool _loading = true;
  bool _unauthenticated = false;
  Object? _loadError;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(_now);
    _selectedMonth = DateTime(today.year, today.month);
    _selectedDate = today;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _unauthenticated = false;
      _loadError = null;
    });
    if (widget.eventsLoader == null && AuthService.sessionToken == null) {
      setState(() {
        _loading = false;
        _unauthenticated = true;
      });
      return;
    }
    try {
      final items = [
        ...await (widget.eventsLoader ??
            ParentPortalService.listCalendarEvents)(),
      ];
      if (!mounted) return;
      items.sort((a, b) => a.startDate.compareTo(b.startDate));
      setState(() {
        _events = items;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ParentAcademicCalendarPage load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _events = const [];
        _loadError = error;
        _loading = false;
      });
    }
  }

  List<CalendarEventItem> get _filteredEvents => _events.where((event) {
    return _selectedFilter == 'ทั้งหมด' ||
        _filterName(event.eventType) == _selectedFilter;
  }).toList();

  List<CalendarEventItem> _eventsForDate(DateTime date) {
    final target = _dateOnly(date);
    return _filteredEvents.where((event) {
      final start = _dateOnly(event.startDate);
      final end = _dateOnly(event.endDate ?? event.startDate);
      return !target.isBefore(start) && !target.isAfter(end);
    }).toList();
  }

  List<CalendarEventItem> get _upcomingEvents => _filteredEvents
      .where(
        (event) => !_dateOnly(
          event.endDate ?? event.startDate,
        ).isBefore(_dateOnly(_now)),
      )
      .toList();

  CalendarEventItem? get _nextEvent =>
      _upcomingEvents.isEmpty ? null : _upcomingEvents.first;

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
                    title: 'ปฏิทินวิชาการ',
                    subtitle:
                        'ติดตามวันสอบ วันหยุด กิจกรรม และกำหนดการของโรงเรียน',
                    icon: Icons.calendar_month_rounded,
                    trailing: _SchoolCalendarBadge(),
                  ),
                  const SizedBox(height: 18),
                  _loadState(),
                  const SizedBox(height: 16),
                  _hero(),
                  const SizedBox(height: 16),
                  _summaryCards(),
                  const SizedBox(height: 16),
                  _filterBar(),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 980) {
                        return Column(
                          children: [
                            _calendarCard(),
                            const SizedBox(height: 14),
                            _selectedDayCard(),
                          ],
                        );
                      }
                      return SizedBox(
                        height: 610,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 7, child: _calendarCard()),
                            const SizedBox(width: 14),
                            Expanded(flex: 4, child: _selectedDayCard()),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            _upcomingCard(),
                            const SizedBox(height: 14),
                            _importantDatesCard(),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _upcomingCard()),
                          const SizedBox(width: 14),
                          Expanded(flex: 5, child: _importantDatesCard()),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _reminderCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadState() {
    if (_loading) {
      return const _StateCard(
        icon: Icons.sync_rounded,
        message: 'กำลังโหลดข้อมูล',
      );
    }
    if (_unauthenticated) {
      return const _StateCard(
        icon: Icons.lock_outline_rounded,
        message: 'กรุณาเข้าสู่ระบบเพื่อดูข้อมูล',
      );
    }
    if (_loadError != null) {
      return _StateCard(
        icon: Icons.error_outline_rounded,
        message: 'ไม่สามารถโหลดข้อมูลได้',
        action: TextButton(
          onPressed: _loadData,
          child: const Text('ลองอีกครั้ง'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _hero() {
    final next = _nextEvent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C5790), Color(0xFF2D83C5)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ปฏิทินโรงเรียน',
                style: TextStyle(color: Colors.white.withValues(alpha: .76)),
              ),
              const SizedBox(height: 4),
              Text(
                _events.isEmpty ? _empty : _thaiMonthYear(_selectedMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroBadge(
                    icon: Icons.today_rounded,
                    text: 'วันนี้ ${_formatDate(_now)}',
                  ),
                  _HeroBadge(
                    icon: Icons.event_available_rounded,
                    text: _events.isEmpty
                        ? _empty
                        : '${_upcomingEvents.length} กำหนดการถัดไป',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'กำหนดการถัดไป',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  next == null ? _empty : _formatDate(next.startDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (next != null)
                  Text(next.title, style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 15), right],
            );
          }
          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              SizedBox(width: 240, child: right),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCards() {
    final cards = [
      ('วันสอบ', 'exam', Icons.edit_note_rounded, const Color(0xFFF09A37)),
      (
        'กิจกรรม',
        'activity',
        Icons.celebration_rounded,
        const Color(0xFF8A65C7),
      ),
      (
        'หยุดโรงเรียน',
        'holiday',
        Icons.beach_access_rounded,
        const Color(0xFF18A06F),
      ),
      (
        'หยุดนักขัตฤกษ์',
        'public_holiday',
        Icons.flag_rounded,
        const Color(0xFFDB5962),
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
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((item) {
            final count = _events
                .where((event) => event.eventType == item.$2)
                .length;
            return SizedBox(
              width: width,
              child: _MetricCard(
                title: item.$1,
                value: _events.isEmpty ? _empty : '$count',
                icon: item.$3,
                color: item.$4,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _filterBar() => ParentCard(
    padding: const EdgeInsets.all(13),
    child: Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('แสดง'),
        ...[
          'ทั้งหมด',
          'วันสอบ',
          'กิจกรรม',
          'วันหยุดโรงเรียน',
          'วันหยุดนักขัตฤกษ์',
        ].map(
          (filter) => ChoiceChip(
            label: Text(filter),
            selected: _selectedFilter == filter,
            onSelected: (_) => setState(() => _selectedFilter = filter),
          ),
        ),
      ],
    ),
  );

  Widget _calendarCard() => ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                icon: Icons.calendar_month_rounded,
                title: 'ปฏิทินรายเดือน',
                subtitle: 'เลือกวันที่เพื่อดูรายละเอียด',
              ),
            ),
            IconButton(
              tooltip: 'เดือนก่อนหน้า',
              onPressed: () => setState(
                () => _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                ),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              _thaiMonthYear(_selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            IconButton(
              tooltip: 'เดือนถัดไป',
              onPressed: () => setState(
                () => _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                ),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
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
        _monthGrid(),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 12,
          runSpacing: 7,
          children: [
            _Legend(label: 'วันสอบ', color: Color(0xFFF09A37)),
            _Legend(label: 'กิจกรรม', color: Color(0xFF8A65C7)),
            _Legend(label: 'วันหยุดโรงเรียน', color: Color(0xFF18A06F)),
            _Legend(label: 'วันหยุดนักขัตฤกษ์', color: Color(0xFFDB5962)),
          ],
        ),
      ],
    ),
  );

  Widget _monthGrid() {
    final first = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final days = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = ((leading + days) / 7).ceil() * 7;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 5.0;
        final width = (constraints.maxWidth - gap * 6) / 7;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(cells, (index) {
            final day = index - leading + 1;
            if (day < 1 || day > days) {
              return SizedBox(width: width, height: 68);
            }
            final date = DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              day,
            );
            return SizedBox(
              width: width,
              height: 68,
              child: _calendarCell(date),
            );
          }),
        );
      },
    );
  }

  Widget _calendarCell(DateTime date) {
    final items = _eventsForDate(date);
    final selected = _sameDay(date, _selectedDate);
    final today = _sameDay(date, _now);
    return Material(
      color: selected ? const Color(0xFFEAF3FF) : const Color(0xFFF9FAFC),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => setState(() => _selectedDate = date),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7EAFE1)
                  : const Color(0xFFE9ECF1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 23,
                height: 23,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: today ? _primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: today ? Colors.white : const Color(0xFF3F4B5C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (items.isNotEmpty)
                Wrap(
                  spacing: 3,
                  children: items
                      .take(3)
                      .map(
                        (event) => Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _eventColor(event.eventType),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedDayCard() {
    final items = _eventsForDate(_selectedDate);
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
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
            child: Text(
              _fullThaiDate(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _EmptyState()
          else
            ...items.map((event) => _EventTile(event: event)),
        ],
      ),
    );
  }

  Widget _upcomingCard() => _EventListCard(
    icon: Icons.upcoming_rounded,
    title: 'กำหนดการที่กำลังจะถึง',
    subtitle: 'รายการสำคัญที่ผู้ปกครองควรทราบ',
    items: _upcomingEvents.take(6).toList(),
  );

  Widget _importantDatesCard() => _EventListCard(
    icon: Icons.flag_rounded,
    title: 'วันสำคัญ',
    subtitle: 'วันสอบและวันหยุดที่บันทึกในระบบ',
    items: _filteredEvents
        .where(
          (event) => const {
            'exam',
            'holiday',
            'public_holiday',
          }.contains(event.eventType),
        )
        .take(6)
        .toList(),
  );

  Widget _reminderCard() => _EventListCard(
    icon: Icons.notifications_active_rounded,
    title: 'แจ้งเตือนสำหรับผู้ปกครอง',
    subtitle: 'สามกำหนดการถัดไปจากปฏิทินโรงเรียน',
    items: _upcomingEvents.take(3).toList(),
    horizontal: true,
  );

  String _filterName(String type) => switch (type) {
    'exam' => 'วันสอบ',
    'activity' => 'กิจกรรม',
    'holiday' => 'วันหยุดโรงเรียน',
    'public_holiday' => 'วันหยุดนักขัตฤกษ์',
    _ => 'ทั้งหมด',
  };
}

class _SchoolCalendarBadge extends StatelessWidget {
  const _SchoolCalendarBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE1E6EE)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.school_rounded, color: Color(0xFF2867B2), size: 18),
        SizedBox(width: 7),
        Text('ปฏิทินโรงเรียน', style: TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const _StateCard({required this.icon, required this.message, this.action});
  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF2867B2)),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        ?action,
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 22),
    child: Center(
      child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Color(0xFF8A94A5))),
    ),
  );
}

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
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2867B2), size: 17),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF8993A4))),
          ],
        ),
      ),
    ],
  );
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroBadge({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF7F899A))),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeekHeader extends StatelessWidget {
  final String text;
  const _WeekHeader(this.text);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(text, style: const TextStyle(color: Color(0xFF7F899A))),
    ),
  );
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label),
    ],
  );
}

class _EventTile extends StatelessWidget {
  final CalendarEventItem event;
  const _EventTile({required this.event});
  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.eventType);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_eventIcon(event.eventType), color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(event.description!),
                if (event.location != null && event.location!.isNotEmpty)
                  Text(
                    event.location!,
                    style: const TextStyle(color: Color(0xFF8993A4)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<CalendarEventItem> items;
  final bool horizontal;
  const _EventListCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
    this.horizontal = false,
  });
  @override
  Widget build(BuildContext context) => ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const _EmptyState()
        else if (horizontal)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 550
                  ? 2
                  : 1;
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: items
                    .map(
                      (event) => SizedBox(
                        width: width,
                        child: _EventTile(event: event),
                      ),
                    )
                    .toList(),
              );
            },
          )
        else
          ...items.map(
            (event) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 88, child: Text(_formatDate(event.startDate))),
                Expanded(child: _EventTile(event: event)),
              ],
            ),
          ),
      ],
    ),
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color _eventColor(String type) => switch (type) {
  'exam' => const Color(0xFFF09A37),
  'activity' => const Color(0xFF8A65C7),
  'holiday' => const Color(0xFF18A06F),
  'public_holiday' => const Color(0xFFDB5962),
  _ => const Color(0xFF2E83C5),
};

IconData _eventIcon(String type) => switch (type) {
  'exam' => Icons.edit_note_rounded,
  'activity' => Icons.celebration_rounded,
  'holiday' => Icons.beach_access_rounded,
  'public_holiday' => Icons.flag_rounded,
  _ => Icons.menu_book_rounded,
};

String _formatDate(DateTime value) {
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
  final local = value.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year + 543}';
}

String _thaiMonthYear(DateTime value) {
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
  return '${months[value.month - 1]} ${value.year + 543}';
}

String _fullThaiDate(DateTime value) {
  const weekdays = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];
  return '${weekdays[value.weekday - 1]} ${_formatDate(value)}';
}
