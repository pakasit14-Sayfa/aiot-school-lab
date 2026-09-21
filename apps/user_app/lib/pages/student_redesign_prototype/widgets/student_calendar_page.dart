import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'student_empty_state.dart';
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
  const StudentCalendarPage({
    super.key,
    this.loadCourses,
    this.loadSchedule,
    this.loadTasks,
    this.loadAssignmentsForCourse,
    this.createTask,
    this.deleteTask,
    this.toggleTask,
  });

  /// Read/write seams, threaded through to the corresponding
  /// CourseService/CalendarService/AssignmentService static calls in
  /// production — widget tests supply these to drive real/empty/error
  /// states and verify mutations without a live Supabase client.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<ClassScheduleSlot>> Function()? loadSchedule;
  final Future<List<PersonalTask>> Function()? loadTasks;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse;
  final Future<void> Function({required String title, required DateTime dueAt})?
  createTask;
  final Future<void> Function(String taskId)? deleteTask;
  final Future<void> Function({required String taskId, required bool done})?
  toggleTask;

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
      final courses = await (widget.loadCourses ?? CourseService.listMyCourses)();
      final schedule = await (widget.loadSchedule ?? CalendarService.listMySchedule)();
      final tasks = await (widget.loadTasks ?? CalendarService.listMyPersonalTasks)();

      final assignmentEvents = <_CalendarEvent>[];
      for (final course in courses) {
        final assignments = await (widget.loadAssignmentsForCourse ??
            AssignmentService.listAssignments)(course.id);
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

  Future<void> _addPersonalEvent(String title, DateTime dueAt) async {
    final create =
        widget.createTask ??
        ({required String title, required DateTime dueAt}) =>
            CalendarService.createPersonalTask(title: title, dueAt: dueAt);
    await create(title: title, dueAt: dueAt);
    if (!mounted) return;
    setState(() {
      _selectedDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
      _focusedMonth = DateTime(dueAt.year, dueAt.month);
    });
    await _load();
  }

  Future<void> _removeEvent(_CalendarEvent event) async {
    final delete = widget.deleteTask ?? CalendarService.deletePersonalTask;
    await delete(event.id);
    if (!mounted) return;
    setState(() {
      if (_selectedEvent?.id == event.id) _selectedEvent = null;
    });
    await _load();
  }

  Future<void> _toggleDone(_CalendarEvent event) async {
    final toggle = widget.toggleTask ?? CalendarService.togglePersonalTask;
    await toggle(taskId: event.id, done: !event.done);
    await _load();
  }

  Future<void> _openAddEventSheet() async {
    final result = await showModalBottomSheet<({String title, DateTime dueAt})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPersonalEventSheet(
        initialDay: _selectedDay,
        monthNames: _monthNames,
        weekdayFull: _weekdayFull,
      ),
    );
    if (result == null || !mounted) return;
    await _addPersonalEvent(result.title, result.dueAt);
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(
                    context,
                    isCompact: isCompact,
                    showFilterTabs: isDesktop,
                  ),
                  if (!isCompact || Navigator.canPop(context))
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
    // Inside the tab shell on a phone the app bar already reads
    // "ปฏิทิน / ตารางเรียน" — a second heading was the first thing the
    // owner flagged on the 2026-09-18 phone review.
    if (isCompact && !Navigator.canPop(context)) {
      return const SizedBox.shrink();
    }
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
      (
        filter: _EventFilter.all,
        label: 'ทั้งหมด',
        color: SchoolPalette.deepGreen,
      ),
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
        color: SchoolPalette.softGreenBg,
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
    final isToday = _isSameDay(_selectedDay, _today);
    final count = _eventsFor(_selectedDay).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: SchoolPalette.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _monthShort[_selectedDay.month - 1],
                  style: const TextStyle(
                    color: SchoolPalette.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_selectedDay.day}',
                  style: const TextStyle(
                    color: SchoolPalette.deepGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
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
                  '${_weekdayFull[_selectedDay.weekday - 1]}ที่ ${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year + 543}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count == 0 ? 'ไม่มีรายการ' : '$count รายการ',
                  style: const TextStyle(
                    color: SchoolPalette.cream,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SchoolPalette.yellow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'วันนี้',
                style: TextStyle(
                  color: SchoolPalette.deepGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _goToToday,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'ไปวันนี้',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
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
        border: Border.all(color: SchoolPalette.glassBorder, width: 1.2),
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
                        ? SchoolPalette.green
                        : isToday
                        ? SchoolPalette.softGreenBg
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: SchoolPalette.green, width: 1.2)
                        : null,
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
                              ? SchoolPalette.deepGreen
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
        border: Border.all(color: SchoolPalette.glassBorder, width: 1.2),
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
        border: Border.all(color: SchoolPalette.glassBorder, width: 1.2),
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
        border: Border.all(color: SchoolPalette.glassBorder, width: 1.2),
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
        border: Border.all(color: SchoolPalette.glassBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSameDay(_selectedDay, _today)
                      ? 'รายการวันนี้'
                      : 'รายการวันที่ ${_selectedDay.day} ${_monthShort[_selectedDay.month - 1]}',
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
                  backgroundColor: SchoolPalette.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const StudentEmptyState(
              icon: Icons.event_available_rounded,
              title: 'ไม่มีรายการในวันนี้',
              hint: 'กด "เพิ่ม" เพื่อจดกิจกรรมส่วนตัว หรือเลือกวันอื่นในปฏิทิน',
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

/// "เพิ่มกิจกรรมส่วนตัว" as a bottom sheet in the shape people know from
/// iOS Calendar / Reminders (2026-09-18 owner review): a title field, a
/// date row and a time row that open pickers (a Cupertino wheel for time
/// instead of the old "ชั่วโมง (0-23)" text boxes that silently clamped
/// typos), a disabled primary button until there is a title, and an
/// explicit ยกเลิก. Pops with the value; the page does the RPC.
class _AddPersonalEventSheet extends StatefulWidget {
  const _AddPersonalEventSheet({
    required this.initialDay,
    required this.monthNames,
    required this.weekdayFull,
  });

  final DateTime initialDay;
  final List<String> monthNames;
  final List<String> weekdayFull;

  @override
  State<_AddPersonalEventSheet> createState() => _AddPersonalEventSheetState();
}

class _AddPersonalEventSheetState extends State<_AddPersonalEventSheet> {
  final _title = TextEditingController();
  late DateTime _day = widget.initialDay;
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);
  bool _showTimeWheel = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String get _dayLabel =>
      '${widget.weekdayFull[_day.weekday - 1]} ${_day.day} ${widget.monthNames[_day.month - 1]} ${_day.year + 543}';

  String get _timeLabel =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')} น.';

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(_day.year - 1),
      lastDate: DateTime(_day.year + 1, 12, 31),
      helpText: 'เลือกวัน',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: SchoolPalette.green,
            onPrimary: Colors.white,
            onSurface: SchoolPalette.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _day = picked);
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop((
      title: title,
      dueAt: DateTime(
        _day.year,
        _day.month,
        _day.day,
        _time.hour,
        _time.minute,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _title.text.trim().isNotEmpty;
    const quick = [
      (label: 'เช้า', time: TimeOfDay(hour: 8, minute: 0)),
      (label: 'บ่าย', time: TimeOfDay(hour: 13, minute: 0)),
      (label: 'เย็น', time: TimeOfDay(hour: 16, minute: 0)),
      (label: 'ค่ำ', time: TimeOfDay(hour: 19, minute: 0)),
    ];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SchoolPalette.glassBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: SchoolPalette.primaryGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กิจกรรมส่วนตัว',
                          style: TextStyle(
                            color: SchoolPalette.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'เห็นเฉพาะคุณ ไม่ส่งถึงครู',
                          style: TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: SchoolPalette.softGreenBg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: SchoolPalette.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'ชื่อกิจกรรม',
                  hintStyle: const TextStyle(
                    color: SchoolPalette.muted,
                    fontWeight: FontWeight.w500,
                  ),
                  helperText: 'เช่น อ่านหนังสือสอบวิทย์ · ซ้อมกีฬาสี',
                  helperStyle: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11,
                  ),
                  prefixIcon: const Icon(
                    Icons.notes_rounded,
                    color: SchoolPalette.green,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: SchoolPalette.glassBorder,
                      width: 1.3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: SchoolPalette.green,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _FieldRow(
                icon: Icons.calendar_today_rounded,
                label: 'วัน',
                value: _dayLabel,
                onTap: _pickDay,
              ),
              const SizedBox(height: 8),
              _FieldRow(
                icon: Icons.schedule_rounded,
                label: 'เวลา',
                value: _timeLabel,
                highlighted: _showTimeWheel,
                onTap: () => setState(() => _showTimeWheel = !_showTimeWheel),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in quick)
                    _QuickTimeChip(
                      label:
                          '${q.label} ${q.time.hour.toString().padLeft(2, '0')}:00',
                      selected:
                          _time.hour == q.time.hour &&
                          _time.minute == q.time.minute,
                      onTap: () => setState(() {
                        _time = q.time;
                        _showTimeWheel = false;
                      }),
                    ),
                ],
              ),
              if (_showTimeWheel) ...[
                const SizedBox(height: 10),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: SchoolPalette.softGreenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    minuteInterval: 5,
                    initialDateTime: DateTime(
                      _day.year,
                      _day.month,
                      _day.day,
                      _time.hour,
                      _time.minute - _time.minute % 5,
                    ),
                    onDateTimeChanged: (dt) => setState(
                      () => _time = TimeOfDay(hour: dt.hour, minute: dt.minute),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _GradientButton(
                enabled: canSave,
                label: 'เพิ่มลงปฏิทิน',
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTimeChip extends StatelessWidget {
  const _QuickTimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SchoolPalette.green : SchoolPalette.softGreenBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? SchoolPalette.green : SchoolPalette.glassBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : SchoolPalette.deepGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: SchoolPalette.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x33165042),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlighted ? SchoolPalette.green : SchoolPalette.glassBorder,
          width: highlighted ? 1.6 : 1.3,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: SchoolPalette.green),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlighted ? SchoolPalette.green : SchoolPalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                highlighted
                    ? Icons.expand_less_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: SchoolPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
