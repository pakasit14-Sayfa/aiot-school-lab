import 'dart:async';
import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';

class SchoolEncouragementCard extends StatefulWidget {
  const SchoolEncouragementCard({super.key, this.height});

  final double? height;

  @override
  State<SchoolEncouragementCard> createState() =>
      _SchoolEncouragementCardState();
}

class _SchoolEncouragementCardState extends State<SchoolEncouragementCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'badge': 'คติพจน์ประจำวัน 🌟',
      'icon': Icons.format_quote_rounded,
      'bgIcon': Icons.landscape_rounded,
      'bgColor': const Color(0xFF14532D),
      'accentColor': SchoolPalette.lime,
      'title': 'เรียนทีละนิด\nทำสม่ำเสมอ\nผลลัพธ์จะชัดขึ้น',
      'subtitle': null,
    },
    {
      'badge': 'ประหยัดพลังงาน ม.5/2 ⚡',
      'icon': Icons.bolt_rounded,
      'bgIcon': Icons.eco_rounded,
      'bgColor': const Color(0xFF9A3412),
      'accentColor': const Color(0xFFFDE047),
      'title': 'ห้อง ม.5/2 วันนี้\nประหยัดไฟ 14.8%\nลด 3.2 kg CO₂',
      'subtitle': 'ช่วยกันปิดไฟและแอร์เมื่อเลิกใช้งาน 💡',
    },
    {
      'badge': 'เกร็ดความรู้ AIoT 🍃',
      'icon': Icons.lightbulb_rounded,
      'bgIcon': Icons.sensors_rounded,
      'bgColor': const Color(0xFF075985),
      'accentColor': const Color(0xFF38BDF8),
      'title': 'อุณหภูมิ 25°C\nประหยัดไฟสูงสุด\nสมองตื่นตัวพร้อมเรียน',
      'subtitle': 'สภาพแวดล้อมดี ช่วยเพิ่มสมาธิ 🎯',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];

    return Container(
      width: double.infinity,
      height: widget.height ?? 162,
      decoration: BoxDecoration(
        color: currentSlide['bgColor'] as Color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (currentSlide['bgColor'] as Color).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -16,
              child: Icon(
                currentSlide['bgIcon'] as IconData,
                size: 100,
                color: (currentSlide['accentColor'] as Color).withValues(
                  alpha: 0.22,
                ),
              ),
            ),
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            slide['icon'] as IconData,
                            color: slide['accentColor'] as Color,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: (slide['accentColor'] as Color).withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: (slide['accentColor'] as Color)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              slide['badge'] as String,
                              style: TextStyle(
                                color: slide['accentColor'] as Color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        slide['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.22,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (slide['subtitle'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          slide['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (currentSlide['accentColor'] as Color)
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
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
}
