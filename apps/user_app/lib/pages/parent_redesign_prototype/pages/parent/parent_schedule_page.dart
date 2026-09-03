import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/parent_common_widgets.dart';

typedef ParentScheduleStudentsLoader =
    Future<List<LinkedStudentItem>> Function();
typedef ParentScheduleLoader =
    Future<List<StudentScheduleItem>> Function(String studentId);
typedef ParentAssignmentsLoader =
    Future<List<StudentAssignmentItem>> Function(String studentId);

class ParentSchedulePage extends StatefulWidget {
  final ParentScheduleStudentsLoader? studentsLoader;
  final ParentScheduleLoader? scheduleLoader;
  final ParentAssignmentsLoader? assignmentsLoader;
  final DateTime Function()? now;

  const ParentSchedulePage({
    super.key,
    this.studentsLoader,
    this.scheduleLoader,
    this.assignmentsLoader,
    this.now,
  });

  @override
  State<ParentSchedulePage> createState() => _ParentSchedulePageState();
}

class _ParentSchedulePageState extends State<ParentSchedulePage> {
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _empty = 'ยังไม่มีข้อมูล';

  String _selectedDay = 'วันนี้';
  String _selectedHomeworkFilter = 'ทั้งหมด';
  List<LinkedStudentItem> _students = const [];
  LinkedStudentItem? _selectedStudent;
  List<StudentScheduleItem> _schedule = const [];
  List<StudentAssignmentItem> _assignments = const [];
  bool _isLoading = true;
  Object? _loadError;
  bool _unauthenticated = false;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? studentId}) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _unauthenticated = false;
    });
    try {
      if (widget.studentsLoader == null && AuthService.sessionToken == null) {
        setState(() {
          _isLoading = false;
          _unauthenticated = true;
        });
        return;
      }

      final students =
          await (widget.studentsLoader ??
              ParentPortalService.listMyLinkedStudents)();
      if (!mounted) return;
      if (students.isEmpty) {
        setState(() {
          _students = const [];
          _selectedStudent = null;
          _schedule = const [];
          _assignments = const [];
          _isLoading = false;
        });
        return;
      }

      final selected = students.firstWhere(
        (student) => student.studentId == studentId,
        orElse: () => students.first,
      );
      final results = await Future.wait<Object>([
        (widget.scheduleLoader ?? ParentPortalService.listMyStudentSchedule)(
          selected.studentId,
        ),
        (widget.assignmentsLoader ??
            ParentPortalService.listMyStudentAssignmentItems)(
          selected.studentId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedStudent = selected;
        _schedule = results[0] as List<StudentScheduleItem>;
        _assignments = results[1] as List<StudentAssignmentItem>;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ParentSchedulePage load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _schedule = const [];
        _assignments = const [];
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  List<StudentScheduleItem> get _visibleSchedule {
    final targetDay = switch (_selectedDay) {
      'วันนี้' => _now.weekday,
      'พรุ่งนี้' => _now.add(const Duration(days: 1)).weekday,
      _ => null,
    };
    final items = targetDay == null
        ? [..._schedule]
        : _schedule.where((item) => item.dayOfWeek == targetDay).toList();
    items.sort((a, b) {
      final day = a.dayOfWeek.compareTo(b.dayOfWeek);
      return day != 0 ? day : a.startTime.compareTo(b.startTime);
    });
    return items;
  }

  bool _isSubmitted(StudentAssignmentItem item) {
    return const {'submitted', 'graded', 'returned'}.contains(item.status);
  }

  bool _isDueSoon(StudentAssignmentItem item) {
    final dueAt = item.dueAt;
    if (dueAt == null || _isSubmitted(item)) return false;
    final difference = dueAt.difference(_now);
    return !difference.isNegative && difference <= const Duration(days: 2);
  }

  List<StudentAssignmentItem> get _filteredAssignments {
    return _assignments.where((item) {
      return switch (_selectedHomeworkFilter) {
        'ใกล้ครบกำหนด' => _isDueSoon(item),
        'ส่งแล้ว' => _isSubmitted(item),
        'รอดำเนินการ' => !_isSubmitted(item),
        _ => true,
      };
    }).toList();
  }

  StudentScheduleItem? get _nextClass {
    final today = _schedule.where((item) => item.dayOfWeek == _now.weekday);
    final currentMinutes = _now.hour * 60 + _now.minute;
    for (final item
        in today.toList()..sort((a, b) => a.startTime.compareTo(b.startTime))) {
      if (_timeMinutes(item.endTime) >= currentMinutes) return item;
    }
    return null;
  }

  int _timeMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  _ScheduleType _scheduleType(StudentScheduleItem item) {
    if (item.dayOfWeek != _now.weekday) return _ScheduleType.upcoming;
    final minutes = _now.hour * 60 + _now.minute;
    if (minutes > _timeMinutes(item.endTime)) return _ScheduleType.completed;
    if (minutes >= _timeMinutes(item.startTime)) return _ScheduleType.current;
    return _ScheduleType.upcoming;
  }

  Future<void> _selectStudent(String studentId) async {
    if (studentId == _selectedStudent?.studentId) return;
    await _loadData(studentId: studentId);
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
                    title: 'ตารางเรียน / การบ้าน',
                    subtitle:
                        'ติดตามตารางเรียน งานที่ได้รับมอบหมาย และกำหนดส่งของบุตรหลาน',
                    icon: Icons.event_note_rounded,
                    trailing: _buildChildBadge(),
                  ),
                  const SizedBox(height: 18),
                  _buildLoadState(),
                  if (!(_isLoading ||
                      _unauthenticated ||
                      _loadError != null ||
                      _selectedStudent == null)) ...[
                    const SizedBox(height: 16),
                    _buildTodayHero(),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildDaySelector(),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 950) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: _buildScheduleCard()),
                              const SizedBox(width: 14),
                              Expanded(flex: 4, child: _buildNextClassCard()),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildScheduleCard(),
                            const SizedBox(height: 14),
                            _buildNextClassCard(),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildHomeworkFilter(),
                    const SizedBox(height: 12),
                    _buildHomeworkCard(),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 900) {
                          return Column(
                            children: [
                              _buildWeeklyWorkloadCard(),
                              const SizedBox(height: 14),
                              _buildInsightCard(),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _buildWeeklyWorkloadCard(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(flex: 5, child: _buildInsightCard()),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadState() {
    if (_isLoading) {
      return const _StateCard(
        icon: Icons.sync_rounded,
        message: 'กำลังโหลดข้อมูล',
      );
    }
    if (_unauthenticated) {
      return const _StateCard(
        icon: Icons.lock_outline_rounded,
        message: 'กรุณาเข้าสู่ระบบอีกครั้ง',
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
    if (_students.isEmpty) {
      return const _StateCard(
        icon: Icons.person_off_outlined,
        message: 'ยังไม่มีนักเรียนที่เชื่อมกับบัญชีนี้',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildChildBadge() {
    if (_students.length > 1 && _selectedStudent != null) {
      return PopupMenuButton<String>(
        onSelected: _selectStudent,
        itemBuilder: (context) => _students
            .map(
              (student) => PopupMenuItem(
                value: student.studentId,
                child: Text(student.fullName),
              ),
            )
            .toList(),
        child: _ChildBadge(name: _selectedStudent!.fullName),
      );
    }
    return _ChildBadge(name: _selectedStudent?.fullName);
  }

  Widget _buildTodayHero() {
    final next = _nextClass;
    final pending = _assignments.where((item) => !_isSubmitted(item)).length;
    final dueSoon = _assignments.where(_isDueSoon).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D5A95), Color(0xFF2E83C5)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ตารางเรียนวันนี้',
                style: TextStyle(color: Colors.white.withValues(alpha: .75)),
              ),
              const SizedBox(height: 4),
              Text(
                _schedule.isEmpty
                    ? _empty
                    : 'มีเรียนทั้งหมด ${_schedule.where((item) => item.dayOfWeek == _now.weekday).length} คาบ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ScheduleHeroBadge(
                    icon: Icons.assignment_rounded,
                    text: _assignments.isEmpty
                        ? _empty
                        : 'มีงานค้าง $pending งาน',
                  ),
                  _ScheduleHeroBadge(
                    icon: Icons.alarm_rounded,
                    text: _assignments.isEmpty
                        ? _empty
                        : '$dueSoon งานใกล้ครบกำหนด',
                  ),
                ],
              ),
            ],
          );
          final right = Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('คาบถัดไป', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  next?.startTime ?? _empty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (next != null)
                  Text(
                    '${next.subjectName}${next.room == null || next.room!.isEmpty ? '' : ' · ${next.room}'}',
                    style: const TextStyle(color: Colors.white),
                  ),
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
              SizedBox(width: 220, child: right),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    final submitted = _assignments.where(_isSubmitted).length;
    final pending = _assignments.length - submitted;
    final items = [
      _SummaryData(
        title: 'คาบเรียนวันนี้',
        value: _schedule.isEmpty
            ? _empty
            : '${_schedule.where((item) => item.dayOfWeek == _now.weekday).length}',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF2E83C5),
      ),
      _SummaryData(
        title: 'งานทั้งหมด',
        value: _assignments.isEmpty ? _empty : '${_assignments.length}',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF8A65C7),
      ),
      _SummaryData(
        title: 'รอดำเนินการ',
        value: _assignments.isEmpty ? _empty : '$pending งาน',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFF09A37),
      ),
      _SummaryData(
        title: 'ส่งแล้ว',
        value: _assignments.isEmpty ? _empty : '$submitted งาน',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF18A06F),
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
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _SummaryTile(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildDaySelector() {
    return ParentCard(
      padding: const EdgeInsets.all(13),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: ['วันนี้', 'พรุ่งนี้', 'สัปดาห์นี้']
            .map(
              (day) => ChoiceChip(
                label: Text(day),
                selected: _selectedDay == day,
                onSelected: (_) => setState(() => _selectedDay = day),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.schedule_rounded,
            title: 'ตารางเรียน',
            subtitle: 'รายวิชา เวลา ห้องเรียน และสถานะของแต่ละคาบ',
          ),
          const SizedBox(height: 14),
          if (_visibleSchedule.isEmpty)
            const _EmptyState()
          else
            ..._visibleSchedule.map(
              (item) => _ScheduleRow(item: item, type: _scheduleType(item)),
            ),
        ],
      ),
    );
  }

  Widget _buildNextClassCard() {
    final next = _nextClass;
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.next_plan_rounded,
            title: 'คาบถัดไป',
            subtitle: 'รายวิชาที่กำลังจะเริ่ม',
          ),
          const SizedBox(height: 14),
          if (next == null)
            const _EmptyState()
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${next.startTime}–${next.endTime}',
                    style: const TextStyle(
                      color: Color(0xFF2867B2),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    next.subjectName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    next.room == null || next.room!.isEmpty
                        ? 'ไม่ระบุห้องเรียน'
                        : next.room!,
                    style: const TextStyle(color: Color(0xFF7D8798)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeworkFilter() {
    return ParentCard(
      padding: const EdgeInsets.all(13),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: ['ทั้งหมด', 'ใกล้ครบกำหนด', 'ส่งแล้ว', 'รอดำเนินการ']
            .map(
              (filter) => ChoiceChip(
                label: Text(filter),
                selected: _selectedHomeworkFilter == filter,
                onSelected: (_) =>
                    setState(() => _selectedHomeworkFilter = filter),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHomeworkCard() {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.assignment_rounded,
            title: 'งานและการบ้าน',
            subtitle: 'งานที่ได้รับมอบหมายและกำหนดส่งจากระบบ',
          ),
          const SizedBox(height: 14),
          if (_filteredAssignments.isEmpty)
            const _EmptyState()
          else
            ..._filteredAssignments.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AssignmentTile(item: item, dueSoon: _isDueSoon(item)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyWorkloadCard() {
    final counts = <int, int>{};
    for (final item in _assignments) {
      if (item.dueAt != null) {
        counts[item.dueAt!.weekday] = (counts[item.dueAt!.weekday] ?? 0) + 1;
      }
    }
    const names = {
      1: 'จันทร์',
      2: 'อังคาร',
      3: 'พุธ',
      4: 'พฤหัสบดี',
      5: 'ศุกร์',
    };
    final maxCount = counts.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.bar_chart_rounded,
            title: 'ภาระงานรายสัปดาห์',
            subtitle: 'จำนวนงานตามวันครบกำหนด',
          ),
          const SizedBox(height: 15),
          if (counts.isEmpty)
            const _EmptyState()
          else
            ...names.entries.map((day) {
              final count = counts[day.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    SizedBox(width: 65, child: Text(day.value)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: count / maxCount,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDF0F5),
                        color: const Color(0xFF2E83C5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 45, child: Text('$count งาน')),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    final dueSoon = _assignments.where(_isDueSoon).length;
    final pending = _assignments.where((item) => !_isSubmitted(item)).length;
    final submitted = _assignments.where(_isSubmitted).length;
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'ข้อมูลที่ควรติดตาม',
            subtitle: 'สรุปจากสถานะงานจริงของนักเรียน',
          ),
          const SizedBox(height: 14),
          if (_assignments.isEmpty)
            const _EmptyState()
          else ...[
            _InsightItem(
              icon: Icons.warning_amber_rounded,
              title: '$dueSoon งานใกล้ครบกำหนด',
              color: const Color(0xFFF09A37),
            ),
            const SizedBox(height: 10),
            _InsightItem(
              icon: Icons.pending_actions_rounded,
              title: '$pending งานรอดำเนินการ',
              color: const Color(0xFF8A65C7),
            ),
            const SizedBox(height: 10),
            _InsightItem(
              icon: Icons.task_alt_rounded,
              title: '$submitted งานส่งแล้ว',
              color: const Color(0xFF18A06F),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChildBadge extends StatelessWidget {
  final String? name;
  const _ChildBadge({this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE1E6EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_rounded, color: Color(0xFF2867B2), size: 18),
          const SizedBox(width: 7),
          Text(
            name == null || name!.isEmpty ? 'ยังไม่เลือกนักเรียน' : name!,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const _StateCard({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return ParentCard(
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          'ยังไม่มีข้อมูล',
          style: TextStyle(color: Color(0xFF8A94A5)),
        ),
      ),
    );
  }
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
          child: Icon(icon, size: 17, color: const Color(0xFF2867B2)),
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
                style: const TextStyle(fontSize: 8.3, color: Color(0xFF8993A4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleHeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ScheduleHeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryTile extends StatelessWidget {
  final _SummaryData data;
  const _SummaryTile({required this.data});

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
              color: data.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(color: Color(0xFF7F899A)),
                ),
                Text(
                  data.value,
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
}

enum _ScheduleType { completed, current, upcoming }

class _ScheduleRow extends StatelessWidget {
  final StudentScheduleItem item;
  final _ScheduleType type;
  const _ScheduleRow({required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      _ScheduleType.completed => const Color(0xFF18A06F),
      _ScheduleType.current => const Color(0xFFF09A37),
      _ScheduleType.upcoming => const Color(0xFF2E83C5),
    };
    final status = switch (type) {
      _ScheduleType.completed => 'เรียนแล้ว',
      _ScheduleType.current => 'กำลังเรียน',
      _ScheduleType.upcoming => 'รอเรียน',
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDF0F4))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text('${item.startTime}\n${item.endTime}'),
          ),
          Container(width: 4, height: 39, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  item.room == null || item.room!.isEmpty
                      ? 'ไม่ระบุห้องเรียน'
                      : item.room!,
                  style: const TextStyle(color: Color(0xFF8993A4)),
                ),
              ],
            ),
          ),
          _StatusBadge(text: status, color: color),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final StudentAssignmentItem item;
  final bool dueSoon;
  const _AssignmentTile({required this.item, required this.dueSoon});

  @override
  Widget build(BuildContext context) {
    final submitted = const {
      'submitted',
      'graded',
      'returned',
    }.contains(item.status);
    final color = submitted
        ? const Color(0xFF18A06F)
        : dueSoon
        ? const Color(0xFFF09A37)
        : const Color(0xFF8A65C7);
    final status = submitted
        ? 'ส่งแล้ว'
        : dueSoon
        ? 'ใกล้ครบกำหนด'
        : 'รอดำเนินการ';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE9ECF1)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.courseName,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  item.dueAt == null
                      ? 'ไม่ระบุกำหนดส่ง'
                      : 'กำหนด ${_formatDateTime(item.dueAt!)}',
                  style: const TextStyle(color: Color(0xFF8993A4)),
                ),
              ],
            ),
          ),
          _StatusBadge(text: status, color: color),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _InsightItem({
    required this.icon,
    required this.title,
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
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
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
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} ${local.year + 543} $hour:$minute น.';
}
