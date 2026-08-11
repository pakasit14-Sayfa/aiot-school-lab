import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../notifications_page.dart';
import '../../../widgets/course_card.dart';
import 'student_redesign_palette.dart';
import 'aiot_weather_sensors_card.dart';
import 'school_encouragement_card.dart';
import 'academy_quick_actions.dart';
import 'academy_continue_learning_card.dart';
import 'academy_tasks_due_card.dart';
import 'learning_progress_card.dart';
import 'student_course_catalog_page.dart';

class StudentVariantSchoolHome extends StatefulWidget {
  const StudentVariantSchoolHome({super.key, this.onViewScore});

  /// Lets the G-Score summary card open the full "คะแนน" page — the score
  /// snapshot lives on the home page since it updates daily, while the full
  /// breakdown is one tap away instead of living in the main nav.
  final VoidCallback? onViewScore;

  @override
  State<StudentVariantSchoolHome> createState() =>
      _StudentVariantSchoolHomeState();
}

class _StudentVariantSchoolHomeState extends State<StudentVariantSchoolHome> {
  final List<Map<String, String>> _activeSafetyAlerts = [
    {
      'id': 'ALT-101',
      'title': 'แจ้งเตือนฝันตกสะสมและน้ำขังผิวถนน ⚠️',
      'content':
          'หลีกเลี่ยงการสัญจรบริเวณด้านหลังอาคาร 4 และใกล้สระน้ำ เนื่องจากกระเบื้องลื่นและอาจเกิดการลื่นล้มได้ง่าย',
      'area': 'หลังอาคาร 4',
    },
    {
      'id': 'ALT-102',
      'title': 'ประกาศซ้อมหนีไฟและฝึกซ้อมความปลอดภัย 🔥',
      'content':
          'ขอให้นักเรียนทุกคนศึกษาจุดรวมพลของอาคารเรียนตนเอง คาบเรียนที่ 7 จะมีการจำลองซ้อมสัญญาณอพยพหนีไฟ',
      'area': 'ทุกอาคารเรียน',
    },
  ];

  Widget _buildSafetyAlertBanner() {
    if (_activeSafetyAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final alert = _activeSafetyAlerts.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: const Color(0xFFFEF3C7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ประกาศความปลอดภัยด่วน 🚨',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'พื้นที่: ${alert['area']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['title']!,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert['content']!,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12.0,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Align แทน Row(mainAxisAlignment: end) — Row เดี่ยวแบบ
                  // นี้เจอ BoxConstraints ความกว้างไม่จำกัดในบาง layout
                  // (เช่น sidebar เดสก์ท็อป) ทำให้ทั้งหน้าพังแบบเงียบ ๆ ใน
                  // release build (ไม่มี assert เตือนเหมือน debug)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _activeSafetyAlerts.removeAt(0);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'รับทราบประกาศความปลอดภัยเรียบร้อยแล้ว',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'รับทราบประกาศ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = screenWidth >= 1024;
            final horizontalPadding = screenWidth < 520 ? 12.0 : 16.0;
            final sectionGap = screenWidth < 520 ? 14.0 : 18.0;
            final afterSummaryGap = screenWidth < 520 ? 8.0 : 10.0;

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1180 : 720),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrototypeBanner(context),
                    const SizedBox(height: 12),
                    _buildSafetyAlertBanner(),
                    _buildHeroHeader(context),
                    const SizedBox(height: 16),
                    const AiotBuildingResourceChartCard(),
                    SizedBox(height: afterSummaryGap),
                    _buildTopSectionGrid(
                      context,
                      onViewScore: widget.onViewScore,
                    ),
                    SizedBox(height: sectionGap),
                    const AcademyQuickActions(),
                    SizedBox(height: sectionGap),
                    const AcademyContinueLearningCard(),
                    SizedBox(height: sectionGap),
                    const AcademyTasksDueCard(),
                    SizedBox(height: sectionGap),
                    _buildAnnouncementsCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrototypeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.0),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_rounded, size: 15, color: Color(0xFFEA580C)),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              '🧪 โต๊ะลองงาน (PROTOTYPE SANDBOX) · Variant A',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFC2410C),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 430;
        final mascotSize = isCompact ? 176.0 : 220.0;
        final textRight = isCompact ? 132.0 : 210.0;
        final titleSize = isCompact ? 31.0 : 38.0;

