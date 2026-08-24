import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorLearningPage extends StatefulWidget {
  const DirectorLearningPage({super.key});

  @override
  State<DirectorLearningPage> createState() => _DirectorLearningPageState();
}

class _DirectorLearningPageState extends State<DirectorLearningPage> {
  String selectedPeriod = 'วันนี้';
  String selectedGrade = 'ทุกระดับชั้น';
  String selectedTrack = 'ทุกสายการเรียน';

  final List<String> periods = const [
    'วันนี้',
    'สัปดาห์นี้',
    'เดือนนี้',
    'ภาคเรียนนี้',
  ];

  final List<String> grades = const [
    'ทุกระดับชั้น',
    'ม.1',
    'ม.2',
    'ม.3',
    'ม.4',
    'ม.5',
    'ม.6',
  ];

  final List<String> tracks = const [
    'ทุกสายการเรียน',
    'วิทย์ - คณิต',
    'สายภาษา',
    'สายทั่วไป',
  ];

  final List<_StudentProgramData> programs = const [
    _StudentProgramData(
      title: 'วิทย์ - คณิต',
      subtitle: 'ม.1 - ม.6',
      icon: Icons.science_rounded,
      color: AppPalette.chartPink,
      students: 442,
      attendance: 96,
      learning: 95,
      behavior: 94,
      environment: 93,
      atRisk: 7,
    ),
    _StudentProgramData(
      title: 'สายภาษา',
      subtitle: 'ม.1 - ม.6',
      icon: Icons.translate_rounded,
      color: AppPalette.learningBlue,
      students: 398,
      attendance: 94,
      learning: 93,
      behavior: 91,
      environment: 95,
      atRisk: 9,
    ),
    _StudentProgramData(
      title: 'สายทั่วไป',
      subtitle: 'ม.1 - ม.6',
      icon: Icons.menu_book_rounded,
      color: AppPalette.chartCream,
      students: 408,
      attendance: 92,
      learning: 90,
      behavior: 89,
      environment: 94,
      atRisk: 12,
    ),
  ];

  final List<_GradeData> gradeData = const [
    _GradeData(
      grade: 'ม.1',
      students: 198,
      rooms: 6,
      attendance: 95,
      learning: 92,
      behavior: 94,
      environment: 93,
      absentToday: 10,
      lateToday: 4,
      supportCases: 3,
    ),
    _GradeData(
      grade: 'ม.2',
      students: 204,
      rooms: 6,
      attendance: 94,
      learning: 93,
      behavior: 92,
      environment: 95,
      absentToday: 12,
      lateToday: 5,
      supportCases: 4,
    ),
    _GradeData(
      grade: 'ม.3',
      students: 206,
      rooms: 6,
      attendance: 88,
      learning: 94,
      behavior: 95,
      environment: 94,
      absentToday: 25,
      lateToday: 6,
      supportCases: 4,
    ),
    _GradeData(
      grade: 'ม.4',
      students: 224,
      rooms: 6,
      attendance: 93,
      learning: 92,
      behavior: 91,
      environment: 94,
      absentToday: 16,
      lateToday: 6,
      supportCases: 5,
    ),
    _GradeData(
      grade: 'ม.5',
      students: 238,
      rooms: 6,
      attendance: 92,
      learning: 91,
      behavior: 90,
      environment: 92,
      absentToday: 19,
      lateToday: 7,
      supportCases: 8,
    ),
    _GradeData(
      grade: 'ม.6',
      students: 250,
      rooms: 6,
      attendance: 86,
      learning: 96,
      behavior: 95,
      environment: 96,
      absentToday: 35,
      lateToday: 8,
      supportCases: 5,
    ),
  ];

