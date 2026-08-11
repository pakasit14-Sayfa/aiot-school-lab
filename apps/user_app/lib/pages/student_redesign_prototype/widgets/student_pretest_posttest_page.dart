import 'package:flutter/material.dart';

import 'student_redesign_palette.dart';

/// UI-only mock: overview of pre-test / post-test scores across every
/// lesson, grouped by subject, so a student can see their improvement at a
/// glance instead of opening each lesson one by one.
class _LessonQuizResult {
  const _LessonQuizResult({
    required this.chapterNumber,
    required this.title,
    required this.beforeScore,
    required this.afterScore,
    required this.maxScore,
  });

  final String chapterNumber;
  final String title;
  final int? beforeScore;
  final int? afterScore;
  final int maxScore;

  bool get hasBoth => beforeScore != null && afterScore != null;
  int get delta => hasBoth ? afterScore! - beforeScore! : 0;
}

class _SubjectQuizGroup {
  const _SubjectQuizGroup({
    required this.subjectName,
    required this.subjectColor,
    required this.icon,
    required this.results,
  });

  final String subjectName;
  final Color subjectColor;
  final IconData icon;
  final List<_LessonQuizResult> results;
}

const _mockGroups = <_SubjectQuizGroup>[
  _SubjectQuizGroup(
    subjectName: 'วิชา AIoT สมาร์ตแล็บ',
    subjectColor: Color(0xFF0D9488),
    icon: Icons.memory_rounded,
    results: [
      _LessonQuizResult(
        chapterNumber: 'บทที่ 10',
        title: 'พื้นฐานเซนเซอร์และไมโครคอนโทรลเลอร์',
        beforeScore: 4,
        afterScore: 9,
        maxScore: 10,
      ),
      _LessonQuizResult(
        chapterNumber: 'บทที่ 11',
        title: 'การอ่านค่าเซนเซอร์วัดแสงแบบเรียลไทม์',
        beforeScore: 5,
        afterScore: 8,
        maxScore: 10,
      ),
      _LessonQuizResult(
        chapterNumber: 'บทที่ 12',
        title: 'อินเทอร์แอคทีฟแล็บ: ควบคุมอุปกรณ์ผ่าน AIoT',
        beforeScore: 6,
        afterScore: 10,
        maxScore: 10,
      ),
      _LessonQuizResult(
        chapterNumber: 'บทที่ 13',
        title: 'วิเคราะห์ข้อมูล PM2.5 จากเซนเซอร์จริง',
        beforeScore: 3,
        afterScore: null,
        maxScore: 10,
      ),
      _LessonQuizResult(
        chapterNumber: 'บทที่ 14',
        title: 'สร้าง Dashboard แสดงผลเซนเซอร์',
        beforeScore: null,
        afterScore: null,
        maxScore: 10,
      ),
    ],
  ),
  _SubjectQuizGroup(
    subjectName: 'วิชาฟิสิกส์ประยุกต์',
    subjectColor: Color(0xFF0284C7),
    icon: Icons.science_rounded,
    results: [
      _LessonQuizResult(
        chapterNumber: 'บทที่ 5',
        title: 'พลังงานและการประหยัดไฟฟ้าในห้องเรียน',
        beforeScore: 5,
        afterScore: 7,
        maxScore: 10,
      ),
      _LessonQuizResult(
        chapterNumber: 'บทที่ 6',
        title: 'แรงและการเคลื่อนที่เบื้องต้น',
        beforeScore: 6,
        afterScore: 9,
        maxScore: 10,
      ),
    ],
  ),
];

class StudentPretestPosttestPage extends StatefulWidget {
  const StudentPretestPosttestPage({super.key});

  @override
  State<StudentPretestPosttestPage> createState() =>
      _StudentPretestPosttestPageState();
}

