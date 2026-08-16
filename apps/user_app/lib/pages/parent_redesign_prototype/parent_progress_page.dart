// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// STK-3: ดูพัฒนาการ/ความก้าวหน้าของบุตร — BR2 สำคัญ: "นำเสนอเชิงสรุป ไม่ลง
// รายละเอียดที่ต้องตีความโดยครู" ต่างจาก STK-2 (คะแนนดิบรายวิชา) หน้านี้
// จึงตั้งใจไม่ใส่ตัวเลขคะแนนดิบ ใช้คำอธิบายเชิงแนวโน้ม/สรุปแทน

import 'package:flutter/material.dart';

import 'parent_shared_widgets.dart';

class _TrendPoint {
  const _TrendPoint(this.label, this.value);
  final String label;
  final double value; // 0..1
}

const _mockTrend = [
  _TrendPoint('ส.ค.', 0.62),
  _TrendPoint('ก.ย.', 0.68),
  _TrendPoint('ต.ค.', 0.65),
  _TrendPoint('พ.ย.', 0.74),
  _TrendPoint('ธ.ค.', 0.80),
];

class ParentProgressPage extends StatelessWidget {
  const ParentProgressPage({super.key, required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'พัฒนาการของบุตร',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              childName,
              style: const TextStyle(
                color: ParentTheme.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ParentGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'แนวโน้มภาพรวม 5 เดือนล่าสุด',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: ParentTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final point in _mockTrend)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      height: 100 * point.value,
                                      color: ParentTheme.primaryTealLight,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    point.label,
                                    style: const TextStyle(
                                      color: ParentTheme.muted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'สรุปสำหรับผู้ปกครอง',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: ParentTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            const _SummaryPoint(
              icon: Icons.trending_up_rounded,
              color: ParentTheme.safeGreen,
              text: 'ผลการเรียนโดยรวมดีขึ้นต่อเนื่องในช่วง 3 เดือนหลัง',
            ),
            const _SummaryPoint(
              icon: Icons.menu_book_rounded,
              color: ParentTheme.primaryTeal,
              text: 'เข้าเรียนและส่งงานสม่ำเสมอ ไม่มีสัญญาณต้องกังวล',
            ),
            const _SummaryPoint(
              icon: Icons.groups_2_rounded,
              color: Color(0xFF0284C7),
              text: 'มีส่วนร่วมในกิจกรรมกลุ่ม/โครงงานดี',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ParentTheme.lightTealBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ParentTheme.tealBorder),
              ),
              child: const Text(
                'ข้อมูลนี้เป็นสรุปเชิงภาพรวมสำหรับผู้ปกครองเท่านั้น หากต้องการ'
                'รายละเอียดเชิงลึก แนะนำให้ปรึกษาครูประจำวิชาโดยตรง',
                style: TextStyle(
                  color: ParentTheme.softText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryPoint extends StatelessWidget {
  const _SummaryPoint({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: ParentTheme.softText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
