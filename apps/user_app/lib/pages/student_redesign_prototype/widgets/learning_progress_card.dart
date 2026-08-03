import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';

class LearningProgressCard extends StatefulWidget {
  const LearningProgressCard({super.key});

  @override
  State<LearningProgressCard> createState() => _LearningProgressCardState();
}

class _LearningProgressCardState extends State<LearningProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();

    // Smooth Apple-style single controller for fill & gentle breathing
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.72).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _breathAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 15,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Minimalist iOS Clean Progress Gauge
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathAnimation.value,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 4.8,
                              backgroundColor: const Color(0xFFF1F5F9),
                              color: const Color(0xFF10B981),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF10B981),
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isCompact
                                ? 'ความคืบหน้าการเรียน'
                                : 'ความคืบหน้าภาคเรียน',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'อัปเดตแล้ว',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompact
                          ? 'คำนวณจากบทเรียน งาน และการเข้าเรียน'
                          : 'คำนวณจากบทเรียน งาน และการเข้าเรียนของภาคเรียนนี้',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: const [
                          MiniStatBadge(
                            icon: Icons.menu_book_rounded,
                            label: '12/20 บทเรียน',
                            color: Color(0xFF0284C7),
                          ),
                          SizedBox(width: 10),
                          MiniStatBadge(
                            icon: Icons.assignment_turned_in_rounded,
                            label: 'ส่งครบ 8/8',
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 10),
                          MiniStatBadge(
                            icon: Icons.fact_check_rounded,
                            label: 'เข้าเรียน 7/10',
                            color: Color(0xFFEA580C),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MiniStatBadge extends StatelessWidget {
  const MiniStatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13.5),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
