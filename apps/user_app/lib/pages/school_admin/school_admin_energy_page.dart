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
        widget.initialWaterSummary != null)
      return;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('การใช้พลังงานทั้งโรงเรียน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),

                    // Primary KPI Cards
                    _buildOverviewCards(theme),
                    const SizedBox(height: 20),

                    // Efficiency Scores
                    _buildEfficiencySection(theme),
                    const SizedBox(height: 20),

                    // 7-day Trend Overview
                    _buildTrendSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'day', label: Text('วันนี้')),
        ButtonSegment(value: 'month', label: Text('เดือนนี้')),
        ButtonSegment(value: 'year', label: Text('ปีนี้')),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (newSet) {
        setState(() => _selectedPeriod = newSet.first);
        _loadData();
      },
    );
  }

  Widget _buildOverviewCards(ThemeData theme) {
    final energyKwh = _energySummary?.totalKwh ?? 0.0;
    final energyCost = _energySummary?.estimatedCostThb ?? 0.0;
    final waterCuM = _waterSummary?.totalM3 ?? 0.0;
    final waterCost = _waterSummary?.estimatedCostThb ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.amber.shade800, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'ไฟฟ้า',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${energyKwh.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ประมาณ ฿${energyCost.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'น้ำประปา',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${waterCuM.toStringAsFixed(1)} ลบ.ม.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ประมาณ ฿${waterCost.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencySection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'คะแนนประสิทธิภาพการใช้พลังงาน (Efficiency Benchmark)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildScoreBadge(
                    'ประสิทธิภาพไฟฟ้า',
                    _energyScore?.score ?? 0.0,
                    _energyScore?.label ?? 'ไม่มีข้อมูล',
                    Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildScoreBadge(
                    'ประสิทธิภาพน้ำประปา',
                    _waterScore?.score ?? 0.0,
                    _waterScore?.label ?? 'ไม่มีข้อมูล',
                    Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(
    String title,
    double score,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${score.toStringAsFixed(0)}/100',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'แนวโน้มการใช้งาน 7 วันย้อนหลัง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_energyTrend.isEmpty && _waterTrend.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'ยังไม่มีข้อมูลประวัติการใช้งานในช่วง 7 วันที่ผ่านมา',
                  ),
                ),
              )
            else ...[
              ...List.generate(_energyTrend.length, (index) {
                final pt = _energyTrend[index];
                final dateStr = '${pt.day.day}/${pt.day.month}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 14)),
                      Row(
                        children: [
                          Text(
                            '${pt.value.toStringAsFixed(1)} kWh',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
