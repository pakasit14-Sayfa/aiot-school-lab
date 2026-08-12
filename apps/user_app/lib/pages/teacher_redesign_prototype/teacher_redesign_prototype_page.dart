// PROTOTYPE ONLY: Teacher redesigned workspace.
// Three variants of the teacher dashboard, switchable in-app on
// /prototype/teacher-redesign?variant=A, B, or C.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'teacher_aiot_dashboard_page.dart';
import 'teacher_aiot_lab_page.dart';
import 'teacher_courses_page.dart';
import 'teacher_grades_page.dart';
import 'teacher_grading_page.dart';
import 'teacher_incident_inbox_page.dart';
import 'teacher_notifications_page.dart';
import 'teacher_profile_page.dart';
import 'teacher_rubric_page.dart';
import 'teacher_students_page.dart';

enum TeacherPrototypeVariant {
  a('A', 'Dashboard'),
  b('B', 'Schedule Focus'),
  c('C', 'Review Ops');

  const TeacherPrototypeVariant(this.key, this.label);

  final String key;
  final String label;

  static TeacherPrototypeVariant fromQuery(String? value) {
    return TeacherPrototypeVariant.values.firstWhere(
      (variant) => variant.key.toLowerCase() == value?.toLowerCase(),
      orElse: () => TeacherPrototypeVariant.a,
    );
  }
}

class TeacherRedesignPrototypePage extends StatefulWidget {
  const TeacherRedesignPrototypePage({super.key, this.initialVariant});

  final TeacherPrototypeVariant? initialVariant;

  @override
  State<TeacherRedesignPrototypePage> createState() =>
      _TeacherRedesignPrototypePageState();
}

class _TeacherRedesignPrototypePageState
    extends State<TeacherRedesignPrototypePage> {
  late TeacherPrototypeVariant variant =
      widget.initialVariant ?? TeacherPrototypeVariant.a;

  // null = ให้ breakpoint กำหนดว่าย่อ/ขยาย sidebar เอง, true/false = ครู
  // กดปุ่มเก็บ/ขยายเองแล้ว จำค่านั้นไว้ทับ breakpoint จนกว่าจะกดสลับอีกที
  bool? _sidebarManualCompact;

  void _toggleSidebar(bool currentlyCompact) {
    setState(() => _sidebarManualCompact = !currentlyCompact);
  }

  void _cycle(int direction) {
    final variants = TeacherPrototypeVariant.values;
    final current = variants.indexOf(variant);
    setState(() {
      variant =
          variants[(current + direction + variants.length) % variants.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.12,
        ),
      ),
      child: Scaffold(
        backgroundColor: TeacherPalette.page,
        // Drawer สำหรับมือถือ — จอกว้างใช้ Sidebar อยู่แล้ว แต่จอแคบ
        // (ไม่ผ่าน isTablet) ไม่มีทางเข้าเมนูอื่นเลยนอกจาก AIoT ที่ลิงก์
        // จากการ์ดในแดชบอร์ด จุดนี้คือทางเข้าเมนูทั้งหมดบนมือถือ
        drawer: const _TeacherMobileDrawer(),
        body: switch (variant) {
          TeacherPrototypeVariant.a => _TeacherDashboardVariant(
            currentVariant: variant,
            onVariantSelected: (next) => setState(() => variant = next),
            onPreviousVariant: () => _cycle(-1),
            onNextVariant: () => _cycle(1),
            sidebarManualCompact: _sidebarManualCompact,
            onToggleSidebar: _toggleSidebar,
          ),
          TeacherPrototypeVariant.b => _TeacherScheduleVariant(
            currentVariant: variant,
            onVariantSelected: (next) => setState(() => variant = next),
            onPreviousVariant: () => _cycle(-1),
            onNextVariant: () => _cycle(1),
          ),
          TeacherPrototypeVariant.c => _TeacherOpsVariant(
            currentVariant: variant,
            onVariantSelected: (next) => setState(() => variant = next),
            onPreviousVariant: () => _cycle(-1),
            onNextVariant: () => _cycle(1),
          ),
        },
      ),
    );
  }
}

// พาเลตฟ้าที่ทีมกำหนดมาใหม่ทั้งหมด (ไล่จากเข้มสุด #235284 ไปอ่อนสุด
// #b8e2f4) แทนโทนเขียวเดิม — ใช้แทนที่ TeacherPalette.primary/primary2
// เป็นหลัก เพราะสองตัวนี้ผูกอยู่กับแทบทุกองค์ประกอบ (sidebar, hero,
// การ์ด, sidebar active state) ทำให้เปลี่ยนธีมทั้งหน้าครูจากจุดเดียว
class TeacherPalette {
  static const ink = Color(
    0xFF35204E,
  ); // #35204E (Indigo - Darkest text & headings)
  static const muted = Color(0xFF542E85); // #542E85 (Violet - Subtitles)
  static const softText = Color(0xFF7448A6); // #7448A6 (Mauve - Secondary text)

  // Exact 6 Color Palette from User Screenshot:
  static const indigo = Color(0xFF35204E); // #35204E (Indigo - Darkest Base)
  static const violet = Color(
    0xFF542E85,
  ); // #542E85 (Violet - Deep Button Base!)
  static const mauve = Color(
    0xFF7448A6,
  ); // #7448A6 (Mauve - Primary Brand Base)
  static const iris = Color(0xFF9367C1); // #9367C1 (Iris - Medium Accent)
  static const periwinkle = Color(
    0xFFB186D7,
  ); // #B186D7 (Periwinkle - Soft Accent)
  static const lavender = Color(0xFFC5A9DC); // #C5A9DC (Lavender - Soft Tint)

  // Palette Aliases (Mapped 100% directly to the user screenshot!)
  static const primary = Color(
    0xFF542E85,
  ); // #542E85 (Violet - Deep Dark Purple Button Base!)
  static const primary2 = Color(
    0xFF35204E,
  ); // #35204E (Indigo - Darkest Primary Accent)
  static const skyDeep = Color(0xFF7448A6); // #7448A6 (Mauve)
  static const skyMid = Color(0xFF9367C1); // #9367C1 (Iris)
  static const skyBright = Color(0xFFB186D7); // #B186D7 (Periwinkle)
  static const skySoft = Color(0xFFC5A9DC); // #C5A9DC (Lavender Tint)
  static const skyVivid = Color(
    0xFFE8DBF4,
  ); // #E8DBF4 (Light Soft Lavender Fill)
  static const skyLight = Color(0xFFF6F0FA); // #F6F0FA (Ultra Soft Page Tint)
  static const skyPale = Color(0xFFF8F5FB); // #F8F5FB (Page Background)

  // Functional Status Accents:
  static const blue = Color(0xFF542E85); // Violet
  static const sky = Color(0xFF9367C1); // Iris
  static const orange = Color(0xFFF97316); // Soft Amber Orange
  static const red = Color(0xFFEF4444); // Soft Rose Red
  static const green = Color(0xFF10B981); // Soft Emerald Mint

  static const page =
      Colors.white; // Pure Crisp White Page Background (#FFFFFF)
  static const sidebar = Color(0xFFF1F5F9); // Soft Slate Grey Sidebar (#F1F5F9)
  static const card = Color(
    0xFFF8FAFC,
  ); // Soft Slate Grey Tinted Card (#F8FAFC)
  static const border = Color(0xFFE2E8F0); // Crisp Slate Border (#E2E8F0)
}

/// 5 breakpoints ไล่ระดับตามที่ทีมส่ง reference มา (BP1 การ์ดเดียวไม่มี
/// chrome → BP5 มีครบ sidebar เต็ม + เนื้อหา + panel ขวา) — ใช้ตัวเลขจาก
/// Material Design 3 window-size classes (compact/medium/expanded/
/// large/extra-large) เป็นฐาน เพราะเป็นมาตรฐานที่ทดสอบมาแล้วว่าอ่านง่าย
/// ในแต่ละช่วงความกว้างจริง ไม่ใช่เลขที่เดาขึ้นมาเอง
class _TeacherBreakpoints {
  const _TeacherBreakpoints._();

  /// BP1 — มือถือ: การ์ดเดียว stack เต็มจอ ไม่มี sidebar ไม่มี panel ขวา
  /// เข้าเมนูอื่นผ่าน Drawer (ปุ่มแฮมเบอร์เกอร์) เท่านั้น
  static const compact = 600.0;

  /// BP2 — แท็บเล็ตแนวตั้ง/มือถือแนวนอน: เนื้อหาเดียวกับ BP1 แต่กว้างขึ้น
  /// เริ่มเห็น sidebar แบบย่อ (ไอคอนล้วน ไม่มี label) แทนที่ Drawer
  static const medium = 900.0;

  /// BP3 — แท็บเล็ต/เดสก์ท็อปแคบ: sidebar ย่อ + เนื้อหาหลัก ยังไม่มี
  /// panel ขวา (พื้นที่ไม่พอให้ทั้งสามโซนอ่านง่าย)
  static const expanded = 1200.0;

  /// BP4 — เดสก์ท็อป: sidebar ย่อ + เนื้อหาหลัก + panel ขวา ครบ 3 โซน
  static const large = 1600.0;

  /// BP5 — เดสก์ท็อปจอกว้าง: sidebar ขยายเต็ม (มี label) + เนื้อหาหลัก +
  /// panel ขวา กว้างสบายขึ้น
  static double get extraLarge => large;
}

class _TeacherDashboardVariant extends StatelessWidget {
  const _TeacherDashboardVariant({
    required this.currentVariant,
    required this.onVariantSelected,
    required this.onPreviousVariant,
    required this.onNextVariant,
    required this.sidebarManualCompact,
    required this.onToggleSidebar,
  });

  final TeacherPrototypeVariant currentVariant;
  final ValueChanged<TeacherPrototypeVariant> onVariantSelected;
  final VoidCallback onPreviousVariant;
  final VoidCallback onNextVariant;

