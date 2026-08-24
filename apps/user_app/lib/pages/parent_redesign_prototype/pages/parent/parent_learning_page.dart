import 'package:flutter/material.dart';
import '../../widgets/parent_common_widgets.dart';

class ParentLearningPage extends StatefulWidget {
  const ParentLearningPage({super.key});

  @override
  State<ParentLearningPage> createState() => _ParentLearningPageState();
}

class _ParentLearningPageState extends State<ParentLearningPage> {
  String selectedPeriod = 'เทอมนี้';
  String selectedSubject = 'ทุกวิชา';

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primary = Color(0xFF2867B2);

  final List<String> periods = const [
    'สัปดาห์นี้',
    'เดือนนี้',
    'เทอมนี้',
  ];

  final List<String> subjects = const [
    'ทุกวิชา',
    'คณิตศาสตร์',
    'วิทยาศาสตร์',
    'ภาษาอังกฤษ',
    'ภาษาไทย',
  ];

  final List<_SubjectLearningData> subjectData = const [
    _SubjectLearningData(
      subject: 'คณิตศาสตร์',
      teacher: 'ครูอนุชา',
      score: 88,
      grade: 'A',
      attendance: 96,
      submitted: 12,
      totalAssignments: 13,
      lateAssignments: 1,
      missingAssignments: 0,
      trend: '+5',
      color: Color(0xFF2E83C5),
    ),
    _SubjectLearningData(
      subject: 'วิทยาศาสตร์',
      teacher: 'ครูปวีณา',
      score: 91,
      grade: 'A',
      attendance: 100,
      submitted: 10,
      totalAssignments: 10,
      lateAssignments: 0,
      missingAssignments: 0,
      trend: '+7',
      color: Color(0xFF18A06F),
    ),
    _SubjectLearningData(
      subject: 'ภาษาอังกฤษ',
      teacher: 'Teacher Anna',
      score: 82,
      grade: 'B+',
      attendance: 92,
      submitted: 9,
      totalAssignments: 11,
      lateAssignments: 1,
      missingAssignments: 1,
      trend: '+2',
      color: Color(0xFF8A65C7),
    ),
    _SubjectLearningData(
      subject: 'ภาษาไทย',
      teacher: 'ครูศิริพร',
      score: 86,
      grade: 'A',
      attendance: 100,
      submitted: 8,
      totalAssignments: 8,
      lateAssignments: 0,
      missingAssignments: 0,
      trend: '+3',
      color: Color(0xFFF09A37),
    ),
  ];

  final List<_AssignmentData> assignmentData = const [
    _AssignmentData(
      subject: 'คณิตศาสตร์',
      title: 'แบบฝึกหัดบทที่ 5',
      dueDate: '22 ส.ค. 2569 · 16:00',
      status: 'ใกล้ถึงกำหนด',
      statusType: _AssignmentStatus.dueSoon,
      score: '-',
    ),
    _AssignmentData(
      subject: 'วิทยาศาสตร์',
      title: 'รายงานการทดลองเรื่องแรง',
      dueDate: '20 ส.ค. 2569',
      status: 'ส่งตรงเวลา',
      statusType: _AssignmentStatus.onTime,
      score: '18/20',
    ),
    _AssignmentData(
      subject: 'ภาษาอังกฤษ',
      title: 'Reading Worksheet 4',
      dueDate: '19 ส.ค. 2569',
      status: 'ส่งช้า 1 วัน',
      statusType: _AssignmentStatus.late,
      score: '14/20',
    ),
    _AssignmentData(
      subject: 'ภาษาอังกฤษ',
      title: 'Vocabulary Unit 6',
      dueDate: '18 ส.ค. 2569',
      status: 'ยังไม่ส่ง',
      statusType: _AssignmentStatus.missing,
      score: '0/10',
    ),
    _AssignmentData(
      subject: 'ภาษาไทย',
      title: 'สรุปใจความสำคัญ',
      dueDate: '17 ส.ค. 2569',
      status: 'ส่งตรงเวลา',
      statusType: _AssignmentStatus.onTime,
      score: '19/20',
    ),
  ];

