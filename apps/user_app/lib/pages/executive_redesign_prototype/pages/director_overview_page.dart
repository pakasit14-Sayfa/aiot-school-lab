import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorOverviewPage extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DirectorOverviewPage({super.key, required this.onNavigate});

  @override
  State<DirectorOverviewPage> createState() => _DirectorOverviewPageState();
}

class _DirectorOverviewPageState extends State<DirectorOverviewPage> {
  int selectedPeriod = 0;
  int selectedUtilityPeriod = 0;

  Map<String, int> _userCounts = {};
  List<DeviceOption> _devices = [];
  List<IncidentSummaryItem> _incidentSummary = [];

  @override
  void initState() {
    super.initState();
    _loadExecutiveData();
  }

  Future<void> _loadExecutiveData() async {
    try {
      final results = await Future.wait([
        UserAdminService.countUsersByRole(),
        LessonService.listSchoolDevices(),
        IncidentService.getIncidentSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _userCounts = results[0] as Map<String, int>;
        _devices = results[1] as List<DeviceOption>;
        _incidentSummary = results[2] as List<IncidentSummaryItem>;
      });
    } catch (_) {}
  }

  final List<_ProgramOverviewData> programOverview = const [
    _ProgramOverviewData(
      title: 'วิทย์ - คณิต',
      subtitle: 'ม.1 - ม.6',
      color: AppPalette.chartPink,
      behavior: 94,
      learning: 96,
      environment: 92,
    ),
    _ProgramOverviewData(
      title: 'สายภาษา',
      subtitle: 'ม.1 - ม.6',
      color: AppPalette.chartBlue,
      behavior: 91,
      learning: 93,
      environment: 95,
    ),
    _ProgramOverviewData(
      title: 'สายทั่วไป',
      subtitle: 'ม.1 - ม.6',
      color: AppPalette.chartCream,
      behavior: 89,
      learning: 90,
      environment: 94,
    ),
  ];


  List<String> get _resourceLabels {
    switch (selectedUtilityPeriod) {
      case 0:
        return const ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
      case 1:
        return const ['W1', 'W2', 'W3', 'W4'];
      default:
        return const ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.'];
    }
  }

  List<double> get _electricValues {
    switch (selectedUtilityPeriod) {
      case 0:
        return const [352, 380, 368, 401, 389, 412, 427];
      case 1:
        return const [2490, 2580, 2640, 2710];
      default:
        return const [10600, 10950, 11120, 10840, 11410, 11890];
    }
  }

  List<double> get _waterValues {
    switch (selectedUtilityPeriod) {
      case 0:
        return const [12.2, 13.1, 14.4, 13.6, 15.0, 16.1, 16.8];
      case 1:
        return const [93, 97, 101, 108];
      default:
        return const [392, 406, 414, 421, 433, 446];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        return SingleChildScrollView(
          child: Column(
            children: [
              _hero(constraints.maxWidth),
              const SizedBox(height: 16),
              _periodSelector(),
              const SizedBox(height: 16),
              _summaryCards(constraints.maxWidth),
              const SizedBox(height: 16),
              if (!compact)
                SizedBox(
                  height: 370,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ฝั่งนักเรียนกว้างกว่าเล็กน้อย เพราะมี 3 สายการเรียน
                      Expanded(
                        flex: 5,
                        child: _learningOverview(),
                      ),
                      const SizedBox(width: 16),

                      // ฝั่งครูยังมีพื้นที่เพียงพอสำหรับกราฟ 3 แท่ง
                      Expanded(
                        flex: 4,
                        child: _teacherOverviewCard(),
                      ),
                    ],
                  ),
                )
              else ...[
                _learningOverview(),
                const SizedBox(height: 16),
                _teacherOverviewCard(),
              ],
              const SizedBox(height: 16),
              if (!compact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _utilityCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _resourceSixTileCard(),
                    ),
                  ],
                )
              else ...[
                _utilityCard(),
                const SizedBox(height: 16),
                _resourceSixTileCard(),
              ],
              const SizedBox(height: 16),
              _importantCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(double width) {
    final isPhone = width < 700;
    final titleFont = isPhone ? 23.0 : 28.0;
    final bodyFont = isPhone ? 11.0 : 12.0;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.heroTag,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'ศูนย์ควบคุมสำหรับผู้อำนวยการโรงเรียน',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'ภาพรวมโรงเรียน\nAIoT Smart Lab',
          style: TextStyle(
            fontSize: titleFont,
            fontWeight: FontWeight.w800,
            height: 1.12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ติดตามการเรียน ครู เหตุฉุกเฉิน พลังงาน น้ำ และสภาพแวดล้อมในหน้าเดียว',
          style: TextStyle(fontSize: bodyFont, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroTag(Icons.cloud_done_rounded, 'ระบบออนไลน์'),
            _HeroTag(Icons.schedule_rounded, 'อัปเดตล่าสุด 2 นาที'),
            _HeroTag(Icons.verified_rounded, 'สถานะปกติ'),
          ],
        ),
      ],
    );