  /// เก็บ/ขยาย sidebar ด้วยมือ — null แปลว่ายังไม่กด ให้ breakpoint
  /// (`expandSidebar` ด้านล่าง) เป็นคนตัดสินใจแทน
  final bool? sidebarManualCompact;
  final ValueChanged<bool> onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // BP1 — ต่ำกว่า 600: การ์ดเดียว ไม่มี chrome ใดๆ เข้าเมนูอื่นผ่าน
        // Drawer (ปุ่มแฮมเบอร์เกอร์) เท่านั้น
        if (width < _TeacherBreakpoints.compact) {
          return const _TeacherMobileDashboard();
        }

        // BP2 (600-899): sidebar ย่อโผล่มาแทน Drawer แต่ยังไม่มี panel
        // ขวา — การ์ดที่ปกติอยู่ panel ขวา (โฟกัสวันนี้, งานรอตรวจ ฯลฯ)
        // ยังโชว์แบบ inline ต่อท้ายเนื้อหาหลักไปก่อนเหมือน BP1
        // BP3 (900-1199): เหมือน BP2 แต่มีที่ว่างมากขึ้น เนื้อหาหลักจึง
        // จัดเป็น 2 คอลัมน์ย่อยได้ (การ์ดสรุป/กราฟ กว้างขึ้น) — ยังไม่มี
        // panel ขวาแยกอยู่ดี เพราะกว้างไม่พอให้ 3 โซนอ่านง่ายพร้อมกัน
        // BP4 (1200-1599): panel ขวาแยกออกมาเป็นคอลัมน์ที่ 3 ของจริง
        // BP5 (ตั้งแต่ 1600): sidebar ขยายเต็มมี label แทนไอคอนล้วน
        final isMedium = width < _TeacherBreakpoints.medium;
        final showRightPanel = width >= _TeacherBreakpoints.expanded;
        final expandSidebar = width >= _TeacherBreakpoints.extraLarge;
        final sidebarCompact = sidebarManualCompact ?? !expandSidebar;

        return Row(
          children: [
            _TeacherSidebar(
              compact: sidebarCompact,
              currentVariant: currentVariant,
              onVariantSelected: onVariantSelected,
              onPreviousVariant: onPreviousVariant,
              onNextVariant: onNextVariant,
              onToggleCompact: () => onToggleSidebar(sidebarCompact),
            ),
            Expanded(
              child: _TeacherPageFrame(
                tightPadding: isMedium,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: showRightPanel ? 7 : 1,
                      child: _TeacherMainDashboardContent(
                        includeRightPanelCardsInline: !showRightPanel,
                      ),
                    ),
                    if (showRightPanel) ...[
                      const SizedBox(width: 22),
                      const SizedBox(width: 330, child: _TeacherRightPanel()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeacherScheduleVariant extends StatelessWidget {
  const _TeacherScheduleVariant({
    required this.currentVariant,
    required this.onVariantSelected,
    required this.onPreviousVariant,
    required this.onNextVariant,
  });

  final TeacherPrototypeVariant currentVariant;
  final ValueChanged<TeacherPrototypeVariant> onVariantSelected;
  final VoidCallback onPreviousVariant;
  final VoidCallback onNextVariant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TeacherSidebar(
          compact: true,
          currentVariant: currentVariant,
          onVariantSelected: onVariantSelected,
          onPreviousVariant: onPreviousVariant,
          onNextVariant: onNextVariant,
        ),
        Expanded(
          child: _TeacherPageFrame(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _GlassCard(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: 'ตารางสอนวันนี้',
                          subtitle:
                              'มองคาบเรียนแบบ timeline เพื่อเตรียมสอนให้เร็ว',
                          icon: Icons.calendar_month_rounded,
                        ),
                        const SizedBox(height: 24),
                        ...TeacherMock.lessons.map(
                          (lesson) => _LargeScheduleItem(lesson: lesson),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                const SizedBox(
                  width: 360,
                  child: Column(
                    children: [
                      _TodayFocusCard(),
                      SizedBox(height: 18),
                      _ReviewQueueCard(),
                      SizedBox(height: 18),
                      _SensorSnapshotCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherOpsVariant extends StatelessWidget {
  const _TeacherOpsVariant({
    required this.currentVariant,
    required this.onVariantSelected,
    required this.onPreviousVariant,
    required this.onNextVariant,
  });

  final TeacherPrototypeVariant currentVariant;
  final ValueChanged<TeacherPrototypeVariant> onVariantSelected;
  final VoidCallback onPreviousVariant;
  final VoidCallback onNextVariant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TeacherSidebar(
          compact: true,
          currentVariant: currentVariant,
          onVariantSelected: onVariantSelected,
          onPreviousVariant: onPreviousVariant,
          onNextVariant: onNextVariant,
        ),
        Expanded(
          child: _TeacherPageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TeacherTopBar(title: 'ศูนย์งานครู'),
                const SizedBox(height: 20),
                const _TeacherSummaryStrip(),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                title: 'งานที่ต้องจัดการ',
                                subtitle:
                                    'รวมงานรอตรวจ นักเรียนที่ต้องติดตาม และคาบถัดไป',
                                icon: Icons.task_alt_rounded,
                              ),
                              const SizedBox(height: 18),
                              ...TeacherMock.reviewTasks.map(
                                (task) => _OpsTaskTile(task: task),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      const SizedBox(width: 380, child: _StudentsWatchCard()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherMobileDashboard extends StatelessWidget {
  const _TeacherMobileDashboard();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: const [
          _TeacherMobileHeader(),
          SizedBox(height: 16),
          _TeacherHero(),
          SizedBox(height: 16),
          // การ์ดน้ำ-ไฟ/เซนเซอร์ + AIoT Smart Wiring Lab อยู่ใต้แจ้งเตือนทันที
          // เหนือตารางสอนวันนี้
          _UtilityAndAiotSensorRow(),
          SizedBox(height: 16),
          _SmartWiringLabCard(),
          SizedBox(height: 16),
          // Tier 2 — บริบทการสอนวันนี้ + ต้องติดตาม
          _ScheduleCard(),
          SizedBox(height: 16),
          _ClassesCarousel(),
          SizedBox(height: 16),
          _ReviewQueueCard(),
          SizedBox(height: 16),
          _StudentsWatchCard(),
          SizedBox(height: 16),
          // Tier 3 — ข้อมูลอ้างอิง/สถิติ
          _TeacherSummaryStrip(),
          SizedBox(height: 16),
          _DashboardChartsRow(),
          SizedBox(height: 16),
          _MiniCalendarCard(),
          SizedBox(height: 16),
          _SensorSnapshotCard(),
        ],
      ),
    );
  }
}

class _TeacherPageFrame extends StatelessWidget {
  const _TeacherPageFrame({required this.child, this.tightPadding = false});

  final Widget child;

  /// BP2 (600-899) ใช้ padding แคบกว่า BP3 ขึ้นไป — พื้นที่ข้างเนื้อหา
  /// น้อยกว่าเพราะ sidebar ย่อกินที่ไปแล้วและจอยังไม่กว้างพอ
  final bool tightPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tightPadding ? 16 : 24,
          20,
          tightPadding ? 16 : 24,
          86,
        ),
        child: child,
      ),
    );
  }
}

class _TeacherSidebar extends StatelessWidget {
  const _TeacherSidebar({
    this.compact = false,
    required this.currentVariant,
    required this.onVariantSelected,
    required this.onPreviousVariant,
    required this.onNextVariant,
    this.onToggleCompact,
    this.insideDrawer = false,
    this.forcedActiveLabel,
  });

  final bool compact;
  final TeacherPrototypeVariant currentVariant;
  final ValueChanged<TeacherPrototypeVariant> onVariantSelected;
  final VoidCallback onPreviousVariant;
  final VoidCallback onNextVariant;

  /// true เมื่อ sidebar นี้ถูกแสดงผ่าน Drawer (TeacherAppDrawer) แทนที่จะ
  /// เป็น sidebar ถาวรฝั่งซ้ายของจอกว้าง — ต้องปิด Drawer ก่อนนำทางเสมอ
  /// ไม่งั้น Drawer จะค้างเปิดอยู่ใต้หน้าใหม่ที่ push ทับไป
  final bool insideDrawer;

  /// บังคับ highlight เมนูตาม label ของหน้าปัจจุบัน (ใช้เมื่อ insideDrawer
  /// เพราะ Drawer นี้ใช้ร่วมกันหลายหน้า ไม่ได้ผูกกับ currentVariant จริง)
  final String? forcedActiveLabel;

  /// ปุ่มเก็บ/ขยาย sidebar ด้วยมือ — null ในที่ที่ยังไม่รองรับการสลับเอง
  /// (เช่น Variant B/C ที่ตายแล้ว ไม่ได้ใช้งานจริงผ่าน UI)
  final VoidCallback? onToggleCompact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 96.0 : 248.0;
    return SafeArea(
      right: false,
      // Align(topLeft) กัน Stack ถูกยืดเต็มความสูงจอโดยพ่อแม่ (เช่น
      // Row(crossAxisAlignment: stretch) ของหน้าที่ปักหมุด sidebar) —
      // ถ้าไม่กันไว้ Stack จะสูงเท่าทั้งจอ แล้วปุ่มย่อ/ขยายที่ใช้
      // Positioned.fill + Align(centerRight) จะไปลอยอยู่กึ่งกลางความสูง
      // ทั้งจอแทนที่จะอยู่กึ่งกลางการ์ด sidebar จริง เกิดเป็นพื้นที่ว่าง
      // โล่งๆ ด้านล่างการ์ดพร้อมปุ่มลอยค้างอยู่ตรงนั้น
      child: Align(
        alignment: Alignment.topLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: width,
                  margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 18,
                    18,
                    compact ? 12 : 18,
                    18,
                  ),
                  decoration: BoxDecoration(
                    // alpha เดิม 0.68 ต่ำเกินไป — สีพื้นหลังของแต่ละหน้า
                    // (เช่น hero การ์ดม่วงเข้มของหน้ารายวิชา เทียบกับพื้นขาว
                    // ของแดชบอร์ด) เลยโปร่งทะลุมาทำให้ sidebar ดูคนละสีกัน
                    // ทั้งที่เป็น widget เดียวกัน ปรับให้ทึบขึ้นเพื่อให้สีคงที่
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _TeacherBrandCard(compact: compact),
                      const SizedBox(height: 18),
                      Expanded(
                        child: ListView.separated(
                          itemCount: TeacherMock.menu.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = TeacherMock.menu[index];
                            // forcedActiveLabel != null คือสัญญาณว่า sidebar
                            // นี้ถูกใช้ซ้ำจากหน้าอื่น (Drawer หรือ sidebar
                            // ถาวรของหน้ารายวิชา/นักเรียน/คะแนน) ไม่ใช่
                            // sidebar ของหน้าแดชบอร์ดเอง — ต้อง push ไปจริง
                            // แทนการสลับ variant ภายในหน้าเดิม
                            final isReusedElsewhere = forcedActiveLabel != null;
                            return _SidebarMenuTile(
                              item: item,
                              active: isReusedElsewhere
                                  ? item.label == forcedActiveLabel
                                  : (index == 0 &&
                                        currentVariant ==
                                            TeacherPrototypeVariant.a),
                              compact: compact,
                              onTap: () {
                                if (insideDrawer) Navigator.pop(context);
                                if (item.label == 'แดชบอร์ด') {
                                  if (isReusedElsewhere) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TeacherRedesignPrototypePage(),
                                      ),
                                    );
                                  } else {
                                    onVariantSelected(
                                      TeacherPrototypeVariant.a,
                                    );
                                  }
                                  return;
                                }
                                _openTeacherMenuItem(context, item.label);
                              },
                            );
                          },
                        ),
                      ),
                      _SidebarProfileCard(compact: compact),
                      const SizedBox(height: 10),
                      _SidebarMiniClassCard(compact: compact),
                    ],
                  ),
                ),
              ),
            ),
            // ปุ่มเก็บ/ขยาย sidebar — ลอยทับขอบขวาตรงกึ่งกลางแนวตั้งของ
            // sidebar (ระหว่างการ์ดแบรนด์บนสุดกับการ์ดโปรไฟล์/ห้องประจำชั้น
            // ล่างสุด) แทนที่จะแทรกอยู่ในลิสต์การ์ดแบบเดิม เพื่อให้เป็น
            // "แฮนเดิลย่อ/ขยาย" ที่หยิบกดได้ทุกเมื่อโดยไม่รบกวนเนื้อหา
            if (onToggleCompact != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionalTranslation(
                    translation: const Offset(0.5, 0),
                    child: _SidebarCollapseToggle(
                      compact: compact,
                      onTap: onToggleCompact!,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ปุ่มเก็บ/ขยาย sidebar ด้วยมือ — ลอยทับขอบขวาตรงกึ่งกลางแนวตั้งของ
/// sidebar (ระหว่างการ์ดแบรนด์บนสุดกับการ์ดโปรไฟล์ล่างสุด) เป็นวงกลม
/// เล็กแบบ "แฮนเดิล" คลิกได้ทุกเมื่อ ไม่ต้องรอ breakpoint กว้าง/แคบพอ
class _SidebarCollapseToggle extends StatelessWidget {
  const _SidebarCollapseToggle({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: TeacherPalette.border)),
      elevation: 3,
      shadowColor: const Color(0x330F172A),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            compact
                ? Icons.keyboard_double_arrow_right_rounded
                : Icons.keyboard_double_arrow_left_rounded,
            size: 16,
            color: TeacherPalette.primary,
          ),
        ),
      ),
    );
  }
}

class _TeacherBrandCard extends StatelessWidget {
  const _TeacherBrandCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.all(10)
          : const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TeacherPalette.violet, TeacherPalette.indigo],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24165042),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: compact
          ? const _AvatarBadge(size: 40, icon: Icons.person_rounded)
          : Row(
              children: [
                const _AvatarBadge(size: 54, icon: Icons.person_rounded),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teacher Workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'AIoT Smart School',
                        style: TextStyle(
                          color: Color(0xFFC8E8F7),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  const _SidebarMenuTile({
    required this.item,
    required this.active,
    required this.compact,
    this.onTap,
  });

  final _MenuItem item;
  final bool active;
  final bool compact;
  final VoidCallback? onTap;

  // เมนูแจ้งเหตุฉุกเฉินใช้สีแดงเสมอ ไม่ตามธีมม่วงปกติของเมนูอื่น —
  // เตือนความสำคัญ/ความเร่งด่วนให้ครูสังเกตเห็นได้ทันทีแม้ไม่ได้ active
  bool get _isEmergencyItem => item.label == 'แจ้งเหตุฉุกเฉิน';

  @override
  Widget build(BuildContext context) {
    const emergencyRed = Color(0xFFDC2626);
    final accentColor = _isEmergencyItem
        ? emergencyRed
        : TeacherPalette.primary;

    // ไอคอนอยู่ในกล่องเหลี่ยมมนของตัวเอง (badge) เสมอ ไม่ว่าจะ active
    // หรือไม่ — ต่างจากเดิมที่ไอคอนลอยอยู่เฉยๆ — ตามแบบ reference ที่ส่งมา
    // และเพิ่มแถบสีบางๆ ชิดขอบขวาตอน active แทนกรอบเส้นรอบการ์ดทั้งใบ
    final iconBadge = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.25)
            : (_isEmergencyItem
                  ? emergencyRed.withValues(alpha: 0.12)
                  : const Color(0xFFF1EEF9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.icon,
        color: active ? Colors.white : accentColor,
        size: 20,
      ),
    );

    final content = Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
      decoration: BoxDecoration(
        color: active ? accentColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? accentColor
              : (_isEmergencyItem
                    ? emergencyRed.withValues(alpha: 0.35)
                    : const Color(0xFFE5D5F2)),
          width: 1.2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: compact
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          iconBadge,
          if (!compact) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : (_isEmergencyItem
                            ? emergencyRed
                            : const Color(0xFF0F172A)),
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                ),
              ),
            ),
            if (active)
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: content,
    );
  }
}

