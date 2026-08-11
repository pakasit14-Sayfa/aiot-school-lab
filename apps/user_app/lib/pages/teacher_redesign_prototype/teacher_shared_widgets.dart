// PROTOTYPE ONLY: small reusable UI bits shared by the teacher-side mock
// pages (รายวิชา/นักเรียน/ตรวจงาน/คะแนน) so each page doesn't redefine the
// same card chrome. Kept intentionally tiny — just chrome, no state/logic.

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette, TeacherAppDrawer;

class TeacherSectionCard extends StatelessWidget {
  const TeacherSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: TeacherPalette.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// การ์ดสรุปตัวเลขเล็ก ๆ ใช้ซ้ำในหน้า "นักเรียน" (สรุปสถานะห้อง) และ
/// หน้า "คะแนน" (G-Score/เฉลี่ย) — ไอคอนอยู่ในกล่องสี, ตัวเลขใหญ่, label เล็ก
class TeacherStatCard extends StatelessWidget {
  const TeacherStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: TeacherPalette.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TeacherPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ชิปสถานะสี (ใช้กับสถานะนักเรียน/สถานะงานตรวจ) — พื้นอ่อน+ตัวหนังสือเข้ม
/// ของสีเดียวกัน ให้ครูกวาดตาเห็นปัญหาได้เร็วโดยไม่ต้องอ่านข้อความ
class TeacherStatusChip extends StatelessWidget {
  const TeacherStatusChip({
    required this.label,
    required this.color,
    super.key,
  });

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

void showTeacherMockAction(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label (mock)'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// โครง Scaffold มาตรฐานของหน้า mock ฝั่งครู (AppBar โปร่ง + กลับ + จำกัด
/// ความกว้างเนื้อหา + topCenter กันปัญหาเนื้อหาสั้นแล้ว "หด" ไปกลางจอ)
class TeacherMockPageShell extends StatelessWidget {
  const TeacherMockPageShell({
    required this.title,
    required this.builder,
    this.actions,
    super.key,
  });

  final String title;
  final Widget Function(BuildContext context, bool isDesktop) builder;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherPalette.page,
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TeacherPalette.ink,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'เมนูนำทาง',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1080 : 640),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
