import 'dart:convert';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';
import '../../utils/web_download.dart';

/// Grid emission factor for purchased electricity, kg CO₂e per kWh.
///
/// Thailand grid mix, TGO (องค์การบริหารจัดการก๊าซเรือนกระจก) Emission Factor
/// for grid electricity. Named and documented rather than left as a bare
/// `* 0.499` in the middle of a widget, so the number on screen can be traced
/// to a source and updated when TGO revises it.
const double kGridEmissionFactorKgCo2ePerKwh = 0.499;

/// Read seams so loading / data / empty / error can each be driven in a test
/// without a live Supabase client.
typedef EsgScoreLoader = Future<UtilityEfficiencyScore?> Function();
typedef EsgEnergySummaryLoader = Future<EnergyUsageSummary?> Function();
typedef EsgWaterSummaryLoader = Future<WaterUsageSummary?> Function();
typedef EsgScheduleLoader = Future<List<DeviceSchedule>> Function();
typedef EsgDownloadBytes =
    void Function({
      required String filename,
      required List<int> bytes,
      required String mimeType,
    });

class SchoolAdminEsgPage extends StatefulWidget {
  const SchoolAdminEsgPage({
    super.key,
    this.initialEnergyScore,
    this.initialWaterScore,
    this.initialEnergySummary,
    this.initialWaterSummary,
    this.loadEnergyScore,
    this.loadWaterScore,
    this.loadEnergySummary,
    this.loadWaterSummary,
    this.loadSchedules,
    this.downloadBytesOverride,
  });

  final UtilityEfficiencyScore? initialEnergyScore;
  final UtilityEfficiencyScore? initialWaterScore;
  final EnergyUsageSummary? initialEnergySummary;
  final WaterUsageSummary? initialWaterSummary;

  final EsgScoreLoader? loadEnergyScore;
  final EsgScoreLoader? loadWaterScore;
  final EsgEnergySummaryLoader? loadEnergySummary;
  final EsgWaterSummaryLoader? loadWaterSummary;
  final EsgScheduleLoader? loadSchedules;
  // Seam for tests: lets a test prove the export button actually calls a
  // download instead of the old always-succeeds SnackBar with no file.
  final EsgDownloadBytes? downloadBytesOverride;

  @override
  State<SchoolAdminEsgPage> createState() => _SchoolAdminEsgPageState();
}

