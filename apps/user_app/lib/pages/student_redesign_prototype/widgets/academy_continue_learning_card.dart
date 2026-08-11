import 'package:flutter/material.dart';
import '../../student/course_list_page.dart';
import 'student_redesign_palette.dart';
import 'student_lessons_page.dart';

class AcademyContinueLearningCard extends StatelessWidget {
  const AcademyContinueLearningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'เรียนต่อจากครั้งล่าสุด',
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
                  MaterialPageRoute(builder: (_) => const StudentLessonsPage()),
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
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon Container + Subtitle & Main Title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFF0F172A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'วิชา AIoT สมาร์ตแล็บ • ม.5/1',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'บทเรียนที่ 4: การวิเคราะห์ข้อมูล PM2.5',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SchoolPalette.ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              // Bottom Row: Percentage + Thick Progress Bar + Step Count
              Row(
                children: [
                  const Text(
                    '65%',
                    style: TextStyle(
                      color: Color.fromARGB(255, 28, 127, 70),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PatternedProgressBar(
                      progress: 0.65,
                      height: 10,
                      backgroundColor: const Color(0xFFF1F5F9),
                      fillColor: const Color.fromARGB(255, 28, 127, 70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '4/6',
                    style: TextStyle(
                      color: Color.fromARGB(255, 28, 127, 70),
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PatternedProgressBar extends StatelessWidget {
  const PatternedProgressBar({
    super.key,
    required this.progress,
    required this.fillColor,
    this.backgroundColor = const Color(0xFFF1F5F9),
    this.height = 10.0,
  });

  final double progress;
  final Color fillColor;
  final Color backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _PatternedProgressBarPainter(
          progress: progress,
          fillColor: fillColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _PatternedProgressBarPainter extends CustomPainter {
  _PatternedProgressBarPainter({
    required this.progress,
    required this.fillColor,
    required this.backgroundColor,
  });

  final double progress;
  final Color fillColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    // Draw background track
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(rrect, bgPaint);

    if (progress <= 0) return;

    final progressWidth = size.width * progress.clamp(0.0, 1.0);
    final progressRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, progressWidth, size.height),
      Radius.circular(size.height / 2),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    // Draw solid progress fill
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRRect(progressRRect, fillPaint);

    // Draw subtle micro-dot grid pattern over the progress fill
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    const dotSpacing = 4.5;
    const dotRadius = 1.0;

    for (double y = 2.5; y < size.height; y += dotSpacing) {
      for (double x = 3.0; x < progressWidth; x += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PatternedProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
