import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'student_redesign_palette.dart';

/// Where a calendar entry came from — drives its color/icon and whether
/// the student is allowed to edit/delete it.
enum _EventSource {
  /// Set by a teacher/admin for the whole class via `class_schedules`
  /// (`set_class_schedule` RPC). Read-only here — no teacher-side
  /// schedule-editing UI exists yet.
  classSchedule,

  /// Pulled from the student's own assignment due dates — read-only here
  /// too; editing an assignment happens on the ใบงาน tab, not this one.
  assignment,

  /// A `student_personal_tasks` row the student created themselves. Only
  /// these can be checked off or removed.
  personal,
}

class _CalendarEvent {
  _CalendarEvent({
    required this.id,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.title,
    required this.subtitle,
    required this.source,
    this.done = false,
  });

  final String id;
  final DateTime date;
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final String title;
  final String subtitle;
  final _EventSource source;
  final bool done;

  int get startMinutesOfDay => startHour * 60 + startMinute;
  int get endMinutesOfDay => startMinutesOfDay + durationMinutes;

  String get timeLabel {
    final endMinutes = startMinutesOfDay + durationMinutes;
    return '${_fmt(startHour, startMinute)} - ${_fmt(endMinutes ~/ 60, endMinutes % 60)}';
  }

  static String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  // สีสันหลากโทนตามภาพต้นแบบ (ม่วง/ส้ม/เขียวมิ้นต์) แทนเขียวแบรนด์เดียว
  // ที่ใช้ทั่วทั้งแอป — ใช้เฉพาะหน้าปฏิทินหน้านี้ตามที่ขอ
  Color get color => switch (source) {
    _EventSource.classSchedule => const Color(0xFF7C3AED),
    _EventSource.assignment => const Color(0xFFF97316),
    _EventSource.personal => const Color(0xFF14B8A6),
  };

  IconData get icon => switch (source) {
    _EventSource.classSchedule => Icons.school_rounded,
    _EventSource.assignment => Icons.assignment_rounded,
    _EventSource.personal => Icons.push_pin_rounded,
  };

  bool get isEditable => source == _EventSource.personal;
}

enum _EventFilter { all, schedule, assignment, personal }

class StudentCalendarPage extends StatefulWidget {
  const StudentCalendarPage({super.key});

  @override
  State<StudentCalendarPage> createState() => _StudentCalendarPageState();
}

class _StudentCalendarPageState extends State<StudentCalendarPage> {
  static final DateTime _today = DateTime.now();

  late DateTime _focusedMonth = DateTime(_today.year, _today.month);
  late DateTime _selectedDay = _today;
  _EventFilter _filter = _EventFilter.all;
  _CalendarEvent? _selectedEvent;

  bool _loading = true;
  List<_CalendarEvent> _events = [];
  List<ClassScheduleSlot> _scheduleSlots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// โหลดตารางเรียนจริง (`list_my_schedule`) + งานส่วนตัวจริง
  /// (`list_my_personal_tasks`) + กำหนดส่งใบงานจริงของทุกวิชาที่ลงทะเบียน
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final courses = await CourseService.listMyCourses();
      final schedule = await CalendarService.listMySchedule();
      final tasks = await CalendarService.listMyPersonalTasks();

      final assignmentEvents = <_CalendarEvent>[];
      for (final course in courses) {
        final assignments = await AssignmentService.listAssignments(course.id);
        for (final a in assignments) {
          if (!a.isPublished || a.dueAt == null) continue;
          final due = a.dueAt!.toLocal();
          assignmentEvents.add(
            _CalendarEvent(
              id: 'asg-${a.id}',
              date: DateTime(due.year, due.month, due.day),
              startHour: due.hour,
              startMinute: due.minute,
              durationMinutes: 0,
              title: a.title,
              subtitle:
                  'กำหนดส่ง ${_fmtHm(due.hour, due.minute)} น. · วิชา ${course.subjectName}',
              source: _EventSource.assignment,
            ),
          );
        }
      }

