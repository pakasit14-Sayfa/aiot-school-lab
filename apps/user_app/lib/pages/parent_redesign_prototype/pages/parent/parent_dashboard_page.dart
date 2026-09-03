import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/parent_common_widgets.dart';
import 'leave_request_dialog.dart';

typedef ParentDashboardStudentsLoader =
    Future<List<LinkedStudentItem>> Function();
typedef ParentDashboardGradesLoader =
    Future<List<StudentGradeItem>> Function(String studentId);
typedef ParentDashboardAssignmentsLoader =
    Future<List<StudentAssignmentItem>> Function(String studentId);
typedef ParentDashboardAttendanceLoader =
    Future<List<StudentAttendanceItem>> Function(String studentId);
typedef ParentDashboardScheduleLoader =
    Future<List<StudentScheduleItem>> Function(String studentId);
typedef ParentDashboardSensorsLoader =
    Future<List<Map<String, dynamic>>> Function();
typedef ParentDashboardEventsLoader = Future<List<SchoolEventItem>> Function();

class ParentDashboardPage extends StatefulWidget {
  final ParentDashboardStudentsLoader? studentsLoader;
  final ParentDashboardGradesLoader? gradesLoader;
  final ParentDashboardAssignmentsLoader? assignmentsLoader;
  final ParentDashboardAttendanceLoader? attendanceLoader;
  final ParentDashboardScheduleLoader? scheduleLoader;
  final ParentDashboardSensorsLoader? sensorsLoader;
  final ParentDashboardEventsLoader? eventsLoader;
  final DateTime Function()? now;

  const ParentDashboardPage({
    super.key,
    this.studentsLoader,
    this.gradesLoader,
    this.assignmentsLoader,
    this.attendanceLoader,
    this.scheduleLoader,
    this.sensorsLoader,
    this.eventsLoader,
    this.now,
  });

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  static const _empty = 'ยังไม่มีข้อมูล';
  static const _bg = Color(0xFFF5F7FB);

