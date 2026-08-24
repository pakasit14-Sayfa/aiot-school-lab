import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorEnvironmentPage extends StatefulWidget {
  const DirectorEnvironmentPage({super.key});

  @override
  State<DirectorEnvironmentPage> createState() =>
      _DirectorEnvironmentPageState();
}

class _DirectorEnvironmentPageState extends State<DirectorEnvironmentPage> {
  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;
  List<UtilityTrendPoint> _energyTrend = [];
  List<UtilityTrendPoint> _waterTrend = [];
  UtilityEfficiencyScore? _energyScore;
  UtilityEfficiencyScore? _waterScore;

  @override
  void initState() {
    super.initState();
    _loadUtilityData();
  }

  Future<void> _loadUtilityData() async {
    try {
      final results = await Future.wait([
        UtilityService.getEnergyUsageSummary(period: 'month'),
        UtilityService.getWaterUsageSummary(period: 'month'),
        UtilityService.getEnergyUsageTrend(days: 7),
        UtilityService.getWaterUsageTrend(days: 7),
        UtilityService.getEnergyEfficiencyScore(),
        UtilityService.getWaterEfficiencyScore(),
      ]);
      if (!mounted) return;
      setState(() {
        _energySummary = results[0] as EnergyUsageSummary?;
        _waterSummary = results[1] as WaterUsageSummary?;
        _energyTrend = results[2] as List<UtilityTrendPoint>;
        _waterTrend = results[3] as List<UtilityTrendPoint>;
        _energyScore = results[4] as UtilityEfficiencyScore?;
        _waterScore = results[5] as UtilityEfficiencyScore?;
      });
    } catch (_) {}
  }
  // ---------------------------------------------------------------------------
  // MOCK DATA
  // ---------------------------------------------------------------------------

  final List<_UsageBreakdown> electricityBreakdown = const [
    _UsageBreakdown('อาคารเรียน 1', '5,200 kWh', 1.0, AppPalette.primaryPink),
    _UsageBreakdown('อาคารเรียน 2', '4,850 kWh', 0.93, AppPalette.chartPink2),
    _UsageBreakdown('อาคารเรียน 3', '3,900 kWh', 0.75, AppPalette.learningBlue),
    _UsageBreakdown('โรงอาหาร', '2,300 kWh', 0.44, AppPalette.chartCream),
    _UsageBreakdown('หอประชุม / ห้องปฏิบัติการ', '1,600 kWh', 0.31,
        AppPalette.environmentGreen),
    _UsageBreakdown('ไฟสนาม / ส่วนกลาง', '600 kWh', 0.12, AppPalette.behaviorYellow),
  ];

  final List<_UsageBreakdown> waterBreakdown = const [
    _UsageBreakdown('อาคารเรียน / ห้องน้ำ', '260 ลบ.ม.', 1.0, AppPalette.learningBlue),
    _UsageBreakdown('โรงอาหาร', '150 ลบ.ม.', 0.58, AppPalette.chartPink2),
    _UsageBreakdown('สนามกีฬา / รดน้ำต้นไม้', '120 ลบ.ม.', 0.46,
        AppPalette.environmentGreen),
    _UsageBreakdown('ส่วนกลาง / อื่น ๆ', '110 ลบ.ม.', 0.42, AppPalette.chartCream),
  ];

  final List<_EnvRecommendation> recommendations = const [
    _EnvRecommendation(
      icon: Icons.ac_unit_rounded,
      title: 'ปรับเวลาเปิด-ปิดเครื่องปรับอากาศอาคาร 2',
      detail:
          'AI พบว่าอาคาร 2 เปิดแอร์ก่อนเข้าเรียน 40 นาที ตั้งเวลาอัตโนมัติช่วยลดหน่วยไฟช่วงเช้าได้',
      saving: 'ประหยัด ~4,200 บาท/เดือน',
      color: AppPalette.learningBlue,
    ),
    _EnvRecommendation(
      icon: Icons.water_damage_rounded,
      title: 'ตรวจสอบจุดน้ำรั่วบริเวณห้องน้ำอาคาร 1',
      detail:
          'อัตราการใช้น้ำกลางคืนสูงผิดปกติต่อเนื่อง 3 คืน คาดว่ามีการรั่วซึมที่ควรตรวจสอบ',
      saving: 'ลดการสูญเสีย ~1,800 บาท/เดือน',
      color: AppPalette.primaryPink,
    ),
    _EnvRecommendation(
      icon: Icons.lightbulb_rounded,
      title: 'เปลี่ยนหลอดไฟโรงอาหารเป็น LED',
      detail:
          'โซนโรงอาหารยังใช้หลอดฟลูออเรสเซนต์ การเปลี่ยนเป็น LED ลดการใช้ไฟลงประมาณ 45%',
      saving: 'คืนทุนภายใน ~8 เดือน',
      color: AppPalette.behaviorYellow,
    ),
  ];