class _SidebarProfileCard extends StatelessWidget {
  const _SidebarProfileCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: compact ? 34 : 40,
      height: compact ? 34 : 40,
      decoration: BoxDecoration(
        color: TeacherPalette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: TeacherPalette.primary,
        size: 22,
      ),
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.74),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherProfilePage()),
          );
        },
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(vertical: 10)
              : const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: TeacherPalette.border),
          ),
          child: compact
              ? Center(child: avatar)
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ครูสมชาย สายวิทย์',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: TeacherPalette.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            'ครูผู้สอน AIoT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: TeacherPalette.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: TeacherPalette.softText,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SidebarMiniClassCard extends StatelessWidget {
  const _SidebarMiniClassCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 10)
          : const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5D5F2)),
      ),
      child: compact
          ? const Center(
              child: Icon(
                Icons.groups_rounded,
                color: TeacherPalette.primary,
                size: 20,
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: TeacherPalette.primary,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ห้องประจำชั้น',
                        style: TextStyle(
                          color: TeacherPalette.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        'ม.5/2 · 32 คน',
                        style: TextStyle(
                          color: TeacherPalette.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _TeacherMainDashboardContent extends StatelessWidget {
  const _TeacherMainDashboardContent({
    this.includeRightPanelCardsInline = false,
  });

  /// BP2/BP3 (มี sidebar แต่ยังไม่มีที่ให้ panel ขวาแยกออกมา) — การ์ดที่
  /// ปกติอยู่ panel ขวา (ปฏิทินย่อ, โฟกัสวันนี้, งานรอตรวจ ฯลฯ) จะต่อท้าย
  /// เนื้อหาหลักแทน ไม่ให้หายไปเฉยๆ ตอนจอไม่กว้างพอ
  final bool includeRightPanelCardsInline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _TeacherTopBar(title: 'แดชบอร์ดครู'),
        const SizedBox(height: 20),
        const _EmergencyAlertBanner(),
        const _CameraSecuritySummaryCard(),
        const _TeacherHero(),
        const SizedBox(height: 18),
        // การ์ดน้ำ-ไฟ/เซนเซอร์ + AIoT Smart Wiring Lab อยู่ใต้แจ้งเตือนทันที
        // เหนือตารางสอนวันนี้
        const _UtilityAndAiotSensorRow(),
        const SizedBox(height: 18),
        const _SmartWiringLabCard(),
        const SizedBox(height: 18),
        // Tier 2 — บริบทการสอนวันนี้ (ต้องรู้ก่อนเริ่มคาบ)
        const _ScheduleCard(),
        const SizedBox(height: 20),
        const _ClassesCarousel(),
        const SizedBox(height: 20),
        if (includeRightPanelCardsInline) ...[
          const _TodayFocusCard(),
          const SizedBox(height: 18),
          const _ReviewQueueCard(),
          const SizedBox(height: 18),
          const _StudentsWatchCard(),
          const SizedBox(height: 20),
        ],
        // Tier 3 — ข้อมูลอ้างอิง/สถิติ (ดูตอนไหนก็ได้ ไม่เร่งด่วน)
        const _TeacherSummaryStrip(),
        const SizedBox(height: 20),
        const _DashboardChartsRow(),
        if (includeRightPanelCardsInline) ...[
          const SizedBox(height: 20),
          const _MiniCalendarCard(),
          const SizedBox(height: 18),
          const _SensorSnapshotCard(),
        ],
      ],
    );
  }
}

/// การ์ดกราฟคู่ (bar + donut) ตาม reference ที่ทีมส่งมา — ฝั่งครูใช้ดู
/// "สถานะส่งงานรายห้อง" (แทน body-fluid bar chart) กับ "สัดส่วนสถานะ
/// นักเรียนทั้งหมด" (แทน composition donut chart)
class _DashboardChartsRow extends StatelessWidget {
  const _DashboardChartsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 640;
        final children = [
          const _SubmissionBarChartCard(),
          const _StudentStatusDonutCard(),
        ];
        if (stacked) {
          return Column(
            children: [children[0], const SizedBox(height: 16), children[1]],
          );
        }
        // ห้ามใช้ CrossAxisAlignment.stretch ตรงนี้ — Row นี้เป็นลูกของ
        // ListView (สูงไม่จำกัด) การ stretch แนวตั้งจะสั่งให้ลูกขยายเต็ม
        // ความสูงที่ไม่จำกัด เกิด "BoxConstraints forces an infinite
        // height" ตอนรันจริง (เจอตอนทดสอบ debug build)
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 16),
              Expanded(child: children[1]),
            ],
          ),
        );
      },
    );
  }
}