class _SchoolAdminEsgPageState extends State<SchoolAdminEsgPage> {
  UtilityEfficiencyScore? _energyScore;
  UtilityEfficiencyScore? _waterScore;
  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;
  List<DeviceSchedule> _schedules = [];
  bool _isLoading = true;
  bool _hasError = false;

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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        widget.loadEnergyScore?.call() ??
            UtilityService.getEnergyEfficiencyScore(),
        widget.loadWaterScore?.call() ??
            UtilityService.getWaterEfficiencyScore(),
        widget.loadEnergySummary?.call() ??
            UtilityService.getEnergyUsageSummary(period: 'month'),
        widget.loadWaterSummary?.call() ??
            UtilityService.getWaterUsageSummary(period: 'month'),
        widget.loadSchedules?.call() ?? DeviceScheduleService.listSchedules(),
      ]);

      if (mounted) {
        setState(() {
          _energyScore = results[0] as UtilityEfficiencyScore?;
          _waterScore = results[1] as UtilityEfficiencyScore?;
          _energySummary = results[2] as EnergyUsageSummary?;
          _waterSummary = results[3] as WaterUsageSummary?;
          _schedules = results[4] as List<DeviceSchedule>;
          _isLoading = false;
        });
      }
    } catch (e) {
      // `catch (_) {}` used to hide the failure, and because every figure on
      // this page falls back to 0, a failed load rendered as a school scoring
      // 0/100 "ต้องปรับปรุง" — an accusation, not a missing value.
      debugPrint('SchoolAdminEsgPage load failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// The energy summary, but only when a meter actually reported it.
  ///
  /// `get_energy_usage_summary` sums with `coalesce(sum(...), 0)`, so a school
  /// with no metering hardware still returns a well-formed row reading 0.0 kWh.
  /// Rendering that as a consumption figure (and as 0 kg CO₂e) claims a
  /// measurement that was never taken. `deviceCount` is what tells the two
  /// apart.
  EnergyUsageSummary? get _measuredEnergy =>
      (_energySummary?.deviceCount ?? 0) > 0 ? _energySummary : null;

  WaterUsageSummary? get _measuredWater =>
      (_waterSummary?.deviceCount ?? 0) > 0 ? _waterSummary : null;

  String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Shared by both CSV and Excel export so the two formats can never drift
  /// apart in content. Returns null when there is nothing measured to export.
  List<List<String>>? _buildReportRows() {
    final energy = _measuredEnergy;
    final water = _measuredWater;
    if (energy == null && water == null) return null;

    return <List<String>>[
      ['metric', 'value', 'unit'],
      if (_energyScore?.score != null)
        ['energy_efficiency_score', '${_energyScore!.score}', 'score/100'],
      if (_waterScore?.score != null)
        ['water_efficiency_score', '${_waterScore!.score}', 'score/100'],
      if (energy != null) ...[
        ['energy_device_count', '${energy.deviceCount}', 'devices'],
        ['energy_total_kwh', '${energy.totalKwh}', 'kWh'],
        ['energy_estimated_cost', '${energy.estimatedCostThb}', 'THB'],
        [
          'energy_carbon_estimate',
          (energy.totalKwh * kGridEmissionFactorKgCo2ePerKwh).toStringAsFixed(
            2,
          ),
          'kg CO2e',
        ],
      ],
      if (water != null) ...[
        ['water_device_count', '${water.deviceCount}', 'devices'],
        ['water_total_m3', '${water.totalM3}', 'm3'],
        ['water_estimated_cost', '${water.estimatedCostThb}', 'THB'],
      ],
    ];
  }

  void _exportEsgReport() {
    final rows = _buildReportRows();
    if (rows == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีข้อมูลพลังงาน/น้ำให้ส่งออก')),
      );
      return;
    }

    final csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');

    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'esg_report_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งออกรายงาน ESG แล้ว (CSV)')),
      );
    }
  }

  void _exportEsgReportExcel() {
    final rows = _buildReportRows();
    if (rows == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีข้อมูลพลังงาน/น้ำให้ส่งออก')),
      );
      return;
    }

    final workbook = xls.Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet() ?? 'Sheet1'];
    for (final row in rows) {
      sheet.appendRow(row.map(xls.TextCellValue.new).toList());
    }
    final bytes = workbook.encode();
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างไฟล์ Excel ไม่สำเร็จ')),
        );
      }
      return;
    }

    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'esg_report_${DateTime.now().toIso8601String().split('T').first}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งออกรายงาน ESG แล้ว (Excel)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Averaged over the pillars that actually returned a score. `score` is
    // nullable in the model on purpose — the backend returns null when there
    // is not enough history to compare periods.
    //
    // This used to read `?? 0.0` on both pillars, so a school with no meter
    // data at all scored 0/100 and was graded "ต้องปรับปรุง" in red. A missing
    // measurement is not a failing measurement; grading a school on data that
    // was never collected is the most damaging thing this page could do.
    final List<double> realScores = [
      if (_energyScore?.score != null) _energyScore!.score!,
      if (_waterScore?.score != null) _waterScore!.score!,
    ];
    final double? overallScore = realScores.isEmpty
        ? null
        : realScores.reduce((a, b) => a + b) / realScores.length;

    String overallLabel;
    Color gradeColor;
    Color gradeBg;
    Color gradeBorder;

    if (overallScore == null) {
      overallLabel = _hasError ? 'โหลดไม่สำเร็จ' : 'ยังไม่มีข้อมูล';
      gradeColor = const Color(0xFF64748B);
      gradeBg = const Color(0xFFF1F5F9);
      gradeBorder = const Color(0xFFE2E8F0);
    } else if (overallScore < 50) {
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
    } else {
      overallLabel = 'ดีมาก';
      gradeColor = const Color(0xFF16A34A);
      gradeBg = const Color(0xFFF0FDF4);
      gradeBorder = const Color(0xFFBBF7D0);
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
                          if (_hasError) ...[
                            const SizedBox(height: 14),
                            _buildErrorBanner(),
                          ],
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
                          _buildPillarsGrid(),
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

          // Wrap, not Row: the export button carries a long disabled-state
          // label and a fixed Row overflowed the header on narrow widths.
          final actionButtons = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                onPressed: _loadData,
                tooltip: 'รีเฟรชข้อมูล',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF64748B),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'ส่งออกรายงาน ESG',
                onSelected: (value) =>
                    value == 'csv' ? _exportEsgReport() : _exportEsgReportExcel(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'csv', child: Text('ส่งออกเป็น CSV')),
                  PopupMenuItem(value: 'excel', child: Text('ส่งออกเป็น Excel')),
                ],
                child: FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('ส่งออกรายงาน ESG'),
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: SchoolAdminPalette.primaryDark,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 750) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleArea, const SizedBox(height: 14), actionButtons],
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
    double? overallScore,
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

          // With no score the circle must not print a green "0 / 100 คะแนน";
          // it goes grey and says there is nothing to grade yet.
          final bool hasScore = overallScore != null;
          final int realScoreCount =
              (_energyScore?.score != null ? 1 : 0) +
              (_waterScore?.score != null ? 1 : 0);
          final scoreCircle = Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasScore
                  ? const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: hasScore
                  ? const [
                      BoxShadow(
                        color: Color(0x2216A34A),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasScore ? overallScore.toStringAsFixed(0) : '—',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasScore ? '/ 100 คะแนน' : 'ยังไม่มีคะแนน',
                    style: const TextStyle(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
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
              Text(
                hasScore
                    ? 'คะแนนรวมด้านสิ่งแวดล้อม เฉลี่ยจากด้านที่มีข้อมูลเทียบช่วงก่อนหน้าแล้ว '
                          '(${realScoreCount == 1 ? "1 ด้าน" : "$realScoreCount ด้าน"})'
                    : 'ยังคำนวณคะแนนไม่ได้ ต้องมีข้อมูลมิเตอร์ย้อนหลังพอที่จะเทียบกับช่วงก่อนหน้าก่อน',
                style: const TextStyle(
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
                    _measuredEnergy == null
                        ? 'ไฟฟ้า: ยังไม่มีข้อมูล'
                        : 'ไฟฟ้า ${_measuredEnergy!.totalKwh.toStringAsFixed(0)} kWh',
                    const Color(0xFFD97706),
                    const Color(0xFFFFFBEB),
                  ),
                  _buildHeroStatChip(
                    Icons.water_drop_rounded,
                    _measuredWater == null
                        ? 'น้ำ: ยังไม่มีข้อมูล'
                        : 'น้ำ ${_measuredWater!.totalM3.toStringAsFixed(0)} m³',
                    const Color(0xFF0284C7),
                    const Color(0xFFF0F9FF),
                  ),
                  // Was labelled "ลดคาร์บอน" (carbon *reduced*) while the
                  // formula computes the emissions *caused by* the electricity
                  // consumed — the opposite meaning. Using more power made the
                  // "reduction" go up. It is now labelled as what it is, and
                  // it disappears entirely when there is no consumption
                  // figure, instead of claiming a tidy 0.
                  _buildHeroStatChip(
                    Icons.co2_rounded,
                    _measuredEnergy == null
                        ? 'คาร์บอนจากไฟฟ้า: ยังไม่มีข้อมูล'
                        : 'คาร์บอนจากไฟฟ้า ~${(_measuredEnergy!.totalKwh * kGridEmissionFactorKgCo2ePerKwh).toStringAsFixed(0)} kg CO₂e',
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
              children: [scoreCircle, const SizedBox(height: 16), detailsBlock],
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

  Widget _buildPillarsGrid() {
    final String noData = _hasError ? 'โหลดไม่สำเร็จ' : 'ยังไม่มีข้อมูล';
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
              subtitle: _measuredEnergy == null
                  ? 'การใช้ไฟฟ้าในเดือนนี้: $noData'
                  : 'การใช้ไฟฟ้าในเดือนนี้: ${_measuredEnergy!.totalKwh.toStringAsFixed(1)} kWh '
                        '(~฿${_measuredEnergy!.estimatedCostThb.toStringAsFixed(0)})',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              score: _energyScore?.score,
              label: _energyScore?.label,
              noDataText: noData,
              width: cardWidth,
            ),
            _buildPillarCard(
              title: 'ประสิทธิภาพการใช้น้ำประปา (Water Conservation)',
              subtitle: _measuredWater == null
                  ? 'การใช้น้ำในเดือนนี้: $noData'
                  : 'การใช้น้ำในเดือนนี้: ${_measuredWater!.totalM3.toStringAsFixed(1)} ลบ.ม. '
                        '(~฿${_measuredWater!.estimatedCostThb.toStringAsFixed(0)})',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
              score: _waterScore?.score,
              label: _waterScore?.label,
              noDataText: noData,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  /// Failure is stated in the page, not only in a snackbar that is gone by the
  /// time anyone reads the score. No raw backend text is shown.
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'โหลดข้อมูล ESG ไม่สำเร็จ คะแนนและตัวเลขที่แสดงอาจไม่เป็นปัจจุบัน',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : _loadData,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double? score,
    required String? label,
    required String noDataText,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  score == null
                      ? noDataText
                      : '${score.toStringAsFixed(0)}/100'
                            '${label == null ? '' : ' ($label)'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: score == null ? const Color(0xFF64748B) : color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // An absent score leaves the bar empty and grey. Rendering it as a
          // filled-to-0% coloured bar made "no measurement" look like a
          // measured zero.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score == null ? 0.0 : (score / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                score == null ? const Color(0xFFE2E8F0) : color,
              ),
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
                const Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
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
          // Only measures whose status this system can actually observe.
          //
          // Removed: "การตรวจจับน้ำรั่วไหล … พร้อมทำงาน" (nothing in the schema
          // detects leaks) and "เป้าหมายลดการปล่อยคาร์บอน 5% … ตามแผนงาน"
          // (no target is stored anywhere, so "ตามแผนงาน" was an unverifiable
          // claim of being on track). Both asserted that equipment and
          // programmes exist and are working.
          _buildScheduleInitiative(),
        ],
      ),
    );
  }

  /// Automatic power cut-off is real: `device_schedules` drives it and the
  /// School Admin device-schedule page manages it. So report what is actually
  /// configured — how many rules are enabled and when one last fired — rather
  /// than a fixed "เปิดใช้งาน" badge that was true even with zero schedules.
  Widget _buildScheduleInitiative() {
    final enabled = _schedules.where((s) => s.enabled).toList();
    final DateTime? lastRun = enabled
        .map((s) => s.lastTriggeredAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (acc, d) => acc == null || d.isAfter(acc) ? d : acc,
        );

    final String status;
    final Color statusColor;
    if (_hasError) {
      status = 'โหลดไม่สำเร็จ';
      statusColor = const Color(0xFFDC2626);
    } else if (enabled.isEmpty) {
      status = 'ยังไม่ได้ตั้งค่า';
      statusColor = const Color(0xFF64748B);
    } else {
      status = 'เปิดใช้งาน ${enabled.length} รายการ';
      statusColor = const Color(0xFF16A34A);
    }

    final String desc = enabled.isEmpty
        ? 'ตั้งเวลาเปิด-ปิดอุปกรณ์อัตโนมัติได้ที่หน้า "ตารางเวลาอุปกรณ์" — ยังไม่มีรายการที่เปิดใช้งาน'
        : 'ตั้งเวลาเปิด-ปิดอุปกรณ์อัตโนมัติ'
              '${lastRun == null ? ' · ยังไม่เคยทำงาน' : ' · ทำงานล่าสุด ${lastRun.day}/${lastRun.month}/${lastRun.year}'}';

    return _buildInitiativeItem(
      'ระบบตัดไฟอัตโนมัติ (Smart Power Auto-Cut)',
      desc,
      status,
      statusColor,
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