      final personalEvents = tasks.where((t) => t.dueAt != null).map((t) {
        final due = t.dueAt!.toLocal();
        return _CalendarEvent(
          id: t.id,
          date: DateTime(due.year, due.month, due.day),
          startHour: due.hour,
          startMinute: due.minute,
          durationMinutes: 60,
          title: t.title,
          subtitle: (t.note != null && t.note!.trim().isNotEmpty)
              ? t.note!
              : 'รายการส่วนตัว',
          source: _EventSource.personal,
          done: t.done,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _scheduleSlots = schedule;
        _events = [
          ..._buildScheduleForMonth(_focusedMonth),
          ..._buildScheduleForMonth(
            DateTime(_focusedMonth.year, _focusedMonth.month + 1),
          ),
          ...assignmentEvents,
          ...personalEvents,
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static String _fmtHm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  List<_CalendarEvent> _buildScheduleForMonth(DateTime month) {
    final events = <_CalendarEvent>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final dayOfWeek = date.weekday - 1; // DateTime.monday=1 → 0=จันทร์
      for (final slot in _scheduleSlots) {
        if (slot.dayOfWeek == dayOfWeek) {
          final startParts = slot.startTime.split(':');
          final endParts = slot.endTime.split(':');
          final startHour = int.parse(startParts[0]);
          final startMinute = int.parse(startParts[1]);
          final endHour = int.parse(endParts[0]);
          final endMinute = int.parse(endParts[1]);
          final duration =
              (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
          events.add(
            _CalendarEvent(
              id: 'sch-${slot.id}-${month.year}-${month.month}-$d',
              date: date,
              startHour: startHour,
              startMinute: startMinute,
              durationMinutes: duration,
              title: slot.subjectName,
              subtitle: (slot.room != null && slot.room!.trim().isNotEmpty)
                  ? 'ห้อง ${slot.room}'
                  : 'ตารางเรียน',
              source: _EventSource.classSchedule,
            ),
          );
        }
      }
    }
    return events;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _matchesFilter(_CalendarEvent e) => switch (_filter) {
    _EventFilter.all => true,
    _EventFilter.schedule => e.source == _EventSource.classSchedule,
    _EventFilter.assignment => e.source == _EventSource.assignment,
    _EventFilter.personal => e.source == _EventSource.personal,
  };

  bool _hasEvents(DateTime day) =>
      _events.any((e) => _isSameDay(e.date, day) && _matchesFilter(e));

  Set<_EventSource> _sourcesFor(DateTime day) => _events
      .where((e) => _isSameDay(e.date, day) && _matchesFilter(e))
      .map((e) => e.source)
      .toSet();

  /// วันจันทร์ของสัปดาห์ที่มี [_selectedDay] อยู่ — ใช้กำหนดคอลัมน์ 7 วัน
  /// ของมุมมองรายสัปดาห์
  DateTime get _weekStart =>
      _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));

  List<_CalendarEvent> _eventsFor(DateTime day) =>
      _events
          .where((e) => _isSameDay(e.date, day) && _matchesFilter(e))
          .toList()
        ..sort((a, b) => a.startMinutesOfDay.compareTo(b.startMinutesOfDay));

  void _goToToday() {
    setState(() {
      _selectedDay = _today;
      _focusedMonth = DateTime(_today.year, _today.month);
    });
  }

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: 7 * deltaWeeks));
      _focusedMonth = DateTime(_selectedDay.year, _selectedDay.month);
      _ensureScheduleExistsForFocusedMonth();
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      _ensureScheduleExistsForFocusedMonth();
      final lastDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        0,
      ).day;
      _selectedDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        _selectedDay.day.clamp(1, lastDay),
      );
    });
  }

  void _ensureScheduleExistsForFocusedMonth() {
    final hasSchedule = _events.any(
      (e) =>
          e.source == _EventSource.classSchedule &&
          e.date.year == _focusedMonth.year &&
          e.date.month == _focusedMonth.month,
    );
    if (!hasSchedule) {
      _events.addAll(_buildScheduleForMonth(_focusedMonth));
    }
  }

  Future<void> _addPersonalEvent(String title, int hour, int minute) async {
    final dueAt = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      hour,
      minute,
    );
    await CalendarService.createPersonalTask(title: title, dueAt: dueAt);
    await _load();
  }

  Future<void> _removeEvent(_CalendarEvent event) async {
    await CalendarService.deletePersonalTask(event.id);
    if (!mounted) return;
    setState(() {
      if (_selectedEvent?.id == event.id) _selectedEvent = null;
    });
    await _load();
  }

  Future<void> _toggleDone(_CalendarEvent event) async {
    await CalendarService.togglePersonalTask(
      taskId: event.id,
      done: !event.done,
    );
    await _load();
  }

  void _openAddEventSheet() {
    final titleController = TextEditingController();
    final hourController = TextEditingController(text: '16');
    final minuteController = TextEditingController(text: '00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
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
                Text(
                  'เพิ่มกิจกรรมส่วนตัว · ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year + 543}',
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'ชื่อกิจกรรม',
                    hintText: 'เช่น อ่านหนังสือสอบวิทย์',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hourController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ชั่วโมง (0-23)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: minuteController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'นาที (0-59)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final hour =
                          int.tryParse(
                            hourController.text.trim(),
                          )?.clamp(0, 23) ??
                          16;
                      final minute =
                          int.tryParse(
                            minuteController.text.trim(),
                          )?.clamp(0, 59) ??
                          0;
                      final navigator = Navigator.of(context);
                      await _addPersonalEvent(
                        titleController.text.trim(),
                        hour,
                        minute,
                      );
                      navigator.pop();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('เพิ่มลงปฏิทิน'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SchoolPalette.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 980;
            final isCompact = constraints.maxWidth < 560;
            return Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(
                    context,
                    isCompact: isCompact,
                    showFilterTabs: isDesktop,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 300,
                                child: _buildLeftColumn(showFilterTabs: false),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildWeekPanel()),
                            ],
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLeftColumn(showFilterTabs: true),
                                const SizedBox(height: 16),
                                // แท็บ "ตารางเรียน" โชว์ตารางเรียนประจำ
                                // สัปดาห์แบบเต็มไปเลย แทนที่จะให้กดเลือก
                                // ทีละวันในปฏิทินย่อก่อนถึงจะเห็นคาบเรียน
                                if (_filter == _EventFilter.schedule)
                                  _buildWeeklyScheduleTable()
                                else
                                  _buildMobileAgenda(),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── ด้านบน: หัวข้อ + แท็บกรองประเภท ────────────────────────────────

  // จอกว้าง (เดสก์ท็อป): แท็บกรองอยู่แถวบนสุดข้างชื่อหน้าเหมือนเดิม
  // เพราะพื้นที่พอ — จอมือถือ: ย้ายไปไว้ใต้ปฏิทินย่อแทน (ดู
  // _buildLeftColumn) กันไม่ให้คอลัมน์ซ้ายมีที่ว่างเปล่าเยอะเกินไป
  // ตอนวางแท็บไว้บนแล้วเหลือพื้นที่ล่างโล่งๆ แบบที่เจอตอนย้ายมาไว้ล่าง
  // ทั้งสองขนาดจอ
  Widget _buildTopBar(
    BuildContext context, {
    required bool isCompact,
    required bool showFilterTabs,
  }) {
    return Row(
      children: [
        if (Navigator.canPop(context))
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: SchoolPalette.ink,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (Navigator.canPop(context)) const SizedBox(width: 8),
        Text(
          'ปฏิทิน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontSize: isCompact ? 19 : 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (showFilterTabs) ...[const Spacer(), _buildFilterTabs()],
      ],
    );
  }

  Widget _buildFilterTabs() {
    // สีของแต่ละแท็บตรงกับจุดสัญลักษณ์ (ม่วง/ส้ม/เขียวมิ้นต์) แทนสีดำ
    // กลางๆ เดียวกันหมด ให้เห็นเชื่อมโยงกับสีในการ์ด/ปฏิทินทันที
    const tabs = [
      (filter: _EventFilter.all, label: 'ทั้งหมด', color: SchoolPalette.ink),
      (
        filter: _EventFilter.schedule,
        label: 'ตารางเรียน',
        color: Color(0xFF7C3AED),
      ),
      (
        filter: _EventFilter.assignment,
        label: 'ใบงาน',
        color: Color(0xFFF97316),
      ),
      (
        filter: _EventFilter.personal,
        label: 'ส่วนตัว',
        color: Color(0xFF14B8A6),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tab in tabs)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() => _filter = tab.filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // กล่องพื้นหลังเปลี่ยนเป็นสีทึบเข้มของแท็บเองตอนถูกเลือก
                  // (ตัวหนังสือเปลี่ยนเป็นขาว) แทนจุดกลมข้างตัวหนังสือ
                  color: _filter == tab.filter ? tab.color : null,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: _filter == tab.filter
                      ? [
                          BoxShadow(
                            color: tab.color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _filter == tab.filter
                        ? Colors.white
                        : SchoolPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── คอลัมน์ซ้าย: ป้ายวันที่ + ปฏิทินย่อ + รายละเอียดกิจกรรมที่เลือก ──

  static const _monthNames = [
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
  static const _monthShort = [
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
  static const _weekdayFull = [
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];
  static const _weekdayShort = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  Widget _buildLeftColumn({required bool showFilterTabs}) {
    // การ์ด "สัญลักษณ์" เดิมซ้ำซ้อนกับสีในแท็บกรองแล้ว เอาออกไปแล้ว —
    // แท็บกรองเองแสดงตรงนี้เฉพาะจอมือถือ (showFilterTabs: true) เดสก์ท็อป
    // อยู่แถวบนสุดแทน (ดู _buildTopBar) กันคอลัมน์ซ้ายมีที่ว่างเปล่าเยอะ
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateBadgeCard(),
        const SizedBox(height: 16),
        _buildMiniMonthCard(),
        if (showFilterTabs) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: _buildFilterTabs(),
          ),
        ],
        if (_selectedEvent != null) ...[
          const SizedBox(height: 16),
          _buildEventDetailCard(_selectedEvent!),
        ],
      ],
    );
  }

  Widget _buildDateBadgeCard() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          // สีแดงส้มแบบกล่อง "APR" ในภาพต้นแบบ แทน gradient เขียวแบรนด์
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40EF4444),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _monthShort[_selectedDay.month - 1],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${_selectedDay.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year + 543}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _weekdayFull[_selectedDay.weekday - 1],
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMonthCard() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = firstOfMonth.weekday - 1;
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBEDCD0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                color: SchoolPalette.ink,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year + 543}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                color: SchoolPalette.ink,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final label in _weekdayShort)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * 7,
            // กำหนด aspect ratio ไว้ กันไม่ให้ช่องวันสูงเกินไปตอนการ์ด
            // ซ้ายเต็มความกว้างจอมือถือ (เดิมไม่กำหนด เลยเป็นสี่เหลี่ยม
            // จัตุรัสตามความกว้างคอลัมน์ ซึ่งกว้างกว่าตอนอยู่ในจอ 300px)
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                dayNumber,
              );
              final isToday = _isSameDay(date, _today);
              final isSelected = _isSameDay(date, _selectedDay);
              final sources = _sourcesFor(date);

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  _selectedDay = date;
                  _selectedEvent = null;
                }),
                child: Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SchoolPalette.ink
                        : isToday
                        ? const Color(0xFFFEE2E2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? const Color(0xFFEF4444)
                              : SchoolPalette.navy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_hasEvents(date))
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final source in sources)
                              Container(
                                width: 3.5,
                                height: 3.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 0.8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : _colorForSource(source),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        )
                      else
                        const SizedBox(height: 3.5),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _colorForSource(_EventSource source) => switch (source) {
    _EventSource.classSchedule => const Color(0xFF7C3AED),
    _EventSource.assignment => const Color(0xFFF97316),
    _EventSource.personal => const Color(0xFF14B8A6),
  };

  Widget _buildEventDetailCard(_CalendarEvent event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBEDCD0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedEvent = null),
                icon: const Icon(Icons.close_rounded, size: 18),
                color: SchoolPalette.muted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: event.color),
              const SizedBox(width: 6),
              Text(
                '${event.date.day} ${_monthNames[event.date.month - 1]} ${event.date.year + 543}',
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: event.color),
              const SizedBox(width: 6),
              Text(
                event.durationMinutes > 0
                    ? event.timeLabel
                    : '${event.startHour.toString().padLeft(2, '0')}:${event.startMinute.toString().padLeft(2, '0')} น.',
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.subtitle,
            style: const TextStyle(
              color: SchoolPalette.navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (event.isEditable) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _toggleDone(event),
                icon: Icon(
                  event.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                ),
                label: Text(
                  event.done ? 'ทำเสร็จแล้ว' : 'ทำเครื่องหมายว่าเสร็จ',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF14B8A6),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _removeEvent(event),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('ลบรายการนี้'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── คอลัมน์ขวา: มุมมองรายสัปดาห์แบบตารางเวลา ──────────────────────

  Widget _buildWeekPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBEDCD0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekToolbar(),
          const SizedBox(height: 14),
          Expanded(child: _buildWeekBoard()),
        ],
      ),
    );
  }

  Widget _buildWeekToolbar() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Row(
      children: [
        IconButton(
          onPressed: () => _shiftWeek(-1),
          icon: const Icon(Icons.chevron_left_rounded),
          color: SchoolPalette.ink,
        ),
        OutlinedButton(
          onPressed: _goToToday,
          style: OutlinedButton.styleFrom(
            foregroundColor: SchoolPalette.ink,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('วันนี้'),
        ),
        IconButton(
          onPressed: () => _shiftWeek(1),
          icon: const Icon(Icons.chevron_right_rounded),
          color: SchoolPalette.ink,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_weekStart.day} ${_monthShort[_weekStart.month - 1]} - ${weekEnd.day} ${_monthShort[weekEnd.month - 1]} ${weekEnd.year + 543}',
            style: const TextStyle(
              color: SchoolPalette.navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        // ปุ่มดำทึบแบบ "+ Add Event" ในภาพต้นแบบ แทน GradientButton เขียว
        FilledButton.icon(
          onPressed: _openAddEventSheet,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('เพิ่มกิจกรรม'),
          style: FilledButton.styleFrom(
            backgroundColor: SchoolPalette.ink,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ตารางเรียนโรงเรียนมีแค่วันจันทร์-ศุกร์ — ตัดเสาร์-อาทิตย์ออกจากมุมมอง
  // รายสัปดาห์ ให้เหลือ 5 คอลัมน์ตรงกับวันเรียนจริง แทนตารางเวลา 7 วัน
  // แบบเดิม แล้วเปลี่ยนจากบล็อกตามเวลาเป็นการ์ดสีวางซ้อนแบบบอร์ด — คลิก
  // การ์ดแล้วรายละเอียดไปโชว์ที่การ์ดซ้ายตามตัวอย่างที่ส่งมา
  Widget _buildWeekBoard() {
    final weekdays = List.generate(5, (i) => _weekStart.add(Duration(days: i)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in weekdays)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DayBoardColumn(
                day: day,
                isToday: _isSameDay(day, _today),
                events: _eventsFor(day),
                selectedEventId: _selectedEvent?.id,
                onEventTap: (event) => setState(() => _selectedEvent = event),
              ),
            ),
          ),
      ],
    );
  }

  // ── แท็บ "ตารางเรียน": ตารางเรียนประจำสัปดาห์เต็มรูปแบบ จัดกลุ่มตาม
  // วัน จ-ศ ให้เห็นทุกคาบทันทีโดยไม่ต้องกดเลือกทีละวันในปฏิทินย่อก่อน ──

  Widget _buildWeeklyScheduleTable() {
    const weekdayLabels = [
      'วันจันทร์',
      'วันอังคาร',
      'วันพุธ',
      'วันพฤหัสบดี',
      'วันศุกร์',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBEDCD0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตารางเรียนประจำสัปดาห์',
            style: TextStyle(
              color: SchoolPalette.navy,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (_scheduleSlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'ยังไม่มีตารางเรียนที่ครูกำหนดไว้',
                  style: TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            for (var dayOfWeek = 0; dayOfWeek <= 4; dayOfWeek++) ...[
              if (_scheduleSlots.any((s) => s.dayOfWeek == dayOfWeek)) ...[
                Text(
                  weekdayLabels[dayOfWeek],
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                for (final slot
                    in (_scheduleSlots
                        .where((s) => s.dayOfWeek == dayOfWeek)
                        .toList()
                      ..sort((a, b) => a.startTime.compareTo(b.startTime))))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              slot.startTime.substring(0, 5),
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.subjectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SchoolPalette.navy,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  (slot.room != null &&
                                          slot.room!.trim().isNotEmpty)
                                      ? 'ห้อง ${slot.room}'
                                      : 'ตารางเรียน',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SchoolPalette.muted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
            ],
        ],
      ),
    );
  }

  // ── มือถือ: agenda รายวันแบบเดิม (ตารางเวลาแนวนอนไม่เหมาะกับจอแคบ) ──

  Widget _buildMobileAgenda() {
    final events = _eventsFor(_selectedDay);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBEDCD0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'รายการวันที่ ${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year + 543}',
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _openAddEventSheet,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('เพิ่ม'),
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolPalette.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 11.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 32,
                    color: SchoolPalette.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ไม่มีรายการในวันนี้',
                    style: TextStyle(
                      color: SchoolPalette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventRow(
                      event: event,
                      onDelete: event.isEditable
                          ? () => _removeEvent(event)
                          : null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One weekday's column in the board view — a date-header pill (with a
/// "TODAY" badge when applicable) followed by a scrollable stack of
/// pastel event cards, matching the Trello-style board reference.
class _DayBoardColumn extends StatelessWidget {
  const _DayBoardColumn({
    required this.day,
    required this.isToday,
    required this.events,
    required this.selectedEventId,
    required this.onEventTap,
  });

  final DateTime day;
  final bool isToday;
  final List<_CalendarEvent> events;
  final String? selectedEventId;
  final ValueChanged<_CalendarEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? const Color(0xFFEF4444) : SchoolPalette.navy,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'TODAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: const Color(0xFFF1F5F9)),
        const SizedBox(height: 8),
        Expanded(
          child: events.isEmpty
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      for (final event in events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BoardEventCard(
                            event: event,
                            isSelected: event.id == selectedEventId,
                            onTap: () => onEventTap(event),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Pastel event card stacked in a day column — clicking it selects the
/// event so its full detail shows in the left-hand detail card.
class _BoardEventCard extends StatelessWidget {
  const _BoardEventCard({
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  final _CalendarEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: isSelected ? 0.24 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: event.color, width: 1.6)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: event.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(event.icon, size: 11, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    event.durationMinutes > 0
                        ? '${event.startHour.toString().padLeft(2, '0')}:${event.startMinute.toString().padLeft(2, '0')}'
                        : 'กำหนดส่ง',
                    style: TextStyle(
                      color: event.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: event.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  decoration: event.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              if (event.source == _EventSource.classSchedule) ...[
                const SizedBox(height: 3),
                Text(
                  event.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: event.color.withValues(alpha: 0.85),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastel pill card — solid-tinted background, bold title on top with the
/// time range underneath, small white icon box on the trailing edge —
/// matching the "Available 08:00-11:00" slot cards in the reference.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, this.onDelete});

  final _CalendarEvent event;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: event.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    decoration: event.done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.durationMinutes > 0
                      ? event.timeLabel
                      : '${event.startHour.toString().padLeft(2, '0')}:${event.startMinute.toString().padLeft(2, '0')} น. · ${event.subtitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: event.color.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: onDelete != null
                ? IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: event.color,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : Icon(event.icon, color: event.color, size: 17),
          ),
        ],
      ),
    );
  }
}