class _SubmissionBarChartCard extends StatelessWidget {
  const _SubmissionBarChartCard();

  @override
  Widget build(BuildContext context) {
    const rooms = [
      (label: 'ม.5/1', percent: 0.92),
      (label: 'ม.5/2', percent: 0.78),
      (label: 'ม.5/3', percent: 0.65),
      (label: 'ม.6/1', percent: 0.88),
      (label: 'ม.6/2', percent: 0.54),
    ];

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  title: 'สถานะส่งงานรายห้อง',
                  subtitle: 'สัดส่วนนักเรียนที่ส่งงานแล้วในแต่ละห้อง',
                  icon: Icons.bar_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final room in rooms) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(room.percent * 100).round()}%',
                          style: const TextStyle(
                            color: TeacherPalette.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 96 * room.percent,
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    TeacherPalette.skySoft,
                                    TeacherPalette.primary,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          room.label,
                          style: const TextStyle(
                            color: TeacherPalette.ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (room != rooms.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentStatusDonutCard extends StatelessWidget {
  const _StudentStatusDonutCard();

  @override
  Widget build(BuildContext context) {
    const segments = [
      (label: 'ปกติ', percent: 0.78, color: TeacherPalette.green),
      (label: 'ต้องติดตาม', percent: 0.14, color: TeacherPalette.orange),
      (label: 'ขาดส่งงานบ่อย', percent: 0.08, color: TeacherPalette.red),
    ];

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'สัดส่วนสถานะนักเรียน',
            subtitle: 'จากนักเรียนทั้งหมดที่รับผิดชอบ',
            icon: Icons.donut_large_rounded,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(108, 108),
                      painter: _DonutPainter(segments: segments),
                    ),
                    const Text(
                      '132\nคน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in segments) ...[
                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              s.label,
                              style: const TextStyle(
                                color: TeacherPalette.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${(s.percent * 100).round()}%',
                            style: const TextStyle(
                              color: TeacherPalette.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (s != segments.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});

  final List<({String label, double percent, Color color})> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 14.0;
    var startAngle = -1.5708; // -90deg in radians
    for (final segment in segments) {
      final sweep = segment.percent * 6.28319; // 2*pi
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => false;
}

class _TeacherTopBar extends StatelessWidget {
  const _TeacherTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'พุธ 5 ส.ค. · เตรียมคาบสอนและงานตรวจวันนี้',
                style: TextStyle(
                  color: TeacherPalette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _RoundAction(
          icon: Icons.search_rounded,
          tooltip: 'ค้นหา',
          onTap: () => _showComingSoon(context, 'ค้นหา'),
        ),
        const SizedBox(width: 10),
        _RoundAction(
          icon: Icons.notifications_none_rounded,
          dot: true,
          tooltip: 'การแจ้งเตือน',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherNotificationsPage(),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        const _TeacherProfilePill(),
      ],
    );
  }
}

// Reminder banner แบบเดียวกับ reference ("Have you had your routine
// check-up?") — พื้นไล่สีฟ้าเข้มเต็มการ์ด แทนที่การ์ดกระจกขาวเดิม
// เพื่อให้เป็นจุดสายตาแรกของแดชบอร์ดเหมือนภาพตัวอย่างที่ส่งมา
class _TeacherHero extends StatelessWidget {
  const _TeacherHero();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      // Clip.none บน Stack ด้านในทำให้มาสคอตโผล่พ้นขอบบนได้ — ต้องมี
      // ClipRect ชั้นนอกสุดกันไม่ให้ส่วนที่โผล่ไปทับการ์ดอื่นด้านบนตอน
      // สกรอลอยู่ในหน้าที่มี ListView ครอบ
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TeacherPalette.primary, TeacherPalette.skyDeep],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33235284),
                  blurRadius: 26,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 480;
                final illustrationWidth = isNarrow ? 96.0 : 148.0;
                // เว้นที่ว่างขวาให้มาสคอตลอยอยู่ (ตัวจริงวาง Positioned
                // ทับด้านนอก ไม่ใช่ inline ในเนื้อหา) กันข้อความ/ปุ่มชน
                final illustrationSpacer = isNarrow
                    ? const SizedBox.shrink()
                    : SizedBox(width: illustrationWidth - 20);

                final textBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แจ้งเตือน',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'มีงานรอตรวจ 18 ชิ้น และนักเรียน 3 คนที่ต้องติดตามวันนี้',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          onPressed: () =>
                              _showComingSoon(context, 'ตรวจงานเลย'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: TeacherPalette.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          child: const Text('ตรวจงานเลย'),
                        ),
                        OutlinedButton(
                          onPressed: () => _showComingSoon(context, 'ดูรายงาน'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          child: const Text('ดูรายงาน'),
                        ),
                      ],
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: illustrationWidth,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Image.asset(
                            'assets/images/teacher_mascot_lion.png',
                            height: illustrationWidth,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.co_present_rounded,
                              size: illustrationWidth * 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      textBlock,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: textBlock),
                    const SizedBox(width: 12),
                    illustrationSpacer,
                  ],
                );
              },
            ),
          ),
          // มาสคอตลอยพ้นขอบบนของการ์ด (ไม่ครอบด้วยกล่องพื้นขาวเหมือนเดิม)
          // ตามภาพ reference ที่ทีมส่งมา — เฉพาะจอกว้าง (Row layout) เท่านั้น
          // เพราะจอแคบพื้นที่ไม่พอให้ลอยแบบนี้ ใช้เวอร์ชัน inline แทน (ด้านบน)
          // ยึดจากขอบล่าง (bottom) แทน top เดิม — เดิมยึด top:-26 แล้ว
          // กำหนดความสูงตายตัว ทำให้ปลายเท้าเลยขอบล่างของการ์ดไปทับกับ
          // การ์ดถัดไปใน ListView (การ์ดถัดไปวาดทีหลังเลยบังเท้า) ยึด
          // bottom ให้เท้าล็อกอยู่ในขอบการ์ดเสมอ ส่วนหัวยังโผล่พ้นขอบบน
          // ได้ตามเดิมเพราะภาพสูงกว่าการ์ด
          Positioned(
            right: 18,
            bottom: 6,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/teacher_mascot_lion.png',
                height: 172,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherMobileHeader extends StatelessWidget {
  const _TeacherMobileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // เปิด Drawer เมนูฝั่งมือถือ — context นี้เป็นลูกของ Scaffold
        // ที่ประกาศ drawer ไว้แล้วที่ TeacherRedesignPrototypePage
        _RoundAction(
          icon: Icons.menu_rounded,
          tooltip: 'เมนู',
          onTap: () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 10),
        const _AvatarBadge(size: 52, icon: Icons.person_rounded),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ครูสมชาย',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              Text(
                'แดชบอร์ดครู · วันนี้',
                style: TextStyle(
                  color: TeacherPalette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const _RoundAction(icon: Icons.notifications_none_rounded, dot: true),
      ],
    );
  }
}

/// เมนู Drawer ฝั่งมือถือ — เนื้อหาเดียวกับ Sidebar เดสก์ท็อป (แบรนด์การ์ด
/// + เมนูหลัก + ห้องประจำชั้น) เพื่อให้จอแคบเข้าถึงเมนูเดียวกันได้ครบ
class _TeacherMobileDrawer extends StatelessWidget {
  const _TeacherMobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: TeacherPalette.page,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            children: [
              const _TeacherBrandCard(compact: false),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: TeacherMock.menu.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = TeacherMock.menu[index];
                    return _SidebarMenuTile(
                      item: item,
                      active: item.label == 'แดชบอร์ด',
                      compact: false,
                      onTap: () {
                        Navigator.pop(context);
                        if (item.label == 'แดชบอร์ด') return;
                        _openTeacherMenuItem(context, item.label);
                      },
                    );
                  },
                ),
              ),
              const _SidebarProfileCard(compact: false),
              const SizedBox(height: 10),
              const _SidebarMiniClassCard(compact: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherSummaryStrip extends StatelessWidget {
  const _TeacherSummaryStrip();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final itemWidth = wide
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: TeacherMock.stats
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _StatCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SoftIcon(icon: item.icon, color: item.color, background: item.tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassesCarousel extends StatelessWidget {
  const _ClassesCarousel();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'ห้องเรียนและรายวิชา',
            subtitle: 'รายวิชาที่กำลังสอนและสถานะของแต่ละห้อง',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * 14)) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: TeacherMock.classes
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: _TeacherClassCard(item: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TeacherClassCard extends StatelessWidget {
  const _TeacherClassCard({required this.item});

  final _ClassItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _showComingSoon(context, item.title),
        child: Container(
          height: 166,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.gradient,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: item.gradient.last.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SoftIcon(
                    icon: item.icon,
                    color: Colors.white,
                    background: Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(width: 10),
                  _DarkPill(label: item.code),
                  const Spacer(),
                  _LightStatusPill(label: item.status, color: item.statusColor),
                ],
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.room} · ${item.students} คน',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'ตารางสอนวันนี้',
            subtitle: 'คาบเรียนและกิจกรรมที่ต้องเตรียม',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 18),
          ...TeacherMock.lessons.map((lesson) => _ScheduleTile(lesson: lesson)),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.lesson});

  final _LessonItem lesson;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showComingSoon(context, lesson.title),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lesson.tint,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: lesson.color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                child: Text(
                  lesson.time,
                  style: TextStyle(
                    color: lesson.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: lesson.color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.room} · ${lesson.note}',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: TeacherPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeScheduleItem extends StatelessWidget {
  const _LargeScheduleItem({required this.lesson});

  final _LessonItem lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lesson.tint,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: lesson.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _SoftIcon(
            icon: lesson.icon,
            color: lesson.color,
            background: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.time,
                  style: TextStyle(
                    color: lesson.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${lesson.room} · ${lesson.note}',
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: lesson.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: () {},
            child: const Text('เปิดคาบ'),
          ),
        ],
      ),
    );
  }
}