  final List<_FollowUpItem> followUps = const [
    _FollowUpItem(
      title: 'การขาดเรียนต่อเนื่อง',
      detail:
          'มี 11 คนที่ขาดเรียนเกินเกณฑ์ในช่วง 7 วันที่ผ่านมา ควรให้ครูประจำชั้นตรวจสอบสาเหตุและติดตามผู้ปกครอง',
      status: 'ควรติดตาม',
      icon: Icons.person_off_rounded,
      color: AppPalette.warning,
    ),
    _FollowUpItem(
      title: 'ผลการเรียนต่ำกว่าเกณฑ์',
      detail:
          'มี 9 คนที่มีผลการเรียนต่ำกว่าเกณฑ์ใน 2 รายวิชาขึ้นไป ควรพิจารณาจัดสอนเสริมและติดตามรายบุคคล',
      status: 'ติดตาม',
      icon: Icons.trending_down_rounded,
      color: AppPalette.chartPink,
    ),
    _FollowUpItem(
      title: 'พฤติกรรมที่ต้องเฝ้าระวัง',
      detail:
          'พบ 5 เหตุการณ์ที่ต้องติดตามจากบันทึกครูและระบบความปลอดภัย โดย 2 เหตุการณ์อยู่ระหว่างการประสานครูประจำชั้น',
      status: 'เฝ้าระวัง',
      icon: Icons.visibility_rounded,
      color: AppPalette.danger,
    ),
    _FollowUpItem(
      title: 'การดูแลห้องเรียนและสภาพแวดล้อม',
      detail:
          'มี 3 ห้องที่คะแนนการดูแลสภาพแวดล้อมต่ำกว่าเกณฑ์ ควรติดตามความสะอาด การจัดโต๊ะ และการใช้ทรัพยากรในห้อง',
      status: 'ควรปรับปรุง',
      icon: Icons.cleaning_services_rounded,
      color: AppPalette.environmentGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'ภาพรวมนักเรียน',
            subtitle:
                'สรุปข้อมูลนักเรียนที่ผู้อำนวยการควรรู้ ทั้งการมาเรียน การเรียน พฤติกรรม การดูแลนักเรียน และสภาพแวดล้อม แยกตามสายการเรียนและระดับชั้น',
          ),
          const SizedBox(height: 14),
          _filterCard(),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _programOverviewSection(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1050) {
                return Column(
                  children: [
                    _attendanceOverviewCard(),
                    const SizedBox(height: 16),
                    _studentCareCard(),
                  ],
                );
              }

              return SizedBox(
                height: 430,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _attendanceOverviewCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _studentCareCard(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _gradeOverviewSection(),
          const SizedBox(height: 16),
          _followUpSection(),
        ],
      ),
    );
  }

  Widget _filterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: directorWhiteCard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final filtersRow = [
            _filterDropdown(
              label: 'ช่วงเวลา',
              value: selectedPeriod,
              items: periods,
              icon: Icons.schedule_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedPeriod = value);
              },
            ),
            _filterDropdown(
              label: 'ระดับชั้น',
              value: selectedGrade,
              items: grades,
              icon: Icons.school_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedGrade = value);
              },
            ),
            _filterDropdown(
              label: 'สายการเรียน',
              value: selectedTrack,
              items: tracks,
              icon: Icons.account_tree_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedTrack = value);
              },
            ),
          ];

          if (compact) {
            return Column(
              children: [
                for (int i = 0; i < filtersRow.length; i++) ...[
                  filtersRow[i],
                  if (i != filtersRow.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: filtersRow[0]),
              const SizedBox(width: 10),
              Expanded(child: filtersRow[1]),
              const SizedBox(width: 10),
              Expanded(child: filtersRow[2]),
            ],
          );
        },
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 18,
          color: AppPalette.primaryPink,
        ),
        filled: true,
        fillColor: AppPalette.pageBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _summaryCards() {
    const items = [
      _StudentSummaryData(
        title: 'นักเรียนทั้งหมด',
        value: '1,248',
        subtitle: '36 ห้องเรียน',
        icon: Icons.groups_rounded,
        color: AppPalette.softPink,
      ),
      _StudentSummaryData(
        title: 'มาเรียนวันนี้',
        value: '94%',
        subtitle: '1,173 คน',
        icon: Icons.how_to_reg_rounded,
        color: AppPalette.softBlue,
      ),
      _StudentSummaryData(
        title: 'ขาดเรียนวันนี้',
        value: '72',
        subtitle: 'ควรติดตาม 11 คน',
        icon: Icons.person_off_rounded,
        color: AppPalette.softCream,
      ),
      _StudentSummaryData(
        title: 'มาสาย',
        value: '27',
        subtitle: 'ลดลงจากเมื่อวาน 5 คน',
        icon: Icons.schedule_rounded,
        color: AppPalette.softPink2,
      ),
      _StudentSummaryData(
        title: 'ต้องดูแลใกล้ชิด',
        value: '23',
        subtitle: 'เรียน / พฤติกรรม / การมาเรียน',
        icon: Icons.health_and_safety_rounded,
        color: AppPalette.softMint,
      ),
      _StudentSummaryData(
        title: 'เหตุพฤติกรรม',
        value: '5',
        subtitle: 'มี 2 เหตุการณ์กำลังติดตาม',
        icon: Icons.warning_amber_rounded,
        color: AppPalette.softPink2,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;
        if (constraints.maxWidth < 720) {
          columns = 2;
        } else if (constraints.maxWidth < 1100) {
          columns = 3;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: columns == 2 ? 126 : 118,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(Colors.white, 0.80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.3,
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

  Widget _programOverviewSection() {
    final visiblePrograms = selectedTrack == 'ทุกสายการเรียน'
        ? programs
        : programs
            .where((item) => item.title == selectedTrack)
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ภาพรวมตามสายการเรียน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เปรียบเทียบจำนวนผู้เรียน การมาเรียน การเรียน พฤติกรรม และการดูแลสภาพแวดล้อมของแต่ละสาย',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    for (int i = 0; i < visiblePrograms.length; i++) ...[
                      _programCard(visiblePrograms[i]),
                      if (i != visiblePrograms.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              int columns = visiblePrograms.length;
              if (constraints.maxWidth < 1050) {
                columns = visiblePrograms.length > 1 ? 2 : 1;
              }

              return GridView.builder(
                itemCount: visiblePrograms.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 230,
                ),
                itemBuilder: (context, index) {
                  return _programCard(visiblePrograms[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _programCard(_StudentProgramData item) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showProgramDialog(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.tint(item.color, 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppPalette.tint(item.color, 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: item.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${item.subtitle} • ${item.students} คน • แตะเพื่อดูรายละเอียด',
                        style: const TextStyle(
                          fontSize: 10.5,
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
            const SizedBox(height: 12),
            _indicatorRow(
              'มาเรียน',
              item.attendance,
              AppPalette.learningBlue,
            ),
            _indicatorRow(
              'การเรียน',
              item.learning,
              AppPalette.primaryPink,
            ),
            _indicatorRow(
              'พฤติกรรม',
              item.behavior,
              AppPalette.behaviorYellow,
            ),
            _indicatorRow(
              'สิ่งแวดล้อม',
              item.environment,
              AppPalette.environmentGreen,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'ต้องติดตาม',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '${item.atRisk} คน',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicatorRow(
    String label,
    int value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 7,
                backgroundColor: AppPalette.softTag,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 31,
            child: Text(
              '$value%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การมาเรียนแยกตามระดับชั้น',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ช่วยให้เห็นระดับชั้นที่มีการขาดเรียนหรือมาสายสูงกว่าปกติได้ทันที',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 245,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  width: 32,
                  child: _AttendanceYAxis(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: _AttendanceGridLines(),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: gradeData.map((item) {
                          final selected =
                              selectedGrade == 'ทุกระดับชั้น' ||
                                  selectedGrade == item.grade;

                          return Expanded(
                            child: Opacity(
                              opacity: selected ? 1 : 0.30,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.attendance}%',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: FractionallySizedBox(
                                          heightFactor:
                                              item.attendance / 100,
                                          widthFactor: 0.72,
                                          child: Container(
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  AppPalette.learningBlue,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 1,
                                      color: AppPalette.border,
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      item.grade,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        color: AppPalette.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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

  Widget _studentCareCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ภาพรวมการดูแลนักเรียนวันนี้',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'สรุปประเด็นที่ครูประจำชั้นและฝ่ายดูแลนักเรียนกำลังติดตาม',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _careTile(
            icon: Icons.person_off_rounded,
            title: 'ขาดเรียน',
            value: '72 คน',
            detail: '11 คนขาดต่อเนื่องเกินเกณฑ์',
            color: AppPalette.warning,
          ),
          _careTile(
            icon: Icons.schedule_rounded,
            title: 'มาสาย',
            value: '27 คน',
            detail: 'ม.5 มีจำนวนสูงสุด 7 คน',
            color: AppPalette.chartCream,
          ),
          _careTile(
            icon: Icons.trending_down_rounded,
            title: 'ผลการเรียนต้องติดตาม',
            value: '9 คน',
            detail: 'ต่ำกว่าเกณฑ์ 2 รายวิชาขึ้นไป',
            color: AppPalette.chartPink,
          ),
          _careTile(
            icon: Icons.warning_amber_rounded,
            title: 'พฤติกรรม',
            value: '5 เหตุการณ์',
            detail: '2 เหตุการณ์อยู่ระหว่างติดตาม',
            color: AppPalette.danger,
          ),
          _careTile(
            icon: Icons.support_agent_rounded,
            title: 'เคสที่ครูประจำชั้นกำลังดูแล',
            value: '23 เคส',
            detail: 'การมาเรียน / การเรียน / พฤติกรรม',
            color: AppPalette.environmentGreen,
          ),
        ],
      ),
    );
  }

  Widget _careTile({
    required IconData icon,
    required String title,
    required String value,
    required String detail,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeOverviewSection() {
    final visibleGrades = selectedGrade == 'ทุกระดับชั้น'
        ? gradeData
        : gradeData
            .where((item) => item.grade == selectedGrade)
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดตามระดับชั้น',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เปรียบเทียบจำนวนนักเรียน ห้องเรียน การมาเรียน ผลการเรียน พฤติกรรม และจำนวนเคสที่ต้องดูแล',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // มือถือ: ให้แต่ละการ์ดกว้างเต็มจอและสูงตามข้อมูลจริง
              // เพื่อไม่ให้ข้อมูลถูกตัดหรือหายจาก mainAxisExtent แบบคงที่
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    for (int i = 0; i < visibleGrades.length; i++) ...[
                      _gradeCard(visibleGrades[i]),
                      if (i != visibleGrades.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              final int columns =
                  constraints.maxWidth < 1080 ? 2 : 3;

              return GridView.builder(
                itemCount: visibleGrades.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 185,
                ),
                itemBuilder: (context, index) {
                  return _gradeCard(visibleGrades[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _gradeCard(_GradeData item) {
    final needsAttention =
        item.attendance < 93 || item.supportCases >= 7;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showGradeDialog(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: needsAttention
              ? AppPalette.tint(AppPalette.warning, 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: needsAttention
                ? AppPalette.tint(AppPalette.warning, 0.22)
                : AppPalette.border,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppPalette.primaryPinkSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.grade,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.primaryPinkDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.students} คน • ${item.rooms} ห้อง',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (needsAttention) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.tint(
                          AppPalette.warning,
                          0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ควรติดตาม',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.warning,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniMetric(
                  'มาเรียน',
                  '${item.attendance}%',
                  AppPalette.learningBlue,
                ),
                _miniMetric(
                  'การเรียน',
                  '${item.learning}%',
                  AppPalette.primaryPink,
                ),
                _miniMetric(
                  'พฤติกรรม',
                  '${item.behavior}%',
                  AppPalette.behaviorYellow,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ขาด ${item.absentToday} • สาย ${item.lateToday}',
                    style: const TextStyle(
                      fontSize: 9.2,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
                Text(
                  'ดูแล ${item.supportCases} เคส',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: item.supportCases >= 7
                        ? AppPalette.warning
                        : AppPalette.environmentGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppPalette.tint(color, 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 8.5,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _followUpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สิ่งที่ผู้อำนวยการควรติดตาม',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'สรุปประเด็นที่ต้องดูแลต่อ ไม่จำเป็นต้องดูข้อมูลรายคนทั้งหมด แต่สามารถกดดูรายละเอียดเพื่อเจาะลงระดับชั้นหรือห้องเรียนได้',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...followUps.map(
            (item) => _followUpTile(item),
          ),
        ],
      ),
    );
  }

  Widget _followUpTile(_FollowUpItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.tint(item.color, 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 19,
              color: item.color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.tint(item.color, 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 9.7,
                    height: 1.45,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProgramDialog(_StudentProgramData item) {
    final gradeDetails = _programGradeDetails(item);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 920,
              maxHeight: 720,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(item.color, 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รายละเอียด ${item.title}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'แยกข้อมูลตามระดับชั้น ม.1 - ม.6 เพื่อให้ผู้อำนวยการเห็นชั้นที่ควรติดตามได้ง่าย',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'ปิด',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // สรุปสายการเรียน
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.tint(item.color, 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _programDialogSummary(
                          'นักเรียน',
                          '${item.students} คน',
                        ),
                        _programDialogSummary(
                          'มาเรียน',
                          '${item.attendance}%',
                        ),
                        _programDialogSummary(
                          'การเรียน',
                          '${item.learning}%',
                        ),
                        _programDialogSummary(
                          'พฤติกรรม',
                          '${item.behavior}%',
                        ),
                        _programDialogSummary(
                          'สิ่งแวดล้อม',
                          '${item.environment}%',
                        ),
                        _programDialogSummary(
                          'ต้องติดตาม',
                          '${item.atRisk} คน',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'รายละเอียดตามระดับชั้น',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'กดที่ระดับชั้นเพื่อดูข้อมูลการมาเรียน การเรียน พฤติกรรม และนักเรียนที่ต้องติดตามเพิ่มเติม',
                    style: TextStyle(
                      fontSize: 9.8,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth < 640 ? 1 : 2;

                        return GridView.builder(
                          itemCount: gradeDetails.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 260,
                          ),
                          itemBuilder: (context, index) {
                            final grade = gradeDetails[index];

                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                _showProgramGradeDetail(
                                  dialogContext,
                                  item,
                                  grade,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppPalette.border,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppPalette.tint(
                                              item.color,
                                              0.10,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            grade.grade,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: item.color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${grade.students} คน',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                '${grade.rooms} ห้องเรียน',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      AppPalette.textMuted,
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
                                    const SizedBox(height: 10),
                                    _gradeInfoTextRow(
                                      'มาเรียน',
                                      '${grade.attendance}%',
                                      AppPalette.learningBlue,
                                    ),
                                    _gradeInfoTextRow(
                                      'การเรียน',
                                      '${grade.learning}%',
                                      AppPalette.primaryPink,
                                    ),
                                    _gradeInfoTextRow(
                                      'พฤติกรรม',
                                      '${grade.behavior}%',
                                      AppPalette.behaviorYellow,
                                    ),
                                    const SizedBox(height: 4),
                                    _gradeInfoTextRow(
                                      'ขาดเรียน / มาสาย',
                                      '${grade.absent} / ${grade.late} คน',
                                      AppPalette.warning,
                                    ),
                                    _gradeInfoTextRow(
                                      'นักเรียนที่ต้องติดตาม',
                                      '${grade.supportCases} คน',
                                      grade.supportCases >= 5
                                          ? AppPalette.warning
                                          : AppPalette.environmentGreen,
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_ProgramGradeDetail> _programGradeDetails(
    _StudentProgramData item,
  ) {
    if (item.title == 'วิทย์ - คณิต') {
      return const [
        _ProgramGradeDetail(
          grade: 'ม.1',
          students: 70,
          rooms: 2,
          attendance: 96,
          learning: 94,
          behavior: 95,
          environment: 93,
          absent: 3,
          late: 1,
          supportCases: 1,
        ),
        _ProgramGradeDetail(
          grade: 'ม.2',
          students: 72,
          rooms: 2,
          attendance: 95,
          learning: 95,
          behavior: 94,
          environment: 94,
          absent: 4,
          late: 2,
          supportCases: 1,
        ),
        _ProgramGradeDetail(
          grade: 'ม.3',
          students: 73,
          rooms: 2,
          attendance: 97,
          learning: 96,
          behavior: 95,
          environment: 93,
          absent: 2,
          late: 1,
          supportCases: 1,
        ),
        _ProgramGradeDetail(
          grade: 'ม.4',
          students: 74,
          rooms: 2,
          attendance: 95,
          learning: 96,
          behavior: 94,
          environment: 92,
          absent: 4,
          late: 2,
          supportCases: 1,
        ),
        _ProgramGradeDetail(
          grade: 'ม.5',
          students: 76,
          rooms: 2,
          attendance: 94,
          learning: 95,
          behavior: 92,
          environment: 91,
          absent: 5,
          late: 2,
          supportCases: 2,
        ),
        _ProgramGradeDetail(
          grade: 'ม.6',
          students: 77,
          rooms: 2,
          attendance: 98,
          learning: 98,
          behavior: 96,
          environment: 95,
          absent: 1,
          late: 1,
          supportCases: 1,
        ),
      ];
    }

    if (item.title == 'สายภาษา') {
      return const [
        _ProgramGradeDetail(
          grade: 'ม.1',
          students: 64,
          rooms: 2,
          attendance: 94,
          learning: 92,
          behavior: 91,
          environment: 95,
          absent: 4,
          late: 2,
          supportCases: 1,
        ),
        _ProgramGradeDetail(
          grade: 'ม.2',
          students: 65,
          rooms: 2,
          attendance: 93,
          learning: 92,
          behavior: 90,
          environment: 94,
          absent: 5,
          late: 2,
          supportCases: 2,
        ),
        _ProgramGradeDetail(
          grade: 'ม.3',
          students: 66,
          rooms: 2,
          attendance: 95,
          learning: 94,
          behavior: 92,
          environment: 96,
          absent: 3,
          late: 1,
          supportCases: 1,
        ),
        _ProgramGradeDetail(
          grade: 'ม.4',
          students: 67,
          rooms: 2,
          attendance: 93,
          learning: 92,
          behavior: 90,
          environment: 94,
          absent: 5,
          late: 2,
          supportCases: 2,
        ),
        _ProgramGradeDetail(
          grade: 'ม.5',
          students: 68,
          rooms: 2,
          attendance: 92,
          learning: 91,
          behavior: 89,
          environment: 94,
          absent: 6,
          late: 3,
          supportCases: 2,
        ),
        _ProgramGradeDetail(
          grade: 'ม.6',
          students: 68,
          rooms: 2,
          attendance: 97,
          learning: 96,
          behavior: 94,
          environment: 97,
          absent: 2,
          late: 1,
          supportCases: 1,
        ),
      ];
    }

    return const [
      _ProgramGradeDetail(
        grade: 'ม.1',
        students: 66,
        rooms: 2,
        attendance: 93,
        learning: 90,
        behavior: 90,
        environment: 94,
        absent: 5,
        late: 2,
        supportCases: 2,
      ),
      _ProgramGradeDetail(
        grade: 'ม.2',
        students: 67,
        rooms: 2,
        attendance: 92,
        learning: 89,
        behavior: 88,
        environment: 93,
        absent: 6,
        late: 3,
        supportCases: 2,
      ),
      _ProgramGradeDetail(
        grade: 'ม.3',
        students: 68,
        rooms: 2,
        attendance: 94,
        learning: 91,
        behavior: 90,
        environment: 95,
        absent: 4,
        late: 2,
        supportCases: 1,
      ),
      _ProgramGradeDetail(
        grade: 'ม.4',
        students: 68,
        rooms: 2,
        attendance: 91,
        learning: 89,
        behavior: 88,
        environment: 93,
        absent: 7,
        late: 3,
        supportCases: 2,
      ),
      _ProgramGradeDetail(
        grade: 'ม.5',
        students: 69,
        rooms: 2,
        attendance: 90,
        learning: 88,
        behavior: 87,
        environment: 92,
        absent: 8,
        late: 4,
        supportCases: 3,
      ),
      _ProgramGradeDetail(
        grade: 'ม.6',
        students: 70,
        rooms: 2,
        attendance: 95,
        learning: 93,
        behavior: 91,
        environment: 96,
        absent: 3,
        late: 1,
        supportCases: 2,
      ),
    ];
  }

  Widget _programDialogSummary(
    String title,
    String value,
  ) {
    return SizedBox(
      width: 115,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 8.8,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeInfoTextRow(
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: AppPalette.tint(color, 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 8.8,
                  color: AppPalette.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showProgramGradeDetail(
    BuildContext parentDialogContext,
    _StudentProgramData program,
    _ProgramGradeDetail grade,
  ) {
    showDialog<void>(
      context: context,
      builder: (detailContext) {
        return AlertDialog(
          title: Text(
            '${program.title} • ${grade.grade}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _dialogMetric(
                    'นักเรียนทั้งหมด',
                    '${grade.students} คน',
                  ),
                  _dialogMetric(
                    'จำนวนห้องเรียน',
                    '${grade.rooms} ห้อง',
                  ),
                  _dialogMetric(
                    'การมาเรียน',
                    '${grade.attendance}%',
                  ),
                  _dialogMetric(
                    'ขาดเรียนวันนี้',
                    '${grade.absent} คน',
                  ),
                  _dialogMetric(
                    'มาสายวันนี้',
                    '${grade.late} คน',
                  ),
                  _dialogMetric(
                    'ภาพรวมการเรียน',
                    '${grade.learning}%',
                  ),
                  _dialogMetric(
                    'พฤติกรรม',
                    '${grade.behavior}%',
                  ),
                  _dialogMetric(
                    'การดูแลสภาพแวดล้อม',
                    '${grade.environment}%',
                  ),
                  _dialogMetric(
                    'นักเรียนที่ต้องติดตาม',
                    '${grade.supportCases} คน',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: grade.supportCases >= 5
                          ? AppPalette.tint(
                              AppPalette.warning,
                              0.08,
                            )
                          : AppPalette.tint(
                              AppPalette.environmentGreen,
                              0.08,
                            ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      grade.supportCases >= 5
                          ? 'ระดับชั้นนี้มีนักเรียนที่ควรติดตามหลายคน แนะนำให้ดูข้อมูลรายห้องเรียนและประสานครูประจำชั้นเพิ่มเติม'
                          : 'ภาพรวมระดับชั้นอยู่ในเกณฑ์ปกติ สามารถติดตามแนวโน้มต่อเนื่องและเจาะดูรายห้องเรียนเมื่อพบความผิดปกติ',
                      style: const TextStyle(
                        fontSize: 9.8,
                        height: 1.45,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(detailContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  void _showGradeDialog(_GradeData item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('รายละเอียดระดับชั้น ${item.grade}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _dialogMetric(
                    'นักเรียน',
                    '${item.students} คน',
                  ),
                  _dialogMetric(
                    'ห้องเรียน',
                    '${item.rooms} ห้อง',
                  ),
                  _dialogMetric(
                    'มาเรียนวันนี้',
                    '${item.attendance}%',
                  ),
                  _dialogMetric(
                    'ขาดเรียน',
                    '${item.absentToday} คน',
                  ),
                  _dialogMetric(
                    'มาสาย',
                    '${item.lateToday} คน',
                  ),
                  _dialogMetric(
                    'ภาพรวมการเรียน',
                    '${item.learning}%',
                  ),
                  _dialogMetric(
                    'พฤติกรรม',
                    '${item.behavior}%',
                  ),
                  _dialogMetric(
                    'สิ่งแวดล้อม',
                    '${item.environment}%',
                  ),
                  _dialogMetric(
                    'เคสที่ต้องดูแล',
                    '${item.supportCases} เคส',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogMetric(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceYAxis extends StatelessWidget {
  const _AttendanceYAxis();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 28,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '100',
            style: TextStyle(
              fontSize: 8,
              color: AppPalette.textMuted,
            ),
          ),
          Text(
            '75',
            style: TextStyle(
              fontSize: 8,
              color: AppPalette.textMuted,
            ),
          ),
          Text(
            '50',
            style: TextStyle(
              fontSize: 8,
              color: AppPalette.textMuted,
            ),
          ),
          Text(
            '25',
            style: TextStyle(
              fontSize: 8,
              color: AppPalette.textMuted,
            ),
          ),
          Text(
            '0',
            style: TextStyle(
              fontSize: 8,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceGridLines extends StatelessWidget {
  const _AttendanceGridLines();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 29,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: AppPalette.border,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppPalette.border,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppPalette.border,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppPalette.border,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppPalette.border,
          ),
        ],
      ),
    );
  }
}

class _StudentSummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StudentSummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _StudentProgramData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int students;
  final int attendance;
  final int learning;
  final int behavior;
  final int environment;
  final int atRisk;

  const _StudentProgramData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.students,
    required this.attendance,
    required this.learning,
    required this.behavior,
    required this.environment,
    required this.atRisk,
  });
}

class _ProgramGradeDetail {
  final String grade;
  final int students;
  final int rooms;
  final int attendance;
  final int learning;
  final int behavior;
  final int environment;
  final int absent;
  final int late;
  final int supportCases;

  const _ProgramGradeDetail({
    required this.grade,
    required this.students,
    required this.rooms,
    required this.attendance,
    required this.learning,
    required this.behavior,
    required this.environment,
    required this.absent,
    required this.late,
    required this.supportCases,
  });
}

class _GradeData {
  final String grade;
  final int students;
  final int rooms;
  final int attendance;
  final int learning;
  final int behavior;
  final int environment;
  final int absentToday;
  final int lateToday;
  final int supportCases;

  const _GradeData({
    required this.grade,
    required this.students,
    required this.rooms,
    required this.attendance,
    required this.learning,
    required this.behavior,
    required this.environment,
    required this.absentToday,
    required this.lateToday,
    required this.supportCases,
  });
}

class _FollowUpItem {
  final String title;
  final String detail;
  final String status;
  final IconData icon;
  final Color color;

  const _FollowUpItem({
    required this.title,
    required this.detail,
    required this.status,
    required this.icon,
    required this.color,
  });
}
