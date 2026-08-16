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
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.design_services_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ฟังก์ชัน "$label" อยู่ในช่วงการออกแบบดีไซน์ (UI Prototype)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF0F172A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        // จอกว้างมาก (เช่นจอคอมทั่วไป ≥1600px รวม sidebar แล้ว) ให้ขยาย
        // พื้นที่เนื้อหาตามไปด้วย แทนที่จะตรึงไว้แค่ 1080 เท่ากับ tablet —
        // เผื่อความกว้างของ sidebar ที่หักออกไปแล้วในเลย์เอาต์นี้
        final contentMaxWidth = screenConstraints.maxWidth >= 1600
            ? 1320.0
            : (isWideDesktop ? 1080.0 : 640.0);

        final content = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
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

/// เมนูปุ่ม 3 จุด (Kebab Menu) ดีไซน์สำเร็จรูปสำหรับทั้งโปรเจกต์
/// มีตัวเลือก: แก้ไข, คัดลอก/ทำซ้ำ, ดูรายละเอียด, แชร์ และ ลบ (พร้อม Confirmation Dialog)
enum TeacherActionType { edit, duplicate, viewDetails, share, delete }

class TeacherThreeDotsMenu extends StatelessWidget {
  const TeacherThreeDotsMenu({
    required this.onSelected,
    this.itemTitle = 'รายการนี้',
    this.iconColor,
    this.showDelete = true,
    super.key,
  });

  final ValueChanged<TeacherActionType> onSelected;
  final String itemTitle;
  final Color? iconColor;
  final bool showDelete;

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text(
              'ยืนยันการลบข้อมูล',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการลบ "$itemTitle" ใช่หรือไม่?\nการดำเนินการนี้ไม่สามารถกู้คืนได้',
          style: const TextStyle(color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onSelected(TeacherActionType.delete);
            },
            child: const Text(
              'ลบรายการ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TeacherActionType>(
      onSelected: (action) {
        if (action == TeacherActionType.delete) {
          _showDeleteDialog(context);
        } else {
          onSelected(action);
        }
      },
      tooltip: 'ตัวเลือกเพิ่มเติม',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      offset: const Offset(0, 38),
      color: Colors.white,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: TeacherActionType.edit,
          height: 40,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF334155)),
              SizedBox(width: 10),
              Text(
                'แก้ไขข้อมูล',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: TeacherActionType.duplicate,
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.content_copy_rounded,
                size: 18,
                color: Color(0xFF334155),
              ),
              SizedBox(width: 10),
              Text(
                'คัดลอก / ทำซ้ำ',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: TeacherActionType.viewDetails,
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Color(0xFF334155),
              ),
              SizedBox(width: 10),
              Text(
                'ดูรายละเอียด',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: TeacherActionType.share,
          height: 40,
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 18, color: Color(0xFF334155)),
              SizedBox(width: 10),
              Text(
                'แชร์ / ส่งออก',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        if (showDelete) ...[
          const PopupMenuDivider(height: 12),
          const PopupMenuItem(
            value: TeacherActionType.delete,
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
                SizedBox(width: 10),
                Text(
                  'ลบรายการนี้',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: iconColor ?? const Color(0xFF64748B),
        ),
      ),
    );
  }
}

/// ป้ายสถานะแอนิเมชัน 6 รูปแบบ (Animated Status Badges & Pills)
/// รองรับ: สำเร็จ, ไม่สำเร็จ, กำลังโหลด, กำลังอัปโหลด, อัปโหลดไม่สำเร็จ, โหลดไม่สำเร็จ
enum StatusBadgeType {
  success,
  failed,
  loading,
  uploading,
  uploadFailed,
  loadFailed,
}

class AnimatedStatusBadge extends StatefulWidget {
  const AnimatedStatusBadge({
    required this.type,
    this.customText,
    this.progress,
    this.onRetry,
    super.key,
  });

  final StatusBadgeType type;
  final String? customText;
  final double? progress;
  final VoidCallback? onRetry;

  @override
  State<AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case StatusBadgeType.success:
        return _buildBadgeChrome(
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFFA7F3D0),
          fg: const Color(0xFF059669),
          text: widget.customText ?? 'ทำสำเร็จ',
          leading: ScaleTransition(
            scale: _pulseAnim,
            child: const Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: Color(0xFF059669),
            ),
          ),
        );

      case StatusBadgeType.failed:
        return _buildBadgeChrome(
          bg: const Color(0xFFFEF2F2),
          border: const Color(0xFFFECACA),
          fg: const Color(0xFFDC2626),
          text: widget.customText ?? 'ทำไม่สำเร็จ',
          leading: ScaleTransition(
            scale: _pulseAnim,
            child: const Icon(
              Icons.cancel_rounded,
              size: 15,
              color: Color(0xFFDC2626),
            ),
          ),
        );

      case StatusBadgeType.loading:
        return _buildBadgeChrome(
          bg: const Color(0xFFF0F9FF),
          border: const Color(0xFFBAE6FD),
          fg: const Color(0xFF0284C7),
          text: widget.customText ?? 'กำลังโหลด...',
          leading: const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),
        );

      case StatusBadgeType.uploading:
        return _buildBadgeChrome(
          bg: const Color(0xFFEEF2FF),
          border: const Color(0xFFC7D2FE),
          fg: const Color(0xFF4F46E5),
          text: widget.progress != null
              ? 'กำลังอัปโหลด ${(widget.progress! * 100).toInt()}%'
              : (widget.customText ?? 'กำลังอัปโหลด...'),
          leading: AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
              );
            },
          ),
          showProgress: widget.progress != null,
          progressValue: widget.progress,
        );

      case StatusBadgeType.uploadFailed:
        return _buildBadgeChrome(
          bg: const Color(0xFFFFF7ED),
          border: const Color(0xFFFDE68A),
          fg: const Color(0xFFD97706),
          text: widget.customText ?? 'อัปโหลดไม่สำเร็จ',
          leading: ScaleTransition(
            scale: _pulseAnim,
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 15,
              color: Color(0xFFD97706),
            ),
          ),
          onRetry: widget.onRetry,
        );

      case StatusBadgeType.loadFailed:
        return _buildBadgeChrome(
          bg: const Color(0xFFF1F5F9),
          border: const Color(0xFFCBD5E1),
          fg: const Color(0xFF475569),
          text: widget.customText ?? 'โหลดไม่สำเร็จ',
          leading: ScaleTransition(
            scale: _pulseAnim,
            child: const Icon(
              Icons.error_outline_rounded,
              size: 15,
              color: Color(0xFF475569),
            ),
          ),
          onRetry: widget.onRetry,
        );
    }
  }

  Widget _buildBadgeChrome({
    required Color bg,
    required Color border,
    required Color fg,
    required String text,
    required Widget leading,
    bool showProgress = false,
    double? progressValue,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: fg.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
          if (showProgress && progressValue != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: fg.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.refresh_rounded, size: 14, color: fg),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