class _StudentPretestPosttestPageState extends State<StudentPretestPosttestPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allResults = _mockGroups.expand((g) => g.results).toList();
    final completed = allResults.where((r) => r.hasBoth).toList();
    final avgBefore = completed.isEmpty
        ? 0.0
        : completed.map((r) => r.beforeScore!).reduce((a, b) => a + b) /
              completed.length;
    final avgAfter = completed.isEmpty
        ? 0.0
        : completed.map((r) => r.afterScore!).reduce((a, b) => a + b) /
              completed.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'คะแนนก่อนเรียน-หลังเรียน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        // Align(topCenter) not Center() — Center() vertically centers the
        // whole scroll view when content is shorter than the viewport,
        // making the page look like it "shrinks to the middle" instead of
        // staying pinned to the top.
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 18,
                    16,
                    isDesktop ? 24 : 18,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        avgBefore,
                        avgAfter,
                        completed.length,
                        allResults.length,
                      ),
                      const SizedBox(height: 14),
                      _buildChartCard(completed),
                      const SizedBox(height: 20),
                      for (final group in _mockGroups) ...[
                        _buildSubjectHeader(group),
                        const SizedBox(height: 10),
                        for (final result in group.results) ...[
                          _buildResultCard(result, group.subjectColor),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Hero gradient band — same brand gradient used on the home page hero, so
  // this reads as the headline number instead of just another white card.
  Widget _buildSummaryCard(
    double avgBefore,
    double avgAfter,
    int completedCount,
    int totalCount,
  ) {
    final improvement = avgAfter - avgBefore;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        decoration: const BoxDecoration(
          gradient: SchoolPalette.primaryGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ภาพรวมพัฒนาการของฉัน',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ทำแบบทดสอบครบแล้ว $completedCount จาก $totalCount บท',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildHeroStat(
                    'เฉลี่ยก่อนเรียน',
                    avgBefore.toStringAsFixed(1),
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _buildHeroStat(
                    'เฉลี่ยหลังเรียน',
                    avgAfter.toStringAsFixed(1),
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _buildHeroStat(
                    'พัฒนาขึ้นเฉลี่ย',
                    '${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}',
                    accent: improvement > 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, {bool accent = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent ? SchoolPalette.mint : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(List<_LessonQuizResult> completed) {
    if (completed.isEmpty) return const SizedBox.shrink();

    final peak = completed.reduce((a, b) => a.delta >= b.delta ? a : b);
    final peakIndex = completed.indexOf(peak);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'พัฒนาการรายบท',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
              ),
              _buildLegendRow(),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_controller.value);
              return SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ProgressChartPainter(
                    results: completed,
                    progress: t,
                    highlightIndex: peakIndex,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow() {
    Widget dot(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: SchoolPalette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        dot(SchoolPalette.muted, 'ก่อนเรียน'),
        const SizedBox(width: 16),
        dot(SchoolPalette.mint, 'หลังเรียน'),
      ],
    );
  }

  Widget _buildSubjectHeader(_SubjectQuizGroup group) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: group.subjectColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(group.icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          group.subjectName,
          style: const TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(_LessonQuizResult result, Color subjectColor) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.chapterNumber,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.title,
                      style: const TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.hasBoth)
                _buildDeltaChip(result.delta)
              else
                _buildPendingChip(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildScorePill(
                  label: 'ก่อนเรียน',
                  score: result.beforeScore,
                  maxScore: result.maxScore,
                  color: SchoolPalette.muted,
                  bg: const Color(0xFFF1F5F9),
                  fillColor: const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFFC7C7CC),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildScorePill(
                  label: 'หลังเรียน',
                  score: result.afterScore,
                  maxScore: result.maxScore,
                  color: subjectColor,
                  bg: subjectColor.withValues(alpha: 0.08),
                  fillColor: subjectColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorePill({
    required String label,
    required int? score,
    required int maxScore,
    required Color color,
    required Color bg,
    required Color fillColor,
  }) {
    final hasScore = score != null;
    final effectiveColor = hasScore ? color : const Color(0xFFC7C7CC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasScore ? bg : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hasScore ? '$score/$maxScore' : 'ยังไม่ทำ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveColor,
              fontSize: hasScore ? 16 : 12.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: hasScore ? score / maxScore : 0,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation(
                hasScore ? fillColor : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaChip(int delta) {
    final isPositive = delta > 0;
    final color = isPositive ? SchoolPalette.mint : SchoolPalette.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.remove_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}$delta',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'รอทำ',
        style: TextStyle(
          color: SchoolPalette.muted,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Draws a modern dual-line chart (before/after) with a soft gradient fill
/// under the "after" line, animated dots, and a small floating badge baked
/// directly into the canvas above the chapter with the biggest improvement
/// — [progress] goes 0→1 to give the chart a "draw in" reveal.
class _ProgressChartPainter extends CustomPainter {
  _ProgressChartPainter({
    required this.results,
    required this.progress,
    this.highlightIndex,
  });

  final List<_LessonQuizResult> results;
  final double progress;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    const topPad = 34.0;
    const bottomPad = 22.0;
    final chartHeight = size.height - topPad - bottomPad;
    final maxScore = results
        .map((r) => r.maxScore)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final stepX = results.length > 1 ? size.width / (results.length - 1) : 0.0;

    double xAt(int i) => results.length > 1 ? i * stepX : size.width / 2;
    double yAt(int score) =>
        topPad + chartHeight - (score / maxScore) * chartHeight;

    // Faint horizontal gridlines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = topPad + chartHeight * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final visibleCount = (results.length * progress).clamp(1, results.length);
    final visibleResults = results.sublist(0, visibleCount.ceil());

    Path buildPath(int Function(_LessonQuizResult) scoreOf) {
      final path = Path();
      for (var i = 0; i < visibleResults.length; i++) {
        final x = xAt(i);
        final y = yAt(scoreOf(visibleResults[i]));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = xAt(i - 1);
          final prevY = yAt(scoreOf(visibleResults[i - 1]));
          final midX = (prevX + x) / 2;
          path.cubicTo(midX, prevY, midX, y, x, y);
        }
      }
      return path;
    }

    final beforePath = buildPath((r) => r.beforeScore ?? 0);
    final afterPath = buildPath((r) => r.afterScore ?? 0);

    // Gradient fill under the "after" line — the visual focal point.
    final fillPath = Path.from(afterPath)
      ..lineTo(xAt(visibleResults.length - 1), topPad + chartHeight)
      ..lineTo(xAt(0), topPad + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          SchoolPalette.mint.withValues(alpha: 0.28),
          SchoolPalette.mint.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPad, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final beforeLinePaint = Paint()
      ..color = SchoolPalette.muted.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(beforePath, beforeLinePaint);

    final afterLinePaint = Paint()
      ..color = SchoolPalette.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(afterPath, afterLinePaint);

    // Dots on top of each line, plus a small "halo" on the after-dot to
    // make the improvement line feel like the hero of the chart.
    for (var i = 0; i < visibleResults.length; i++) {
      final result = visibleResults[i];
      final x = xAt(i);

      if (result.beforeScore != null) {
        final y = yAt(result.beforeScore!);
        canvas.drawCircle(
          Offset(x, y),
          3.2,
          Paint()..color = SchoolPalette.muted,
        );
        canvas.drawCircle(
          Offset(x, y),
          3.2,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }

      if (result.afterScore != null) {
        final y = yAt(result.afterScore!);
        final isPeak = i == highlightIndex && progress > 0.98;
        if (isPeak) {
          canvas.drawCircle(
            Offset(x, y),
            9,
            Paint()..color = SchoolPalette.mint.withValues(alpha: 0.16),
          );
        }
        canvas.drawCircle(
          Offset(x, y),
          4.2,
          Paint()..color = SchoolPalette.mint,
        );
        canvas.drawCircle(
          Offset(x, y),
          4.2,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );

        if (isPeak && result.beforeScore != null) {
          _drawPeakBadge(canvas, size, x, y, result.delta);
        }
      }

      // Chapter label under each point.
      final label = result.chapterNumber.replaceAll('บทที่ ', 'บ.');
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: SchoolPalette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPad + 6),
      );
    }
  }

  // A compact pill baked directly into the canvas above the chart's best
  // point — avoids the overlay-widget positioning bugs of a floating
  // tooltip while still calling out the standout result.
  void _drawPeakBadge(Canvas canvas, Size size, double x, double y, int delta) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$delta',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingH = 8.0;
    const paddingV = 4.0;
    final badgeWidth = textPainter.width + paddingH * 2;
    const badgeHeight = 20.0;
    var badgeLeft = x - badgeWidth / 2;
    badgeLeft = badgeLeft.clamp(0.0, size.width - badgeWidth);
    final badgeTop = (y - badgeHeight - 10).clamp(0.0, size.height.toDouble());

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = SchoolPalette.ink
        ..style = PaintingStyle.fill,
    );
    textPainter.paint(
      canvas,
      Offset(badgeLeft + paddingH, badgeTop + paddingV),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.results != results ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}