class _TeacherRightPanel extends StatelessWidget {
  const _TeacherRightPanel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        // Tier 2 — ต้องทำ/ต้องติดตาม ไว้บนสุดของ panel ขวา
        _TodayFocusCard(),
        SizedBox(height: 18),
        _ReviewQueueCard(),
        SizedBox(height: 18),
        _StudentsWatchCard(),
        SizedBox(height: 18),
        // Tier 3 — อ้างอิง
        _MiniCalendarCard(),
        SizedBox(height: 18),
        _SensorSnapshotCard(),
      ],
    );
  }
}

/// ปฏิทินย่อประจำเดือน แบบเดียวกับ "Upcoming Check-ups" ใน reference —
/// mock ตายตัวไว้ที่เดือนปัจจุบัน ยังไม่เชื่อมกิจกรรมจริง แค่ไฮไลต์
/// "วันนี้" กับวันที่มีคาบสอน/นัดหมายไว้เป็นตัวอย่าง
class _MiniCalendarCard extends StatelessWidget {
  const _MiniCalendarCard();

  @override
  Widget build(BuildContext context) {
    const monthLabel = 'สิงหาคม 2569';
    const weekdays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    // เดือนนี้เริ่มวันเสาร์ (index 5), มี 31 วัน — ใช้เลขคงที่เป็น mock
    const leadingBlanks = 5;
    const daysInMonth = 31;
    const today = 6;
    const markedDays = {13, 20, 27};

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  monthLabel,
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showComingSoon(context, 'เดือนก่อนหน้า'),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: TeacherPalette.muted,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showComingSoon(context, 'เดือนถัดไป'),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: TeacherPalette.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        color: TeacherPalette.softText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingBlanks + 1;
              if (day < 1) return const SizedBox.shrink();
              final isToday = day == today;
              final isMarked = markedDays.contains(day);
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _showComingSoon(context, 'วันที่ $day'),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? TeacherPalette.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isToday ? Colors.white : TeacherPalette.ink,
                          fontSize: 11.5,
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                      if (isMarked && !isToday)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: TeacherPalette.skySoft,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle(
            title: 'โฟกัสวันนี้',
            subtitle: 'สิ่งที่ควรทำก่อนเริ่มคาบ',
            icon: Icons.flag_rounded,
          ),
          SizedBox(height: 16),
          _FocusRow(
            label: 'ตรวจใบงาน PM2.5',
            value: '18 ชิ้น',
            color: TeacherPalette.orange,
            icon: Icons.assignment_rounded,
          ),
          _FocusRow(
            label: 'นักเรียนไม่ส่งงาน',
            value: '3 คน',
            color: TeacherPalette.red,
            icon: Icons.person_search_rounded,
          ),
          _FocusRow(
            label: 'คาบถัดไป',
            value: '10:30',
            color: TeacherPalette.blue,
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }
}

class _ReviewQueueCard extends StatelessWidget {
  const _ReviewQueueCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'งานรอตรวจ',
            subtitle: 'คิวงานที่ส่งเข้ามาล่าสุด',
            icon: Icons.fact_check_rounded,
          ),
          const SizedBox(height: 14),
          ...TeacherMock.reviewTasks.map((task) => _ReviewTaskTile(task: task)),
        ],
      ),
    );
  }
}

class _StudentsWatchCard extends StatelessWidget {
  const _StudentsWatchCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'นักเรียนที่ต้องติดตาม',
            subtitle: 'ดูจากงานค้างและการเข้าเรียน',
            icon: Icons.groups_3_rounded,
          ),
          const SizedBox(height: 14),
          ...TeacherMock.students.map(
            (student) => _StudentWatchTile(student: student),
          ),
        ],
      ),
    );
  }
}

/// แบนเนอร์เตือนเหตุฉุกเฉินที่ยังไม่มีใครรับเรื่อง — โผล่บนสุดของแดชบอร์ด
/// เฉพาะตอนมีเหตุค้างจริง (ไม่มีก็ไม่แสดงอะไรเลย) สีแดงถ้ามี SOS ปนอยู่
/// ไม่งั้นใช้สีอำพัน แตะแล้วพาไปหน้ารับแจ้งเหตุตรงๆ
class _EmergencyAlertBanner extends StatelessWidget {
  const _EmergencyAlertBanner();

  @override
  Widget build(BuildContext context) {
    final pending = mockIncidentReports
        .where((i) => i.status == IncidentStatus.newReport)
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final hasSos = pending.any((i) => i.category == IncidentCategory.sos);
    final color = hasSos ? const Color(0xFFDC2626) : const Color(0xFFD97706);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherIncidentInboxPage(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasSos
                        ? Icons.emergency_rounded
                        : Icons.warning_amber_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasSos
                            ? 'มีเหตุ SOS ฉุกเฉินรอดำเนินการ!'
                            : 'มีการแจ้งเหตุรอดำเนินการ',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pending.length} รายการ · แตะเพื่อดูรายละเอียด',
                        style: const TextStyle(
                          color: TeacherPalette.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// การ์ดสรุปเหตุการณ์กล้อง AI Security ตรวจพบบุคคล/ความผิดปกติรอการตรวจ
class _CameraSecuritySummaryCard extends StatelessWidget {
  const _CameraSecuritySummaryCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherNotificationsPage(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'เหตุการณ์กล้อง AI Security รอตรวจ 2 รายการ',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ตรวจพบบุคคลภายนอก · ประตูหลังโรงเรียน (09:10 น.)',
                        style: TextStyle(
                          color: TeacherPalette.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiotSensorRow extends StatelessWidget {
  const _AiotSensorRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.level,
    this.value,
    this.unit,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String level;
  final String? value;
  final String? unit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isNormal = level == 'ปกติ';

    // Theme-matched soft pastel icon container palette
    Color iconBgColor;
    Color iconColor;

    if (icon == Icons.air_rounded) {
      iconBgColor = const Color(0xFFE0F2FE); // Soft Cyan/Sky
      iconColor = const Color(0xFF0284C7);
    } else if (icon == Icons.thermostat_rounded) {
      iconBgColor = const Color(0xFFFFF7ED); // Soft Orange/Amber
      iconColor = const Color(0xFFEA580C);
    } else if (icon == Icons.water_drop_rounded) {
      iconBgColor = const Color(0xFFEFF6FF); // Soft Blue
      iconColor = const Color(0xFF2563EB);
    } else {
      iconBgColor = const Color(0xFFFFF1F2); // Soft Rose/Pink
      iconColor = const Color(0xFFE11D48);
    }

    final badgeBgColor = isNormal
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);
    final badgeTextColor = isNormal
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);
    final badgeDotColor = isNormal
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final badgeBorderColor = isNormal
        ? const Color(0xFFA7F3D0).withValues(alpha: 0.6)
        : const Color(0xFFFECACA).withValues(alpha: 0.6);

    return Container(
      padding: EdgeInsets.only(top: 10, bottom: showDivider ? 10 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Theme-matched Soft Glass Icon Container
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (value != null) const SizedBox(height: 1),
                if (value != null)
                  Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                          ),
                        ),
                        if (unit != null) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: unit,
                            style: TextStyle(
                              color: iconColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Redesigned Theme-matched Soft Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeBorderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: badgeDotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: badgeDotColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  level,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// สีฟ้าน้ำเงินสื่อความหมาย "น้ำ" ตรงตัว — ใช้แทน TeacherPalette.sky (ม่วง
/// อ่อน) ในจุดนี้โดยเฉพาะ เพราะสีฟ้าจริงสื่อชัดเจนกว่าเวลาแสดงคู่กับไฟฟ้า
const _kWaterBlue = Color(0xFF0EA5E9);

/// จอกว้างพอ (คอม/แท็บเล็ตแนวนอน) วางการ์ดน้ำ-ไฟ กับการ์ดเซนเซอร์ AIoT
/// เคียงข้างกันซ้าย-ขวาแทนการวางซ้อนกันแนวตั้ง เพื่อลดความยาวของหน้าจอ
/// ใช้ความกว้างของพื้นที่เนื้อหาหลัก (ไม่ใช่ความกว้างจอทั้งหมด) ตัดสินใจ
/// เพราะคอลัมน์เนื้อหาหลักอาจแคบกว่าจอจริงเมื่อมี sidebar/panel ขวา
class _UtilityAndAiotSensorRow extends StatelessWidget {
  const _UtilityAndAiotSensorRow();

  static const _sideBySideBreakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _sideBySideBreakpoint) {
          // จงใจไม่ใช้ IntrinsicHeight+stretch ให้สองการ์ดสูงเท่ากัน เพราะ
          // การคำนวณ intrinsic height ทำที่ความกว้างเต็ม แล้วพอ Expanded
          // บีบให้แคบลงจริง ข้อความบางบรรทัดตัดคำใหม่ทำให้สูงเกินมาไม่กี่
          // px จน overflow — ปล่อยให้แต่ละการ์ดสูงตามเนื้อหาตัวเองแทน
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _HomeroomUtilityCard()),
              SizedBox(width: 18),
              Expanded(child: _AiotWeatherSensorsCard()),
            ],
          );
        }
        return const Column(
          children: [
            _HomeroomUtilityCard(),
            SizedBox(height: 18),
            _AiotWeatherSensorsCard(),
          ],
        );
      },
    );
  }
}

