// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// 2026-08-16: จุดเริ่มต้นของโฟลเดอร์ผู้ปกครอง — ตรวจสอบวอลต์กลาง
// (AIoT-School-Lab-Vault) แล้วพบว่าผู้ปกครองมี 11 UC: STK-1/STK-1a (ผูก
// บัญชี+อนุมัติ — STK-1a เป็นสิทธิ์ครู/admin ไม่ใช่ผู้ปกครอง จึงไม่ได้สร้าง
// หน้าในนี้), STK-2 (ดูคะแนนบุตร), STK-3 (ดูพัฒนาการบุตร), STK-4 (แจ้งเตือน
// ฉุกเฉิน), STK-5 (รายงานสรุปเป็นระยะ), CON-1..5 (ยินยอม/PDPA) ดูรายละเอียด
// ที่มาของแต่ละหน้าใน NOTES.md ของโฟลเดอร์นี้
//
// ธีมสีแยกจากบทบาทอื่นโดยตั้งใจ (ตามธรรมเนียมเดิมของโปรเจกต์ — แต่ละบทบาท
// มีธีม/widget ของตัวเอง ไม่ import ข้ามโฟลเดอร์) ใช้ teal/emerald เป็นสีหลัก
// สื่อถึงความอบอุ่น/ไว้วางใจ ต่างจาก purple ของครู, indigo ของผอ, green สด
// ของนักเรียน
import 'package:flutter/material.dart';

class ParentTheme {
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color primaryTealLight = Color(0xFF14B8A6);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color softText = Color(0xFF475569);
  static const Color border = Color(0xFFE2E8F0);
  static const Color lightTealBg = Color(0xFFF0FDFA);
  static const Color tealBorder = Color(0xFF99F6E4);
  static const Color bgSlate = Color(0xFFF4F6F8);

  static const Color safeGreen = Color(0xFF059669);
  static const Color warningOrange = Color(0xFFD97706);
  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color infoCyan = Color(0xFF0284C7);
}

/// การ์ดกริดที่ยุบจำนวนคอลัมน์อัตโนมัติเมื่อจอแคบลง — แพทเทิร์นเดียวกับ
/// FacilityResponsiveGrid/ExecutiveResponsiveGrid (ไม่ import ข้ามโฟลเดอร์)
class ParentResponsiveGrid extends StatelessWidget {
  const ParentResponsiveGrid({
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

class ParentGlassCard extends StatelessWidget {
  const ParentGlassCard({
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
        border: Border.all(color: ParentTheme.border),
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

class ParentStatusChip extends StatelessWidget {
  const ParentStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// mock เด็ก 1 คนที่ผูกกับบัญชีผู้ปกครองแล้ว — ใช้ 2 คนใน mock data เพื่อ
/// สาธิตตัวสลับบุตร (Main Flow ของ STK-2/STK-3 มีขั้น "เลือกบุตร" ชัดเจน
/// แปลว่าผู้ปกครอง 1 คนอาจมีบุตรมากกว่า 1 คนในระบบพร้อมกันได้)
class ParentChildMock {
  const ParentChildMock({
    required this.id,
    required this.name,
    required this.gradeRoom,
    required this.avatarColor,
    required this.avatarIcon,
  });

  final String id;
  final String name;
  final String gradeRoom;
  final Color avatarColor;
  final IconData avatarIcon;
}

const parentMockChildren = [
  ParentChildMock(
    id: 'child-1',
    name: 'ด.ช. ปุณณ์ ใจดี',
    gradeRoom: 'ม.5/2',
    avatarColor: ParentTheme.primaryTeal,
    avatarIcon: Icons.face_rounded,
  ),
  ParentChildMock(
    id: 'child-2',
    name: 'ด.ญ. ปวีณ์ ใจดี',
    gradeRoom: 'ม.2/1',
    avatarColor: Color(0xFFDB2777),
    avatarIcon: Icons.face_3_rounded,
  ),
];

/// ตัวสลับบุตร ใช้ซ้ำได้ทุกหน้าที่ต้อง "เลือกบุตร" ก่อนแสดงข้อมูล (STK-2/
/// STK-3/STK-4/STK-5 Main Flow ข้อ 1 ทุกตัวเริ่มจากขั้นนี้เหมือนกัน)
class ParentChildSwitcher extends StatelessWidget {
  const ParentChildSwitcher({
    super.key,
    required this.children,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ParentChildMock> children;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (children.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final child = children[index];
          final isSelected = child.id == selectedId;
          return InkWell(
            onTap: () => onSelected(child.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? ParentTheme.primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? ParentTheme.primaryTeal
                      : ParentTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : child.avatarColor.withValues(alpha: 0.12),
                    child: Icon(
                      child.avatarIcon,
                      size: 15,
                      color: isSelected ? Colors.white : child.avatarColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        child.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : ParentTheme.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        child.gradeRoom,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : ParentTheme.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Scaffold มาตรฐานของหน้า mock ฝั่งผู้ปกครอง — AppBar โปร่ง + กลับ + จำกัด
/// ความกว้างเนื้อหา + topCenter กันปัญหาเนื้อหาสั้นแล้ว "หด" ไปกลางจอ
/// (แพทเทิร์นเดียวกับ TeacherMockPageShell แต่แบบง่าย ไม่มี sidebar ถาวร
/// เพราะผู้ปกครองไม่ใช่บทบาทที่ต้องสลับหน้าถี่แบบครู)
class ParentMockPageShell extends StatelessWidget {
  const ParentMockPageShell({
    super.key,
    required this.title,
    required this.builder,
  });

  final String title;
  final Widget Function(BuildContext context, bool isDesktop) builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentTheme.bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: ParentTheme.ink,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 640),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: builder(context, isDesktop),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