  final List<_SensorReading> sensors = const [
    _SensorReading(
      icon: Icons.thermostat_rounded,
      name: 'อุณหภูมิ',
      value: '31',
      unit: '°C',
      status: 'เฝ้าระวัง',
      statusColor: AppPalette.warning,
      location: 'เฉลี่ยห้องเรียน',
      detail: 'ความชื้นสัมพัทธ์ 62%',
    ),
    _SensorReading(
      icon: Icons.blur_on_rounded,
      name: 'ฝุ่น PM2.5',
      value: '38',
      unit: 'µg/m³',
      status: 'ปานกลาง',
      statusColor: AppPalette.warning,
      location: 'ลานกลางแจ้ง',
      detail: 'PM10 อยู่ที่ 62 µg/m³',
    ),
    _SensorReading(
      icon: Icons.light_mode_rounded,
      name: 'ความเข้มแสง',
      value: '480',
      unit: 'lux',
      status: 'เหมาะสม',
      statusColor: AppPalette.success,
      location: 'ห้องเรียนเฉลี่ย',
      detail: 'มาตรฐาน 300 - 500 lux',
    ),
    _SensorReading(
      icon: Icons.local_fire_department_rounded,
      name: 'แก๊ส & ควัน',
      value: 'ปกติ',
      unit: '',
      status: 'ปลอดภัย',
      statusColor: AppPalette.success,
      location: 'โรงอาหาร / ห้องแล็บ',
      detail: 'LPG 0 ppm • ไม่พบควัน',
    ),
    _SensorReading(
      icon: Icons.co2_rounded,
      name: 'CO₂',
      value: '720',
      unit: 'ppm',
      status: 'ปกติ',
      statusColor: AppPalette.success,
      location: 'เฉลี่ยห้องเรียน',
      detail: 'ต่ำกว่าเกณฑ์ 1,000 ppm',
    ),
    _SensorReading(
      icon: Icons.air_rounded,
      name: 'คุณภาพอากาศรวม (AQI)',
      value: '72',
      unit: 'AQI',
      status: 'ปานกลาง',
      statusColor: AppPalette.warning,
      location: 'ทั้งโรงเรียน',
      detail: 'กลุ่มเสี่ยงควรลดกิจกรรมกลางแจ้ง',
    ),
  ];

  final List<_ZoneAir> zones = const [
    _ZoneAir('อาคารเรียน 1', '34', '690', '30°C', 'ดี', AppPalette.success),
    _ZoneAir('อาคารเรียน 2', '41', '780', '32°C', 'ปานกลาง', AppPalette.warning),
    _ZoneAir('อาคารเรียน 3', '45', '810', '31°C', 'ปานกลาง', AppPalette.warning),
    _ZoneAir('โรงอาหาร', '52', '950', '33°C', 'ควรระวัง', AppPalette.danger),
    _ZoneAir('ห้องปฏิบัติการ', '29', '640', '28°C', 'ดี', AppPalette.success),
  ];

  final List<_RateRef> electricityRates = const [
    _RateRef('ประเภทผู้ใช้', 'สถานศึกษา / กิจการขนาดกลาง'),
    _RateRef('ค่าพลังงานไฟฟ้า', '4.1839 บาท/หน่วย'),
    _RateRef('ค่า Ft (งวดปัจจุบัน)', '0.3972 บาท/หน่วย'),
    _RateRef('ค่าบริการรายเดือน', '312.24 บาท'),
    _RateRef('ภาษีมูลค่าเพิ่ม', '7%'),
  ];

