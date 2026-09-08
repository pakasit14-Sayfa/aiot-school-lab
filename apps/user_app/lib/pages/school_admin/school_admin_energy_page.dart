import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../utils/web_download.dart';

/// Read seams so loading / data / empty / error can each be driven in a test
/// without a live Supabase client — the same pattern as the School Admin
/// pages that already meet the DoD.
typedef EnergySummaryLoader =
    Future<EnergyUsageSummary?> Function(String period);
typedef WaterSummaryLoader = Future<WaterUsageSummary?> Function(String period);
typedef UtilityTrendLoader = Future<List<UtilityTrendPoint>> Function();
typedef UtilityScoreLoader = Future<UtilityEfficiencyScore?> Function();
typedef EnergyPageDownloadBytes =
    void Function({
      required String filename,
      required List<int> bytes,
      required String mimeType,
    });

class SchoolAdminEnergyPage extends StatefulWidget {
  const SchoolAdminEnergyPage({
    super.key,
    this.initialEnergySummary,
    this.initialWaterSummary,
    this.initialEnergyTrend,
    this.initialWaterTrend,
    this.initialEnergyScore,
    this.initialWaterScore,
    this.loadEnergySummary,
    this.loadWaterSummary,
    this.loadEnergyTrend,
    this.loadWaterTrend,
    this.loadEnergyScore,
    this.loadWaterScore,
    this.downloadBytesOverride,
  });

  final EnergyUsageSummary? initialEnergySummary;
  final WaterUsageSummary? initialWaterSummary;
  final List<UtilityTrendPoint>? initialEnergyTrend;
  final List<UtilityTrendPoint>? initialWaterTrend;
  final UtilityEfficiencyScore? initialEnergyScore;
  final UtilityEfficiencyScore? initialWaterScore;

  final EnergySummaryLoader? loadEnergySummary;
  final WaterSummaryLoader? loadWaterSummary;
  final UtilityTrendLoader? loadEnergyTrend;
  final UtilityTrendLoader? loadWaterTrend;
  final UtilityScoreLoader? loadEnergyScore;
  final UtilityScoreLoader? loadWaterScore;
  // Seam for tests: lets a test prove the export button actually calls a
  // download instead of the old always-succeeds SnackBar with no file.
  final EnergyPageDownloadBytes? downloadBytesOverride;

  @override
  State<SchoolAdminEnergyPage> createState() => _SchoolAdminEnergyPageState();
}

