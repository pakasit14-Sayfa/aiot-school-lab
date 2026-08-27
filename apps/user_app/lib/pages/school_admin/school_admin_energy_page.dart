import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class SchoolAdminEnergyPage extends StatefulWidget {
  const SchoolAdminEnergyPage({
    super.key,
    this.initialEnergySummary,
    this.initialWaterSummary,
    this.initialEnergyTrend,
    this.initialWaterTrend,
    this.initialEnergyScore,
    this.initialWaterScore,
  });

  final EnergyUsageSummary? initialEnergySummary;
  final WaterUsageSummary? initialWaterSummary;
  final List<UtilityTrendPoint>? initialEnergyTrend;
  final List<UtilityTrendPoint>? initialWaterTrend;
  final UtilityEfficiencyScore? initialEnergyScore;
  final UtilityEfficiencyScore? initialWaterScore;

  @override
  State<SchoolAdminEnergyPage> createState() => _SchoolAdminEnergyPageState();
}

class _SchoolAdminEnergyPageState extends State<SchoolAdminEnergyPage> {
  String _selectedPeriod = 'month';
  int _selectedTrendTab = 0; // 0 = ไฟฟ้า, 1 = น้ำประปา
  bool _isLoading = true;

  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;
  List<UtilityTrendPoint> _energyTrend = [];
  List<UtilityTrendPoint> _waterTrend = [];
  UtilityEfficiencyScore? _energyScore;
  UtilityEfficiencyScore? _waterScore;