  final List<_RateRef> waterRates = const [
    _RateRef('ประเภทผู้ใช้', 'ราชการ / ธุรกิจขนาดกลาง'),
    _RateRef('อัตราค่าน้ำ (แบบขั้นบันได)', '16.00 - 21.50 บาท/ลบ.ม.'),
    _RateRef('ค่าบริการรายเดือน', '90.00 บาท'),
    _RateRef('ค่าน้ำดิบ / บำบัด', 'รวมในบิล'),
    _RateRef('ภาษีมูลค่าเพิ่ม', '7%'),
  ];

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'สิ่งแวดล้อมและทรัพยากรโรงเรียน',
            subtitle:
                'ติดตามการใช้น้ำ ใช้ไฟ ค่าใช้จ่ายโดยประมาณ พร้อมการคาดการณ์ด้วย AI และคุณภาพสิ่งแวดล้อมภายในโรงเรียนแบบเรียลไทม์',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _aiInsightCard(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final electricity = _utilityCard(
                title: 'การใช้ไฟฟ้า',
                subtitle: 'เดือนนี้ (1 - 21 ส.ค. 2569)',
                icon: Icons.bolt_rounded,
                color: AppPalette.behaviorYellow,
                usage: '18,450',
                usageUnit: 'kWh',
                estCost: '82,150',
                trendText: '+6.2% จากเดือนก่อน',
                trendUp: true,
                breakdown: electricityBreakdown,
                onTap: () => _showElectricityDetail(context),
              );

              final water = _utilityCard(
                title: 'การใช้น้ำ',
                subtitle: 'เดือนนี้ (1 - 21 ส.ค. 2569)',
                icon: Icons.water_drop_rounded,
                color: AppPalette.learningBlue,
                usage: '640',
                usageUnit: 'ลบ.ม.',
                estCost: '12,880',
                trendText: '-3.1% จากเดือนก่อน',
                trendUp: false,
                breakdown: waterBreakdown,
                onTap: () => _showWaterDetail(context),
              );

              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    electricity,
                    const SizedBox(height: 16),
                    water,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: electricity),
                    const SizedBox(width: 16),
                    Expanded(child: water),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _airQualitySection(),
          const SizedBox(height: 16),
          _rateReferenceCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY CARDS
  // ---------------------------------------------------------------------------