    final mascotOuterSize = isPhone ? 170.0 : 240.0;

    final mascot = SizedBox(
      width: mascotOuterSize,
      height: mascotOuterSize,
      child: Container(
        padding: EdgeInsets.all(isPhone ? 6 : 8),
        decoration: BoxDecoration(
          color: AppPalette.tint(Colors.white, 0.12),
          borderRadius: BorderRadius.circular(isPhone ? 30 : 38),
        ),
        child: Image.asset(
          'assets/images/robot_logo.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.smart_toy_rounded,
                size: 84,
                color: AppPalette.primaryPink,
              ),
            );
          },
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.heroPink, AppPalette.heroPinkDark],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: isPhone
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: text,
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: mascot,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 20),
                mascot,
              ],
            ),
    );
  }

  Widget _periodSelector() {
    const labels = ['รายวัน', 'สัปดาห์', 'เดือน'];
    return Row(
      children: [
        const Expanded(
          child: Text('ภาพรวมข้อมูล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppPalette.primaryPinkSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: List.generate(labels.length, (index) {
              final active = selectedPeriod == index;
              return InkWell(
                onTap: () => setState(() => selectedPeriod = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppPalette.textDark : AppPalette.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _summaryCards(double width) {
    final studentCount = _userCounts['student'] ?? 1248;
    final teacherCount = _userCounts['teacher'] ?? 58;
    final totalIncidents = _incidentSummary.fold<int>(
      0,
      (sum, item) => sum + item.totalCount,
    );
    final incidentCount = '$totalIncidents';
    final deviceCount = _devices.isNotEmpty ? '${_devices.length}' : '84';

    final items = <_SummaryData>[
      _SummaryData(
        'นักเรียนทั้งหมด',
        '$studentCount',
        'ในระบบโรงเรียน',
        'ลงทะเบียนแล้ว',
        Icons.groups_rounded,
        AppPalette.softPink,
      ),
      _SummaryData(
        'ครูและบุคลากร',
        '$teacherCount',
        'ในระบบโรงเรียน',
        'ประจำการ',
        Icons.co_present_rounded,
        AppPalette.softCream,
      ),
      _SummaryData(
        'เหตุฉุกเฉิน',
        incidentCount,
        'รายงานในระบบ',
        totalIncidents > 0 ? 'ต้องติดตาม' : 'ปกติ',
        Icons.warning_amber_rounded,
        AppPalette.softPink2,
      ),
      _SummaryData(
        'อุปกรณ์ IoT',
        deviceCount,
        'ติดตั้งในห้องเรียน',
        'ออนไลน์',
        Icons.sensors_rounded,
        AppPalette.softBlue,
      ),
    ];

    final int columns = width < 900 ? 2 : 4;
    final double cardHeight = width < 650 ? 132 : 126;

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: width < 650 ? 10 : 12,
        mainAxisSpacing: width < 650 ? 10 : 12,
        mainAxisExtent: cardHeight,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: null,
          child: Container(
            padding: EdgeInsets.all(width < 650 ? 12 : 14),
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: width < 650 ? 32 : 34,
                      height: width < 650 ? 32 : 34,
                      decoration: BoxDecoration(
                        color: AppPalette.tint(Colors.white, 0.82),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        item.icon,
                        size: width < 650 ? 17 : 18,
                        color: AppPalette.textDark,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        item.badge,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: width < 650 ? 8.5 : 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: width < 650 ? 9.5 : 10.5,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: width < 650 ? 21 : 23,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: width < 650 ? 8.5 : 9.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _learningOverview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ภาพรวมตามสายการเรียน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ภาพรวมด้านพฤติกรรม การเรียน และการดูแลรักษาสภาพแวดล้อมในห้องเรียน',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(2),
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              if (narrow) {
                return Column(
                  children: programOverview
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _programChartCard(item),
                          ))
                      .toList(),
                );
              }

              return Row(
                children: programOverview
                    .map((item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _programChartCard(item),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _programChartCard(_ProgramOverviewData item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => widget.onNavigate(2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.tint(item.color, 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppPalette.tint(item.color, 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textDark,
                    ),
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'แตะเพื่อดูระดับชั้น',
              style: TextStyle(
                fontSize: 9.5,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // แกน Y 0 - 100%
                  const SizedBox(
                    width: 28,
                    child: _YAxisLabels(),
                  ),
                  const SizedBox(width: 6),

                  // พื้นที่กราฟ
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: _ChartGridLines(),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _metricBar(
                              label: 'พฤติกรรม',
                              value: item.behavior,
                              color: AppPalette.behaviorYellow,
                              softColor: AppPalette.tint(
                                AppPalette.behaviorYellow,
                                0.18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _metricBar(
                              label: 'การเรียน',
                              value: item.learning,
                              color: AppPalette.learningBlue,
                              softColor: AppPalette.tint(
                                AppPalette.learningBlue,
                                0.18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _metricBar(
                              label: 'สิ่งแวดล้อม',
                              value: item.environment,
                              color: AppPalette.environmentGreen,
                              softColor: AppPalette.tint(
                                AppPalette.environmentGreen,
                                0.18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBar({
    required String label,
    required int value,
    required Color color,
    required Color softColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: value / 100,
                widthFactor: 0.88,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // แกน X
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 1),
            color: AppPalette.border,
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8.8,
                fontWeight: FontWeight.w600,
                color: AppPalette.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _utilityCard() {
    final electricitySeries = <_ChartSeries>[
      _ChartSeries(
        name: 'ไฟฟ้า',
        color: AppPalette.chartPink,
        values: _electricValues,
        latestValue:
            '${_electricValues.last.toStringAsFixed(0)} kWh',
      ),
    ];

    final waterSeries = <_ChartSeries>[
      _ChartSeries(
        name: 'น้ำ',
        color: AppPalette.learningBlue,
        values: _waterValues,
        latestValue:
            '${_waterValues.last.toStringAsFixed(selectedUtilityPeriod == 0 ? 1 : 0)} m³',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: directorWhiteCard(),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แนวโน้มการใช้ทรัพยากร',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ติดตามการใช้ไฟฟ้าและน้ำ แยกตามรายวัน รายสัปดาห์ และรายเดือน',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _miniPeriodSelector(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final int columns =
                constraints.maxWidth < 680 ? 1 : 2;

            final cards = <Widget>[
              _compactChartCard(
                title: 'ไฟฟ้า',
                subtitle: 'แนวโน้มการใช้ไฟฟ้า',
                icon: Icons.bolt_rounded,
                color: AppPalette.chartPink,
                series: electricitySeries,
                labels: _resourceLabels,
              ),
              _compactChartCard(
                title: 'น้ำ',
                subtitle: 'แนวโน้มการใช้น้ำ',
                icon: Icons.water_drop_rounded,
                color: AppPalette.learningBlue,
                series: waterSeries,
                labels: _resourceLabels,
              ),
            ];

            if (columns == 1) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 12),
                  cards[1],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _resourceSixTileCard() {
    return Container(
      width: double.infinity,
      height: 350,
      padding: const EdgeInsets.all(14),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.tint(
                    AppPalette.environmentGreen,
                    0.12,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.sensors_rounded,
                  size: 18,
                  color: AppPalette.environmentGreen,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ภาพรวมสิ่งแวดล้อม',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ภาพรวมคุณภาพอากาศ แสง อุณหภูมิ และการแจ้งเตือนก๊าซภายในห้องเรียน',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // แบ่งพื้นที่ที่เหลือให้ 3 แถวเท่ากัน
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _resourceTile(
                          title: 'PM2.5',
                          value: '18 µg/m³',
                          icon: Icons.air_rounded,
                          color: AppPalette.chartCream,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _resourceTile(
                          title: 'ความเข้มแสง',
                          value: '420 lux',
                          icon: Icons.light_mode_rounded,
                          color: AppPalette.behaviorYellow,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _resourceTile(
                          title: 'อุณหภูมิ',
                          value: '27.5 °C',
                          icon: Icons.thermostat_rounded,
                          color: AppPalette.learningBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _resourceTile(
                          title: 'CO₂',
                          value: '690 ppm',
                          icon: Icons.co2_rounded,
                          color: AppPalette.environmentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _resourceTile(
                          title: 'ก๊าซมีเทน',
                          value: 'ปกติ',
                          icon: Icons.sensors_rounded,
                          color: AppPalette.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _resourceTile(
                          title: 'ควัน',
                          value: 'ไม่พบ',
                          icon: Icons.local_fire_department_rounded,
                          color: AppPalette.danger,
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


  Widget _resourceTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.09),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppPalette.tint(color, 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<_ChartSeries> series,
    required List<String> labels,
  }) {
    final values = series.expand((item) => item.values).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b) * 1.12;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.tint(color, 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 18,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _resourceLegendChip(
            color: series.first.color,
            text:
                '${series.first.name} ${series.first.latestValue}',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: _ScaledYAxisLabels(maxValue: maxValue),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(
                            '${title}_$selectedUtilityPeriod',
                          ),
                          tween: Tween(begin: 0, end: 1),
                          duration:
                              const Duration(milliseconds: 1400),
                          curve: Curves.easeInOutQuart,
                          builder: (context, progress, _) {
                            return CustomPaint(
                              painter:
                                  _AnimatedLineChartPainter(
                                series: series,
                                maxValue: maxValue,
                                progress: progress,
                              ),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children:
                            List.generate(labels.length, (index) {
                          return Expanded(
                            child: Text(
                              labels[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 8,
                                color: AppPalette.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
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

  Widget _miniPeriodSelector() {
    const labels = ['รายวัน', 'สัปดาห์', 'เดือน'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.primaryPinkSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final active = selectedUtilityPeriod == index;
          return InkWell(
            onTap: () => setState(() => selectedUtilityPeriod = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppPalette.textDark : AppPalette.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _resourceLegendChip({
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ภาพรวมครู',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ภาพรวมการมาปฏิบัติงาน การสอน และการดูแลรักษาสภาพแวดล้อมในห้องเรียน',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(3),
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  width: 28,
                  child: _YAxisLabels(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: _ChartGridLines(),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _teacherMetricBar(
                            label: 'มาปฏิบัติงาน',
                            value: 96,
                            color: AppPalette.behaviorYellow,
                            softColor: AppPalette.tint(
                              AppPalette.behaviorYellow,
                              0.18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _teacherMetricBar(
                            label: 'การสอน',
                            value: 94,
                            color: AppPalette.learningBlue,
                            softColor: AppPalette.tint(
                              AppPalette.learningBlue,
                              0.18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _teacherMetricBar(
                            label: 'สิ่งแวดล้อม',
                            value: 92,
                            color: AppPalette.environmentGreen,
                            softColor: AppPalette.tint(
                              AppPalette.environmentGreen,
                              0.18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _teacherStatChip(
                icon: Icons.fact_check_rounded,
                color: AppPalette.behaviorYellow,
                text: 'ครูมาปฏิบัติงาน 58 / 61 คน',
              ),
              _teacherStatChip(
                icon: Icons.cast_for_education_rounded,
                color: AppPalette.learningBlue,
                text: 'คาบสอนสำเร็จ 94%',
              ),
              _teacherStatChip(
                icon: Icons.cleaning_services_rounded,
                color: AppPalette.environmentGreen,
                text: 'ดูแลห้องเรียน 92%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teacherMetricBar({
    required String label,
    required int value,
    required Color color,
    required Color softColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: value / 100,
                widthFactor: 0.58,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 1),
            color: AppPalette.border,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8.8,
                fontWeight: FontWeight.w600,
                color: AppPalette.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherStatChip({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.2,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _importantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สิ่งที่ควรทราบวันนี้',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'สรุปเหตุการณ์และข้อมูลที่มีความผิดปกติหรือควรติดตาม เพื่อช่วยให้ผู้บริหารเห็นประเด็นสำคัญได้ทันที',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _important(
            color: AppPalette.warning,
            icon: Icons.water_drop_rounded,
            title: 'การใช้น้ำสูงผิดปกติที่อาคาร 2',
            subtitle: 'วันนี้ 10:30 น. • อาคาร 2 ชั้น 1–3',
            detail:
                'ระบบตรวจพบว่าปริมาณการใช้น้ำของอาคาร 2 สูงกว่าค่าเฉลี่ยช่วงเวลาเดียวกันประมาณ 28% โดยเพิ่มขึ้นต่อเนื่องตั้งแต่ช่วงเช้า แนะนำให้ตรวจสอบห้องน้ำ จุดล้างมือ วาล์วน้ำ และท่อบริเวณชั้น 2 เป็นพิเศษ เพื่อคัดกรองกรณีก๊อกเปิดทิ้งหรือการรั่วซึม',
            status: 'ควรตรวจสอบ',
          ),

          _important(
            color: AppPalette.danger,
            icon: Icons.sports_martial_arts_rounded,
            title: 'ตรวจพบเหตุทะเลาะวิวาท',
            subtitle: 'วันนี้ 10:24 น. • อาคาร 2 ชั้น 3',
            detail:
                'กล้อง AI ตรวจพบพฤติกรรมที่มีความเสี่ยงต่อการทะเลาะวิวาทบริเวณทางเดินหน้า ห้อง ม.5/2 ระบบได้บันทึกเหตุการณ์และส่งการแจ้งเตือนไปยังผู้รับผิดชอบแล้ว ควรติดตามผลการดำเนินการและบันทึกข้อสรุปของเหตุการณ์',
            status: 'เร่งด่วน',
          ),

          _important(
            color: AppPalette.chartPink,
            icon: Icons.groups_rounded,
            title: 'นักเรียน ม.5/2 ขาดเรียนสูงกว่าปกติ',
            subtitle: 'วันนี้ • ม.5/2 ขาดเรียน 8 คน',
            detail:
                'จำนวนผู้ขาดเรียนสูงกว่าค่าเฉลี่ยประจำห้อง ควรให้ครูประจำชั้นตรวจสอบสาเหตุ แยกกรณีลาป่วย ลากิจ หรือขาดเรียนโดยไม่แจ้ง และติดตามนักเรียนที่มีประวัติขาดเรียนต่อเนื่อง',
            status: 'ติดตาม',
          ),

          _important(
            color: AppPalette.warning,
            icon: Icons.bolt_rounded,
            title: 'การใช้ไฟฟ้าอาคาร 3 สูงกว่าค่าเฉลี่ย',
            subtitle: 'ช่วง 08:00–12:00 น. • สูงขึ้นประมาณ 18%',
            detail:
                'การใช้ไฟเพิ่มขึ้นชัดเจนในช่วงก่อนเที่ยง โดยเฉพาะพื้นที่ห้องปฏิบัติการและห้องเรียนชั้น 3 ควรตรวจสอบเครื่องปรับอากาศ อุปกรณ์ไฟฟ้ากำลังสูง และอุปกรณ์ที่อาจเปิดทิ้งหลังเลิกใช้งาน',
            status: 'เฝ้าระวัง',
          ),

          _important(
            color: AppPalette.environmentGreen,
            icon: Icons.air_rounded,
            title: 'คุณภาพอากาศในห้องเรียนส่วนใหญ่อยู่ในเกณฑ์ปกติ',
            subtitle: 'PM2.5 เฉลี่ย 18 µg/m³ • CO₂ เฉลี่ย 690 ppm',
            detail:
                'ค่าฝุ่นและคาร์บอนไดออกไซด์ในภาพรวมยังอยู่ในระดับที่ระบบกำหนดว่าเหมาะสม อย่างไรก็ตามควรติดตามห้องที่มีนักเรียนหนาแน่นหรือมีการปิดห้องเป็นเวลานาน เพื่อรักษาการระบายอากาศให้เหมาะสม',
            status: 'ปกติ',
          ),

          _important(
            color: AppPalette.primaryPink,
            icon: Icons.calendar_month_rounded,
            title: 'มีนัดประชุมฝ่ายบริหารวันนี้',
            subtitle: '15:00 น. • ห้องประชุม 1',
            detail:
                'หัวข้อหลักคือการติดตามข้อมูลการมาเรียน การใช้ทรัพยากร และเหตุการณ์แจ้งเตือนประจำสัปดาห์ ผู้บริหารสามารถเปิดข้อมูลใน Dashboard เพื่อใช้ประกอบการประชุมได้ทันที',
            status: 'กำหนดการ',
          ),
        ],
      ),
    );
  }

  Widget _important({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String detail,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.tint(color, 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.2,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.tint(color, 0.13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.8,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10.2,
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
}



class _AnimatedLineChartPainter extends CustomPainter {
  final List<_ChartSeries> series;
  final double maxValue;
  final double progress;

  const _AnimatedLineChartPainter({
    required this.series,
    required this.maxValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double topPadding = 12;
    const double bottomPadding = 10;
    final double chartHeight = size.height - topPadding - bottomPadding;
    final double chartWidth = size.width;

    final gridPaint = Paint()
      ..color = AppPalette.border
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = topPadding + (chartHeight * i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    if (series.isEmpty || series.first.values.isEmpty) return;

    final visibleWidth = chartWidth * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, visibleWidth, size.height));

    final pointCount = series.first.values.length;
    final dx = pointCount > 1 ? chartWidth / (pointCount - 1) : chartWidth;

    for (final item in series) {
      final points = <Offset>[];
      for (int i = 0; i < item.values.length; i++) {
        final x = dx * i;
        final y = topPadding + chartHeight - ((item.values[i] / maxValue) * chartHeight);
        points.add(Offset(x, y));
      }

      final fillPath = Path();
      fillPath.moveTo(points.first.dx, topPadding + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final current = points[i];
        final midX = (prev.dx + current.dx) / 2;
        final midY = (prev.dy + current.dy) / 2;
        linePath.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
        fillPath.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
      }

      final last = points.last;
      linePath.lineTo(last.dx, last.dy);
      fillPath.lineTo(last.dx, last.dy);
      fillPath.lineTo(last.dx, topPadding + chartHeight);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = item.color.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );

      // soft glow behind line
      canvas.drawPath(
        linePath,
        Paint()
          ..color = item.color.withValues(alpha: 0.20)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..color = item.color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      final pointPaint = Paint()..color = item.color;
      final pointInner = Paint()..color = Colors.white;

      Offset? lastVisiblePoint;
      for (final point in points) {
        if (point.dx <= visibleWidth) {
          lastVisiblePoint = point;
          canvas.drawCircle(point, 5, pointPaint);
          canvas.drawCircle(point, 2.3, pointInner);
        }
      }

      if (lastVisiblePoint != null) {
        canvas.drawCircle(
          lastVisiblePoint,
          9,
          Paint()..color = item.color.withValues(alpha: 0.16),
        );
        canvas.drawCircle(lastVisiblePoint, 5, pointPaint);
        canvas.drawCircle(lastVisiblePoint, 2.3, pointInner);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedLineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.series != series;
  }
}

class _ChartSeries {
  final String name;
  final Color color;
  final List<double> values;
  final String latestValue;

  _ChartSeries({
    required this.name,
    required this.color,
    required this.values,
    required this.latestValue,
  });
}

class _ScaledYAxisLabels extends StatelessWidget {
  final double maxValue;

  const _ScaledYAxisLabels({
    required this.maxValue,
  });

  String _label(double ratio) {
    final value = maxValue * ratio;
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }
    if (value >= 10) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 27),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_label(1.0), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          Text(_label(0.75), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          Text(_label(0.50), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          Text(_label(0.25), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          const Text('0', style: TextStyle(fontSize: 8, color: AppPalette.textMuted)),
        ],
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final String sub;
  final String badge;
  final IconData icon;
  final Color bg;
  const _SummaryData(this.title, this.value, this.sub, this.badge, this.icon, this.bg);
}

class _ProgramOverviewData {
  final String title;
  final String subtitle;
  final Color color;
  final int behavior;
  final int learning;
  final int environment;

  const _ProgramOverviewData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.behavior,
    required this.learning,
    required this.environment,
  });
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroTag(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.tint(Colors.white, 0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 10.5, color: Colors.white)),
        ],
      ),
    );
  }
}


class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 30,
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

class _ChartGridLines extends StatelessWidget {
  const _ChartGridLines();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        top: 20,
        bottom: 31,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Divider(height: 1, thickness: 1, color: AppPalette.border),
          Divider(height: 1, thickness: 1, color: AppPalette.border),
          Divider(height: 1, thickness: 1, color: AppPalette.border),
          Divider(height: 1, thickness: 1, color: AppPalette.border),
          Divider(height: 1, thickness: 1, color: AppPalette.border),
        ],
      ),
    );
  }
}