  List<LinkedStudentItem> _students = const [];
  LinkedStudentItem? _selectedStudent;
  List<StudentGradeItem> _grades = const [];
  List<StudentAssignmentItem> _assignments = const [];
  List<StudentAttendanceItem> _attendance = const [];
  List<StudentScheduleItem> _schedule = const [];
  List<Map<String, dynamic>> _sensors = const [];
  List<SchoolEventItem> _events = const [];
  bool _loading = true;
  bool _unauthenticated = false;
  Object? _loadError;
  Object? _sensorError;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? studentId}) async {
    setState(() {
      _loading = true;
      _unauthenticated = false;
      _loadError = null;
      _sensorError = null;
    });
    if (widget.studentsLoader == null && AuthService.sessionToken == null) {
      setState(() {
        _loading = false;
        _unauthenticated = true;
      });
      return;
    }
    try {
      final students =
          await (widget.studentsLoader ??
              ParentPortalService.listMyLinkedStudents)();
      if (!mounted) return;
      if (students.isEmpty) {
        setState(() {
          _students = const [];
          _selectedStudent = null;
          _clearData();
          _loading = false;
        });
        return;
      }
      final selected = students.firstWhere(
        (student) => student.studentId == studentId,
        orElse: () => students.first,
      );
      final core = await Future.wait<Object>([
        (widget.gradesLoader ?? ParentPortalService.listMyStudentGrades)(
          selected.studentId,
        ),
        (widget.assignmentsLoader ??
            ParentPortalService.listMyStudentAssignmentItems)(
          selected.studentId,
        ),
        (widget.attendanceLoader ??
            ParentPortalService.listMyStudentAttendance)(selected.studentId),
        (widget.scheduleLoader ?? ParentPortalService.listMyStudentSchedule)(
          selected.studentId,
        ),
        (widget.eventsLoader ?? ParentPortalService.listSchoolEvents)(),
      ]);
      List<Map<String, dynamic>> sensors = const [];
      Object? sensorError;
      try {
        sensors =
            await (widget.sensorsLoader ??
                AiotLabService.getLatestSensorReadings)();
      } catch (error) {
        sensorError = error;
      }
      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedStudent = selected;
        _grades = core[0] as List<StudentGradeItem>;
        _assignments = core[1] as List<StudentAssignmentItem>;
        _attendance = core[2] as List<StudentAttendanceItem>;
        _schedule = core[3] as List<StudentScheduleItem>;
        _events = core[4] as List<SchoolEventItem>;
        _sensors = sensors;
        _sensorError = sensorError;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ParentDashboardPage load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _clearData();
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _clearData() {
    _grades = const [];
    _assignments = const [];
    _attendance = const [];
    _schedule = const [];
    _sensors = const [];
    _events = const [];
  }

  bool _isSubmitted(StudentAssignmentItem item) =>
      const {'submitted', 'graded', 'returned'}.contains(item.status);

  double? get _attendanceRate {
    if (_attendance.isEmpty) return null;
    final present = _attendance
        .where((item) => item.isPresent || item.isLate)
        .length;
    return present / _attendance.length;
  }

  double? get _averageScore {
    final score = _grades.fold<num>(0, (sum, item) => sum + item.score);
    final max = _grades.fold<num>(0, (sum, item) => sum + item.maxScore);
    return max == 0 ? null : score / max * 100;
  }

  List<StudentAttendanceItem> get _todayAttendance =>
      _attendance.where((item) => _sameDay(item.classDate, _now)).toList()
        ..sort((a, b) => a.markedAt.compareTo(b.markedAt));

  List<StudentScheduleItem> get _todaySchedule =>
      _schedule.where((item) => item.dayOfWeek == _now.weekday).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  StudentScheduleItem? get _currentClass {
    final minutes = _now.hour * 60 + _now.minute;
    for (final item in _todaySchedule) {
      if (minutes >= _timeMinutes(item.startTime) &&
          minutes <= _timeMinutes(item.endTime)) {
        return item;
      }
    }
    return null;
  }

  String _sensorValue(String metric, {int fractionDigits = 0}) {
    for (final reading in _sensors) {
      if (reading['metric'] == metric && reading['value'] is num) {
        return (reading['value'] as num).toStringAsFixed(fractionDigits);
      }
    }
    return _empty;
  }

  int _timeMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  Future<void> _selectStudent(String studentId) async {
    if (studentId != _selectedStudent?.studentId) {
      await _loadData(studentId: studentId);
    }
  }

  void _openLeaveForm() {
    showDialog<void>(
      context: context,
      builder: (context) => LeaveRequestFormDialog(
        studentId: _selectedStudent?.studentId,
        onSubmitted: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _assignments.where((item) => !_isSubmitted(item)).length;
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
                    title: 'ภาพรวมผู้ปกครอง',
                    subtitle: 'ติดตามข้อมูลสำคัญของบุตรหลานจากระบบในหน้าเดียว',
                    icon: Icons.dashboard_rounded,
                    trailing: _childBadge(),
                  ),
                  const SizedBox(height: 18),
                  _loadState(),
                  const SizedBox(height: 16),
                  _hero(),
                  const SizedBox(height: 16),
                  _quickActions(),
                  const SizedBox(height: 16),
                  _metrics(pending),
                  const SizedBox(height: 16),
                  _environmentCard(),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [_todayStatusCard(), _attendanceCard()];
                      if (constraints.maxWidth < 760) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 14),
                            cards[1],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(flex: 4, child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [_learningCard(), _scheduleCard()];
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 14),
                            cards[1],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [_homeworkCard(), _eventsCard()];
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 14),
                            cards[1],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _schoolMessagesCard(),
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
    if (_students.isEmpty) {
      return const _StateCard(
        icon: Icons.person_off_outlined,
        message: 'ยังไม่มีนักเรียนที่เชื่อมกับบัญชีนี้',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _childBadge() {
    final badge = _ChildBadge(name: _selectedStudent?.fullName);
    if (_students.length < 2 || _selectedStudent == null) return badge;
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
      child: badge,
    );
  }

  Widget _hero() {
    final current = _currentClass;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173B69), Color(0xFF2E83C5)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลของ ${_selectedStudent?.fullName ?? _empty}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            current == null ? _empty : 'กำลังเรียน ${current.subjectName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            current == null
                ? _empty
                : '${current.startTime}–${current.endTime}${current.room == null ? '' : ' · ${current.room}'}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() => ParentCard(
    padding: const EdgeInsets.all(14),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: _selectedStudent == null ? null : _openLeaveForm,
          icon: const Icon(Icons.event_busy_rounded),
          label: const Text('แจ้งลา'),
        ),
        OutlinedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('รีเฟรชข้อมูล'),
        ),
      ],
    ),
  );

  Widget _metrics(int pending) {
    final todayTime = _todayAttendance.isEmpty
        ? _empty
        : _formatTime(_todayAttendance.first.markedAt);
    final cards = [
      _MetricData(
        'มาเรียนวันนี้',
        todayTime,
        Icons.login_rounded,
        const Color(0xFF18A06F),
      ),
      _MetricData(
        'อัตรามาเรียน',
        _attendanceRate == null
            ? _empty
            : '${(_attendanceRate! * 100).round()}%',
        Icons.fact_check_rounded,
        const Color(0xFF2E83C5),
      ),
      _MetricData(
        'งานที่ต้องทำ',
        _assignments.isEmpty ? _empty : '$pending งาน',
        Icons.assignment_rounded,
        const Color(0xFF8A65C7),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _MetricCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _environmentCard() {
    final metrics = [
      ('อุณหภูมิ', _sensorValue('temperature', fractionDigits: 1), '°C'),
      ('PM2.5', _sensorValue('pm25'), 'µg/m³'),
      ('แสง', _sensorValue('light_lux'), 'lux'),
      ('AQI', _sensorValue('aqi'), ''),
    ];
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.sensors_rounded,
            title: 'สภาพแวดล้อมโรงเรียน',
            subtitle: 'ค่าล่าสุดจากเซนเซอร์ของโรงเรียน',
          ),
          const SizedBox(height: 14),
          if (_sensorError != null)
            const Text('ไม่สามารถโหลดข้อมูลเซนเซอร์ได้')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metrics
                  .map(
                    (item) => SizedBox(
                      width: 190,
                      child: _LabelValue(
                        label: item.$1,
                        value: item.$2 == _empty
                            ? _empty
                            : '${item.$2} ${item.$3}'.trim(),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _todayStatusCard() {
    final rows = <Widget>[];
    rows.addAll(
      _todayAttendance.map(
        (item) => _TimelineRow(
          time: _formatTime(item.markedAt),
          title: item.courseName,
          detail: _attendanceStatus(item.status),
          icon: Icons.fact_check_rounded,
        ),
      ),
    );
    rows.addAll(
      _todaySchedule.map(
        (item) => _TimelineRow(
          time: item.startTime,
          title: item.subjectName,
          detail: item.room == null || item.room!.isEmpty
              ? 'ไม่ระบุห้องเรียน'
              : item.room!,
          icon: Icons.menu_book_rounded,
        ),
      ),
    );
    return _ContentCard(
      icon: Icons.timeline_rounded,
      title: 'สถานะของลูกวันนี้',
      subtitle: 'การเข้าเรียนและตารางเรียนวันนี้',
      empty: rows.isEmpty,
      children: rows,
    );
  }

  Widget _attendanceCard() {
    final present = _attendance.where((item) => item.isPresent).length;
    final late = _attendance.where((item) => item.isLate).length;
    final excused = _attendance.where((item) => item.isExcused).length;
    return _ContentCard(
      icon: Icons.fact_check_rounded,
      title: 'สรุปการมาเรียน',
      subtitle: 'ข้อมูลที่บันทึกในระบบ',
      empty: _attendance.isEmpty,
      children: [
        Text(
          '${((_attendanceRate ?? 0) * 100).round()}%',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _LabelValue(label: 'มาเรียน', value: '$present'),
            _LabelValue(label: 'สาย', value: '$late'),
            _LabelValue(label: 'ลา', value: '$excused'),
          ],
        ),
      ],
    );
  }

  Widget _learningCard() {
    final bySubject = <String, List<StudentGradeItem>>{};
    for (final grade in _grades) {
      bySubject.putIfAbsent(grade.subjectName, () => []).add(grade);
    }
    return _ContentCard(
      icon: Icons.analytics_rounded,
      title: 'ภาพรวมผลการเรียน',
      subtitle: 'คะแนนที่ยืนยันแล้วในระบบ',
      empty: _grades.isEmpty,
      children: [
        _LabelValue(
          label: 'คะแนนเฉลี่ย',
          value: '${(_averageScore ?? 0).round()}%',
        ),
        const SizedBox(height: 12),
        ...bySubject.entries.map((entry) {
          final score = entry.value.fold<num>(
            0,
            (sum, item) => sum + item.score,
          );
          final max = entry.value.fold<num>(
            0,
            (sum, item) => sum + item.maxScore,
          );
          return _TimelineRow(
            time: max == 0 ? _empty : '${(score / max * 100).round()}%',
            title: entry.key,
            detail: '${entry.value.length} รายการคะแนน',
            icon: Icons.bar_chart_rounded,
          );
        }),
      ],
    );
  }

  Widget _scheduleCard() => _ContentCard(
    icon: Icons.schedule_rounded,
    title: 'ตารางเรียนวันนี้',
    subtitle: _formatDate(_now),
    empty: _todaySchedule.isEmpty,
    children: _todaySchedule
        .map(
          (item) => _TimelineRow(
            time: item.startTime,
            title: item.subjectName,
            detail: item.room == null || item.room!.isEmpty
                ? 'ไม่ระบุห้องเรียน'
                : item.room!,
            icon: Icons.menu_book_rounded,
          ),
        )
        .toList(),
  );

  Widget _homeworkCard() => _ContentCard(
    icon: Icons.assignment_rounded,
    title: 'ภาระงานและการบ้าน',
    subtitle: 'สถานะและกำหนดส่งจากระบบ',
    empty: _assignments.isEmpty,
    children: _assignments
        .map(
          (item) => _TimelineRow(
            time: item.dueAt == null ? 'ไม่ระบุ' : _formatDate(item.dueAt!),
            title: item.title,
            detail:
                '${item.courseName} · ${_isSubmitted(item) ? 'ส่งแล้ว' : 'รอดำเนินการ'}',
            icon: Icons.assignment_rounded,
          ),
        )
        .toList(),
  );

  Widget _eventsCard() {
    final upcoming = _events
        .where(
          (event) => !event.startDate.isBefore(
            DateTime(_now.year, _now.month, _now.day),
          ),
        )
        .take(5)
        .toList();
    return _ContentCard(
      icon: Icons.event_rounded,
      title: 'กิจกรรมที่กำลังจะถึง',
      subtitle: 'กำหนดการจากโรงเรียน',
      empty: upcoming.isEmpty,
      children: upcoming
          .map(
            (event) => _TimelineRow(
              time: _formatDate(event.startDate),
              title: event.title,
              detail: event.location ?? 'ไม่ระบุสถานที่',
              icon: Icons.event_available_rounded,
            ),
          )
          .toList(),
    );
  }

  Widget _schoolMessagesCard() => const _ContentCard(
    icon: Icons.chat_bubble_rounded,
    title: 'ข้อความจากโรงเรียน',
    subtitle: 'ยังไม่มีแหล่งข้อมูลประกาศสำหรับหน้านี้',
    empty: true,
    children: [],
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

class _ChildBadge extends StatelessWidget {
  final String? name;
  const _ChildBadge({this.name});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE1E6EE)),
    ),
    child: Text(
      name == null || name!.isEmpty ? 'ยังไม่เลือกนักเรียน' : name!,
      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool empty;
  final List<Widget> children;
  const _ContentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        if (empty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                'ยังไม่มีข้อมูล',
                style: TextStyle(color: Color(0xFF8A94A5)),
              ),
            ),
          )
        else
          ...children,
      ],
    ),
  );
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricData(this.title, this.value, this.icon, this.color);
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  const _MetricCard({required this.data});
  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Icon(data.icon, color: data.color, size: 27),
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
                  fontSize: 17,
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

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Color(0xFF8993A4))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class _TimelineRow extends StatelessWidget {
  final String time;
  final String title;
  final String detail;
  final IconData icon;
  const _TimelineRow({
    required this.time,
    required this.title,
    required this.detail,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(time, style: const TextStyle(color: Color(0xFF8993A4))),
        ),
        Icon(icon, color: const Color(0xFF2E83C5), size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(detail, style: const TextStyle(color: Color(0xFF8993A4))),
            ],
          ),
        ),
      ],
    ),
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _attendanceStatus(String value) => switch (value) {
  'present' => 'มาเรียน',
  'late' => 'มาสาย',
  'absent' => 'ขาดเรียน',
  'excused' => 'ลา',
  _ => value,
};

String _formatTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} น.';
}

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
