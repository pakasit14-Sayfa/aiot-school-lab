import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/parent_common_widgets.dart';

typedef ParentLearningStudentsLoader =
    Future<List<LinkedStudentItem>> Function();
typedef ParentGradesLoader =
    Future<List<StudentGradeItem>> Function(String studentId);
typedef ParentLearningAttendanceLoader =
    Future<List<StudentAttendanceItem>> Function(String studentId);
typedef ParentLearningAssignmentsLoader =
    Future<List<StudentAssignmentItem>> Function(String studentId);

class ParentLearningPage extends StatefulWidget {
  final ParentLearningStudentsLoader? studentsLoader;
  final ParentGradesLoader? gradesLoader;
  final ParentLearningAttendanceLoader? attendanceLoader;
  final ParentLearningAssignmentsLoader? assignmentsLoader;
  final DateTime Function()? now;

  const ParentLearningPage({
    super.key,
    this.studentsLoader,
    this.gradesLoader,
    this.attendanceLoader,
    this.assignmentsLoader,
    this.now,
  });

  @override
  State<ParentLearningPage> createState() => _ParentLearningPageState();
}

class _ParentLearningPageState extends State<ParentLearningPage> {
  static const _empty = 'ยังไม่มีข้อมูล';
  static const _bg = Color(0xFFF5F7FB);
  static const _colors = [
    Color(0xFF2E83C5),
    Color(0xFF18A06F),
    Color(0xFF8A65C7),
    Color(0xFFF09A37),
  ];