  Widget _summaryCards() {
    const items = [
      _EnvSummary(
        title: 'ค่าไฟเดือนนี้ (ประมาณ)',
        value: '฿82,150',
        subtitle: 'ณ วันที่ 21',
        icon: Icons.bolt_rounded,
        color: AppPalette.softCream,
      ),
      _EnvSummary(
        title: 'ค่าน้ำเดือนนี้ (ประมาณ)',
        value: '฿12,880',
        subtitle: 'ณ วันที่ 21',
        icon: Icons.water_drop_rounded,
        color: AppPalette.softBlue,
      ),
      _EnvSummary(
        title: 'ใช้ไฟฟ้า',
        value: '18,450',
        subtitle: 'kWh',
        icon: Icons.electric_meter_rounded,
        color: AppPalette.softPink,
      ),
      _EnvSummary(
        title: 'ใช้น้ำ',
        value: '640',
        subtitle: 'ลบ.ม.',
        icon: Icons.opacity_rounded,
        color: AppPalette.softMint,
      ),
      _EnvSummary(
        title: 'PM2.5 เฉลี่ย',
        value: '38',
        subtitle: 'ปานกลาง',
        icon: Icons.blur_on_rounded,
        color: AppPalette.softPink2,
      ),
      _EnvSummary(
        title: 'CO₂ เฉลี่ย',
        value: '720',
        subtitle: 'ppm • ปกติ',
        icon: Icons.co2_rounded,
        color: AppPalette.softTag,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;
        if (constraints.maxWidth < 700) {
          columns = 2;
        } else if (constraints.maxWidth < 1120) {
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
            mainAxisExtent: columns == 2 ? 126 : 116,
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
                      color: AppPalette.tint(Colors.white, 0.82),
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
                      fontSize: 9.2,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.2,
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

  // ---------------------------------------------------------------------------
  // AI INSIGHT CARD
  // ---------------------------------------------------------------------------

  Widget _aiInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF3FC), Color(0xFFFBEDF3)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.tint(Colors.black, 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.border),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppPalette.primaryPink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI คาดการณ์ค่าใช้จ่ายสิ้นเดือน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ประเมินจากการใช้งานปัจจุบัน + ประวัติย้อนหลัง 12 เดือน',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppPalette.border),
                ),
                child: const Text(
                  'ความมั่นใจ 92%',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.primaryPinkDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;

              final estimates = [
                _aiEstimateBox(
                  'ค่าไฟคาดการณ์',
                  '฿118,400',
                  '+6.2%',
                  AppPalette.danger,
                ),
                _aiEstimateBox(
                  'ค่าน้ำคาดการณ์',
                  '฿18,600',
                  '-3.1%',
                  AppPalette.success,
                ),
                _aiEstimateBox(
                  'รวมทั้งหมด',
                  '฿137,000',
                  'สิ้นเดือน',
                  AppPalette.textMuted,
                ),
              ];

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < estimates.length; i++) ...[
                      estimates[i],
                      if (i != estimates.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < estimates.length; i++) ...[
                    Expanded(child: estimates[i]),
                    if (i != estimates.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'คำแนะนำจาก AI เพื่อลดค่าใช้จ่าย',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 10),
          ...recommendations.map(_recommendationTile),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppPalette.tint(Colors.white, 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppPalette.textMuted,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'ตัวเลขเป็นการคาดคะเนค่าใช้จ่ายเบื้องต้น คำนวณจากปริมาณการใช้ไฟฟ้าและน้ำ '
                    'ในปัจจุบัน ร่วมกับอัตราค่าบริการและประวัติการใช้ย้อนหลัง 12 เดือน '
                    'จึงอาจคลาดเคลื่อนจากบิลจริง',
                    style: TextStyle(
                      fontSize: 8.6,
                      height: 1.5,
                      color: AppPalette.textMuted,
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

  Widget _aiEstimateBox(
    String label,
    String value,
    String tag,
    Color tagColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tag,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: tagColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationTile(_EnvRecommendation item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.tint(item.color, 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.4,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(item.color, 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.saving,
                    style: TextStyle(
                      fontSize: 8.6,
                      fontWeight: FontWeight.w800,
                      color: item.color,
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

  // ---------------------------------------------------------------------------
  // UTILITY (ELECTRICITY / WATER) CARD
  // ---------------------------------------------------------------------------

  Widget _utilityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String usage,
    required String usageUnit,
    required String estCost,
    required String trendText,
    required bool trendUp,
    required List<_UsageBreakdown> breakdown,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppPalette.tint(color, 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
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
              if (onTap != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(color, 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          fontSize: 8.6,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 14, color: color),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                usage,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  usageUnit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.tint(
                    trendUp ? AppPalette.danger : AppPalette.success,
                    0.10,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: trendUp ? AppPalette.danger : AppPalette.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 8.6,
                        fontWeight: FontWeight.w700,
                        color: trendUp ? AppPalette.danger : AppPalette.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppPalette.tint(color, 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 18, color: color),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'ค่าใช้จ่ายโดยประมาณ (รวม Ft + VAT)',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '฿$estCost',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'สัดส่วนการใช้งานตามพื้นที่',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...breakdown.map((row) => _usageRow(row, color)),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: card,
    );
  }

  Widget _usageRow(_UsageBreakdown row, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                row.value,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: row.progress,
              minHeight: 7,
              backgroundColor: AppPalette.softTag,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ELECTRICITY DETAIL (แตะการ์ดการใช้ไฟเพื่อดูรายละเอียด)
  // ---------------------------------------------------------------------------

  void _showElectricityDetail(BuildContext context) {
    _showUtilityDetail(
      context,
      title: 'การใช้ไฟฟ้า • รายละเอียด',
      headerIcon: Icons.bolt_rounded,
      color: AppPalette.behaviorYellow,
      breakdown: electricityBreakdown,
      avgDay: '879',
      avgDaySub: 'kWh/วัน',
      avgWeek: '6,150',
      avgWeekSub: 'kWh/สัปดาห์',
      peakTime: '13.50',
      peakSub: 'น. • 910 kWh',
      topLabel: 'อาคารที่ใช้ไฟมากที่สุด',
      topName: 'อาคารเรียน 1',
      topValue: '5,200 kWh',
      topShare: '~28% ของทั้งหมด',
      weeklyTitle: 'การใช้ไฟ 7 วันล่าสุด',
      weeklySubtitle: 'หน่วย kWh ต่อวัน • เฉลี่ย ~880 kWh/วัน',
      hourlyTitle: 'การใช้ไฟรายชั่วโมงวันนี้',
      hourlySubtitle: 'หน่วย kWh ต่อชั่วโมง',
      peakNote: 'ใช้ไฟสูงสุดช่วง 13.50 น. (910 kWh) — ตรงกับช่วงเปิดแอร์บ่าย',
      rankTitle: 'อันดับพื้นที่ใช้ไฟสูงสุด',
      note: 'หมายเหตุ: ข้อมูลจากมิเตอร์อัจฉริยะแยกอาคาร ตัวเลขค่าใช้จ่ายเป็นการ'
          'คาดคะเนเบื้องต้นจากหน่วยการใช้จริง × อัตราค่าไฟ + Ft + VAT',
      weekly: const [
        _BarData('จ', 820),
        _BarData('อ', 910),
        _BarData('พ', 880),
        _BarData('พฤ', 950),
        _BarData('ศ', 1020),
        _BarData('ส', 540, muted: true),
        _BarData('อา', 430, muted: true),
      ],
      hourly: const [
        _BarData('08', 520),
        _BarData('09', 680),
        _BarData('10', 720),
        _BarData('11', 760),
        _BarData('12', 690),
        _BarData('13', 880),
        _BarData('14', 910, highlight: true),
        _BarData('15', 840),
        _BarData('16', 600),
        _BarData('17', 380),
        _BarData('18', 220),
      ],
    );
  }

  void _showWaterDetail(BuildContext context) {
    _showUtilityDetail(
      context,
      title: 'การใช้น้ำ • รายละเอียด',
      headerIcon: Icons.water_drop_rounded,
      color: AppPalette.learningBlue,
      breakdown: waterBreakdown,
      avgDay: '30.5',
      avgDaySub: 'ลบ.ม./วัน',
      avgWeek: '213',
      avgWeekSub: 'ลบ.ม./สัปดาห์',
      peakTime: '12.10',
      peakSub: 'น. • ช่วงพักเที่ยง',
      topLabel: 'พื้นที่ใช้น้ำมากที่สุด',
      topName: 'อาคารเรียน / ห้องน้ำ',
      topValue: '260 ลบ.ม.',
      topShare: '~41% ของทั้งหมด',
      weeklyTitle: 'การใช้น้ำ 7 วันล่าสุด',
      weeklySubtitle: 'หน่วย ลบ.ม. ต่อวัน • เฉลี่ย ~30 ลบ.ม./วัน',
      hourlyTitle: 'การใช้น้ำรายชั่วโมงวันนี้',
      hourlySubtitle: 'หน่วย ลบ.ม. ต่อชั่วโมง (โดยประมาณ)',
      peakNote: 'ใช้น้ำสูงสุดช่วง 12.10 น. — ช่วงพักกลางวันที่โรงอาหารและห้องน้ำ',
      rankTitle: 'อันดับพื้นที่ใช้น้ำสูงสุด',
      note: 'หมายเหตุ: ข้อมูลจากมิเตอร์น้ำแยกโซน ตัวเลขค่าใช้จ่ายเป็นการ'
          'คาดคะเนเบื้องต้นจากหน่วยการใช้จริง × อัตราค่าน้ำ + ค่าบริการ + VAT',
      weekly: const [
        _BarData('จ', 32),
        _BarData('อ', 34),
        _BarData('พ', 31),
        _BarData('พฤ', 35),
        _BarData('ศ', 36),
        _BarData('ส', 18, muted: true),
        _BarData('อา', 12, muted: true),
      ],
      hourly: const [
        _BarData('08', 3),
        _BarData('09', 3),
        _BarData('10', 4),
        _BarData('11', 4),
        _BarData('12', 6, highlight: true),
        _BarData('13', 4),
        _BarData('14', 3),
        _BarData('15', 3),
        _BarData('16', 2),
        _BarData('17', 2),
        _BarData('18', 1),
      ],
    );
  }

  void _showUtilityDetail(
    BuildContext context, {
    required String title,
    required IconData headerIcon,
    required Color color,
    required List<_BarData> weekly,
    required List<_BarData> hourly,
    required List<_UsageBreakdown> breakdown,
    required String avgDay,
    required String avgDaySub,
    required String avgWeek,
    required String avgWeekSub,
    required String peakTime,
    required String peakSub,
    required String topLabel,
    required String topName,
    required String topValue,
    required String topShare,
    required String weeklyTitle,
    required String weeklySubtitle,
    required String hourlyTitle,
    required String hourlySubtitle,
    required String peakNote,
    required String rankTitle,
    required String note,
  }) {
    final ranked = [...breakdown]
      ..sort((a, b) => b.progress.compareTo(a.progress));

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(color, 0.14),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          headerIcon,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'ข้อมูลเชิงลึกประจำเดือน • อัปเดต 21 ส.ค. 2569',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final boxes = [
                                _statBox(
                                  Icons.calendar_today_rounded,
                                  'ค่าเฉลี่ยต่อวัน',
                                  avgDay,
                                  avgDaySub,
                                  color,
                                ),
                                _statBox(
                                  Icons.date_range_rounded,
                                  'ค่าเฉลี่ยต่อสัปดาห์',
                                  avgWeek,
                                  avgWeekSub,
                                  AppPalette.environmentGreen,
                                ),
                                _statBox(
                                  Icons.schedule_rounded,
                                  'ช่วงใช้งานสูงสุด',
                                  peakTime,
                                  peakSub,
                                  AppPalette.primaryPink,
                                ),
                              ];

                              if (constraints.maxWidth < 560) {
                                return Column(
                                  children: [
                                    for (int i = 0; i < boxes.length; i++) ...[
                                      boxes[i],
                                      if (i != boxes.length - 1)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  for (int i = 0; i < boxes.length; i++) ...[
                                    Expanded(child: boxes[i]),
                                    if (i != boxes.length - 1)
                                      const SizedBox(width: 10),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppPalette.tint(color, 0.09),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppPalette.tint(color, 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events_rounded,
                                    color: color,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topLabel,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppPalette.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        topName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      topValue,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      topShare,
                                      style: const TextStyle(
                                        fontSize: 8.6,
                                        color: AppPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _chartCard(
                            weeklyTitle,
                            weeklySubtitle,
                            weekly,
                            color,
                          ),
                          const SizedBox(height: 14),
                          _chartCard(
                            hourlyTitle,
                            hourlySubtitle,
                            hourly,
                            color,
                            peakNote: peakNote,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            rankTitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (int i = 0; i < ranked.length; i++)
                            _rankRow(i + 1, ranked[i]),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.tint(AppPalette.primaryPink, 0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              note,
                              style: const TextStyle(
                                fontSize: 8.8,
                                height: 1.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _statBox(
    IconData icon,
    String label,
    String value,
    String sub,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppPalette.tint(color, 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 8.2,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    String title,
    String subtitle,
    List<_BarData> bars,
    Color color, {
    String? peakNote,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 12),
          _barChart(bars, color),
          if (peakNote != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.push_pin_rounded,
                  size: 13,
                  color: AppPalette.primaryPink,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    peakNote,
                    style: const TextStyle(
                      fontSize: 8.8,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.primaryPinkDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _barChart(List<_BarData> bars, Color color) {
    final maxVal = bars
        .map((b) => b.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${bar.value}',
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: bar.highlight
                            ? AppPalette.primaryPinkDark
                            : AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: (bar.value / maxVal) * 96,
                      decoration: BoxDecoration(
                        color: bar.highlight
                            ? AppPalette.primaryPink
                            : (bar.muted
                                ? AppPalette.tint(color, 0.4)
                                : color),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bar.label,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight:
                            bar.highlight ? FontWeight.w800 : FontWeight.w600,
                        color: bar.highlight
                            ? AppPalette.primaryPinkDark
                            : AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rankRow(int rank, _UsageBreakdown row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppPalette.primaryPink
                  : AppPalette.tint(AppPalette.primaryPink, 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: rank == 1 ? Colors.white : AppPalette.primaryPinkDark,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AIR QUALITY SECTION
  // ---------------------------------------------------------------------------

  Widget _airQualitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'คุณภาพสิ่งแวดล้อมภายในโรงเรียน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ข้อมูลจากเซ็นเซอร์ IoT อุณหภูมิ ฝุ่น PM แสง แก๊ส/ควัน และ CO₂ อัปเดตทุก 1 นาที',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 3;
              if (constraints.maxWidth < 560) {
                columns = 2;
              } else if (constraints.maxWidth < 900) {
                columns = 3;
              }

              return GridView.builder(
                itemCount: sensors.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 138,
                ),
                itemBuilder: (context, index) {
                  return _sensorCard(sensors[index]);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'เปรียบเทียบตามพื้นที่',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'PM2.5 (µg/m³) • CO₂ (ppm) • อุณหภูมิ',
            style: TextStyle(fontSize: 9, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 10),
          _zoneHeaderRow(),
          const SizedBox(height: 4),
          ...zones.map(_zoneRow),
        ],
      ),
    );
  }

  Widget _sensorCard(_SensorReading sensor) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.tint(sensor.statusColor, 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(sensor.icon, size: 18, color: sensor.statusColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.tint(sensor.statusColor, 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sensor.status,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: sensor.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            sensor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  sensor.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (sensor.unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    sensor.unit,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sensor.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _zoneHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: const [
          Expanded(
            flex: 4,
            child: Text(
              'พื้นที่',
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PM2.5',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CO₂',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'อุณหภูมิ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'สถานะ',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneRow(_ZoneAir zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.tint(zone.color, 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.tint(zone.color, 0.13)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              zone.zone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              zone.pm25,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              zone.co2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              zone.temp,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.tint(zone.color, 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  zone.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: zone.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RATE REFERENCE CARD
  // ---------------------------------------------------------------------------

  Widget _rateReferenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.tint(AppPalette.primaryPink, 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: AppPalette.primaryPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อ้างอิงการคำนวณค่าใช้จ่าย',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'อัตราที่ AI ใช้ประมาณการค่าน้ำ-ค่าไฟ',
                      style: TextStyle(fontSize: 9.5, color: AppPalette.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final electric = _rateBlock(
                'อัตราค่าไฟฟ้า',
                Icons.bolt_rounded,
                AppPalette.behaviorYellow,
                electricityRates,
              );
              final water = _rateBlock(
                'อัตราค่าน้ำประปา',
                Icons.water_drop_rounded,
                AppPalette.learningBlue,
                waterRates,
              );

              if (constraints.maxWidth < 720) {
                return Column(
                  children: [
                    electric,
                    const SizedBox(height: 12),
                    water,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: electric),
                  const SizedBox(width: 12),
                  Expanded(child: water),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.tint(AppPalette.primaryPink, 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'หมายเหตุ: ค่าใช้จ่ายเป็นการประมาณการเบื้องต้นจากอัตราปัจจุบันและอาจต่างจากบิลจริง '
              'AI คำนวณจากหน่วยการใช้งานสะสม × อัตราตามขั้น + ค่า Ft + ค่าบริการ + VAT 7% '
              'และปรับด้วยแนวโน้มการใช้งานย้อนหลังของโรงเรียน',
              style: TextStyle(
                fontSize: 8.8,
                height: 1.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateBlock(
    String title,
    IconData icon,
    Color color,
    List<_RateRef> rates,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rates.map(
            (rate) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      rate.label,
                      style: const TextStyle(
                        fontSize: 8.8,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Text(
                      rate.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------

class _EnvSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _EnvSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _UsageBreakdown {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _UsageBreakdown(this.label, this.value, this.progress, this.color);
}

class _EnvRecommendation {
  final IconData icon;
  final String title;
  final String detail;
  final String saving;
  final Color color;

  const _EnvRecommendation({
    required this.icon,
    required this.title,
    required this.detail,
    required this.saving,
    required this.color,
  });
}

class _SensorReading {
  final IconData icon;
  final String name;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final String location;
  final String detail;

  const _SensorReading({
    required this.icon,
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.location,
    required this.detail,
  });
}

class _ZoneAir {
  final String zone;
  final String pm25;
  final String co2;
  final String temp;
  final String status;
  final Color color;

  const _ZoneAir(
    this.zone,
    this.pm25,
    this.co2,
    this.temp,
    this.status,
    this.color,
  );
}

class _RateRef {
  final String label;
  final String value;

  const _RateRef(this.label, this.value);
}

class _BarData {
  final String label;
  final int value;
  final bool highlight;
  final bool muted;

  const _BarData(
    this.label,
    this.value, {
    this.highlight = false,
    this.muted = false,
  });
}
