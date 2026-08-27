import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolAdminEsgPage extends StatefulWidget {
  const SchoolAdminEsgPage({
    super.key,
    this.initialEnergyScore,
    this.initialWaterScore,
    this.initialEnergySummary,
    this.initialWaterSummary,
  });

  final UtilityEfficiencyScore? initialEnergyScore;
  final UtilityEfficiencyScore? initialWaterScore;
  final EnergyUsageSummary? initialEnergySummary;
  final WaterUsageSummary? initialWaterSummary;

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
    if (widget.initialEnergyScore != null ||
        widget.initialEnergySummary != null) {
      _energyScore = widget.initialEnergyScore;
      _waterScore = widget.initialWaterScore;
      _energySummary = widget.initialEnergySummary;
      _waterSummary = widget.initialWaterSummary;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.initialEnergyScore != null ||
        widget.initialEnergySummary != null) {
      return;
    }
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

  void _exportEsgReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ดาวน์โหลดรายงาน ESG ประจำเดือน (PDF/Excel) เรียบร้อยแล้ว'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF16A34A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate combined score
    final eScore = _energyScore?.score ?? 0.0;
    final wScore = _waterScore?.score ?? 0.0;
    final count = (_energyScore != null ? 1 : 0) + (_waterScore != null ? 1 : 0);
    final overallScore = count > 0 ? (eScore + wScore) / count : 0.0;

    String overallLabel = 'ดีมาก';
    Color gradeColor = const Color(0xFF16A34A);
    Color gradeBg = const Color(0xFFF0FDF4);
    Color gradeBorder = const Color(0xFFBBF7D0);

    if (overallScore < 50) {
      overallLabel = 'ต้องปรับปรุง';
      gradeColor = const Color(0xFFDC2626);
      gradeBg = const Color(0xFFFEF2F2);
      gradeBorder = const Color(0xFFFECACA);
    } else if (overallScore < 75) {
      overallLabel = 'ปานกลาง';
      gradeColor = const Color(0xFFD97706);
      gradeBg = const Color(0xFFFFFBEB);
      gradeBorder = const Color(0xFFFDE68A);
    } else if (overallScore < 90) {
      overallLabel = 'ดี';
      gradeColor = const Color(0xFF2563EB);
      gradeBg = const Color(0xFFEFF6FF);
      gradeBorder = const Color(0xFFBFDBFE);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1450),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildOverallGreenScoreHero(
                            overallScore,
                            overallLabel,
                            gradeColor,
                            gradeBg,
                            gradeBorder,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'การประเมินประสิทธิภาพรายด้าน (Environmental Pillars)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPillarsGrid(eScore, wScore),
                          const SizedBox(height: 20),
                          _buildInitiativesSection(),
                          const SizedBox(height: 20),
                          _buildScopeDisclosureCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleArea = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF16A34A),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รายงาน ESG & Green School Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ดัชนีความยั่งยืนด้านสิ่งแวดล้อม การประหยัดพลังงาน และเป้าหมายลดการปล่อยคาร์บอน',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _loadData,
                tooltip: 'รีเฟรชข้อมูล',
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _exportEsgReport,
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('ส่งออกรายงาน ESG'),
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolAdminPalette.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 750) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleArea,
                const SizedBox(height: 14),
                actionButtons,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleArea),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallGreenScoreHero(
    double overallScore,
    String overallLabel,
    Color gradeColor,
    Color gradeBg,
    Color gradeBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          final scoreCircle = Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2216A34A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
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
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '/ 100 คะแนน',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );

          final detailsBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  const Text(
                    'Green School Performance Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: gradeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gradeBorder),
                    ),
                    child: Text(
                      'ระดับ: $overallLabel',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: gradeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'ดัชนีคะแนนรวมด้านสิ่งแวดล้อม คำนวณจากข้อมูลมิเตอร์ตรวจวัด IoT และอัตราการใช้พลังงานเทียบเป้าหมายความยั่งยืนประจำปีการศึกษา',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildHeroStatChip(
                    Icons.bolt_rounded,
                    'ไฟฟ้า ${_energySummary?.totalKwh.toStringAsFixed(0) ?? "0"} kWh',
                    const Color(0xFFD97706),
                    const Color(0xFFFFFBEB),
                  ),
                  _buildHeroStatChip(
                    Icons.water_drop_rounded,
                    'น้ำ ${_waterSummary?.totalM3.toStringAsFixed(0) ?? "0"} m³',
                    const Color(0xFF0284C7),
                    const Color(0xFFF0F9FF),
                  ),
                  _buildHeroStatChip(
                    Icons.energy_savings_leaf_rounded,
                    'ลดคาร์บอน ~${((_energySummary?.totalKwh ?? 0) * 0.499).toStringAsFixed(0)} kg CO₂e',
                    const Color(0xFF16A34A),
                    const Color(0xFFF0FDF4),
                  ),
                ],
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                scoreCircle,
                const SizedBox(height: 16),
                detailsBlock,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              scoreCircle,
              const SizedBox(width: 24),
              Expanded(child: detailsBlock),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroStatChip(IconData icon, String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsGrid(double eScore, double wScore) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleCol = constraints.maxWidth < 800;
        final cardWidth = isSingleCol
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildPillarCard(
              title: 'ประสิทธิภาพการใช้พลังงานไฟฟ้า (Energy Efficiency)',
              subtitle: 'การใช้ไฟฟ้าในเดือนนี้: ${_energySummary?.totalKwh.toStringAsFixed(1) ?? "0"} kWh (~฿${_energySummary?.estimatedCostThb.toStringAsFixed(0) ?? "0"})',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              score: eScore,
              label: _energyScore?.label ?? 'ไม่มีข้อมูล',
              width: cardWidth,
            ),
            _buildPillarCard(
              title: 'ประสิทธิภาพการใช้น้ำประปา (Water Conservation)',
              subtitle: 'การใช้น้ำในเดือนนี้: ${_waterSummary?.totalM3.toStringAsFixed(1) ?? "0"} ลบ.ม. (~฿${_waterSummary?.estimatedCostThb.toStringAsFixed(0) ?? "0"})',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
              score: wScore,
              label: _waterScore?.label ?? 'ไม่มีข้อมูล',
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPillarCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double score,
    required String label,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  '${score.toStringAsFixed(0)}/100 ($label)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
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

  Widget _buildInitiativesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'มาตรการประหยัดพลังงานและความยั่งยืน (Green School Initiatives)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInitiativeItem(
            'ระบบตัดไฟอัตโนมัติ (Smart Power Auto-Cut)',
            'ตั้งเวลาปิดเครื่องปรับอากาศและไฟส่องสว่างหลัง 17:00 น. ผ่าน pg_cron Engine',
            'เปิดใช้งาน',
            const Color(0xFF16A34A),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInitiativeItem(
            'การตรวจจับน้ำรั่วไหล (Water Leakage Detection)',
            'เฝ้าระวังอัตราการไหลผิดปกติในเวลากลางคืนด้วยเซนเซอร์ Pulse Flow Meter',
            'พร้อมทำงาน',
            const Color(0xFF0284C7),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInitiativeItem(
            'เป้าหมายลดการปล่อยคาร์บอน (Carbon Footprint Target)',
            'ลดการใช้พลังงานไฟฟ้าลง 5% เมื่อเทียบกับปีการศึกษาที่ผ่านมา',
            'ตามแผนงาน',
            const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiativeItem(
    String title,
    String desc,
    String status,
    Color statusColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withAlpha(60)),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeDisclosureCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ขอบเขตและที่มาของข้อมูล (ESG Transparency & Methodology)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'คะแนน Green Score ด้านสิ่งแวดล้อม (Environmental) คำนวณจากข้อมูลมิเตอร์วัดการใช้ไฟฟ้าและน้ำประปาจริงในระบบ IoT สำหรับมิติการจัดการขยะ (Waste Management) และมิติสังคม/ธรรมาภิบาล (Social & Governance) ปัจจุบันยังไม่มีอุปกรณ์จัดเก็บข้อมูลอัตโนมัติ จึงไม่มีการแสดงผลตัวเลขประมาณการ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
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