  String _selectedPeriod = 'เทอมนี้';
  String _selectedSubject = 'ทุกวิชา';
  List<LinkedStudentItem> _students = const [];
  LinkedStudentItem? _selectedStudent;
  List<StudentGradeItem> _grades = const [];
  List<StudentAttendanceItem> _attendance = const [];
  List<StudentAssignmentItem> _assignments = const [];
  bool _isLoading = true;
  bool _unauthenticated = false;
  Object? _loadError;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? studentId}) async {
    setState(() {
      _isLoading = true;
      _unauthenticated = false;
      _loadError = null;
    });
    if (widget.studentsLoader == null && AuthService.sessionToken == null) {
      setState(() {
        _isLoading = false;
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
          _grades = const [];
          _attendance = const [];
          _assignments = const [];
          _isLoading = false;
        });
        return;
      }
      final selected = students.firstWhere(
        (student) => student.studentId == studentId,
        orElse: () => students.first,
      );
      final result = await Future.wait<Object>([
        (widget.gradesLoader ?? ParentPortalService.listMyStudentGrades)(
          selected.studentId,
        ),
        (widget.attendanceLoader ??
            ParentPortalService.listMyStudentAttendance)(selected.studentId),
        (widget.assignmentsLoader ??
            ParentPortalService.listMyStudentAssignmentItems)(
          selected.studentId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedStudent = selected;
        _grades = result[0] as List<StudentGradeItem>;
        _attendance = result[1] as List<StudentAttendanceItem>;
        _assignments = result[2] as List<StudentAssignmentItem>;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ParentLearningPage load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _grades = const [];
        _attendance = const [];
        _assignments = const [];
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  DateTime? get _cutoff => switch (_selectedPeriod) {
    'สัปดาห์นี้' => _now.subtract(const Duration(days: 7)),
    'เดือนนี้' => DateTime(_now.year, _now.month, 1),
    _ => null,
  };

  List<StudentGradeItem> get _periodGrades => _grades.where((item) {
    if (_cutoff == null) return true;
    return item.confirmedAt != null && !item.confirmedAt!.isBefore(_cutoff!);
  }).toList();

  List<StudentAttendanceItem> get _periodAttendance =>
      _attendance.where((item) {
        return _cutoff == null || !item.classDate.isBefore(_cutoff!);
      }).toList();

  List<StudentAssignmentItem> get _periodAssignments =>
      _assignments.where((item) {
        if (_cutoff == null) return true;
        return item.dueAt != null && !item.dueAt!.isBefore(_cutoff!);
      }).toList();

  List<String> get _subjects {
    final values = <String>{
      ..._periodGrades.map((item) => item.subjectName),
      ..._periodAttendance.map((item) => item.courseName),
      ..._periodAssignments.map((item) => item.courseName),
    }..removeWhere((value) => value.trim().isEmpty);
    final result = values.toList()..sort();
    return ['ทุกวิชา', ...result];
  }

  List<_SubjectSummary> get _subjectSummaries {
    final subjects = _subjects
        .skip(1)
        .where(
          (subject) =>
              _selectedSubject == 'ทุกวิชา' || subject == _selectedSubject,
        );
    return subjects.toList().asMap().entries.map((entry) {
      final subject = entry.value;
      final grades = _periodGrades.where((item) => item.subjectName == subject);
      final attendance = _periodAttendance
          .where((item) => item.courseName == subject)
          .toList();
      final assignments = _periodAssignments
          .where((item) => item.courseName == subject)
          .toList();
      final score = grades.fold<num>(0, (sum, item) => sum + item.score);
      final maxScore = grades.fold<num>(0, (sum, item) => sum + item.maxScore);
      final present = attendance
          .where((item) => item.isPresent || item.isLate)
          .length;
      final submitted = assignments.where(_isSubmitted).length;
      return _SubjectSummary(
        subject: subject,
        scorePercent: maxScore > 0 ? score / maxScore * 100 : null,
        attendancePercent: attendance.isEmpty
            ? null
            : present / attendance.length * 100,
        submitted: assignments.isEmpty ? null : submitted,
        totalAssignments: assignments.isEmpty ? null : assignments.length,
        pending: assignments.isEmpty ? null : assignments.length - submitted,
        color: _colors[entry.key % _colors.length],
      );
    }).toList();
  }

  bool _isSubmitted(StudentAssignmentItem item) {
    return const {'submitted', 'graded', 'returned'}.contains(item.status);
  }

  double? get _averageScore {
    final score = _periodGrades.fold<num>(0, (sum, item) => sum + item.score);
    final max = _periodGrades.fold<num>(0, (sum, item) => sum + item.maxScore);
    return max > 0 ? score / max * 100 : null;
  }

  double? get _attendanceRate {
    if (_periodAttendance.isEmpty) return null;
    final present = _periodAttendance
        .where((item) => item.isPresent || item.isLate)
        .length;
    return present / _periodAttendance.length * 100;
  }

  List<StudentAssignmentItem> get _visibleAssignments => _periodAssignments
      .where(
        (item) =>
            _selectedSubject == 'ทุกวิชา' ||
            item.courseName == _selectedSubject,
      )
      .toList();

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
                    title: 'การเรียนของลูก',
                    subtitle:
                        'ติดตามการเข้าเรียน การส่งงาน และคะแนนจากข้อมูลจริง',
                    icon: Icons.menu_book_rounded,
                    trailing: _childBadge(),
                  ),
                  const SizedBox(height: 18),
                  _loadState(),
                  const SizedBox(height: 16),
                  _filterBar(),
                  const SizedBox(height: 16),
                  _summaryCards(),
                  const SizedBox(height: 16),
                  _overviewCards(),
                  const SizedBox(height: 16),
                  _subjectPerformance(),
                  const SizedBox(height: 16),
                  _assignmentTracking(),
                  const SizedBox(height: 16),
                  _activityAndInsight(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadState() {
    if (_isLoading) {
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

  Widget _filterBar() {
    final subjects = _subjects;
    if (!subjects.contains(_selectedSubject)) _selectedSubject = 'ทุกวิชา';
    return ParentCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('ช่วงข้อมูล'),
          ...['สัปดาห์นี้', 'เดือนนี้', 'เทอมนี้'].map(
            (period) => ChoiceChip(
              label: Text(period),
              selected: _selectedPeriod == period,
              onSelected: (_) => setState(() {
                _selectedPeriod = period;
                _selectedSubject = 'ทุกวิชา';
              }),
            ),
          ),
          const Text('รายวิชา'),
          DropdownButton<String>(
            value: _selectedSubject,
            items: subjects
                .map(
                  (subject) =>
                      DropdownMenuItem(value: subject, child: Text(subject)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedSubject = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryCards() {
    final assignments = _periodAssignments;
    final submitted = assignments.where(_isSubmitted).length;
    final pending = assignments.length - submitted;
    final cards = [
      _MetricData(
        title: 'เข้าเรียน',
        value: _percent(_attendanceRate),
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF18A06F),
      ),
      _MetricData(
        title: 'ส่งงาน',
        value: assignments.isEmpty
            ? _empty
            : '$submitted/${assignments.length}',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF2E83C5),
      ),
      _MetricData(
        title: 'งานค้าง',
        value: assignments.isEmpty ? _empty : '$pending งาน',
        icon: Icons.assignment_late_rounded,
        color: const Color(0xFFDB5962),
      ),
      _MetricData(
        title: 'คะแนนเฉลี่ย',
        value: _percent(_averageScore),
        icon: Icons.analytics_rounded,
        color: const Color(0xFF8A65C7),
      ),
      const _MetricData(
        title: 'GPA ล่าสุด',
        value: _empty,
        icon: Icons.star_rounded,
        color: Color(0xFFF09A37),
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
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  child: _MetricCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _overviewCards() {
    final assignments = _periodAssignments;
    final submitted = assignments.where(_isSubmitted).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _OverviewCard(
            title: 'การเข้าเรียน',
            icon: Icons.fact_check_rounded,
            value: _percent(_attendanceRate),
            detail: _periodAttendance.isEmpty
                ? _empty
                : '${_periodAttendance.length} คาบที่บันทึกแล้ว',
          ),
          _OverviewCard(
            title: 'การส่งงาน',
            icon: Icons.assignment_rounded,
            value: assignments.isEmpty
                ? _empty
                : '$submitted/${assignments.length}',
            detail: assignments.isEmpty
                ? _empty
                : '${assignments.length - submitted} งานรอดำเนินการ',
          ),
          _OverviewCard(
            title: 'ผลการเรียน',
            icon: Icons.insights_rounded,
            value: _percent(_averageScore),
            detail: _periodGrades.isEmpty
                ? _empty
                : '${_periodGrades.length} รายการคะแนน',
          ),
        ];
        if (constraints.maxWidth < 960) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: card,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _subjectPerformance() {
    final data = _subjectSummaries;
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.bar_chart_rounded,
            title: 'ผลการเรียนรายวิชา',
            subtitle: 'คะแนน การเข้าเรียน และงานจากข้อมูลที่บันทึกในระบบ',
          ),
          const SizedBox(height: 15),
          if (data.isEmpty)
            const _EmptyState()
          else
            ...data.map((item) => _SubjectRow(item: item)),
        ],
      ),
    );
  }

  Widget _assignmentTracking() {
    final items = _visibleAssignments;
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.assignment_rounded,
            title: 'ติดตามงานและการบ้าน',
            subtitle: 'สถานะและกำหนดส่งจากระบบ',
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _EmptyState()
          else
            ...items.map((item) => _AssignmentRow(item: item)),
        ],
      ),
    );
  }

  Widget _activityAndInsight() {
    final activities = <_Activity>[];
    for (final grade in _periodGrades) {
      activities.add(
        _Activity(
          date: grade.confirmedAt,
          title: 'บันทึกคะแนน ${grade.subjectName}',
          detail: '${grade.score}/${grade.maxScore}',
        ),
      );
    }
    for (final record in _periodAttendance) {
      activities.add(
        _Activity(
          date: record.classDate,
          title: 'บันทึกการเข้าเรียน ${record.courseName}',
          detail: _attendanceStatus(record.status),
        ),
      );
    }
    activities.sort(
      (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
    );
    final pending = _periodAssignments
        .where((item) => !_isSubmitted(item))
        .length;
    final absent = _periodAttendance.where((item) => item.isAbsent).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final recent = ParentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.history_rounded,
                title: 'กิจกรรมล่าสุด',
                subtitle: 'รายการคะแนนและการเข้าเรียนล่าสุด',
              ),
              const SizedBox(height: 14),
              if (activities.isEmpty)
                const _EmptyState()
              else
                ...activities
                    .take(5)
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title),
                        subtitle: Text(item.detail),
                        trailing: Text(
                          item.date == null ? '' : _formatDate(item.date!),
                        ),
                      ),
                    ),
            ],
          ),
        );
        final insight = ParentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.auto_awesome_rounded,
                title: 'ข้อมูลที่ควรติดตาม',
                subtitle: 'สรุปจากข้อมูลจริงในช่วงที่เลือก',
              ),
              const SizedBox(height: 14),
              if (_periodAssignments.isEmpty && _periodAttendance.isEmpty)
                const _EmptyState()
              else ...[
                _InsightRow(text: '$pending งานรอดำเนินการ'),
                const SizedBox(height: 10),
                _InsightRow(text: '$absent คาบที่ขาดเรียน'),
              ],
            ],
          ),
        );
        if (constraints.maxWidth < 900) {
          return Column(
            children: [recent, const SizedBox(height: 14), insight],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: recent),
            const SizedBox(width: 14),
            Expanded(flex: 5, child: insight),
          ],
        );
      },
    );
  }
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
        child: Icon(icon, size: 17, color: const Color(0xFF2867B2)),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  const _MetricCard({required this.data});
  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Icon(data.icon, color: data.color, size: 26),
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

