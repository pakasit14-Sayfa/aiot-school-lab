import 'dart:ui';
import 'package:flutter/material.dart';
import 'facility_ux_states.dart';

/// 🎨 Facility Redesign Design System Colors & Theme Tokens (3-Color Steel Blue Palette)
class FacilityTheme {
  // 3 Primary Colors from User Palette:
  // 1. #1C4B62 (Deep Ocean Steel Blue - Primary Brand Base)
  // 2. #CD3318 (Crimson Terracotta Red - Critical SOS Emergency)
  // 3. #E8A519 (Warm Mustard Gold - Warning & Follow-up)

  static const Color primaryBlue = Color(
    0xFF1C4B62,
  ); // #1C4B62 (Primary Steel Blue)
  static const Color primaryNavy = Color(0xFF1C4B62); // #1C4B62
  static const Color primaryPurple = Color(
    0xFF1C4B62,
  ); // #1C4B62 Alias for compatibility
  static const Color inkIndigo = Color(
    0xFF0F2E3D,
  ); // #0F2E3D (Darkest Steel Blue Text)
  static const Color softMauve = Color(
    0xFF3B6E87,
  ); // #3B6E87 (Muted Steel Blue Text)
  static const Color irisAccent = Color(0xFFE8A519); // #E8A519 Accent
  static const Color periwinkleTint = Color(0xFFE8A519);
  static const Color lavenderSoft = Color(0xFFD3E2EC);
  static const Color lightPurpleBg = Color(
    0xFFF4F6F8,
  ); // Clean Soft Gray Page Background (#F4F6F8)
  static const Color purpleCardBg =
      Colors.white; // Crisp Solid White Card (#FFFFFF)
  static const Color purpleBorder = Color(
    0xFFE2E8F0,
  ); // Crisp Light Gray Border (#E2E8F0)
  static const Color bgSlate = Color(0xFFF4F6F8);

  // Functional Status Colors (Incorporating User Palette Hex Codes)
  static const Color safeGreen = Color(0xFF059669); // #059669 (Normal / Safe)
  static const Color warningOrange = Color(
    0xFFE8A519,
  ); // #E8A519 (Warm Mustard Gold)
  static const Color emergencyRed = Color(
    0xFFCD3318,
  ); // #CD3318 (Crimson Terracotta Red)
  static const Color infoCyan = Color(
    0xFF1C4B62,
  ); // #1C4B62 (Deep Ocean Steel Blue)

  // Text Colors
  static const Color textDark = Color(0xFF0F2E3D);
  static const Color textMuted = Color(0xFF3B6E87);
}