/// ภาพรวม Smart Wiring Lab ต้องอยู่เหนือข้อมูลการสอนทั่วไป เพราะเป็นงาน
/// หลักของครูในโครงการนี้ ส่วนข้อมูลรายกลุ่มและการควบคุมอุปกรณ์อยู่ใน
/// TeacherAiotLabPage เพื่อไม่ให้ Dashboard กลายเป็นหน้าจัดการรายละเอียด
/// ทั้งหมดในหน้าเดียว
class _SmartWiringLabCard extends StatelessWidget {
  const _SmartWiringLabCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TeacherPalette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cable_rounded,
                  color: TeacherPalette.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AIoT Smart Wiring Lab วันนี้',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'AIOT-501 · ม.5/2 · คาบ 10:30 น. · ชุดฝึก 6 ชุด',
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const _LabStatusChip(
                label: 'กำลังใช้งาน',
                icon: Icons.play_circle_rounded,
                color: TeacherPalette.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 480
                  ? 2
                  : 1;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * 10)) / columns;
              const metrics = [
                _LabMetric(
                  label: 'ชุดฝึกพร้อม',
                  value: '5/6',
                  icon: Icons.checklist_rounded,
                  color: TeacherPalette.green,
                ),
                _LabMetric(
                  label: 'Pico 2 ออนไลน์',
                  value: '10/12',
                  icon: Icons.memory_rounded,
                  color: TeacherPalette.primary,
                ),
                _LabMetric(
                  label: 'กำลังต่อสาย',
                  value: '4 กลุ่ม',
                  icon: Icons.cable_rounded,
                  color: TeacherPalette.skyDeep,
                ),
                _LabMetric(
                  label: 'ผ่านการตรวจ',
                  value: '2 กลุ่ม',
                  icon: Icons.verified_rounded,
                  color: TeacherPalette.green,
                ),
                _LabMetric(
                  label: 'รอเริ่มระบบจริง',
                  value: '1 กลุ่ม',
                  icon: Icons.pending_actions_rounded,
                  color: TeacherPalette.orange,
                ),
                _LabMetric(
                  label: 'ต้องตรวจสอบ',
                  value: '1 รายการ',
                  icon: Icons.error_outline_rounded,
                  color: TeacherPalette.red,
                ),
              ];

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: itemWidth,
                        child: _LabMetricTile(metric: metric),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          const _LabDeviceNotice(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherAiotLabPage()),
                );
              },
              icon: const Icon(Icons.settings_input_component_rounded),
              label: const Text('เปิด AIoT Lab'),
              style: FilledButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabMetric {
  const _LabMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _LabMetricTile extends StatelessWidget {
  const _LabMetricTile({required this.metric});

  final _LabMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: metric.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: metric.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.value,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabStatusChip extends StatelessWidget {
  const _LabStatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabDeviceNotice extends StatelessWidget {
  const _LabDeviceNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TeacherPalette.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TeacherPalette.red.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.portable_wifi_off_rounded,
            size: 18,
            color: TeacherPalette.red,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'ชุดฝึก 06: Pico 2 ไม่ตอบสนอง ต้องตรวจสาย USB ก่อนเริ่มคาบ',
              style: TextStyle(
                color: TeacherPalette.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// การใช้น้ำ-ไฟของ "ห้องประจำชั้น" ที่ครูเป็นที่ปรึกษา (คนละส่วนกับ
/// AIoT Classroom ที่โชว์สภาพอากาศห้องที่สอน) — mock ตัวเลขรายสัปดาห์
/// เทียบกับสัปดาห์ก่อนหน้า ให้ครูเห็นแนวโน้มการประหยัดพลังงานของห้องตน
class _HomeroomUtilityCard extends StatelessWidget {
  const _HomeroomUtilityCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'การใช้น้ำ-ไฟ',
            subtitle: 'สัปดาห์นี้',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _UtilityMiniMetric(
                  icon: Icons.bolt_rounded,
                  label: 'ไฟฟ้า',
                  scopeBadge: 'รายห้อง',
                  value: '142',
                  unit: 'kWh',
                  trendUp: true,
                  trendLabel: '+8%',
                  color: TeacherPalette.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UtilityMiniMetric(
                  icon: Icons.water_drop_rounded,
                  label: 'น้ำ',
                  scopeBadge: 'รายอาคาร',
                  value: '3.2',
                  unit: 'm³',
                  trendUp: false,
                  trendLabel: '-4%',
                  color: _kWaterBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'เทียบกับค่าเฉลี่ยสัปดาห์ก่อนหน้า',
            style: TextStyle(
              color: TeacherPalette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const _UtilityWeeklyChart(),
        ],
      ),
    );
  }
}

/// การ์ดเซนเซอร์สภาพอากาศ AIoT — เนื้อหา/เลย์เอาต์แบบเดียวกับ
/// AiotWeatherSensorsCard ฝั่งนักเรียน (aiot_weather_sensors_card.dart)
/// แต่ปรับให้ใช้ TeacherPalette/_GlassCard ของแดชบอร์ดครูแทน SchoolPalette
/// เพื่อให้เข้ากับ Design System เดิมของหน้านี้ ปุ่มด้านล่างพาไปหน้า
/// AiotDashboardPage ตัวจริง (อ่านค่าเซนเซอร์สดจาก Supabase) เหมือนกัน
class _AiotWeatherSensorsCard extends StatelessWidget {
  const _AiotWeatherSensorsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _StatusPulseDot(color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ข้อมูลเซนเซอร์สภาพอากาศ AIoT',
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const _AiotSensorRow(
            icon: Icons.air_rounded,
            title: 'ฝุ่น PM2.5 (ห้องเรียนปลอดภัย)',
            value: '18',
            unit: 'µg/m³',
            subtitle: 'สภาพอากาศดีมาก',
            level: 'ปกติ',
            showDivider: true,
          ),
          const _AiotSensorRow(
            icon: Icons.thermostat_rounded,
            title: 'อุณหภูมิห้องเรียน',
            value: '28.5',
            unit: '°C',
            subtitle: 'อบอุ่นกำลังดี',
            level: 'ปกติ',
            showDivider: true,
          ),
          const _AiotSensorRow(
            icon: Icons.water_drop_rounded,
            title: 'ความชื้นสัมพัทธ์',
            value: '62',
            unit: '%RH',
            subtitle: 'สภาพแวดล้อมเหมาะสม',
            level: 'ปกติ',
            showDivider: true,
          ),
          const _AiotSensorRow(
            icon: Icons.wb_sunny_rounded,
            title: 'ดัชนีรังสี UV',
            value: 'UV 6',
            subtitle: 'เฝ้าระวังแสงแดดจัด',
            level: 'ไม่ปลอดภัย',
            showDivider: false,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherAiotDashboardPage(),
                ),
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'ไปหน้า AIoT Dashboard',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPulseDot extends StatelessWidget {
  const _StatusPulseDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

/// กราฟแท่งคู่ (ไฟฟ้า/น้ำ) รายวันของห้องประจำชั้น จ.-ศ. — ปรับสเกลแท่งแยก
/// ต่อชนิดพลังงาน (kWh กับ m³ หน่วยต่างกัน) เทียบกับค่าสูงสุดของตัวเอง
/// ในสัปดาห์ ไม่เทียบข้ามหน่วยกัน ผลรวมของแต่ละชุดตรงกับตัวเลขสรุปด้านบน
/// (ไฟฟ้า 142 kWh, น้ำ 3.2 m³) ข้อมูล mock ทั้งหมด พร้อมสลับเป็น API ทีหลัง
/// เวอร์ชันดัดแปลงของ "Project Scope & Progress Trend Line Chart" (การ์ด 7
/// ใน teacher_storybook_page.dart) — เอาเทคนิคเส้นวิ่งเรืองแสง (running
/// glow) + crosshair hover มาใช้ซ้ำ เหลือ 2 เส้นแทน 3 (ไฟฟ้า/น้ำ) แล้ว
/// เปลี่ยนสีให้เข้ากับ TeacherPalette ของแดชบอร์ดนี้แทนโทนน้ำเงิน/แดง/เขียว
/// เดิม ป้ายแกน X เปลี่ยนจากวันที่โปรเจกต์เป็นวันในสัปดาห์ (จ.-ศ.)
class _UtilityWeeklyChart extends StatefulWidget {
  const _UtilityWeeklyChart();

  @override
  State<_UtilityWeeklyChart> createState() => _UtilityWeeklyChartState();
}

class _UtilityWeeklyChartState extends State<_UtilityWeeklyChart>
    with SingleTickerProviderStateMixin {
  static const _days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

  late final AnimationController _controller;
  double _hoverXRatio = 0.72;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'ค่าเฉลี่ยรายวัน',
              style: TextStyle(
                color: TeacherPalette.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Spacer(),
            _UtilityLegendDot(color: TeacherPalette.orange, label: 'ไฟฟ้า'),
            SizedBox(width: 10),
            _UtilityLegendDot(color: _kWaterBlue, label: 'น้ำ'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return MouseRegion(
                onHover: (event) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final localPos = box.globalToLocal(event.position);
                    setState(() {
                      _hoverXRatio = (localPos.dx / box.size.width).clamp(
                        0.0,
                        1.0,
                      );
                      _isHovered = true;
                    });
                  }
                },
                onExit: (_) {
                  setState(() {
                    _isHovered = false;
                    _hoverXRatio = 0.72;
                  });
                },
                child: CustomPaint(
                  painter: _UtilityGlowLineChartPainter(
                    pulsePhase: _controller.value,
                    hoverXRatio: _hoverXRatio,
                    isHovered: _isHovered,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final day in _days)
              Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _UtilityGlowLineChartPainter extends CustomPainter {
  _UtilityGlowLineChartPainter({
    required this.pulsePhase,
    required this.hoverXRatio,
    required this.isHovered,
  });

  final double pulsePhase;
  final double hoverXRatio;
  final bool isHovered;

  static const _electricColor = TeacherPalette.orange; // ไฟฟ้า
  static const _waterColor = _kWaterBlue; // น้ำ
  static const _electricGlow = Color(0xFFFDBA74);
  static const _waterGlow = Color(0xFF7DD3FC);
  static const _days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // เส้นไฟฟ้า (จ.-ศ. อิงสัดส่วนจาก 26/24/30/28/34 kWh ที่ใช้ในการ์ดนี้)
    final electricPath = Path();
    electricPath.moveTo(0, h * 0.68);
    electricPath.cubicTo(
      w * 0.10,
      h * 0.80,
      w * 0.18,
      h * 0.90,
      w * 0.25,
      h * 0.72,
    );
    electricPath.cubicTo(
      w * 0.34,
      h * 0.52,
      w * 0.42,
      h * 0.48,
      w * 0.50,
      h * 0.55,
    );
    electricPath.cubicTo(
      w * 0.62,
      h * 0.65,
      w * 0.78,
      h * 0.30,
      w * 1.0,
      h * 0.10,
    );

    // เส้นน้ำ (จ.-ศ. อิงสัดส่วนจาก m³) — มีจุดตัดกับเส้นไฟฟ้าช่วง อ.-พ.
    final waterPath = Path();
    waterPath.moveTo(0, h * 0.82);
    waterPath.cubicTo(
      w * 0.10,
      h * 0.88,
      w * 0.18,
      h * 0.76,
      w * 0.25,
      h * 0.70, // ตัดและอยู่เหนือเส้นไฟฟ้าเล็กน้อยตรงช่วง อ.
    );
    waterPath.cubicTo(
      w * 0.34,
      h * 0.65,
      w * 0.42,
      h * 0.82,
      w * 0.50,
      h * 0.85,
    );
    waterPath.cubicTo(
      w * 0.62,
      h * 0.88,
      w * 0.78,
      h * 0.65,
      w * 1.0,
      h * 0.58,
    );

    // 1. แรเงาใต้เส้นน้ำ (Water Cyan Gradient Fill)
    final waterFillPath = Path.from(waterPath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final waterFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _waterColor.withValues(alpha: 0.22),
          _waterColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // 2. แรเงาใต้เส้นไฟฟ้า (Electric Orange Gradient Fill)
    final electricFillPath = Path.from(electricPath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final electricFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _electricColor.withValues(alpha: 0.22),
          _electricColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // วาดแรเงาสีฟ้าของน้ำไว้ล่างสุด แล้วตามด้วยแรเงาสีส้มของไฟซ้อนทับ
    canvas.drawPath(waterFillPath, waterFillPaint);
    canvas.drawPath(electricFillPath, electricFillPaint);

    final electricBasePaint = Paint()
      ..color = _electricColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final waterBasePaint = Paint()
      ..color = _waterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(electricPath, electricBasePaint);
    canvas.drawPath(waterPath, waterBasePaint);

    // เส้นวิ่งเรืองแสง (running glow) — วิ่งพร้อมกันตาม pulsePhase เดียวกัน
    // วาดเส้นไฟก่อน แล้วตามด้วยเส้นน้ำ เพื่อให้แรงเงาไฟไปซ่อนอยู่ด้านหลังแรงเหนาน้ำ
    _drawRunningGlowEffect(canvas, electricPath, _electricGlow, pulsePhase);
    _drawRunningGlowEffect(canvas, waterPath, _waterGlow, pulsePhase);

    // End node circles
    final electricEnd = Offset(w, h * 0.10);
    final waterEnd = Offset(w, h * 0.58);
    canvas.drawCircle(electricEnd, 4.5, Paint()..color = _electricColor);
    canvas.drawCircle(
      electricEnd,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(waterEnd, 4.5, Paint()..color = _waterColor);
    canvas.drawCircle(
      waterEnd,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Crosshair + tooltip แสดงวันที่ตรงตำแหน่ง hover บนเส้นไฟฟ้า
    final targetX = hoverXRatio * w;
    final focusY = _getElectricLineYAtX(targetX, w, h);
    final pinCenter = Offset(targetX, focusY);

    final crossPaint = Paint()
      ..color = const Color(0xFFE2D9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(targetX, 0), Offset(targetX, h), crossPaint);

    canvas.drawCircle(pinCenter, 5.0, Paint()..color = _electricColor);
    canvas.drawCircle(
      pinCenter,
      7.5,
      Paint()..color = _electricColor.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      pinCenter,
      5.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    final dayIndex = (hoverXRatio * _days.length).floor().clamp(
      0,
      _days.length - 1,
    );
    _drawTooltipBadge(canvas, pinCenter, _days[dayIndex]);
  }

  void _drawRunningGlowEffect(
    Canvas canvas,
    Path path,
    Color glowColor,
    double phase,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final totalLen = metric.length;
      final headDist = totalLen * phase;
      final tailLen = totalLen * 0.28;

      final pulsePath = metric.extractPath(
        (headDist - tailLen).clamp(0.0, totalLen),
        headDist.clamp(0.0, totalLen),
      );

      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawPath(pulsePath, glowPaint);
      canvas.drawPath(pulsePath, corePaint);
    }
  }

  double _getElectricLineYAtX(double x, double w, double h) {
    if (x <= w * 0.25) {
      final t = (x / (w * 0.25)).clamp(0.0, 1.0);
      return h * 0.68 - (h * -0.04) * t;
    } else if (x <= w * 0.50) {
      final t = ((x - w * 0.25) / (w * 0.25)).clamp(0.0, 1.0);
      return h * 0.72 - (h * 0.17) * t;
    } else {
      final t = ((x - w * 0.50) / (w * 0.50)).clamp(0.0, 1.0);
      return h * 0.55 - (h * 0.45) * t;
    }
  }

  void _drawTooltipBadge(Canvas canvas, Offset pinCenter, String text) {
    final tooltipOffset = Offset(pinCenter.dx - 16, pinCenter.dy - 30);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipOffset.dx, tooltipOffset.dy, 32, 20),
      const Radius.circular(7),
    );

    final borderPaint = Paint()
      ..color = const Color(0xFFE2D9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final fillPaint = Paint()..color = Colors.white;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: TeacherPalette.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        tooltipOffset.dx + (32 - textPainter.width) / 2,
        tooltipOffset.dy + (20 - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _UtilityGlowLineChartPainter oldDelegate) =>
      true;
}

class _UtilityLegendDot extends StatelessWidget {
  const _UtilityLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: TeacherPalette.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UtilityMiniMetric extends StatelessWidget {
  const _UtilityMiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.trendUp,
    required this.trendLabel,
    required this.color,
    this.scopeBadge,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final bool trendUp;
  final String trendLabel;
  final Color color;
  final String? scopeBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              if (scopeBadge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scopeBadge!,
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                color: TeacherPalette.ink,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                trendUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: trendUp
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
              const SizedBox(width: 3),
              Text(
                '$trendLabel จากสัปดาห์ก่อน',
                style: TextStyle(
                  color: trendUp
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorSnapshotCard extends StatelessWidget {
  const _SensorSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'AIoT Classroom',
            subtitle: 'สภาพห้องเรียนที่รับผิดชอบ',
            icon: Icons.sensors_rounded,
          ),
          const SizedBox(height: 12),
          const _SensorMiniMetric(
            label: 'PM2.5',
            value: '18',
            unit: 'µg/m³',
            color: TeacherPalette.blue,
          ),
          const SizedBox(height: 8),
          const _SensorMiniMetric(
            label: 'Temp',
            value: '28.5',
            unit: '°C',
            color: TeacherPalette.orange,
          ),
          const SizedBox(height: 8),
          const _SensorMiniMetric(
            label: 'Humidity',
            value: '62',
            unit: '%RH',
            color: TeacherPalette.primary2,
          ),
          const SizedBox(height: 8),
          const _SensorMiniMetric(
            label: 'UV',
            value: '2',
            unit: '',
            color: TeacherPalette.violet,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherAiotLabPage()),
                );
              },
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('เปิด AIoT Lab Control'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TeacherPalette.primary,
                side: const BorderSide(color: TeacherPalette.primary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _SoftIcon(
            icon: icon,
            color: color,
            background: color.withValues(alpha: 0.11),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TeacherPalette.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ReviewTaskTile extends StatelessWidget {
  const _ReviewTaskTile({required this.task});

  final _ReviewTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: task.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SoftIcon(
            icon: task.icon,
            color: task.color,
            background: Colors.white,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  task.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _LightStatusPill(label: task.count, color: task.color),
        ],
      ),
    );
  }
}

class _OpsTaskTile extends StatelessWidget {
  const _OpsTaskTile({required this.task});

  final _ReviewTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Row(
        children: [
          _SoftIcon(
            icon: task.icon,
            color: task.color,
            background: task.color.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.subtitle,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: task.color,
              foregroundColor: Colors.white,
            ),
            onPressed: () {},
            child: Text(task.count),
          ),
        ],
      ),
    );
  }
}

class _StudentWatchTile extends StatelessWidget {
  const _StudentWatchTile({required this.student});

  final _StudentWatch student;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: student.color.withValues(alpha: 0.12),
            child: Text(
              student.name.characters.first,
              style: TextStyle(
                color: student.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  student.reason,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _LightStatusPill(label: student.status, color: student.color),
        ],
      ),
    );
  }
}

class _SensorMiniMetric extends StatelessWidget {
  const _SensorMiniMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
              children: [
                TextSpan(
                  text: unit.isEmpty ? '' : ' $unit',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SoftIcon(
          icon: icon,
          color: TeacherPalette.primary,
          background: const Color(0xFFF1EEF9),
          size: 42,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: TeacherPalette.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F172A),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/teacher_mascot_lion.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.75),
          errorBuilder: (context, error, stackTrace) =>
              Icon(icon, color: Colors.white, size: size * 0.56),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    this.dot = false,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final bool dot;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.78),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: TeacherPalette.border),
          ),
          child: Icon(icon, color: TeacherPalette.ink),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        tooltip == null ? button : Tooltip(message: tooltip!, child: button),
        if (dot)
          Positioned(
            top: 4,
            right: 5,
            child: IgnorePointer(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: TeacherPalette.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TeacherProfilePill extends StatelessWidget {
  const _TeacherProfilePill();

  void _showRoleSwitcherModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: TeacherPalette.primary,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'สลับสิทธิ์การทำงาน (Active Role)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: TeacherPalette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'เลือกสิทธิ์ในการเข้าถึงเมนูและข้อมูลของโรงเรียน (สำหรับผู้มีหลายบทบาท)',
              style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
            ),
            const SizedBox(height: 16),
            _buildRoleOption(
              context,
              roleName: 'ครูประจำชั้น (Homeroom Teacher)',
              sub: 'ม.5/2 • เข้าถึงข้อมูลนักเรียนและบรรยากาศห้องเรียน',
              isSelected: true,
            ),
            const SizedBox(height: 10),
            _buildRoleOption(
              context,
              roleName: 'ครูผู้สอนรายวิชา (Subject Teacher)',
              sub: 'กลุ่มสาระวิทยาศาสตร์และเทคโนโลยี • จัดการวิชาและตรวจงาน',
              isSelected: false,
            ),
            const SizedBox(height: 10),
            _buildRoleOption(
              context,
              roleName: 'หัวหน้าหมวดวิชา (Head of Department)',
              sub: 'อนุมัติเกณฑ์ Rubric และดูภาพรวมการสอนทั้งหมวด',
              isSelected: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context, {
    required String roleName,
    required String sub,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สลับสิทธิ์การทำงานเป็น "$roleName" เรียบร้อยแล้ว'),
            backgroundColor: TeacherPalette.primary,
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? TeacherPalette.primary.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? TeacherPalette.primary
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected
                  ? TeacherPalette.primary
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? TeacherPalette.primary
                          : TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TeacherPalette.muted,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1EEF9),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => _showRoleSwitcherModal(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFF9AD4F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/teacher_mascot_lion.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.75),
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_rounded,
                      color: TeacherPalette.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ครูสมชาย',
                    style: TextStyle(
                      color: TeacherPalette.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    'ครูประจำชั้น (ม.5/2) ▾',
                    style: TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LightStatusPill extends StatelessWidget {
  const _LightStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class TeacherMock {
  static const menu = [
    _MenuItem('แดชบอร์ด', Icons.dashboard_rounded),
    _MenuItem('รายวิชา', Icons.menu_book_rounded),
    _MenuItem('นักเรียน', Icons.groups_2_rounded),
    _MenuItem('ตรวจงาน', Icons.assignment_turned_in_rounded),
    _MenuItem('คะแนน', Icons.bar_chart_rounded),
    _MenuItem('Rubric', Icons.fact_check_rounded),
    _MenuItem('Wiring Lab', Icons.cable_rounded),
    _MenuItem('AIoT Dashboard', Icons.sensors_rounded),
    _MenuItem('แจ้งเหตุฉุกเฉิน', Icons.emergency_rounded),
  ];

  static const stats = [
    _StatItem(
      'คาบสอนวันนี้',
      '4',
      Icons.co_present_rounded,
      TeacherPalette.blue,
      Color(0xFFF1EEF9),
    ),
    _StatItem(
      'งานรอตรวจ',
      '18',
      Icons.assignment_rounded,
      TeacherPalette.orange,
      Color(0xFFF1EEF9),
    ),
    _StatItem(
      'ต้องติดตาม',
      '3',
      Icons.person_search_rounded,
      TeacherPalette.red,
      Color(0xFFEDF7FC),
    ),
    _StatItem(
      'ห้องปกติ',
      '6/7',
      Icons.sensors_rounded,
      TeacherPalette.green,
      Color(0xFFF1EEF9),
    ),
  ];

  static const classes = [
    _ClassItem(
      'AIOT-501',
      'AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
      'ม.5/2',
      32,
      Icons.memory_rounded,
      '2 งานค้าง',
      TeacherPalette.orange,
      [TeacherPalette.primary, TeacherPalette.primary2],
    ),
    _ClassItem(
      'PHYS-302',
      'ฟิสิกส์ประยุกต์และการทดลอง',
      'ม.5/1',
      30,
      Icons.bolt_rounded,
      'ส่งครบแล้ว',
      TeacherPalette.green,
      [TeacherPalette.skyDeep, TeacherPalette.skyMid],
    ),
    _ClassItem(
      'BIO-204',
      'ชีววิทยาและสิ่งแวดล้อม',
      'ม.4/3',
      35,
      Icons.eco_rounded,
      'มีแจ้งเตือน',
      TeacherPalette.red,
      [TeacherPalette.skyBright, TeacherPalette.skyVivid],
    ),
  ];

  static const lessons = [
    _LessonItem(
      '08:30',
      'AIoT: วิเคราะห์ข้อมูล PM2.5',
      'Lab 2 · ม.5/2',
      'ใช้ข้อมูลเซนเซอร์จริงในห้อง',
      Icons.sensors_rounded,
      TeacherPalette.primary,
      Color(0xFFF1EEF9),
    ),
    _LessonItem(
      '10:30',
      'ฟิสิกส์: คลื่นและแสง',
      'ห้อง 403 · ม.5/1',
      'เตรียมชุดทดลอง',
      Icons.bolt_rounded,
      TeacherPalette.blue,
      Color(0xFFF1EEF9),
    ),
    _LessonItem(
      '13:30',
      'ตรวจงาน: ใบงานชีววิทยา',
      'ห้องพักครู',
      'เหลือ 18 ชิ้น',
      Icons.fact_check_rounded,
      TeacherPalette.orange,
      Color(0xFFF1EEF9),
    ),
  ];

  static const reviewTasks = [
    _ReviewTask(
      'ใบงาน PM2.5',
      'AIOT-501 · ส่งเข้ามา 18 ชิ้น',
      '18',
      Icons.assignment_rounded,
      TeacherPalette.orange,
    ),
    _ReviewTask(
      'แบบทดสอบก่อนเรียน',
      'PHYS-302 · รอตรวจคำตอบ',
      '9',
      Icons.quiz_rounded,
      TeacherPalette.blue,
    ),
    _ReviewTask(
      'รายงานแล็บชีววิทยา',
      'BIO-204 · เลยกำหนด 3 คน',
      '3',
      Icons.warning_rounded,
      TeacherPalette.red,
    ),
  ];

  static const students = [
    _StudentWatch('สายฟ้า', 'ค้างส่ง 2 งาน', 'ด่วน', TeacherPalette.red),
    _StudentWatch(
      'มินตรา',
      'คะแนนตกจากสัปดาห์ก่อน',
      'ดูคะแนน',
      TeacherPalette.orange,
    ),
    _StudentWatch(
      'ก้องภพ',
      'ขาดเรียน 2 ครั้ง',
      'เช็กชื่อ',
      TeacherPalette.blue,
    ),
  ];
}

class _MenuItem {
  const _MenuItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, this.color, this.tint);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
}

class _ClassItem {
  const _ClassItem(
    this.code,
    this.title,
    this.room,
    this.students,
    this.icon,
    this.status,
    this.statusColor,
    this.gradient,
  );
  final String code;
  final String title;
  final String room;
  final int students;
  final IconData icon;
  final String status;
  final Color statusColor;
  final List<Color> gradient;
}

class _LessonItem {
  const _LessonItem(
    this.time,
    this.title,
    this.room,
    this.note,
    this.icon,
    this.color,
    this.tint,
  );
  final String time;
  final String title;
  final String room;
  final String note;
  final IconData icon;
  final Color color;
  final Color tint;
}

class _ReviewTask {
  const _ReviewTask(
    this.title,
    this.subtitle,
    this.count,
    this.icon,
    this.color,
  );
  final String title;
  final String subtitle;
  final String count;
  final IconData icon;
  final Color color;
}

class _StudentWatch {
  const _StudentWatch(this.name, this.reason, this.status, this.color);
  final String name;
  final String reason;
  final String status;
  final Color color;
}

/// Lightweight tap feedback for dashboard elements that don't have a real
/// destination yet in this prototype — matches the same "SnackBar instead
/// of a dead tap" pattern used across the redesign prototypes so nothing
/// with an arrow/tappable look silently does nothing when pressed.
void _showComingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label (อยู่ระหว่างออกแบบ)'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// เมนูไซด์บาร์/Drawer ฝั่งครู (นอกจาก "แดชบอร์ด" ที่สลับ variant ในหน้า
/// เดิม) — แต่ละอันพาไปหน้า mock ของตัวเองแล้ว (รายวิชา/นักเรียน/ตรวจงาน/
/// คะแนน/AIoT) เมนูที่ยังไม่มีหน้าเลยค่อย fallback ไปโชว์ "อยู่ระหว่าง
/// ออกแบบ" ตามเดิม
void _openTeacherMenuItem(BuildContext context, String label) {
  switch (label) {
    case 'รายวิชา':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherCoursesPage()),
      );
    case 'นักเรียน':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherStudentsPage()),
      );
    case 'ตรวจงาน':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherGradingPage()),
      );
    case 'คะแนน':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherGradesPage()),
      );
    case 'Rubric':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherRubricPage()),
      );
    case 'Wiring Lab':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherAiotLabPage()),
      );
    case 'AIoT Dashboard':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherAiotDashboardPage()),
      );
    case 'แจ้งเหตุฉุกเฉิน':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherIncidentInboxPage()),
      );
    default:
      _showComingSoon(context, label);
  }
}