class _SchoolAdminEnergyPageState extends State<SchoolAdminEnergyPage> {
  String _selectedPeriod = 'month';
  int _selectedTrendTab = 0; // 0 = ไฟฟ้า, 1 = น้ำประปา
  bool _isLoading = true;
  bool _hasError = false;

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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        widget.loadEnergySummary?.call(_selectedPeriod) ??
            UtilityService.getEnergyUsageSummary(period: _selectedPeriod),
        widget.loadWaterSummary?.call(_selectedPeriod) ??
            UtilityService.getWaterUsageSummary(period: _selectedPeriod),
        widget.loadEnergyTrend?.call() ??
            UtilityService.getEnergyUsageTrend(days: 7),
        widget.loadWaterTrend?.call() ??
            UtilityService.getWaterUsageTrend(days: 7),
        widget.loadEnergyScore?.call() ??
            UtilityService.getEnergyEfficiencyScore(),
        widget.loadWaterScore?.call() ??
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
    } catch (e) {
      // The failure used to be swallowed by `catch (_) {}`, which left every
      // card on its hardcoded fallback — a director could not tell a failed
      // load from a real reading. Surface it, keep whatever was last
      // confirmed, and never invent a number in its place.
      debugPrint('SchoolAdminEnergyPage load failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// Formats a real measurement, or says plainly that there is none. Loading,
  /// empty and failure must never collapse into a number that reads as a
  /// meter reading.
  String _figure(String? text) {
    if (text != null) return text;
    return _hasError ? 'โหลดไม่สำเร็จ' : 'ยังไม่มีข้อมูล';
  }

  String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _exportReport() {
    final energy = (_energySummary?.deviceCount ?? 0) > 0
        ? _energySummary
        : null;
    final water = (_waterSummary?.deviceCount ?? 0) > 0
        ? _waterSummary
        : null;
    if (energy == null &&
        water == null &&
        _energyTrend.isEmpty &&
        _waterTrend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีข้อมูลพลังงาน/น้ำให้ส่งออก')),
      );
      return;
    }

    final rows = <List<String>>[
      ['section', 'metric', 'value', 'unit'],
      if (energy != null) ...[
        ['summary', 'energy_device_count', '${energy.deviceCount}', 'devices'],
        ['summary', 'energy_total_kwh', '${energy.totalKwh}', 'kWh'],
        [
          'summary',
          'energy_estimated_cost',
          '${energy.estimatedCostThb}',
          'THB',
        ],
      ],
      if (water != null) ...[
        ['summary', 'water_device_count', '${water.deviceCount}', 'devices'],
        ['summary', 'water_total_m3', '${water.totalM3}', 'm3'],
        [
          'summary',
          'water_estimated_cost',
          '${water.estimatedCostThb}',
          'THB',
        ],
      ],
      for (final point in _energyTrend)
        [
          'energy_trend',
          point.day.toIso8601String().split('T').first,
          '${point.value}',
          'kWh',
        ],
      for (final point in _waterTrend)
        [
          'water_trend',
          point.day.toIso8601String().split('T').first,
          '${point.value}',
          'm3',
        ],
    ];
    final csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');

    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'energy_report_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ส่งออกรายงานแล้ว')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF9E401A)),
              )
            : SingleChildScrollView(
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
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                onPressed: _exportReport,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text("ส่งออกรายงาน"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: const Color(0xFF334155),
                ),
              ),
              IconButton(
                onPressed: _loadData,
                tooltip: "รีเฟรชข้อมูล",
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF475569),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  /// Failure is stated in the page, not only in a snackbar that has already
  /// disappeared by the time the director reads the numbers. No raw backend
  /// text is shown.
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
              'โหลดข้อมูลการใช้พลังงานไม่สำเร็จ ตัวเลขที่แสดงอาจไม่เป็นปัจจุบัน',
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
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
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
    // Every value below is either a real backend figure or an explicit
    // "ยังไม่มีข้อมูล" / "โหลดไม่สำเร็จ". The old `?? 4.5` / `?? 18.0` /
    // `?? 'ดีเยี่ยม'` / "ประหยัดกว่าเกณฑ์มาตรฐาน 12.4%" fallbacks made an
    // empty database and a failed request both render as a confident meter
    // reading. `isRateDefault` and `deviceCount` come from the RPC precisely
    // so the page can disclose how the number was reached — they were fetched
    // and then thrown away.
    // A summary built from zero meters is not a measurement of zero. The RPC
    // sums readings with `coalesce(sum(sr.value), 0)`, so a school with no
    // metering hardware still gets a well-formed row reading 0.0 kWh — which
    // on screen claims the school consumed nothing. `deviceCount` is what
    // separates "measured, and it was zero" from "nothing is measuring".
    final energy = (_energySummary?.deviceCount ?? 0) > 0
        ? _energySummary
        : null;
    final water = (_waterSummary?.deviceCount ?? 0) > 0 ? _waterSummary : null;
    final energyScore = _energyScore;

    String rateDetail(double rate, bool isDefault, String unit) =>
        'อัตรา ฿${rate.toStringAsFixed(2)} / $unit'
        '${isDefault ? ' (อัตรากลาง ยังไม่ได้ตั้งค่าของโรงเรียน)' : ''}';

    final String? totalCostText = (energy != null && water != null)
        ? '฿${(energy.estimatedCostThb + water.estimatedCostThb).toStringAsFixed(0)}'
        : null;

    final items = [
      _EnergyKpiData(
        title: "การใช้ไฟฟ้าทั้งหมด",
        value: _figure(
          energy == null ? null : '${energy.totalKwh.toStringAsFixed(1)} kWh',
        ),
        subValue: energy == null
            ? 'ยังไม่มีมิเตอร์ที่ส่งค่า'
            : 'ประมาณ ฿${energy.estimatedCostThb.toStringAsFixed(0)} · จากมิเตอร์ ${energy.deviceCount} จุด',
        detail: energy == null
            ? '—'
            : rateDetail(
                energy.electricityRateThb,
                energy.isRateDefault,
                'หน่วย',
              ),
        icon: Icons.bolt_rounded,
        color: const Color(0xFFD97706),
      ),
      _EnergyKpiData(
        title: "การใช้น้ำประปาทั้งหมด",
        value: _figure(
          water == null ? null : '${water.totalM3.toStringAsFixed(1)} ลบ.ม.',
        ),
        subValue: water == null
            ? 'ยังไม่มีมิเตอร์ที่ส่งค่า'
            : 'ประมาณ ฿${water.estimatedCostThb.toStringAsFixed(0)} · จากมิเตอร์ ${water.deviceCount} จุด',
        detail: water == null
            ? '—'
            : rateDetail(water.waterRateThb, water.isRateDefault, 'ลบ.ม.'),
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF0284C7),
      ),
      _EnergyKpiData(
        title: "ค่าสาธารณูปโภครวม",
        value: _figure(totalCostText),
        subValue: "ค่าไฟ + ค่าน้ำประปา",
        detail: energy?.disclaimer ?? water?.disclaimer ?? '—',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF9E401A),
      ),
      _EnergyKpiData(
        title: "ดัชนีประสิทธิภาพพลังงาน",
        // score is nullable in the model *on purpose*: the backend returns
        // null when there is not enough history to compare periods. Filling
        // that with a number would be inventing the verdict.
        value: _figure(
          energyScore?.score == null
              ? null
              : '${energyScore!.score!.toStringAsFixed(0)} / 100',
        ),
        subValue: energyScore?.label == null
            ? 'ยังเทียบกับช่วงก่อนหน้าไม่ได้'
            : 'ระดับ: ${energyScore!.label}',
        detail: energyScore?.score == null
            ? '—'
            : 'ช่วงนี้ ${energyScore!.current.toStringAsFixed(1)} · ช่วงก่อน ${energyScore.previous.toStringAsFixed(1)}',
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
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

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
    final List<UtilityTrendPoint> activePoints = _selectedTrendTab == 0
        ? _energyTrend
        : _waterTrend;
    final String unit = _selectedTrendTab == 0 ? "kWh" : "ลบ.ม.";
    final Color activeColor = _selectedTrendTab == 0
        ? const Color(0xFFD97706)
        : const Color(0xFF0284C7);

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
                    _buildTrendTabButton(
                      0,
                      "⚡ ไฟฟ้า (kWh)",
                      const Color(0xFFD97706),
                    ),
                    _buildTrendTabButton(
                      1,
                      "💧 น้ำประปา (m³)",
                      const Color(0xFF0284C7),
                    ),
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
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
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
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${pt.value.toStringAsFixed(1)} $unit",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: activeColor,
                              ),
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
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
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

  Widget _buildVisualTrendBars(
    List<UtilityTrendPoint> points,
    Color color,
    String unit,
  ) {
    final double maxVal = points
        .map((p) => p.value)
        .fold(0.0, (a, b) => a > b ? a : b);
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
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "ประเมินเปรียบเทียบตามมาตรฐานอาคารสถานศึกษาประหยัดพลังงาน",
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _buildEfficiencyScoreRow(
                title: "ประสิทธิภาพไฟฟ้า",
                score: _energyScore?.score,
                label: _energyScore?.label,
                current: _energyScore?.current,
                previous: _energyScore?.previous,
                unit: 'kWh',
                color: const Color(0xFFD97706),
                icon: Icons.bolt_rounded,
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildEfficiencyScoreRow(
                title: "ประสิทธิภาพน้ำประปา",
                score: _waterScore?.score,
                label: _waterScore?.label,
                current: _waterScore?.current,
                previous: _waterScore?.previous,
                unit: 'm³',
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
          // The four bars here (อาคารเรียน 1 = 1,420 kWh 31%, …) were a const
          // list. Nothing in the schema can produce them today: no RPC
          // aggregates usage by building, and `devices.building` is null on
          // every row, so even a new RPC would have nothing to group by.
          // Showing the gap is the honest state; inventing a split across
          // buildings that were never metered is not.
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "สัดส่วนการใช้พลังงานรายอาคาร",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                "แจกแจงตามจุดติดตั้งมิเตอร์อัจฉริยะในแต่ละอาคาร",
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.domain_disabled_rounded,
                      size: 34,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "ยังไม่มีข้อมูลรายอาคาร",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "ต้องระบุอาคารให้อุปกรณ์มิเตอร์ก่อน จึงจะแจกแจงการใช้พลังงานรายอาคารได้",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        );

        if (constraints.maxWidth < 1100) {
          return Column(
            children: [
              efficiency,
              const SizedBox(height: 16),
              buildingBreakdown,
            ],
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
    required double? score,
    required String? label,
    required double? current,
    required double? previous,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    // A missing score is a real answer from the backend ("not enough history
    // to compare"), not a gap to paper over.
    final String scoreText = score == null
        ? (_hasError ? 'โหลดไม่สำเร็จ' : 'ยังไม่มีข้อมูล')
        : '${score.toStringAsFixed(0)}/100';
    // Only quote the two period figures when the backend was able to grade
    // them. With no meters the RPC still returns current = previous = 0, and
    // printing "ช่วงนี้: 0.0 kWh (เทียบช่วงก่อน 0.0 kWh)" next to a
    // "ยังไม่มีข้อมูล" score contradicts it — the row would be claiming a
    // measurement of zero in the same breath as saying nothing was measured.
    final String comparisonText =
        (score == null || current == null || previous == null)
        ? 'ยังไม่มีข้อมูลเทียบช่วงก่อนหน้า'
        : 'ช่วงนี้: ${current.toStringAsFixed(1)} $unit '
              '(เทียบช่วงก่อน ${previous.toStringAsFixed(1)} $unit)';

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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (label != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                comparisonText,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          scoreText,
          style: TextStyle(
            fontSize: score == null ? 12 : 17,
            fontWeight: FontWeight.w900,
            color: score == null ? const Color(0xFF64748B) : color,
          ),
        ),
      ],
    );
  }

  /// One line per comparison the backend can actually justify.
  ///
  /// The previous version asserted things no part of this system observes —
  /// "ตรวจพบเครื่องปรับอากาศห้องปฏิบัติการ 2 เปิดใช้งานต่อเนื่องเกิน 8 ชม.",
  /// "ไม่มีสัญญาณท่อรั่วซึม", "ประหยัดงบประมาณได้ประมาณ ฿2,860". There is no
  /// per-appliance runtime tracking, no leak detection and no budget baseline
  /// anywhere in the schema, so those were claims about a school that the
  /// system had never measured. What *is* real is the period-over-period
  /// comparison the efficiency RPCs return, so only that is stated.
  List<String> _realInsights() {
    final List<String> lines = [];

    void compare(UtilityEfficiencyScore? s, String noun, String unit) {
      if (s == null || s.previous <= 0) return;
      final double change = (s.current - s.previous) / s.previous * 100;
      final String direction = change <= 0 ? 'ลดลง' : 'เพิ่มขึ้น';
      lines.add(
        '• $noun$direction ${change.abs().toStringAsFixed(1)}% '
        'เทียบช่วงก่อนหน้า (${s.current.toStringAsFixed(1)} $unit '
        'จาก ${s.previous.toStringAsFixed(1)} $unit)',
      );
    }

    compare(_energyScore, 'การใช้ไฟฟ้า', 'kWh');
    compare(_waterScore, 'การใช้น้ำประปา', 'm³');
    return lines;
  }

  Widget _buildSavingRecommendations() {
    final List<String> insights = _realInsights();
    final bool hasInsights = insights.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasInsights ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasInsights
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            color: hasInsights
                ? const Color(0xFF16A34A)
                : const Color(0xFF94A3B8),
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "การเปลี่ยนแปลงเทียบช่วงก่อนหน้า",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: hasInsights
                        ? const Color(0xFF14532D)
                        : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasInsights
                      ? insights.join('\n')
                      : 'ยังไม่มีข้อมูลมากพอจะเทียบกับช่วงก่อนหน้า',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasInsights
                        ? const Color(0xFF166534)
                        : const Color(0xFF64748B),
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