/// 🧊 Glassmorphic Card (BackdropFilter Real Blur) for Facility UI
class FacilityGlassCard extends StatelessWidget {
  const FacilityGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 28,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// การ์ดกริดที่ยุบจำนวนคอลัมน์อัตโนมัติเมื่อจอแคบลง — แทนที่
/// `Row(children: [Expanded(...), Expanded(...), ...])` แบบตายตัวที่ไม่
/// ยุบเลยตอนจอมือถือแคบ ทำให้การ์ดบีบจนอ่านไม่ออก (ตามแพทเทิร์น "Mobile
/// responsive UI UX guideline" ที่ผู้ใช้ส่งมา — คอลัมน์เท่ากันแถวเดียวบน
/// จอกว้าง รีโฟลว์เป็นน้อยคอลัมน์ลง/ซ้อนกันเมื่อพื้นที่ไม่พอ)
///
/// ใช้แทนทุกจุดที่เคยเป็น "N การ์ดเท่ากันเรียงแถวเดียว" ในโฟลเดอร์นี้
/// (quick actions, KPI cards, summary cards ฯลฯ) — ไม่ใช้กับแถบ step
/// progress indicator เพราะจุดประสงค์ต่างกัน (step ต้องบีบรวมกันเสมอ
/// ไม่ใช่ซ้อนกัน)
class FacilityResponsiveGrid extends StatelessWidget {
  const FacilityResponsiveGrid({
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

/// 🔔 3-Tier Notification Banner (Critical / Warning / Info)
enum FacilityNotificationTier { critical, warning, info }

class FacilityNotificationBanner extends StatelessWidget {
  const FacilityNotificationBanner({
    super.key,
    required this.tier,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onActionPressed,
    this.onDismiss,
  });

  final FacilityNotificationTier tier;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onActionPressed;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color iconColor;
    IconData iconData;

    switch (tier) {
      case FacilityNotificationTier.critical:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFCA5A5);
        iconColor = FacilityTheme.emergencyRed;
        iconData = Icons.warning_amber_rounded;
        break;
      case FacilityNotificationTier.warning:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFCD34D);
        iconColor = FacilityTheme.warningOrange;
        iconData = Icons.error_outline_rounded;
        break;
      case FacilityNotificationTier.info:
        bg = const Color(0xFFF0F9FF);
        border = const Color(0xFF7DD3FC);
        iconColor = FacilityTheme.infoCyan;
        iconData = Icons.info_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FacilityTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onActionPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: FacilityTheme.textMuted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

/// 🚨 Emergency Floating SOS Trigger Button with 1-Step Confirm Dialog
class FacilityFloatingSOSButton extends StatelessWidget {
  const FacilityFloatingSOSButton({
    super.key,
    required this.onSOSTriggered,
    this.compact = false,
  });

  final Function(String location, String details) onSOSTriggered;

  /// 2026-08-15: จอมือถือ (compact=true) ใช้ปุ่มกลมไอคอนล้วน แทน extended
  /// FAB ที่มีข้อความ — ยังคงอยู่ตำแหน่งเดิม (ล่างขวา/กลาง) เพราะเป็นโซนที่
  /// นิ้วโป้งเอื้อมถึงง่ายตอนถือมือเดียว (ตรงกับ STK-12 Main Flow 3b ที่
  /// ต้องกดได้ทันทีจากทุกหน้า) แค่ลดขนาด/ตัดข้อความออกให้บังพื้นที่น้อยลง
  /// และเข้ากับรอยบากตรงกลาง bottom nav ได้พอดีกว่า — จอกว้าง (desktop)
  /// ยังคงข้อความไว้เพราะมีพื้นที่เหลือและช่วยให้เข้าใจปุ่มได้ไวขึ้น
  final bool compact;

  // 2026-08-15: เดิม "จุดเกิดเหตุ" เป็นช่องข้อความอิสระ พิมพ์เป็นอาคารไหน
  // ก็ได้ — ขัดกับหลัก scope=อาคารที่รับผิดชอบเท่านั้น (เหมือนที่แก้ไปแล้ว
  // ในหน้า dashboard/ควบคุมไฟ-น้ำ) ล็อกอาคารเป็นค่าคงที่ ให้เลือกได้แค่ชั้น
  // ภายในอาคารเดียวกัน ส่วนจุดที่แน่นอน (เช่น "หน้าห้อง 204") ใส่ในช่อง
  // รายละเอียดแทน — ยังคงยืดหยุ่นพอสำหรับอธิบายจุดเกิดเหตุจริงตอนฉุกเฉิน
  static const _assignedBuilding = 'อาคาร 3 (วิทยาศาสตร์)';
  static const _floorOptions = ['ชั้น 1', 'ชั้น 2', 'ชั้น 3'];

  void _showSOSConfirmModal(BuildContext context) {
    var selectedFloor = _floorOptions[1];
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: FacilityTheme.emergencyRed,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แจ้งเหตุฉุกเฉิน (SOS Alert)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: FacilityTheme.emergencyRed,
                          ),
                        ),
                        Text(
                          'กดเพื่อกระจายสัญญาณเตือนด่วนไปยังทีมครูและช่างทันที',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: FacilityTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'จุดเกิดเหตุ (ล็อกตามอาคารที่รับผิดชอบ):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FacilityTheme.bgSlate,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: FacilityTheme.softMauve,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              _assignedBuilding,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: FacilityTheme.inkIndigo,
                              ),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedFloor,
                              isDense: true,
                              icon: const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: FacilityTheme.emergencyRed,
                              ),
                              style: const TextStyle(
                                color: FacilityTheme.emergencyRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                              onChanged: (val) {
                                if (val == null) return;
                                setDialogState(() => selectedFloor = val);
                              },
                              items: _floorOptions.map((f) {
                                return DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'รายละเอียดเหตุการณ์ (ถ้ามี):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: detailsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'เช่น พบกลุ่มควัน, น้ำรั่วซึมรุนแรง, ประตูล็อคขัดข้อง...',
                        filled: true,
                        fillColor: FacilityTheme.bgSlate,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(
                      color: FacilityTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    onSOSTriggered(
                      '$_assignedBuilding $selectedFloor',
                      detailsController.text.trim(),
                    );
                  },
                  icon: const Icon(Icons.warning_rounded, size: 18),
                  label: const Text(
                    'ยืนยันส่ง SOS ด่วน (1 ขั้นตอน)',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacilityTheme.emergencyRed,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return FloatingActionButton(
        onPressed: () => _showSOSConfirmModal(context),
        backgroundColor: FacilityTheme.emergencyRed,
        elevation: 6,
        highlightElevation: 10,
        tooltip: 'แจ้งเหตุ SOS',
        child: const Icon(
          Icons.campaign_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    }
    return FloatingActionButton.extended(
      onPressed: () => _showSOSConfirmModal(context),
      backgroundColor: FacilityTheme.emergencyRed,
      elevation: 6,
      highlightElevation: 10,
      icon: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
      label: const Text(
        'แจ้งเหตุ SOS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// 📱 Layout Container Shell (Desktop Sidebar vs Mobile Bottom Nav)
class FacilityAppShell extends StatefulWidget {
  const FacilityAppShell({
    super.key,
    required this.child,
    required this.selectedRouteIndex,
    required this.onNavigate,
    required this.onSOSTriggered,
    this.activeAreaAlertLocation,
  });

  final Widget child;
  final int selectedRouteIndex;
  final Function(int index) onNavigate;
  final Function(String location, String details) onSOSTriggered;

  /// STK-12 BR6: Warning Light ที่ผู้ดูแลอาคารเปิดเองผ่านปุ่มลอย "แจ้งเหตุ
  /// SOS" ต้องรอครู/ผู้บริหารยืนยันก่อนปิดเท่านั้น — ผู้ดูแลอาคารปิดเอง
  /// ไม่ได้ จึง null = ไม่มีสัญญาณเตือนค้าง, ไม่ null = มีสัญญาณเตือนพื้นที่
  /// ค้างอยู่ (เก็บชื่อจุดเกิดเหตุไว้แสดงในแบนเนอร์) แบนเนอร์นี้ตั้งใจไม่มี
  /// ปุ่มปิด/dismiss ให้กด เพื่อบังคับ BR6 ในระดับ UI
  final String? activeAreaAlertLocation;

  @override
  State<FacilityAppShell> createState() => _FacilityAppShellState();
}

class _FacilityAppShellState extends State<FacilityAppShell> {
  bool _isCompact = false;

  static const _navItems = [
    {'title': 'ภาพรวม', 'icon': Icons.space_dashboard_rounded},
    // 2026-08-14: เดิมชื่อ "เปิด-ปิดอาคาร" เป็น checklist wizard ไม่มี UC
    // ทางการรองรับ — เปลี่ยนเป็นควบคุมไฟ-น้ำ (STK-11) แทนแล้ว ยังคงชื่อ
    // เมนูให้สื่อความหมายเดิมที่ผู้ใช้เข้าใจ (เปิด/ปิดของในอาคาร)
    {'title': 'เปิด-ปิดไฟ/น้ำ (STK-11)', 'icon': Icons.lightbulb_rounded},
    // 2026-08-15: เดิมชื่อ "เหตุและ SOS" — หน้านี้ตอนนี้จำกัดสโคปเหลือแค่
    // เหตุการณ์อุปกรณ์/โครงสร้างอาคารตาม STK-12 (เหตุฉุกเฉินบุคคลไม่อยู่ใน
    // ลิสต์นี้แล้ว ใช้ปุ่มลอย FacilityFloatingSOSButton แทน) เปลี่ยนชื่อ
    // เมนูให้สื่อสโคปที่ถูกต้อง กันสับสนกับปุ่ม "แจ้งเหตุ SOS" ลอยที่แยกกัน
    {
      'title': 'เหตุอุปกรณ์/อาคาร (STK-12)',
      'icon': Icons.report_problem_rounded,
    },
    {'title': 'แผนที่อาคาร', 'icon': Icons.map_rounded},
    {'title': 'งานซ่อมบำรุง', 'icon': Icons.build_rounded},
    {'title': 'อุปกรณ์ AIoT', 'icon': Icons.sensors_rounded},
    // 2026-08-15: ตัด 'เวรและการตรวจ' ทิ้ง — ไล่หา UC รองรับใน STK-6..12
    // แล้วไม่เจอตัวไหนพูดถึงตารางเวร/รอบตรวจของผู้ดูแลอาคารเลย (แจ้งผู้ใช้
    // แล้ว ผู้ใช้ยืนยันให้ตัดทิ้ง) ทำให้ index ตั้งแต่ 'Storybook' เป็นต้น
    // ไปเลื่อนขึ้นมา 1 ตำแหน่ง — อัปเดต switch ใน
    // FacilityStorybookPage._buildActivePage() ให้ตรงกันแล้ว
    {'title': ' Storybook', 'icon': Icons.auto_awesome_rounded},
    // เพิ่มท้ายลิสต์เสมอ ห้ามแทรกกลาง — index ของแต่ละแถวถูก hardcode ใช้
    // ในสวิตช์ที่ FacilityStorybookPage._buildActivePage() และปุ่ม
    // _buildMobileBottomNav() ด้วย แทรกกลางจะเลื่อน index ตัวอื่นทั้งหมด
    {'title': 'ภาพรวมอาคาร (สเปกใหม่)', 'icon': Icons.thermostat_rounded},
    {'title': 'สุขภาพอุปกรณ์ (STK-9)', 'icon': Icons.health_and_safety_rounded},
    {'title': 'รายงานความปลอดภัย (STK-10)', 'icon': Icons.security_rounded},
    // STK-6 (พลังงาน) ไม่มีเมนูแยก — รวมเป็นแท็บใน "ภาพรวมอาคาร (สเปกใหม่)"
    // (facility_building_overview_page.dart) แล้ว อย่าเพิ่มเมนูแยกอีก
    // เคยมีไฟล์ facility_energy_dashboard_page.dart ซ้ำมาก่อน ลบไปแล้ว
    //
    // 2026-08-14: เคยรวม "ภาพรวมอาคาร (สเปกใหม่)" เข้ากับ "ภาพรวม" (index 0)
    // เป็นหน้าเดียวช่วงสั้นๆ วันเดียวกัน แล้วแยกกลับมาตามคำขอผู้ใช้ — จะ
    // ปรับปรุงทีละหน้าแบบค่อยเป็นค่อยไปแทน ดู NOTES.md หัวข้อ "แยกกลับ"
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: FacilityTheme.bgSlate,
      body: Column(
        children: [
          if (widget.activeAreaAlertLocation != null)
            _buildAreaAlertBanner(widget.activeAreaAlertLocation!),
          Expanded(child: isDesktop ? _buildDesktopLayout() : widget.child),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
      floatingActionButton: FacilityFloatingSOSButton(
        onSOSTriggered: widget.onSOSTriggered,
        compact: !isDesktop,
      ),
      floatingActionButtonLocation: isDesktop
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerDocked,
    );
  }

  /// STK-12 BR6 — ไม่มี onDismiss ให้ตั้งใจ ผู้ดูแลอาคารปิดสัญญาณนี้เองไม่ได้
  /// ต้องรอครู/ผู้บริหารยืนยันปิดจากฝั่งของครูเท่านั้น (ยังไม่ implement ฝั่ง
  /// ครูในโปรโตไทป์นี้ — ปุ่ม "แจ้งเตือนซ้ำ" เป็นแค่ ping ซ้ำ ไม่ใช่ปิด)
  Widget _buildAreaAlertBanner(String location) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: FacilityNotificationBanner(
        tier: FacilityNotificationTier.critical,
        title: '🔴 สัญญาณเตือนพื้นที่เปิดอยู่ (แจ้งเชิงรุกโดยผู้ดูแลอาคาร)',
        message:
            'จุดเกิดเหตุ: $location · รอครู/ผู้บริหารยืนยันปิดเท่านั้น '
            '(เกิน 15 นาทีไม่มีผู้ยืนยัน ระบบจะยกระดับแจ้ง School Admin '
            'ให้ยืนยันปิดแทน)',
        actionLabel: 'แจ้งเตือนซ้ำ',
        onActionPressed: () {
          FacilityUXStates.showSuccessToast(
            context,
            'ส่งแจ้งเตือนซ้ำไปยังครู/ผู้บริหารในพื้นที่แล้ว',
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Deep Steel Blue Sidebar (#1C4B62)
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          width: _isCompact ? 80 : 250,
          color: const Color(0xFF1C4B62),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Color(0xFFE8A519),
                        size: 24,
                      ),
                    ),
                    if (!_isCompact) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'FACILITY SMART',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isCompact = !_isCompact;
                        });
                      },
                      icon: Icon(
                        _isCompact
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      tooltip: _isCompact ? 'ขยาย Sidebar' : 'ย่อ Sidebar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // MAIN Section Label
              if (!_isCompact)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'MAIN',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

              // Navigation List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _navItems.length,
                  itemBuilder: (context, idx) {
                    final isSelected = idx == widget.selectedRouteIndex;
                    final item = _navItems[idx];
                    final icon = item['icon'] as IconData;
                    final title = item['title'] as String;

                    if (_isCompact) {
                      return Tooltip(
                        message: title,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => widget.onNavigate(idx),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE8A519)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? const Color(0xFF0F2E3D)
                                    : Colors.white70,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => widget.onNavigate(idx),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8A519)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x30E8A519),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                color: isSelected
                                    ? const Color(0xFF0F2E3D)
                                    : Colors.white,
                                size: 21,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: isSelected
                                        ? const Color(0xFF0F2E3D)
                                        : Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 5,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F2E3D),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // SUPPORT Section & Bottom Promo Card
              if (!_isCompact) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ศูนย์ควบคุมอาคาร',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ตรวจสอบความปลอดภัย และควบคุมฮาร์ดแวร์เรียลไทม์',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            widget.onNavigate(2); // Jump to Incident Inbox
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8A519),
                            foregroundColor: const Color(0xFF0F2E3D),
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: const Text('ดูรายละเอียด'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Main Content Area with Ultra Soft Purple Page Background
        Expanded(
          child: Container(
            color: FacilityTheme.lightPurpleBg,
            child: widget.child,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () => widget.onNavigate(0),
            icon: Icon(
              Icons.space_dashboard_rounded,
              color: widget.selectedRouteIndex == 0
                  ? FacilityTheme.primaryBlue
                  : FacilityTheme.textMuted,
            ),
            tooltip: 'ภาพรวม',
          ),
          IconButton(
            onPressed: () => widget.onNavigate(1),
            icon: Icon(
              Icons.lightbulb_rounded,
              color: widget.selectedRouteIndex == 1
                  ? FacilityTheme.primaryBlue
                  : FacilityTheme.textMuted,
            ),
            tooltip: 'เปิด-ปิดไฟ/น้ำ',
          ),
          const SizedBox(width: 40), // Gap for center floating SOS button
          IconButton(
            onPressed: () => widget.onNavigate(2),
            icon: Icon(
              Icons.report_problem_rounded,
              color: widget.selectedRouteIndex == 2
                  ? FacilityTheme.primaryBlue
                  : FacilityTheme.textMuted,
            ),
            tooltip: 'เหตุอุปกรณ์/อาคาร (STK-12)',
          ),
          IconButton(
            onPressed: () => _showMoreMenu(context),
            icon: Icon(
              // ปุ่ม "เพิ่มเติม" — เข้าถึงเมนูที่เหลือทั้งหมด (index 3-9)
              // รวม STK-6(ใหม่)/STK-9/STK-10 ที่ก่อนหน้านี้เข้าจากมือถือ
              // ไม่ได้เลยเพราะ bottom nav มีแค่ 4 ปุ่มคงที่ index 0/1/2/7
              Icons.more_horiz_rounded,
              color: widget.selectedRouteIndex >= 3
                  ? FacilityTheme.primaryBlue
                  : FacilityTheme.textMuted,
            ),
            tooltip: 'เพิ่มเติม',
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'เมนูทั้งหมด',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: FacilityTheme.inkIndigo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 3; i < _navItems.length; i++)
                  ListTile(
                    leading: Icon(
                      _navItems[i]['icon'] as IconData,
                      color: widget.selectedRouteIndex == i
                          ? FacilityTheme.primaryPurple
                          : FacilityTheme.inkIndigo,
                    ),
                    title: Text(
                      (_navItems[i]['title'] as String).trim(),
                      style: TextStyle(
                        fontWeight: widget.selectedRouteIndex == i
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: widget.selectedRouteIndex == i
                            ? FacilityTheme.primaryPurple
                            : FacilityTheme.inkIndigo,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      widget.onNavigate(i);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