        return SizedBox(
          height: isCompact ? 262 : 286,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F3E33),
                        Color(0xFF165042),
                        Color(0xFF2A6B58),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26165042),
                        blurRadius: 22,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: CustomPaint(painter: _SchoolHeroPatternPainter()),
                ),
              ),
              Positioned(
                right: isCompact ? -8 : 18,
                top: isCompact ? 14 : 2,
                child: SizedBox(
                  width: mascotSize,
                  height: mascotSize,
                  child: Image.asset(
                    'assets/images/mascot_lion_anim.png',
                    width: mascotSize,
                    height: mascotSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/mascot_lion_anim.gif',
                        width: mascotSize,
                        height: mascotSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/mascot_lion_clean.png',
                            width: mascotSize,
                            height: mascotSize,
                            fit: BoxFit.contain,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                left: 24,
                right: textRight,
                top: isCompact ? 34 : 38,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดีตอนเช้า,',
                      style: TextStyle(
                        color: SchoolPalette.cream,
                        fontSize: isCompact ? 19 : 23,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'สายฟ้า!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'มาต่อบทเรียน AIoT และงานทดลองวันนี้กัน',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: isCompact ? 15 : 17,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                bottom: 26,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isCompact ? 304 : 360,
                    minWidth: isCompact ? 288 : 328,
                  ),
                  child: const LearningProgressCard(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSectionGrid(
    BuildContext context, {
    VoidCallback? onViewScore,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTwoColumn = width >= 900;
        final columnGap = width >= 1100 ? 18.0 : 14.0;

        if (!isTwoColumn) {
          return Column(
            children: [
              const AiotWeatherSensorsCard(),
              const SizedBox(height: 16),
              AcademyLearningScoreCard(onTap: onViewScore),
              const SizedBox(height: 16),
              const SchoolEncouragementCard(),
            ],
          );
        }

        final scoreCardHeight = width >= 1100 ? 238.0 : 232.0;
        final encouragementCardHeight = width >= 1100 ? 192.0 : 186.0;
        final sensorCardHeight =
            scoreCardHeight + encouragementCardHeight + columnGap;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: AiotWeatherSensorsCard(height: sensorCardHeight),
            ),
            SizedBox(width: columnGap),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: scoreCardHeight,
                    child: AcademyLearningScoreCard(onTap: onViewScore),
                  ),
                  SizedBox(height: columnGap),
                  SizedBox(
                    height: encouragementCardHeight,
                    child: SchoolEncouragementCard(
                      height: encouragementCardHeight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnnouncementsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ข่าวสารประกาศโรงเรียน',
                style: TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: SchoolPalette.green,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text(
                    'ดูทั้งหมด',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
          child: SoftCard(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x337C3AED),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'แจ้งเตือนย้ายห้องเรียนชั่วคราว',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SchoolPalette.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          Text(
                            '10 นาทีที่แล้ว',
                            style: TextStyle(
                              color: SchoolPalette.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'เนื่องจากมีการซ่อมบำรุงเซนเซอร์ AIoT ในห้องแล็บ 2 วันนี้ ให้เปลี่ยนไปใช้ห้องแล็บ 1 อาคารวิทยาศาสตร์แทนครับ',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AiotBuildingResourceChartCard extends StatelessWidget {
  const AiotBuildingResourceChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA3E635)),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 2,
                      top: 4,
                      child: Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFD97706),
                        size: 16,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 4,
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF0284C7),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คะแนนประหยัดพลังงานของอาคารเรียน ⚡💧',
                      style: TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'ภาพรวมทั้งอาคาร (ยิ่งคะแนนสูง ยิ่งประหยัดได้ดีเยี่ยม)',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '73.5 คะแนน',
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'ระดับ: ประหยัดดีเยี่ยม 🏆',
                    style: TextStyle(
                      color: const Color(0xFF16A34A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chart section (Combined average in %)
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 95,
                      getTitlesWidget: (value, meta) {
                        final valInt = value.toInt();
                        if (valInt == 100) {
                          return const Text(
                            '100 (ประหยัดมาก)',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          );
                        } else if (valInt == 75) {
                          return const Text(
                            '75 (ประหยัดดี)',
                            style: TextStyle(
                              color: SchoolPalette.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          );
                        } else if (valInt == 50) {
                          return const Text(
                            '50 (ปานกลาง)',
                            style: TextStyle(
                              color: SchoolPalette.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          );
                        } else if (valInt == 25) {
                          return const Text(
                            '25 (ใช้ไฟเยอะ)',
                            style: TextStyle(
                              color: Color(0xFFEA580C),
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          );
                        } else if (valInt == 0) {
                          return const Text(
                            '0 (ใช้เยอะมาก)',
                            style: TextStyle(
                              color: Color(0xFFE11D48),
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1, // Fixes repeating labels
                      getTitlesWidget: (value, meta) {
                        const days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[index],
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 55), // Mon: (52% + 58%) / 2 = 55%
                      FlSpot(1, 63.5), // Tue: (65% + 62%) / 2 = 63.5%
                      FlSpot(2, 80), // Wed: (82% + 78%) / 2 = 80%
                      FlSpot(3, 59), // Thu: (58% + 60%) / 2 = 59%
                      FlSpot(4, 86.5), // Fri: (88% + 85%) / 2 = 86.5%
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD1FAE5).withValues(alpha: 0.4),
                          const Color(0xFFE0F2FE).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEFF4F8)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.tips_and_updates_rounded,
                color: Color(0xFF16A34A),
                size: 13,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'คิดจากปริมาณน้ำและไฟที่อาคารใช้จริง ยิ่งใช้น้อย คะแนนยิ่งสูงขึ้น! 💡',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AcademyLearningScoreCard extends StatelessWidget {
  const AcademyLearningScoreCard({super.key, this.onTap});

  /// Opens the full "คะแนน" page with subject grades, trend, and badges.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: SchoolPalette.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x6643AC60),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'คะแนนและผลการเรียน G-Score (ภาคเรียนที่ 1/2569)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SchoolPalette.muted,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              const tiles = [
                LearningScoreTile(
                  icon: Icons.military_tech_rounded,
                  label: 'คะแนน G-Score รวม',
                  value: '92 / 100',
                  status: 'ระดับดีเยี่ยม',
                  color: Color(0xFF0284C7),
                  bgTint: Color(0xFFE0F2FE),
                ),
                LearningScoreTile(
                  icon: Icons.grade_rounded,
                  label: 'เกรดเฉลี่ยสะสม',
                  value: 'GPA 3.85',
                  status: 'เกียรตินิยม',
                  color: Color(0xFFEA580C),
                  bgTint: Color(0xFFFFEDD5),
                ),
                LearningScoreTile(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'ภาระงานที่ส่งแล้ว',
                  value: '18 / 20 งาน',
                  status: 'ส่งครบ 100%',
                  color: Color(0xFF059669),
                  bgTint: Color(0xFFD1FAE5),
                ),
                LearningScoreTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'เหรียญ & แบดจ์',
                  value: '15 แบดจ์',
                  status: 'ผู้เชี่ยวชาญ AIoT',
                  color: Color(0xFFD97706),
                  bgTint: Color(0xFFFEF3C7),
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: tiles[0]),
                        const SizedBox(width: 8),
                        Expanded(child: tiles[1]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: tiles[2]),
                        const SizedBox(width: 8),
                        Expanded(child: tiles[3]),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: tiles
                    .map(
                      (tile) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: tile,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: content,
    );
  }
}

class LearningScoreTile extends StatelessWidget {
  const LearningScoreTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.color,
    required this.bgTint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color color;
  final Color bgTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
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

class _SchoolHeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.3;

    for (var x = -size.height; x < size.width; x += 92) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.58, size.height),
        linePaint,
      );
    }

    final glowPaint = Paint()
      ..color = SchoolPalette.yellow.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      44,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.86),
      56,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