class TeacherAppDrawer extends StatelessWidget {
  const TeacherAppDrawer({super.key, this.activeLabel});

  final String? activeLabel;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _TeacherSidebar(
        currentVariant: TeacherPrototypeVariant.a,
        onVariantSelected: (_) {},
        onPreviousVariant: () {},
        onNextVariant: () {},
        compact: false,
        insideDrawer: true,
        forcedActiveLabel: activeLabel,
      ),
    );
  }
}

/// Sidebar ถาวรฝั่งซ้าย ใช้แทน TeacherAppDrawer บนจอกว้าง (>=900px) สำหรับ
/// หน้า mock อื่นๆ (รายวิชา/นักเรียน/คะแนน) — ผู้ใช้ไม่ต้องกดแฮมเบอร์เกอร์
/// เปิดปิดทุกครั้งเหมือนหน้าแดชบอร์ดที่ปักหมุด sidebar ไว้ค้างอยู่แล้ว
class TeacherPersistentSidebar extends StatelessWidget {
  const TeacherPersistentSidebar({
    super.key,
    this.activeLabel,
    this.compact = false,
    this.onToggleCompact,
  });

  final String? activeLabel;
  final bool compact;
  final VoidCallback? onToggleCompact;

  @override
  Widget build(BuildContext context) {
    return _TeacherSidebar(
      currentVariant: TeacherPrototypeVariant.a,
      onVariantSelected: (_) {},
      onPreviousVariant: () {},
      onNextVariant: () {},
      compact: compact,
      onToggleCompact: onToggleCompact,
      forcedActiveLabel: activeLabel,
    );
  }
}
