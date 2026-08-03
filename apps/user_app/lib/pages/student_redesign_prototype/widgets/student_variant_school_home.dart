import 'package:flutter/material.dart';
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

class StudentVariantSchoolHome extends StatelessWidget {
  const StudentVariantSchoolHome({super.key});

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
                    _buildHeroHeader(context),
                    const SizedBox(height: 16),
                    const AcademyTodayExecutiveSummaryBar(),
                    SizedBox(height: afterSummaryGap),
                    _buildTopSectionGrid(context),
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
          Text(
            '🧪 โต๊ะลองงาน (PROTOTYPE SANDBOX) · Variant A',
            style: TextStyle(
              color: Color(0xFFC2410C),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
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

  Widget _buildTopSectionGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTwoColumn = width >= 900;
        final columnGap = width >= 1100 ? 18.0 : 14.0;

        if (!isTwoColumn) {
          return const Column(
            children: [
              AiotWeatherSensorsCard(),
              SizedBox(height: 16),
              AcademyLearningScoreCard(),
              SizedBox(height: 16),
              SchoolEncouragementCard(),
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
                    child: const AcademyLearningScoreCard(),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF7C3AED),
                    size: 24,
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

class AcademyTodayExecutiveSummaryBar extends StatelessWidget {
  const AcademyTodayExecutiveSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_rounded, color: SchoolPalette.green, size: 16),
              SizedBox(width: 6),
              Text(
                'สรุปภาพรวมวันนี้สำหรับนักเรียน',
                style: TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SummaryChip(
                icon: Icons.assignment_late_rounded,
                label: 'งานต้องส่งวันนี้: 2 ชิ้น',
                color: Color(0xFFC2410C),
                bgColor: Color(0xFFFFEDD5),
              ),
              SummaryChip(
                icon: Icons.timer_rounded,
                label: 'ด่วนที่สุด: ใบงานชีววิทยา',
                color: Color(0xFFBE123C),
                bgColor: Color(0xFFFFE4E6),
              ),
              SummaryChip(
                icon: Icons.schedule_rounded,
                label: 'คาบถัดไป: 13:30 น.',
                color: Color(0xFF0369A1),
                bgColor: Color(0xFFE0F2FE),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryChip extends StatelessWidget {
  const SummaryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 238),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AcademyLearningScoreCard extends StatelessWidget {
  const AcademyLearningScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC7E2D0)),
                ),
                child: const Text(
                  'GRADE A+ 🌟',
                  style: TextStyle(
                    color: SchoolPalette.green,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
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
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
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
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
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
