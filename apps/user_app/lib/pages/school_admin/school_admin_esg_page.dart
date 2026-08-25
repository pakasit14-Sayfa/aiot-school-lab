import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class SchoolAdminEsgPage extends StatefulWidget {
  const SchoolAdminEsgPage({super.key});

  @override
  State<SchoolAdminEsgPage> createState() => _SchoolAdminEsgPageState();
}

class _SchoolAdminEsgPageState extends State<SchoolAdminEsgPage> {
  UtilityEfficiencyScore? _energyScore;
  UtilityEfficiencyScore? _waterScore;
  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        UtilityService.getEnergyEfficiencyScore(),
        UtilityService.getWaterEfficiencyScore(),
        UtilityService.getEnergyUsageSummary(period: 'month'),
        UtilityService.getWaterUsageSummary(period: 'month'),
      ]);

      if (mounted) {
        setState(() {
          _energyScore = results[0] as UtilityEfficiencyScore?;
          _waterScore = results[1] as UtilityEfficiencyScore?;
          _energySummary = results[2] as EnergyUsageSummary?;
          _waterSummary = results[3] as WaterUsageSummary?;
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

    // Calculate combined score
    final eScore = _energyScore?.score ?? 0.0;
    final wScore = _waterScore?.score ?? 0.0;
    final count = (_energyScore != null ? 1 : 0) + (_waterScore != null ? 1 : 0);
    final overallScore = count > 0 ? (eScore + wScore) / count : 0.0;

    String overallLabel = 'ดีมาก';
    if (overallScore < 50) {
      overallLabel = 'ต้องปรับปรุง';
    } else if (overallScore < 75) {
      overallLabel = 'ปานกลาง';
    } else if (overallScore < 90) {
      overallLabel = 'ดี';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงาน ESG & Green Score'),
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
                    // Main Green Score Card
                    _buildOverallGreenScoreCard(overallScore, overallLabel),
                    const SizedBox(height: 20),

                    // Pillar Breakdown
                    const Text(
                      'การประเมินประสิทธิภาพรายด้าน (Environmental Pillars)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildPillarCard(
                      title: 'ประสิทธิภาพการใช้พลังงานไฟฟ้า (Energy Efficiency)',
                      icon: Icons.bolt,
                      color: Colors.amber.shade800,
                      score: eScore,
                      label: _energyScore?.label ?? 'ไม่มีข้อมูล',
                      summaryText:
                          'การใช้ไฟฟ้าในเดือนนี้: ${_energySummary?.totalKwh.toStringAsFixed(1) ?? "0"} kWh (~฿${_energySummary?.estimatedCostThb.toStringAsFixed(0) ?? "0"})',
                    ),
                    const SizedBox(height: 12),
                    _buildPillarCard(
                      title: 'ประสิทธิภาพการใช้น้ำประปา (Water Conservation)',
                      icon: Icons.water_drop,
                      color: Colors.blue.shade700,
                      score: wScore,
                      label: _waterScore?.label ?? 'ไม่มีข้อมูล',
                      summaryText:
                          'การใช้น้ำในเดือนนี้: ${_waterSummary?.totalM3.toStringAsFixed(1) ?? "0"} ลบ.ม. (~฿${_waterSummary?.estimatedCostThb.toStringAsFixed(0) ?? "0"})',
                    ),
                    const SizedBox(height: 24),

                    // Scope and Honest Data Disclosure Card
                    _buildScopeDisclosureCard(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallGreenScoreCard(double overallScore, String overallLabel) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      overallScore.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const Text(
                      '/ 100',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Green School Score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ระดับ: $overallLabel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ประเมินจากข้อมูลตรวจวัด IoT ด้านไฟฟ้าและน้ำประปาจริง',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required String title,
    required IconData icon,
    required Color color,
    required double score,
    required String label,
    required String summaryText,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(0)}/100 ($label)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              summaryText,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeDisclosureCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                'ขอบเขตและที่มาของข้อมูล (ESG Transparency)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'คะแนน Green Score ด้านสิ่งแวดล้อม (Environmental) คำนวณจากข้อมูลมิเตอร์วัดการใช้ไฟฟ้าและน้ำประปาจริงในระบบ IoT สำหรับมิติการจัดการขยะ (Waste Management) และมิติสังคม/ธรรมาภิบาล (Social & Governance) ปัจจุบันยังไม่มีอุปกรณ์จัดเก็บข้อมูลอัตโนมัติ จึงไม่มีการแสดงผลตัวเลขประมาณการ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }
}
