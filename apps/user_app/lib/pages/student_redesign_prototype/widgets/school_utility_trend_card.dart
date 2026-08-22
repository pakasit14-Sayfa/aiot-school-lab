import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_redesign_palette.dart';

class SchoolUtilityTrendCard extends StatefulWidget {
  const SchoolUtilityTrendCard({super.key, this.height});

  final double? height;

  @override
  State<SchoolUtilityTrendCard> createState() =>
      _SchoolUtilityTrendCardState();
}

class _SchoolUtilityTrendCardState extends State<SchoolUtilityTrendCard>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;
  List<UtilityTrendPoint> _energyTrend = [];
  List<UtilityTrendPoint> _waterTrend = [];
  UtilityEfficiencyScore? _energyScore;
  UtilityEfficiencyScore? _waterScore;

  late AnimationController _animController;
  late Animation<double> _drawProgress;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _drawProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        UtilityService.getEnergyUsageSummary(period: 'week'),
        UtilityService.getWaterUsageSummary(period: 'week'),
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
        _loading = false;
      });
      _animController.forward(from: 0.0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _hasEnergy => (_energySummary?.deviceCount ?? 0) > 0;
  bool get _hasWater => (_waterSummary?.deviceCount ?? 0) > 0;

  double? get _combinedScore {
    final scores = [
      _energyScore?.score,
      _waterScore?.score,
    ].whereType<double>().toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _scoreLabel(double s) {
    if (s >= 70) return 'ประหยัดดีเยี่ยม 🌱';
    if (s >= 50) return 'เกณฑ์มาตรฐาน ⚡';
    return 'ชวนกันประหยัดไฟ 💡';
  }

  Color _scoreColor(double s) {
    if (s >= 70) return const Color(0xFF10B981);
    if (s >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFF43F5E);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SchoolPalette.glassBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (!_hasEnergy && !_hasWater) {
      return const SizedBox.shrink();
    }

    final score = _combinedScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Compact Title & Live Badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.energy_savings_leaf_rounded,
                size: 15,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'คะแนนพลังงานและสิ่งแวดล้อม',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: SchoolPalette.ink,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (score != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _scoreColor(score).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _scoreColor(score).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${score.toStringAsFixed(0)}% · ${_scoreLabel(score)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _scoreColor(score),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Metrics Summary Row (Pills)
        Row(
          children: [
            if (_hasEnergy)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡ ', style: TextStyle(fontSize: 9.5)),
                    Text(
                      'ไฟฟ้า ${_energySummary!.totalKwh.toStringAsFixed(0)} kWh',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF854D0E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            if (_hasWater)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💧 ', style: TextStyle(fontSize: 9.5)),
                    Text(
                      'น้ำ ${_waterSummary!.totalM3.toStringAsFixed(1)} m³',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0369A1),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            const Text(
              '🌱 Safe & Green Lab',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Animated Live Running Graph
        Expanded(
          child: AnimatedBuilder(
            animation: _drawProgress,
            builder: (context, _) {
              return _AnimatedWaveGraph(
                energyPoints: _hasEnergy ? _energyTrend : const [],
                waterPoints: _hasWater ? _waterTrend : const [],
                animationProgress: _drawProgress.value,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimatedWaveGraph extends StatelessWidget {
  const _AnimatedWaveGraph({
    required this.energyPoints,
    required this.waterPoints,
    required this.animationProgress,
  });

  final List<UtilityTrendPoint> energyPoints;
  final List<UtilityTrendPoint> waterPoints;
  final double animationProgress;

  List<double> _normalizeValues(List<UtilityTrendPoint> points) {
    if (points.isEmpty) return [];
    final maxVal = points.map((p) => p.value).fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal <= 0) return List.filled(points.length, 0.0);
    return points.map((p) => p.value / maxVal * 100).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dayLabels = (energyPoints.isNotEmpty ? energyPoints : waterPoints)
        .map((p) => p.day)
        .toList();
    final energyNorm = _normalizeValues(energyPoints);
    final waterNorm = _normalizeValues(waterPoints);

    final combined = <double>[];
    for (var i = 0; i < dayLabels.length; i++) {
      final e = i < energyNorm.length ? energyNorm[i] : null;
      final w = i < waterNorm.length ? waterNorm[i] : null;
      if (e != null && w != null) {
        combined.add((e + w) / 2);
      } else {
        combined.add(e ?? w ?? 0);
      }
    }

    final animatedSpots = <FlSpot>[];
    final count = combined.length;
    for (var i = 0; i < count; i++) {
      final targetY = combined[i];
      // Progressive curve draw animation from left to right
      final pointProgress = (animationProgress * count - i).clamp(0.0, 1.0);
      final currentY = targetY * pointProgress;
      animatedSpots.add(FlSpot(i.toDouble(), currentY));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 105,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 0.8),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 15,
              interval: math.max(1, (dayLabels.length / 4).floor()).toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${dayLabels[idx].day}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: SchoolPalette.muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => SchoolPalette.ink,
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              final parts = <String>[];
              if (idx >= 0 && idx < energyPoints.length) {
                parts.add('⚡ ${energyPoints[idx].value.toStringAsFixed(1)} kWh');
              }
              if (idx >= 0 && idx < waterPoints.length) {
                parts.add('💧 ${waterPoints[idx].value.toStringAsFixed(1)} m³');
              }
              return LineTooltipItem(
                parts.join('  ·  '),
                const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: animatedSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            barWidth: 3.2,
            isStrokeCapRound: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF59E0B), // Warm Amber Energy
                Color(0xFF06B6D4), // Cyan Water
                Color(0xFF10B981), // Emerald Eco
              ],
            ),
            dotData: FlDotData(
              show: animationProgress > 0.6,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2.2,
                strokeColor: const Color(0xFF06B6D4),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF06B6D4).withValues(alpha: 0.22),
                  const Color(0xFF10B981).withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
