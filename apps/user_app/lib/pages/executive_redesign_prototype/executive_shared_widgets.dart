// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// 2026-08-15: จุดเริ่มต้นของโฟลเดอร์ผู้บริหารสถานศึกษา (ผอ) — ตรวจสอบวอลต์
// กลาง (AIoT-School-Lab-Vault) แล้วพบว่า ผอ มียูสเคสเฉพาะทางแค่ตัวเดียวคือ
// LA-9 "ดูรายงานภาพรวมของสถานศึกษา" (ต่างจากผู้ดูแลอาคารที่มี 7 ยูสเคส)
// ดูรายละเอียดที่มาของแต่ละองค์ประกอบใน NOTES.md ของโฟลเดอร์นี้
//
// ธีมสีแยกจาก FacilityTheme โดยตั้งใจ — ให้แต่ละบทบาทมีธีมของตัวเอง (ตาม
// แพทเทิร์นเดียวกับ facility_redesign_prototype/teacher_redesign_prototype/
// student_redesign_prototype ที่ต่างก็มีธีมแยกกัน) สีหลักใช้ indigo เข้ม
// (สื่อถึงอำนาจ/ความน่าเชื่อถือ) ส่วนสีความหมาย (แดง/เขียว/ส้ม) คงไว้
// เหมือนกับ FacilityTheme เพื่อให้ผู้ใช้แอปคุ้นเคยไม่ต้องเรียนรู้ใหม่
import 'package:flutter/material.dart';

class ExecutiveTheme {
  static const Color primaryIndigo = Color(0xFF312E81);
  static const Color primaryIndigoLight = Color(0xFF4C46B8);
  static const Color inkIndigo = Color(0xFF0F172A);
  static const Color softMauve = Color(0xFF64748B);
  static const Color goldAccent = Color(0xFFE8A519);
  static const Color lightIndigoBg = Color(0xFFEEF2FF);
  static const Color indigoBorder = Color(0xFFC7D2FE);
  static const Color bgSlate = Color(0xFFF4F6F8);

  static const Color safeGreen = Color(0xFF059669);
  static const Color warningOrange = Color(0xFFD97706);
  static const Color emergencyRed = Color(0xFFCD3318);
  static const Color infoCyan = Color(0xFF0284C7);
}

/// การ์ดกริดที่ยุบจำนวนคอลัมน์อัตโนมัติเมื่อจอแคบลง — ยกแพทเทิร์นเดียวกับ
/// FacilityResponsiveGrid มา (ไม่ import ข้ามโฟลเดอร์ เพื่อให้แต่ละบทบาท
/// เป็นอิสระจากกัน ตามธรรมเนียมเดิมของโปรเจกต์นี้)
class ExecutiveResponsiveGrid extends StatelessWidget {
  const ExecutiveResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.minItemWidth = 220,
  });

  final List<Widget> children;
  final double spacing;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final rawColumns = ((maxWidth + spacing) / (minItemWidth + spacing))
            .floor();
        final columns = rawColumns.clamp(1, children.length);
        final itemWidth = (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class ExecutiveGlassCard extends StatelessWidget {
  const ExecutiveGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