class _OverviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String detail;
  const _OverviewCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.detail,
  });
  @override
  Widget build(BuildContext context) => ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: icon,
          title: title,
          subtitle: 'ข้อมูลในช่วงที่เลือก',
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(color: Color(0xFF7F899A))),
      ],
    ),
  );
}

class _SubjectSummary {
  final String subject;
  final double? scorePercent;
  final double? attendancePercent;
  final int? submitted;
  final int? totalAssignments;
  final int? pending;
  final Color color;
  const _SubjectSummary({
    required this.subject,
    this.scorePercent,
    this.attendancePercent,
    this.submitted,
    this.totalAssignments,
    this.pending,
    required this.color,
  });
}

class _SubjectRow extends StatelessWidget {
  final _SubjectSummary item;
  const _SubjectRow({required this.item});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFEDF0F4))),
    ),
    child: Wrap(
      spacing: 18,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: Row(
            children: [
              Container(width: 8, height: 34, color: item.color),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item.subject,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        _LabelValue(label: 'คะแนน', value: _percent(item.scorePercent)),
        _LabelValue(
          label: 'เข้าเรียน',
          value: _percent(item.attendancePercent),
        ),
        _LabelValue(
          label: 'ส่งงาน',
          value: item.totalAssignments == null
              ? 'ยังไม่มีข้อมูล'
              : '${item.submitted}/${item.totalAssignments}',
        ),
        _LabelValue(
          label: 'งานค้าง',
          value: item.pending == null ? 'ยังไม่มีข้อมูล' : '${item.pending}',
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
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8993A4))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _AssignmentRow extends StatelessWidget {
  final StudentAssignmentItem item;
  const _AssignmentRow({required this.item});
  @override
  Widget build(BuildContext context) {
    final submitted = const {
      'submitted',
      'graded',
      'returned',
    }.contains(item.status);
    final color = submitted ? const Color(0xFF18A06F) : const Color(0xFFF09A37);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDF0F4))),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.courseName, style: TextStyle(color: color)),
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  item.dueAt == null
                      ? 'ไม่ระบุกำหนดส่ง'
                      : 'กำหนด ${_formatDate(item.dueAt!)}',
                  style: const TextStyle(color: Color(0xFF8993A4)),
                ),
              ],
            ),
          ),
          Text(
            submitted ? 'ส่งแล้ว' : 'รอดำเนินการ',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String text;
  const _InsightRow({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF8A65C7).withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _Activity {
  final DateTime? date;
  final String title;
  final String detail;
  const _Activity({this.date, required this.title, required this.detail});
}

String _percent(double? value) =>
    value == null ? 'ยังไม่มีข้อมูล' : '${value.round()}%';

String _attendanceStatus(String status) => switch (status) {
  'present' => 'มาเรียน',
  'late' => 'มาสาย',
  'absent' => 'ขาดเรียน',
  'excused' => 'ลา',
  _ => status,
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