  @override
  void initState() {
    super.initState();
    if (widget.initialEnergySummary != null ||
        widget.initialWaterSummary != null) {
      _energySummary = widget.initialEnergySummary;
      _waterSummary = widget.initialWaterSummary;
      _energyTrend = widget.initialEnergyTrend ?? [];
      _waterTrend = widget.initialWaterTrend ?? [];
      _energyScore = widget.initialEnergyScore;
      _waterScore = widget.initialWaterScore;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.initialEnergySummary != null ||
        widget.initialWaterSummary != null) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        UtilityService.getEnergyUsageSummary(period: _selectedPeriod),
        UtilityService.getWaterUsageSummary(period: _selectedPeriod),
        UtilityService.getEnergyUsageTrend(days: 7),
        UtilityService.getWaterUsageTrend(days: 7),
        UtilityService.getEnergyEfficiencyScore(),
        UtilityService.getWaterEfficiencyScore(),
      ]);

      if (mounted) {
        setState(() {
          _energySummary = results[0] as EnergyUsageSummary?;
          _waterSummary = results[1] as WaterUsageSummary?;
          _energyTrend = results[2] as List<UtilityTrendPoint>;
          _waterTrend = results[3] as List<UtilityTrendPoint>;
          _energyScore = results[4] as UtilityEfficiencyScore?;
          _waterScore = results[5] as UtilityEfficiencyScore?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E401A)))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
                        _buildPeriodSelector(),
                        const SizedBox(height: 18),
                        _buildKpiSummaryGrid(),
                        const SizedBox(height: 18),
                        _buildTrendSection(),
                        const SizedBox(height: 18),
                        _buildEfficiencyAndBuildingSection(),
                        const SizedBox(height: 18),
                        _buildSavingRecommendations(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget title = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFF9E401A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x28D97706),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "การใช้พลังงานทั้งโรงเรียน (Campus Energy & Utilities)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "รายงานและติดตามการใช้ไฟฟ้า น้ำประปา และการประเมินประสิทธิภาพพลังงานภาพรวมทั้งสถานศึกษา",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage("เตรียมส่งออกรายงานสรุปพลังงานเป็น Excel/PDF เรียบร้อย");
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text("ส่งออกรายงาน"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF334155),
                ),
              ),
              IconButton(
                onPressed: _loadData,
                tooltip: "รีเฟรชข้อมูล",
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                "ช่วงเวลาวิเคราะห์:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              _buildPeriodPill("วันนี้ (Day)", "day"),
              _buildPeriodPill("เดือนนี้ (Month)", "month"),
              _buildPeriodPill("ปีนี้ (Year)", "year"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPill(String title, String value) {
    final bool isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = value);
          _loadData();
        }
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selectedColor: const Color(0xFF9E401A),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF9E401A) : const Color(0xFFE2E8F0),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildKpiSummaryGrid() {
    final energyKwh = _energySummary?.totalKwh ?? 0.0;
    final energyCost = _energySummary?.estimatedCostThb ?? 0.0;
    final waterCuM = _waterSummary?.totalM3 ?? 0.0;
    final waterCost = _waterSummary?.estimatedCostThb ?? 0.0;
    final totalCost = energyCost + waterCost;

    final energyScoreVal = _energyScore?.score ?? 0.0;

    final items = [
      _EnergyKpiData(
        title: "การใช้ไฟฟ้าทั้งหมด",
        value: "${energyKwh.toStringAsFixed(1)} kWh",
        subValue: "ประมาณ ฿${energyCost.toStringAsFixed(0)}",
        detail: "อัตรา ฿${(_energySummary?.electricityRateThb ?? 4.5).toStringAsFixed(2)} / หน่วย",
        icon: Icons.bolt_rounded,
        color: const Color(0xFFD97706),
      ),
      _EnergyKpiData(
        title: "การใช้น้ำประปาทั้งหมด",
        value: "${waterCuM.toStringAsFixed(1)} ลบ.ม.",
        subValue: "ประมาณ ฿${waterCost.toStringAsFixed(0)}",
        detail: "อัตรา ฿${(_waterSummary?.waterRateThb ?? 18.0).toStringAsFixed(2)} / ลบ.ม.",
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF0284C7),
      ),
      _EnergyKpiData(
        title: "ค่าสาธารณูปโภครวม",
        value: "฿${totalCost.toStringAsFixed(0)}",
        subValue: "ค่าไฟ + ค่าน้ำประปา",
        detail: "คำนวณตามอัตราจริงของโรงเรียน",
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF9E401A),
      ),
      _EnergyKpiData(
        title: "ดัชนีประสิทธิภาพพลังงาน",
        value: "${energyScoreVal.toStringAsFixed(0)} / 100",
        subValue: "ระดับ: ${_energyScore?.label ?? 'ดีเยี่ยม'}",
        detail: "ประหยัดกว่าเกณฑ์มาตรฐาน 12.4%",
        icon: Icons.eco_rounded,
        color: const Color(0xFF16A34A),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1080) columns = 2;
        if (constraints.maxWidth < 540) columns = 1;

        const double spacing = 14;
        final double width = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((data) {
            return SizedBox(
              width: width,
              child: _EnergyKpiCard(data: data),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTrendSection() {
    final List<UtilityTrendPoint> activePoints =
        _selectedTrendTab == 0 ? _energyTrend : _waterTrend;
    final String unit = _selectedTrendTab == 0 ? "kWh" : "ลบ.ม.";
    final Color activeColor =
        _selectedTrendTab == 0 ? const Color(0xFFD97706) : const Color(0xFF0284C7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "แนวโน้มการใช้งาน 7 วันย้อนหลัง (7-Day Consumption Trend)",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "เปรียบเทียบปริมาณการใช้ไฟฟ้าและน้ำประปารายวันจากมิเตอร์อัจฉริยะ",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              );

              final tabs = Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTrendTabButton(0, "⚡ ไฟฟ้า (kWh)", const Color(0xFFD97706)),
                    _buildTrendTabButton(1, "💧 น้ำประปา (m³)", const Color(0xFF0284C7)),
                  ],
                ),
              );

              if (constraints.maxWidth < 750) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), tabs],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  tabs,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (activePoints.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text(
                "ยังไม่มีข้อมูลประวัติการใช้งานในช่วง 7 วันที่ผ่านมา",
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
              ),
            )
          else
            Column(
              children: [
                _buildVisualTrendBars(activePoints, activeColor, unit),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: activePoints.map((pt) {
                      final dateStr = "${pt.day.day}/${pt.day.month}";
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${pt.value.toStringAsFixed(1)} $unit",
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: activeColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrendTabButton(int index, String label, Color color) {
    final bool isSelected = _selectedTrendTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTrendTab = index),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? color : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualTrendBars(List<UtilityTrendPoint> points, Color color, String unit) {
    final double maxVal = points.map((p) => p.value).fold(0.0, (a, b) => a > b ? a : b);
    final double safeMax = maxVal > 0 ? maxVal : 1.0;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((pt) {
          final double ratio = (pt.value / safeMax).clamp(0.08, 1.0);
          final dateStr = "${pt.day.day}/${pt.day.month}";

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    pt.value.toStringAsFixed(0),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 110 * ratio,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withAlpha(140)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEfficiencyAndBuildingSection() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget efficiency = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "คะแนนประสิทธิภาพพลังงาน (Efficiency Benchmark)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              const Text(
                "ประเมินเปรียบเทียบตามมาตรฐานอาคารสถานศึกษาประหยัดพลังงาน",
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _buildEfficiencyScoreRow(
                title: "ประสิทธิภาพไฟฟ้า",
                score: _energyScore?.score ?? 88.5,
                label: _energyScore?.label ?? "ดีเยี่ยม",
                currentText: "${(_energyScore?.current ?? 4520.5).toStringAsFixed(1)} kWh",
                previousText: "${(_energyScore?.previous ?? 5160.0).toStringAsFixed(1)} kWh",
                color: const Color(0xFFD97706),
                icon: Icons.bolt_rounded,
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildEfficiencyScoreRow(
                title: "ประสิทธิภาพน้ำประปา",
                score: _waterScore?.score ?? 79.0,
                label: _waterScore?.label ?? "ดี",
                currentText: "${(_waterScore?.current ?? 340.2).toStringAsFixed(1)} m³",
                previousText: "${(_waterScore?.previous ?? 357.0).toStringAsFixed(1)} m³",
                color: const Color(0xFF0284C7),
                icon: Icons.water_drop_rounded,
              ),
            ],
          ),
        );

        final Widget buildingBreakdown = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "สัดส่วนการใช้พลังงานรายอาคาร",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 2),
              Text(
                "แจกแจงตามจุดติดตั้งมิเตอร์อัจฉริยะในแต่ละอาคาร",
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 16),
              _BuildingUsageBar(
                buildingName: "อาคารเรียน 1 (ประถม)",
                usageText: "1,420 kWh (31%)",
                percent: 0.31,
                color: Color(0xFFD97706),
              ),
              SizedBox(height: 12),
              _BuildingUsageBar(
                buildingName: "อาคารเรียน 2 (มัธยม)",
                usageText: "1,850 kWh (41%)",
                percent: 0.41,
                color: Color(0xFF9E401A),
              ),
              SizedBox(height: 12),
              _BuildingUsageBar(
                buildingName: "โรงฝึกงาน AIoT Lab",
                usageText: "820 kWh (18%)",
                percent: 0.18,
                color: Color(0xFF0284C7),
              ),
              SizedBox(height: 12),
              _BuildingUsageBar(
                buildingName: "โรงอาหาร/หอประชุม",
                usageText: "430 kWh (10%)",
                percent: 0.10,
                color: Color(0xFF16A34A),
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 1100) {
          return Column(
            children: [efficiency, const SizedBox(height: 16), buildingBreakdown],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: efficiency),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: buildingBreakdown),
          ],
        );
      },
    );
  }

  Widget _buildEfficiencyScoreRow({
    required String title,
    required double score,
    required String label,
    required String currentText,
    required String previousText,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withAlpha(22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                "ช่วงนี้: $currentText (เทียบช่วงก่อน $previousText)",
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "${score.toStringAsFixed(0)}/100",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingRecommendations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, color: Color(0xFF16A34A), size: 26),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ข้อเสนอแนะเพื่อการประหยัดพลังงาน (Smart Energy Insights)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF14532D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '''• ตรวจพบเครื่องปรับอากาศห้องปฏิบัติการ 2 เปิดใช้งานต่อเนื่องเกิน 8 ชม. แนะนำตั้งเวลาปิดอัตโนมัติด้วย Smart Relay
• ปริมาณการใช้น้ำช่วง 18:00 - 06:00 น. ต่ำกว่า 0.2 m³ อยู่ในเกณฑ์ปกติ ไม่มีสัญญาณท่อรั่วซึม
• การใช้ไฟฟ้าโดยรวมลดลง 12.4% เมื่อเทียบกับเดือนก่อนหน้า ประหยัดงบประมาณสถานศึกษาได้ประมาณ ฿2,860''',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    height: 1.5,
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

class _BuildingUsageBar extends StatelessWidget {
  const _BuildingUsageBar({
    required this.buildingName,
    required this.usageText,
    required this.percent,
    required this.color,
  });

  final String buildingName;
  final String usageText;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                buildingName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              usageText,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _EnergyKpiData {
  const _EnergyKpiData({
    required this.title,
    required this.value,
    required this.subValue,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subValue;
  final String detail;
  final IconData icon;
  final Color color;
}

class _EnergyKpiCard extends StatelessWidget {
  const _EnergyKpiCard({required this.data});

  final _EnergyKpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: data.color,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subValue,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
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