  List<_SubjectLearningData> get filteredSubjects {
    if (selectedSubject == 'ทุกวิชา') {
      return subjectData;
    }
    return subjectData
        .where((item) => item.subject == selectedSubject)
        .toList();
  }

  List<_AssignmentData> get filteredAssignments {
    if (selectedSubject == 'ทุกวิชา') {
      return assignmentData;
    }
    return assignmentData
        .where((item) => item.subject == selectedSubject)
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
                    title: 'การเรียนของลูก',
                    subtitle:
                        'ติดตามการเข้าเรียน การส่งงาน คะแนน และพัฒนาการของน้องมะลิ',
                    icon: Icons.menu_book_rounded,
                    trailing: _buildChildBadge(),
                  ),
                  const SizedBox(height: 18),

                  _buildFilterBar(),

                  const SizedBox(height: 16),

                  _buildMainSummary(),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 960) {
                        return const Column(
                          children: [
                            _AttendanceLearningCard(),
                            SizedBox(height: 14),
                            _AssignmentSummaryCard(),
                            SizedBox(height: 14),
                            _OverallPerformanceCard(),
                          ],
                        );
                      }

                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _AttendanceLearningCard(),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: _AssignmentSummaryCard(),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: _OverallPerformanceCard(),
                            ),
                          ],
                        );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildSubjectPerformance(),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 1000) {
                        return Column(
                          children: [
                            _buildAssignmentTracking(),
                            const SizedBox(height: 14),
                            const _LearningBehaviorCard(),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _buildAssignmentTracking(),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              flex: 4,
                              child: _LearningBehaviorCard(),
                            ),
                          ],
                        );
                    },
                  ),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return const Column(
                          children: [
                            _RecentLearningActivityCard(),
                            SizedBox(height: 14),
                            _AiLearningInsightCard(),
                          ],
                        );
                      }

                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _RecentLearningActivityCard(),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: _AiLearningInsightCard(),
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

  Widget _buildFilterBar() {
    return ParentCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 700;

          final periodSelector = Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final period in periods)
                ChoiceChip(
                  label: Text(
                    period,
                    style: const TextStyle(fontSize: 9),
                  ),
                  selected: selectedPeriod == period,
                  onSelected: (_) {
                    setState(() {
                      selectedPeriod = period;
                    });
                  },
                ),
            ],
          );

          final subjectSelector = DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSubject,
              borderRadius: BorderRadius.circular(14),
              items: subjects
                  .map(
                    (subject) => DropdownMenuItem(
                      value: subject,
                      child: Text(
                        subject,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedSubject = value;
                });
              },
            ),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ช่วงข้อมูล',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF7F899A),
                  ),
                ),
                const SizedBox(height: 7),
                periodSelector,
                const SizedBox(height: 12),
                const Text(
                  'กรองตามรายวิชา',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF7F899A),
                  ),
                ),
                const SizedBox(height: 4),
                subjectSelector,
              ],
            );
          }

          return Row(
            children: [
              const Text(
                'ช่วงข้อมูล',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF7F899A),
                ),
              ),
              const SizedBox(width: 10),
              periodSelector,
              const Spacer(),
              const Text(
                'รายวิชา',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF7F899A),
                ),
              ),
              const SizedBox(width: 10),
              subjectSelector,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainSummary() {
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
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final cards = const [
          _LearningSummaryTile(
            title: 'เข้าเรียนครบ',
            value: '96%',
            subtitle: 'ขาด 0 · ลา 2 · สาย 0',
            icon: Icons.fact_check_rounded,
            color: Color(0xFF18A06F),
          ),
          _LearningSummaryTile(
            title: 'ส่งงานตรงเวลา',
            value: '90%',
            subtitle: '39 จาก 43 งาน',
            icon: Icons.task_alt_rounded,
            color: Color(0xFF2E83C5),
          ),
          _LearningSummaryTile(
            title: 'งานค้าง',
            value: '1 งาน',
            subtitle: 'ภาษาอังกฤษ',
            icon: Icons.assignment_late_rounded,
            color: Color(0xFFDB5962),
          ),
          _LearningSummaryTile(
            title: 'คะแนนเฉลี่ย',
            value: '86.8',
            subtitle: '4 วิชาหลัก',
            icon: Icons.analytics_rounded,
            color: Color(0xFF8A65C7),
          ),
          _LearningSummaryTile(
            title: 'GPA ล่าสุด',
            value: '3.62',
            subtitle: 'อยู่ในระดับดีมาก',
            icon: Icons.star_rounded,
            color: Color(0xFFF09A37),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: card,
              ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectPerformance() {
    final data = filteredSubjects;

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.bar_chart_rounded,
            title: 'ผลการเรียนและความรับผิดชอบรายวิชา',
            subtitle:
                'ดูคะแนน การเข้าเรียน และสถานะการส่งงานของแต่ละวิชา',
          ),
          const SizedBox(height: 15),

          LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;

              if (!desktop) {
                return Column(
                  children: [
                    for (final item in data) ...[
                      _MobileSubjectCard(item: item),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'รายวิชา',
                            style: _TableHeaderStyle.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'คะแนน',
                            style: _TableHeaderStyle.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'เข้าเรียน',
                            style: _TableHeaderStyle.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ส่งงาน',
                            style: _TableHeaderStyle.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ส่งช้า',
                            style: _TableHeaderStyle.style,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'งานค้าง',
                            style: _TableHeaderStyle.style,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'แนวโน้ม',
                            textAlign: TextAlign.end,
                            style: _TableHeaderStyle.style,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final item in data)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFEDF0F4),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.subject,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        item.teacher,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF8C95A5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.score} · ${item.grade}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _PercentCell(
                              value: item.attendance,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.submitted}/${item.totalAssignments}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _CountBadge(
                              count: item.lateAssignments,
                              type: _CountBadgeType.warning,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _CountBadge(
                              count: item.missingAssignments,
                              type: _CountBadgeType.danger,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.trend,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Color(0xFF169A6E),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentTracking() {
    final assignments = filteredAssignments;

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.assignment_rounded,
            title: 'ติดตามการส่งงาน',
            subtitle:
                'ผู้ปกครองดูได้ว่าส่งตรงเวลา ส่งช้า หรือยังไม่ส่ง',
          ),
          const SizedBox(height: 14),
          for (final item in assignments)
            _AssignmentRow(item: item),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP SUMMARY CARDS
// ============================================================================

class _LearningSummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _LearningSummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
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
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 21,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 8.7,
                    color: Color(0xFF7E889A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
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

// ============================================================================
// ATTENDANCE CARD
// ============================================================================

class _AttendanceLearningCard extends StatelessWidget {
  const _AttendanceLearningCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.co_present_rounded,
            title: 'การเข้าเรียน',
            subtitle: 'การเข้าเรียนในชั้นและการขาดเรียน',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '96%',
                style: TextStyle(
                  fontSize: 30,
                  color: Color(0xFF169A6E),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _StatusBadge(
                  text: 'เข้าเรียนสม่ำเสมอ',
                  color: const Color(0xFF169A6E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: const LinearProgressIndicator(
              value: .96,
              minHeight: 9,
              backgroundColor: Color(0xFFEDF0F5),
              valueColor: AlwaysStoppedAnimation(
                Color(0xFF2E83C5),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Expanded(
                child: _SmallStatBox(
                  value: '48',
                  label: 'เข้าเรียน',
                  color: Color(0xFF18A06F),
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _SmallStatBox(
                  value: '2',
                  label: 'ลา',
                  color: Color(0xFFF09A37),
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _SmallStatBox(
                  value: '0',
                  label: 'ขาด',
                  color: Color(0xFFDB5962),
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _SmallStatBox(
                  value: '0',
                  label: 'สาย',
                  color: Color(0xFF8A65C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const _InfoLine(
            icon: Icons.check_circle_outline_rounded,
            text: 'ไม่มีรายวิชาที่ขาดเรียนเกินเกณฑ์',
            color: Color(0xFF169A6E),
          ),
          const SizedBox(height: 7),
          const _InfoLine(
            icon: Icons.info_outline_rounded,
            text: 'ภาษาอังกฤษมีอัตราเข้าเรียนต่ำสุดที่ 92%',
            color: Color(0xFFF09A37),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ASSIGNMENT SUMMARY
// ============================================================================

class _AssignmentSummaryCard extends StatelessWidget {
  const _AssignmentSummaryCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.task_alt_rounded,
            title: 'การส่งงาน',
            subtitle: 'ภาพรวมความรับผิดชอบในการส่งงาน',
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _LargeAssignmentMetric(
                  value: '39',
                  label: 'ส่งตรงเวลา',
                  color: Color(0xFF18A06F),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LargeAssignmentMetric(
                  value: '3',
                  label: 'ส่งช้า',
                  color: Color(0xFFF09A37),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LargeAssignmentMetric(
                  value: '1',
                  label: 'ยังไม่ส่ง',
                  color: Color(0xFFDB5962),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'อัตราส่งงานตรงเวลา',
            style: TextStyle(
              fontSize: 8.5,
              color: Color(0xFF7F899A),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: const LinearProgressIndicator(
              value: .90,
              minHeight: 9,
              backgroundColor: Color(0xFFEDF0F5),
              valueColor: AlwaysStoppedAnimation(
                Color(0xFF18A06F),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '90%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF169A6E),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD67C25),
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'มีงานภาษาอังกฤษ 1 งานที่ยังไม่ส่ง ควรติดตามภายในวันนี้',
                    style: TextStyle(
                      fontSize: 8.7,
                      height: 1.45,
                      color: Color(0xFF8B6039),
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
// OVERALL PERFORMANCE
// ============================================================================

class _OverallPerformanceCard extends StatelessWidget {
  const _OverallPerformanceCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.insights_rounded,
            title: 'พัฒนาการโดยรวม',
            subtitle: 'เทียบกับช่วงก่อนหน้า',
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _ProgressMetricRow(
                  label: 'คะแนน',
                  value: '86.8',
                  trend: '+4.2',
                  progress: .87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const _ProgressMetricRow(
            label: 'การเข้าเรียน',
            value: '96%',
            trend: '+1%',
            progress: .96,
          ),
          const SizedBox(height: 13),
          const _ProgressMetricRow(
            label: 'ส่งงานตรงเวลา',
            value: '90%',
            trend: '+6%',
            progress: .90,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF2B75B8),
                  size: 18,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'ภาพรวมดีขึ้นจากเดือนก่อน โดยเฉพาะวิทยาศาสตร์และการส่งงานตรงเวลา',
                    style: TextStyle(
                      fontSize: 8.7,
                      height: 1.45,
                      color: Color(0xFF52667D),
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
// ASSIGNMENT TRACKING
// ============================================================================

class _AssignmentRow extends StatelessWidget {
  final _AssignmentData item;

  const _AssignmentRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.statusType) {
      _AssignmentStatus.onTime => const Color(0xFF18A06F),
      _AssignmentStatus.late => const Color(0xFFF09A37),
      _AssignmentStatus.missing => const Color(0xFFDB5962),
      _AssignmentStatus.dueSoon => const Color(0xFF2E83C5),
    };

    final statusIcon = switch (item.statusType) {
      _AssignmentStatus.onTime => Icons.check_circle_rounded,
      _AssignmentStatus.late => Icons.schedule_rounded,
      _AssignmentStatus.missing => Icons.error_rounded,
      _AssignmentStatus.dueSoon => Icons.notifications_active_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEDF0F4),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 650;

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.subject} · กำหนดส่ง ${item.dueDate}',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF8791A2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusBadge(
                      text: item.status,
                      color: statusColor,
                    ),
                    const Spacer(),
                    Text(
                      'คะแนน ${item.score}',
                      style: const TextStyle(
                        fontSize: 8.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  statusIcon,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.subject,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFF8C95A5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  item.dueDate,
                  style: const TextStyle(
                    fontSize: 8.7,
                    color: Color(0xFF7F899A),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusBadge(
                    text: item.status,
                    color: statusColor,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  item.score,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// LEARNING BEHAVIOR
// ============================================================================

class _LearningBehaviorCard extends StatelessWidget {
  const _LearningBehaviorCard();

  @override
  Widget build(BuildContext context) {
    const behaviors = [
      (
        'เข้าชั้นเรียนตรงเวลา',
        96,
        Color(0xFF18A06F),
        Icons.schedule_rounded
      ),
      (
        'ส่งงานตามกำหนด',
        90,
        Color(0xFF2E83C5),
        Icons.task_alt_rounded
      ),
      (
        'มีส่วนร่วมในชั้นเรียน',
        88,
        Color(0xFF8A65C7),
        Icons.record_voice_over_rounded
      ),
      (
        'ความสม่ำเสมอในการเรียน',
        92,
        Color(0xFFF09A37),
        Icons.auto_graph_rounded
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.psychology_alt_rounded,
            title: 'พฤติกรรมการเรียน',
            subtitle: 'ข้อมูลภาพรวมที่ครูและระบบบันทึก',
          ),
          const SizedBox(height: 14),
          for (final item in behaviors)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.$3.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.$4,
                      size: 17,
                      color: item.$3,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.$1,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${item.$2}%',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: item.$3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: item.$2 / 100,
                            minHeight: 7,
                            backgroundColor:
                                const Color(0xFFEDF0F5),
                            valueColor:
                                AlwaysStoppedAnimation(item.$3),
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
// RECENT LEARNING ACTIVITY
// ============================================================================

class _RecentLearningActivityCard extends StatelessWidget {
  const _RecentLearningActivityCard();

  @override
  Widget build(BuildContext context) {
    const activities = [
      (
        'วันนี้ 10:15',
        'คณิตศาสตร์',
        'ทำแบบฝึกหัดในชั้นเรียนครบ 10/10 ข้อ',
        Icons.calculate_rounded,
        Color(0xFF2E83C5)
      ),
      (
        'วันนี้ 09:22',
        'การเข้าเรียน',
        'เข้าคาบคณิตศาสตร์ตรงเวลา',
        Icons.check_circle_rounded,
        Color(0xFF18A06F)
      ),
      (
        'เมื่อวาน 16:43',
        'วิทยาศาสตร์',
        'ส่งรายงานการทดลองแล้ว',
        Icons.science_rounded,
        Color(0xFF8A65C7)
      ),
      (
        '19 ส.ค. 18:20',
        'ภาษาอังกฤษ',
        'ส่ง Reading Worksheet ช้ากว่ากำหนด 1 วัน',
        Icons.schedule_rounded,
        Color(0xFFF09A37)
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.history_rounded,
            title: 'กิจกรรมการเรียนล่าสุด',
            subtitle: 'สิ่งที่เกิดขึ้นล่าสุดเกี่ยวกับการเรียน',
          ),
          const SizedBox(height: 13),
          for (final item in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFF8C95A5),
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.$5.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.$4,
                      size: 17,
                      color: item.$5,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: Color(0xFF8791A2),
                            height: 1.4,
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
// AI INSIGHT
// ============================================================================

class _AiLearningInsightCard extends StatelessWidget {
  const _AiLearningInsightCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LearningSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Learning Insight',
            subtitle: 'สรุปประเด็นที่ผู้ปกครองควรติดตาม',
          ),
          const SizedBox(height: 13),
          const _InsightItem(
            title: 'จุดเด่น',
            description:
                'วิทยาศาสตร์มีคะแนนสูงและส่งงานครบทุกงาน การเข้าเรียน 100%',
            color: Color(0xFF18A06F),
            icon: Icons.thumb_up_alt_rounded,
          ),
          const SizedBox(height: 10),
          const _InsightItem(
            title: 'ควรติดตาม',
            description:
                'ภาษาอังกฤษมีงานค้าง 1 งาน และอัตราเข้าเรียนต่ำกว่าวิชาอื่น',
            color: Color(0xFFF09A37),
            icon: Icons.visibility_rounded,
          ),
          const SizedBox(height: 10),
          const _InsightItem(
            title: 'แนะนำ',
            description:
                'ช่วยจัดเวลาอ่านภาษาอังกฤษ 20–30 นาทีต่อวัน และตรวจงานก่อนกำหนดส่ง',
            color: Color(0xFF2E83C5),
            icon: Icons.lightbulb_rounded,
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const _InsightItem({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
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
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF627084),
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

// ============================================================================
// SUBJECT MOBILE CARD
// ============================================================================

class _MobileSubjectCard extends StatelessWidget {
  final _SubjectLearningData item;

  const _MobileSubjectCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8EBF1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 37,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.subject,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.teacher,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF8C95A5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.score} · ${item.grade}',
                style: TextStyle(
                  color: item.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniSubjectMetric(
                  label: 'เข้าเรียน',
                  value: '${item.attendance}%',
                ),
              ),
              Expanded(
                child: _MiniSubjectMetric(
                  label: 'ส่งงาน',
                  value:
                      '${item.submitted}/${item.totalAssignments}',
                ),
              ),
              Expanded(
                child: _MiniSubjectMetric(
                  label: 'ส่งช้า',
                  value: '${item.lateAssignments}',
                ),
              ),
              Expanded(
                child: _MiniSubjectMetric(
                  label: 'งานค้าง',
                  value: '${item.missingAssignments}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMALL COMPONENTS
// ============================================================================

class _LearningSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LearningSectionTitle({
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
            color: _ParentLearningColors.primary,
            size: 17,
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
                  fontSize: 8.4,
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

class _SmallStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SmallStatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7F899A),
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeAssignmentMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _LargeAssignmentMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7F899A),
              fontSize: 7.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 8.3,
              color: Color(0xFF7C8798),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
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
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProgressMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final double progress;

  const _ProgressMetricRow({
    required this.label,
    required this.value,
    required this.trend,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              trend,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF169A6E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFEDF0F5),
            valueColor: const AlwaysStoppedAnimation(
              Color(0xFF2E83C5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PercentCell extends StatelessWidget {
  final int value;

  const _PercentCell({
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = value >= 95
        ? const Color(0xFF169A6E)
        : value >= 90
            ? const Color(0xFFF09A37)
            : const Color(0xFFDB5962);

    return Text(
      '$value%',
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

enum _CountBadgeType {
  warning,
  danger,
}

class _CountBadge extends StatelessWidget {
  final int count;
  final _CountBadgeType type;

  const _CountBadge({
    required this.count,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final color = count == 0
        ? const Color(0xFF169A6E)
        : type == _CountBadgeType.warning
            ? const Color(0xFFF09A37)
            : const Color(0xFFDB5962);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          count == 0 ? 'ไม่มี' : '$count',
          style: TextStyle(
            color: color,
            fontSize: 7.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MiniSubjectMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniSubjectMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 7.5,
            color: Color(0xFF8993A4),
          ),
        ),
      ],
    );
  }
}

class _TableHeaderStyle {
  static const TextStyle style = TextStyle(
    fontSize: 8.5,
    fontWeight: FontWeight.w800,
    color: Color(0xFF697486),
  );
}

class _ParentLearningColors {
  static const Color primary = Color(0xFF2867B2);
}

// ============================================================================
// DATA MODELS
// ============================================================================

class _SubjectLearningData {
  final String subject;
  final String teacher;
  final int score;
  final String grade;
  final int attendance;
  final int submitted;
  final int totalAssignments;
  final int lateAssignments;
  final int missingAssignments;
  final String trend;
  final Color color;

  const _SubjectLearningData({
    required this.subject,
    required this.teacher,
    required this.score,
    required this.grade,
    required this.attendance,
    required this.submitted,
    required this.totalAssignments,
    required this.lateAssignments,
    required this.missingAssignments,
    required this.trend,
    required this.color,
  });
}

enum _AssignmentStatus {
  onTime,
  late,
  missing,
  dueSoon,
}

class _AssignmentData {
  final String subject;
  final String title;
  final String dueDate;
  final String status;
  final _AssignmentStatus statusType;
  final String score;

  const _AssignmentData({
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.statusType,
    required this.score,
  });
}
