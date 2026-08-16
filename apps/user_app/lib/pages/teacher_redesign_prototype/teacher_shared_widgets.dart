// PROTOTYPE ONLY: small reusable UI bits shared by the teacher-side mock
// pages (รายวิชา/นักเรียน/ตรวจงาน/คะแนน) so each page doesn't redefine the
// same card chrome. Kept intentionally tiny — just chrome, no state/logic.

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart'
    show TeacherPalette, TeacherAppDrawer, TeacherPersistentSidebar;

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
class TeacherMockPageShell extends StatefulWidget {
  const TeacherMockPageShell({
    required this.title,
    required this.builder,
    this.actions,
    this.activeMenuLabel,
    super.key,
  });

  final String title;
  final Widget Function(BuildContext context, bool isDesktop) builder;
  final List<Widget>? actions;

  /// ชื่อเมนู sidebar ที่ตรงกับหน้านี้ (เช่น 'รายวิชา', 'นักเรียน') — ใช้
  /// ไฮไลต์เมนูที่ถูกต้องใน Drawer ให้ทำงานเหมือนหน้าแดชบอร์ด แทนที่จะ
  /// ไม่ไฮไลต์อะไรเลยหรือค้างไฮไลต์ผิดหน้า
  final String? activeMenuLabel;

  @override
  State<TeacherMockPageShell> createState() => _TeacherMockPageShellState();
}

class _TeacherMockPageShellState extends State<TeacherMockPageShell> {
  // null = ให้จอกว้างขยาย sidebar ไว้เสมอ, true/false = ครูกดปุ่มเก็บ/
  // ขยายเองแล้ว จำค่านั้นไว้ทับ default จนกว่าจะกดสลับอีกที — พฤติกรรม
  // เดียวกับปุ่มเก็บ/ขยาย sidebar ของหน้าแดชบอร์ด
  bool? _manualCompact;

  void _toggleSidebar(bool currentlyCompact) {
    setState(() => _manualCompact = !currentlyCompact);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, screenConstraints) {
        // จอกว้าง (>=900px) ปักหมุด sidebar ไว้ค้างข้างซ้ายเหมือนหน้า
        // แดชบอร์ด แทนที่จะต้องกดแฮมเบอร์เกอร์เปิด Drawer ทุกครั้ง —
        // จอแคบยังใช้ Drawer เดิมเพราะพื้นที่ไม่พอวาง sidebar ค้าง
        final isWideDesktop = screenConstraints.maxWidth >= 900;
        final sidebarCompact = _manualCompact ?? false;

        final content = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWideDesktop ? 1080 : 640),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: widget.builder(context, isWideDesktop),
            ),
          ),
        );

        final titleRow = Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (widget.actions != null) ...widget.actions!,
            ],
          ),
        );

        if (isWideDesktop) {
          // จอกว้าง: ไม่ใช้ AppBar คั่นด้านบน sidebar เหมือนหน้าแดชบอร์ด
          // — ถ้าใช้ AppBar ร่วมกันทั้งแถว sidebar จะเริ่มต่ำกว่าแนว
          // ขอบบนจริง ทำให้สูง/สัดส่วนต่างจาก sidebar ของหน้าแดชบอร์ด
          // ที่ไม่มี AppBar คั่นเลย ชื่อหน้าย้ายไปอยู่ในคอลัมน์เนื้อหาแทน
          return Scaffold(
            backgroundColor: TeacherPalette.page,
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TeacherPersistentSidebar(
                    activeLabel: widget.activeMenuLabel,
                    compact: sidebarCompact,
                    onToggleCompact: () => _toggleSidebar(sidebarCompact),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        titleRow,
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: TeacherPalette.page,
          drawer: TeacherAppDrawer(activeLabel: widget.activeMenuLabel),
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
              widget.title,
              style: const TextStyle(
                color: TeacherPalette.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            actions: widget.actions,
          ),
          body: SafeArea(child: content),
        );
      },
    );
  }
}
