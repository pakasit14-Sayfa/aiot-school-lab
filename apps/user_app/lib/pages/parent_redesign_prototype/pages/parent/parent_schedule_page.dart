import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/parent_common_widgets.dart';

class ParentSchedulePage extends StatefulWidget {
  const ParentSchedulePage({super.key});

  @override
  State<ParentSchedulePage> createState() => _ParentSchedulePageState();
}

class _ParentSchedulePageState extends State<ParentSchedulePage> {
  static const Color _bg = Color(0xFFF5F7FB);

  String selectedDay = 'วันนี้';
  String selectedHomeworkFilter = 'ทั้งหมด';

  LinkedStudentItem? _selectedStudent;
  List<StudentScheduleItem> _realSchedule = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final students = await ParentPortalService.listMyLinkedStudents();
      if (!mounted) return;
      if (students.isNotEmpty) {
        final firstStudent = students.first;
        final sched = await ParentPortalService.listMyStudentSchedule(
          firstStudent.studentId,
        );
        if (!mounted) return;
        setState(() {
          _selectedStudent = firstStudent;
          _realSchedule = sched;
        });
      }
    } catch (_) {}
  }

  List<_ScheduleItem> get _effectiveSchedule {
    if (_realSchedule.isEmpty) return schedule;
    return _realSchedule.map((s) {
      return _ScheduleItem(
        time: s.startTime,
        endTime: s.endTime,
        subject: s.subjectName,
        teacher: 'ครูผู้สอน',
        room: s.room ?? 'ห้องเรียน',
        type: _ScheduleType.upcoming,
      );
    }).toList();
  }

  final List<String> days = const [
    'วันนี้',
    'พรุ่งนี้',
    'สัปดาห์นี้',
  ];

  final List<String> homeworkFilters = const [
    'ทั้งหมด',
    'ใกล้ครบกำหนด',
    'ส่งแล้ว',
    'รอดำเนินการ',
  ];

  final List<_ScheduleItem> schedule = const [
    _ScheduleItem(
      time: '08:30',
      endTime: '09:20',
      subject: 'ภาษาไทย',
      teacher: 'ครูศิริพร',
      room: 'ห้อง ม.2/1',
      type: _ScheduleType.completed,
    ),
    _ScheduleItem(
      time: '09:30',
      endTime: '10:20',
      subject: 'คณิตศาสตร์',
      teacher: 'ครูอนุชา',
      room: 'ห้อง ม.2/1',
      type: _ScheduleType.current,
    ),
    _ScheduleItem(
      time: '10:30',
      endTime: '11:20',
      subject: 'วิทยาศาสตร์',
      teacher: 'ครูปวีณา',
      room: 'Lab 2',
      type: _ScheduleType.upcoming,
    ),
    _ScheduleItem(
      time: '13:00',
      endTime: '13:50',
      subject: 'ภาษาอังกฤษ',
      teacher: 'Teacher Anna',
      room: 'ห้อง ม.2/1',
      type: _ScheduleType.upcoming,
    ),
    _ScheduleItem(
      time: '14:00',
      endTime: '14:50',
      subject: 'สังคมศึกษา',
      teacher: 'ครูสมชาย',
      room: 'ห้อง ม.2/1',
      type: _ScheduleType.upcoming,
    ),
    _ScheduleItem(
      time: '15:00',
      endTime: '15:50',
      subject: 'กิจกรรมโฮมรูม',
      teacher: 'ครูประจำชั้น',
      room: 'ห้อง ม.2/1',
      type: _ScheduleType.upcoming,
    ),
  ];

  final List<_HomeworkItem> homework = const [
    _HomeworkItem(
      subject: 'คณิตศาสตร์',
      title: 'แบบฝึกหัดบทที่ 5',
      dueDate: '22 ส.ค. 2569 · 16:00 น.',
      teacher: 'ครูอนุชา',
      status: 'ใกล้ครบกำหนด',
      statusType: _HomeworkStatus.dueSoon,
      progress: 0.70,
    ),
    _HomeworkItem(
      subject: 'วิทยาศาสตร์',
      title: 'รายงานการทดลอง เรื่องแรงและการเคลื่อนที่',
      dueDate: '25 ส.ค. 2569',
      teacher: 'ครูปวีณา',
      status: 'กำลังทำ',
      statusType: _HomeworkStatus.inProgress,
      progress: 0.45,
    ),
    _HomeworkItem(
      subject: 'ภาษาอังกฤษ',
      title: 'Reading Worksheet Unit 6',
      dueDate: '27 ส.ค. 2569',
      teacher: 'Teacher Anna',
      status: 'รอดำเนินการ',
      statusType: _HomeworkStatus.pending,
      progress: 0.0,
    ),
    _HomeworkItem(
      subject: 'ภาษาไทย',
      title: 'สรุปใจความสำคัญจากบทอ่าน',
      dueDate: '20 ส.ค. 2569',
      teacher: 'ครูศิริพร',
      status: 'ส่งแล้ว',
      statusType: _HomeworkStatus.submitted,
      progress: 1.0,
    ),
  ];

  List<_HomeworkItem> get filteredHomework {
    return homework.where((item) {
      switch (selectedHomeworkFilter) {
        case 'ใกล้ครบกำหนด':
          return item.statusType == _HomeworkStatus.dueSoon;
        case 'ส่งแล้ว':
          return item.statusType == _HomeworkStatus.submitted;
        case 'รอดำเนินการ':
          return item.statusType == _HomeworkStatus.pending ||
              item.statusType == _HomeworkStatus.inProgress;
        default:
          return true;
      }
    }).toList();
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

                  _buildTodayHero(),

                  const SizedBox(height: 16),

                  _buildSummaryCards(),

                  const SizedBox(height: 16),

                  _buildDaySelector(),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 950) {
                        return Column(
                          children: [
                            _buildTodayScheduleCard(),
                            const SizedBox(height: 14),
                            const _NextClassCard(),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _buildTodayScheduleCard(),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            flex: 4,
                            child: _NextClassCard(),
                          ),
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
                        return const Column(
                          children: [
                            _WeeklyWorkloadCard(),
                            SizedBox(height: 14),
                            _ParentHomeworkInsightCard(),
                          ],
                        );
                      }

                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _WeeklyWorkloadCard(),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            flex: 5,
                            child: _ParentHomeworkInsightCard(),
                          ),
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
    final name = _selectedStudent != null && _selectedStudent!.firstName.isNotEmpty
        ? _selectedStudent!.firstName
        : 'มะลิ';
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.face_rounded,
            color: Color(0xFF2867B2),
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            'น้อง$name · ม.2/1',
            style: const TextStyle(
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

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ตารางเรียนวันนี้',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'มีเรียนทั้งหมด 6 คาบ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ศุกร์ 21 สิงหาคม 2569 · เวลาเรียน 08:30–15:50 น.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .80),
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ScheduleHeroBadge(
                    icon: Icons.play_circle_fill_rounded,
                    text: 'กำลังเรียนคณิตศาสตร์',
                  ),
                  _ScheduleHeroBadge(
                    icon: Icons.assignment_rounded,
                    text: 'มีงานค้าง 2 งาน',
                  ),
                  _ScheduleHeroBadge(
                    icon: Icons.alarm_rounded,
                    text: '1 งานใกล้ครบกำหนด',
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
              border: Border.all(
                color: Colors.white.withValues(alpha: .13),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คาบถัดไป',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '10:30',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'วิทยาศาสตร์ · Lab 2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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
      _ScheduleSummaryData(
        title: 'คาบเรียนวันนี้',
        value: '6',
        subtitle: 'เรียนแล้ว 2 คาบ',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF2E83C5),
      ),
      _ScheduleSummaryData(
        title: 'งานทั้งหมด',
        value: '4',
        subtitle: 'ในช่วงสัปดาห์นี้',
        icon: Icons.assignment_rounded,
        color: Color(0xFF8A65C7),
      ),
      _ScheduleSummaryData(
        title: 'ใกล้ครบกำหนด',
        value: '1 งาน',
        subtitle: 'ภายในพรุ่งนี้',
        icon: Icons.alarm_rounded,
        color: Color(0xFFF09A37),
      ),
      _ScheduleSummaryData(
        title: 'ส่งแล้ว',
        value: '1 งาน',
        subtitle: 'ส่งตรงเวลา',
        icon: Icons.task_alt_rounded,
        color: Color(0xFF18A06F),
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
                child: _ScheduleSummaryTile(data: item),
              ),
          ],
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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text(
              'ตาราง',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF7D8798),
              ),
            ),
          ),
          for (final day in days)
            ChoiceChip(
              label: Text(
                day,
                style: const TextStyle(fontSize: 9),
              ),
              selected: selectedDay == day,
              onSelected: (_) {
                setState(() {
                  selectedDay = day;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleCard() {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScheduleSectionTitle(
            icon: Icons.schedule_rounded,
            title: 'ตารางเรียนวันนี้',
            subtitle: 'รายวิชา เวลา ห้องเรียน และสถานะของแต่ละคาบ',
          ),
          const SizedBox(height: 14),
          for (final item in _effectiveSchedule)
            _ScheduleRow(item: item),
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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text(
              'งานและการบ้าน',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF7D8798),
              ),
            ),
          ),
          for (final filter in homeworkFilters)
            ChoiceChip(
              label: Text(
                filter,
                style: const TextStyle(fontSize: 9),
              ),
              selected: selectedHomeworkFilter == filter,
              onSelected: (_) {
                setState(() {
                  selectedHomeworkFilter = filter;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard() {
    final items = filteredHomework;

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScheduleSectionTitle(
            icon: Icons.assignment_rounded,
            title: 'งานและการบ้าน',
            subtitle: 'ติดตามงานที่ได้รับมอบหมายและกำหนดส่ง',
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'ไม่มีรายการในหมวดนี้',
                  style: TextStyle(
                    color: Color(0xFF8A94A5),
                    fontSize: 9,
                  ),
                ),
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HomeworkTile(item: item),
              ),
        ],
      ),
    );
  }
}

// ============================================================================
// NEXT CLASS
// ============================================================================

class _NextClassCard extends StatelessWidget {
  const _NextClassCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScheduleSectionTitle(
            icon: Icons.next_plan_rounded,
            title: 'คาบถัดไป',
            subtitle: 'รายวิชาที่กำลังจะเริ่ม',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '10:30–11:20',
                  style: TextStyle(
                    color: Color(0xFF2867B2),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'วิทยาศาสตร์',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'ครูปวีณา · Lab 2',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF7D8798),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _NextClassInfo(
            icon: Icons.science_rounded,
            title: 'หัวข้อ',
            value: 'แรงและการเคลื่อนที่',
          ),
          const SizedBox(height: 9),
          const _NextClassInfo(
            icon: Icons.inventory_2_rounded,
            title: 'สิ่งที่ต้องเตรียม',
            value: 'สมุดวิทยาศาสตร์ + ใบงาน',
          ),
          const SizedBox(height: 9),
          const _NextClassInfo(
            icon: Icons.assignment_outlined,
            title: 'งานที่เกี่ยวข้อง',
            value: 'รายงานการทดลอง กำหนด 25 ส.ค.',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WEEKLY WORKLOAD
// ============================================================================

class _WeeklyWorkloadCard extends StatelessWidget {
  const _WeeklyWorkloadCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('จันทร์', 1, 0),
      ('อังคาร', 2, 1),
      ('พุธ', 1, 1),
      ('พฤหัสบดี', 3, 1),
      ('ศุกร์', 2, 1),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScheduleSectionTitle(
            icon: Icons.bar_chart_rounded,
            title: 'ภาระงานรายสัปดาห์',
            subtitle: 'จำนวนงานที่ได้รับและงานที่ครบกำหนดในแต่ละวัน',
          ),
          const SizedBox(height: 15),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 65,
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 8.7,
                        color: Color(0xFF697486),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: item.$2 / 3,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDF0F5),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF2E83C5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${item.$2} งาน · ส่ง ${item.$3}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFF778295),
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
// PARENT INSIGHT
// ============================================================================

class _ParentHomeworkInsightCard extends StatelessWidget {
  const _ParentHomeworkInsightCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScheduleSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'Homework Insight',
            subtitle: 'ข้อมูลที่ผู้ปกครองควรติดตาม',
          ),
          const SizedBox(height: 14),
          const _InsightItem(
            icon: Icons.warning_amber_rounded,
            title: 'มี 1 งานใกล้ครบกำหนด',
            detail:
                'แบบฝึกหัดคณิตศาสตร์บทที่ 5 ต้องส่งภายในพรุ่งนี้ 16:00 น.',
            color: Color(0xFFF09A37),
          ),
          const SizedBox(height: 10),
          const _InsightItem(
            icon: Icons.task_alt_rounded,
            title: 'งานที่ส่งล่าสุดตรงเวลา',
            detail:
                'ภาษาไทย: สรุปใจความสำคัญจากบทอ่าน ส่งเรียบร้อยแล้ว',
            color: Color(0xFF18A06F),
          ),
          const SizedBox(height: 10),
          const _InsightItem(
            icon: Icons.pending_actions_rounded,
            title: 'ยังมี 2 งานที่ต้องติดตาม',
            detail:
                'วิทยาศาสตร์กำลังทำ และภาษาอังกฤษยังไม่ได้เริ่ม',
            color: Color(0xFF8A65C7),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMALL COMPONENTS
// ============================================================================

class _ScheduleHeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScheduleHeroBadge({
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
              fontSize: 8.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ScheduleSectionTitle({
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

class _ScheduleSummaryTile extends StatelessWidget {
  final _ScheduleSummaryData data;

  const _ScheduleSummaryTile({
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
                    fontSize: 16,
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

class _ScheduleRow extends StatelessWidget {
  final _ScheduleItem item;

  const _ScheduleRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      _ScheduleType.completed => const Color(0xFF18A06F),
      _ScheduleType.current => const Color(0xFFF09A37),
      _ScheduleType.upcoming => const Color(0xFF2E83C5),
    };

    final status = switch (item.type) {
      _ScheduleType.completed => 'เรียนแล้ว',
      _ScheduleType.current => 'กำลังเรียน',
      _ScheduleType.upcoming => 'รอเรียน',
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
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.endTime,
                  style: const TextStyle(
                    fontSize: 7.5,
                    color: Color(0xFF8A94A5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 39,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontSize: 9.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.teacher} · ${item.room}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF8993A4),
                  ),
                ),
              ],
            ),
          ),
          _ScheduleStatusBadge(
            text: status,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  final _HomeworkItem item;

  const _HomeworkTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.statusType) {
      _HomeworkStatus.dueSoon => const Color(0xFFF09A37),
      _HomeworkStatus.inProgress => const Color(0xFF2E83C5),
      _HomeworkStatus.pending => const Color(0xFF8A65C7),
      _HomeworkStatus.submitted => const Color(0xFF18A06F),
    };

    final icon = switch (item.statusType) {
      _HomeworkStatus.dueSoon => Icons.alarm_rounded,
      _HomeworkStatus.inProgress => Icons.edit_note_rounded,
      _HomeworkStatus.pending => Icons.pending_actions_rounded,
      _HomeworkStatus.submitted => Icons.task_alt_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE9ECF1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 650;

          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.subject,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 9.7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.teacher} · กำหนด ${item.dueDate}',
                      style: const TextStyle(
                        fontSize: 7.9,
                        color: Color(0xFF8993A4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final progress = SizedBox(
            width: mobile ? double.infinity : 205,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: color,
                          fontSize: 8.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${(item.progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE9EDF3),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 10),
                progress,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 14),
              progress,
            ],
          );
        },
      ),
    );
  }
}

class _NextClassInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _NextClassInfo({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF687486),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 7.5,
                  color: Color(0xFF8A94A5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 8.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.detail,
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
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 8,
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

class _ScheduleStatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _ScheduleStatusBadge({
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
          fontSize: 7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// DATA
// ============================================================================

enum _ScheduleType {
  completed,
  current,
  upcoming,
}

class _ScheduleItem {
  final String time;
  final String endTime;
  final String subject;
  final String teacher;
  final String room;
  final _ScheduleType type;

  const _ScheduleItem({
    required this.time,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
  });
}

enum _HomeworkStatus {
  dueSoon,
  inProgress,
  pending,
  submitted,
}

class _HomeworkItem {
  final String subject;
  final String title;
  final String dueDate;
  final String teacher;
  final String status;
  final _HomeworkStatus statusType;
  final double progress;

  const _HomeworkItem({
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.teacher,
    required this.status,
    required this.statusType,
    required this.progress,
  });
}

class _ScheduleSummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ScheduleSummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
