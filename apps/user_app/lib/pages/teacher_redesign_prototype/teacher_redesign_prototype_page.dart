// PROTOTYPE ONLY: Teacher redesigned workspace.
// Three variants of the teacher dashboard, switchable in-app on
// /prototype/teacher-redesign?variant=A, B, or C.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_aiot_dashboard_page.dart';
import 'teacher_aiot_lab_page.dart';
import 'teacher_attendance_page.dart';
import 'teacher_leave_approval_page.dart';
import 'teacher_courses_page.dart';
import 'teacher_grades_page.dart';
import 'teacher_grading_page.dart';
import 'teacher_gscore_confirm_page.dart';
import 'teacher_incident_inbox_page.dart';
import 'teacher_notifications_page.dart';
import 'teacher_parent_binding_approval_page.dart';
import 'teacher_profile_page.dart';
import 'teacher_knowledge_library_page.dart';
import 'teacher_question_bank_page.dart';
import 'teacher_rubric_page.dart';
import 'teacher_shared_widgets.dart';
import 'teacher_student_support_page.dart';
import 'teacher_students_page.dart';
import 'teacher_class_schedule_page.dart';

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
                            final isActive = isReusedElsewhere
                                ? item.label == forcedActiveLabel
                                : (index == 0 &&
                                      currentVariant ==
                                          TeacherPrototypeVariant.a);

                            return _SidebarMenuTile(
                              item: item,
                              active: isActive,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUserModel?.name ?? 'ครูผู้สอน',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: TeacherPalette.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            currentUserModel?.email ?? 'ครูผู้สอน',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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

typedef _RoomBar = ({String label, double percent});

class _SubmissionBarChartCard extends StatefulWidget {
  const _SubmissionBarChartCard();

  @override
  State<_SubmissionBarChartCard> createState() =>
      _SubmissionBarChartCardState();
}

class _SubmissionBarChartCardState extends State<_SubmissionBarChartCard> {
  List<_RoomBar>? _rooms;
  String? _error;

  Future<void> _load() async {
    try {
      final courses = (await CourseService.listMyCourses())
          .where((c) => c.isActive)
          .toList();
      final rooms = <_RoomBar>[];
      for (final course in courses) {
        final roster = await CourseService.listCourseStudents(course.id);
        if (roster.isEmpty) continue;
        final assignments = (await AssignmentService.listAssignments(
          course.id,
        )).where((a) => a.status == 'published').toList();
        if (assignments.isEmpty) continue;

        var submitted = 0;
        for (final assignment in assignments) {
          final submissions = await AssignmentService.listSubmissions(
            assignment.id,
          );
          submitted += submissions.length;
        }
        final expected = assignments.length * roster.length;
        rooms.add(
          (
            label: course.gradeLevel ?? course.subjectName,
            percent: submitted / expected,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'โหลดสถานะส่งงานไม่สำเร็จ');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  title: 'สถานะส่งงานรายวิชา',
                  subtitle: 'สัดส่วนงานที่ส่งแล้ว เทียบกับงานที่มอบหมายทั้งหมด',
                  icon: Icons.bar_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                color: TeacherPalette.red,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (_rooms == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          else if (_rooms!.isEmpty)
            const Text(
              'ยังไม่มีข้อมูลงานที่มอบหมายให้เปรียบเทียบ',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            SizedBox(
              height: 148,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final room in _rooms!) ...[
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
                              height: 96 * room.percent.clamp(0, 1),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: TeacherPalette.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (room != _rooms!.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentStatusDonutCard extends StatefulWidget {
  const _StudentStatusDonutCard();

  @override
  State<_StudentStatusDonutCard> createState() =>
      _StudentStatusDonutCardState();
}

class _StudentStatusDonutCardState extends State<_StudentStatusDonutCard> {
  int? _total;
  List<({String label, double percent, Color color})>? _segments;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CourseService.listMyCourses(),
        StudentSupportService.listAutoFlaggedStudents(),
      ]);
      final courses = (results[0] as List<CourseSummary>)
          .where((c) => c.isActive)
          .toList();
      final flagged = results[1] as List<AutoFlaggedStudent>;

      final allStudentIds = <String>{};
      for (final course in courses) {
        final roster = await CourseService.listCourseStudents(course.id);
        allStudentIds.addAll(roster.map((s) => s.studentId));
      }

      final missingWork = flagged
          .where((f) => f.reason == 'ค้างส่งงาน')
          .map((f) => f.studentId)
          .toSet();
      final needsFollowUp = flagged
          .where((f) => f.reason != 'ค้างส่งงาน')
          .map((f) => f.studentId)
          .toSet()
        ..removeAll(missingWork);
      final total = allStudentIds.length;
      final normalCount = total - missingWork.length - needsFollowUp.length;

      if (!mounted) return;
      setState(() {
        _total = total;
        _segments = total == 0
            ? []
            : [
                (
                  label: 'ปกติ',
                  percent: normalCount / total,
                  color: TeacherPalette.green,
                ),
                (
                  label: 'ต้องติดตาม',
                  percent: needsFollowUp.length / total,
                  color: TeacherPalette.orange,
                ),
                (
                  label: 'ขาดส่งงานบ่อย',
                  percent: missingWork.length / total,
                  color: TeacherPalette.red,
                ),
              ];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'โหลดสัดส่วนนักเรียนไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = _segments;
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
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                color: TeacherPalette.red,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (segments == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          else if (segments.isEmpty)
            const Text(
              'ยังไม่มีนักเรียนในความรับผิดชอบ',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
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
                      Text(
                        '${_total ?? 0}\nคน',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
          onTap: () => _showTeacherSearchDialog(context),
        ),
        const SizedBox(width: 10),
        _RoundAction(
          icon: Icons.notifications_none_rounded,
          dot: true,
          tooltip: 'การแจ้งเตือน',
          onTap: () => _showTeacherNotificationPreview(context),
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
/// สรุป 2 ตัวเลขที่ `_TeacherHero`/`_TeacherSummaryStrip` ใช้ร่วมกัน —
/// เขียนแยกจาก `_ReviewQueueCard`/`_StudentsWatchCard` เพราะสองการ์ดนั้น
/// ต้องการรายละเอียดรายชิ้น/รายคน ส่วนตรงนี้ต้องการแค่ยอดรวม ให้แต่ละ
/// วิดเจ็ตดึงข้อมูลของตัวเองอิสระต่อกัน (ตามแพทเทิร์นเดิมของไฟล์นี้) แทนที่
/// จะยกสเตทขึ้นมาไว้ที่ widget แม่ ซึ่งจะเปราะบางเพราะการ์ดเดียวกันถูกวาง
/// ไว้หลายจุดสำหรับ breakpoint ต่าง ๆ
Future<int> _fetchPendingReviewTotal() async {
  final courses = (await CourseService.listMyCourses())
      .where((c) => c.isActive)
      .toList();
  var pending = 0;
  for (final course in courses) {
    final assignments = (await AssignmentService.listAssignments(
      course.id,
    )).where((a) => a.status == 'published');
    for (final assignment in assignments) {
      final submissions = await AssignmentService.listSubmissions(
        assignment.id,
      );
      pending += submissions.where((s) => s.status == 'submitted').length;
    }
  }
  return pending;
}

Future<int> _fetchFlaggedStudentTotal() async {
  return (await StudentSupportService.listAutoFlaggedStudents()).length;
}

class _TeacherHero extends StatefulWidget {
  const _TeacherHero();

  @override
  State<_TeacherHero> createState() => _TeacherHeroState();
}

class _TeacherHeroState extends State<_TeacherHero> {
  int? _pending;
  int? _flagged;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _fetchPendingReviewTotal(),
        _fetchFlaggedStudentTotal(),
      ]);
      if (!mounted) return;
      setState(() {
        _pending = results[0];
        _flagged = results[1];
      });
    } catch (_) {
      // เงียบไว้ — banner แค่โชว์ข้อความโหลดค้างต่อ ไม่ใช่จุดหลักของหน้า
    }
  }

  String get _bannerText {
    if (_pending == null || _flagged == null) {
      return 'กำลังโหลดข้อมูลวันนี้...';
    }
    if (_pending == 0 && _flagged == 0) {
      return 'วันนี้ไม่มีงานค้างตรวจและไม่มีนักเรียนที่ต้องติดตาม';
    }
    return 'มีงานรอตรวจ $_pending ชิ้น และนักเรียน $_flagged คนที่ต้องติดตามวันนี้';
  }

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
                    Text(
                      _bannerText,
                      style: const TextStyle(
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeacherGradingPage(),
                            ),
                          ),
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeacherGradesPage(),
                            ),
                          ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUserModel?.name ?? 'ครูผู้สอน',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
        _RoundAction(
          icon: Icons.notifications_none_rounded,
          dot: true,
          tooltip: 'การแจ้งเตือน',
          onTap: () => _showTeacherNotificationPreview(context),
        ),
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

class _TeacherSummaryStrip extends StatefulWidget {
  const _TeacherSummaryStrip();

  @override
  State<_TeacherSummaryStrip> createState() => _TeacherSummaryStripState();
}

class _TeacherSummaryStripState extends State<_TeacherSummaryStrip> {
  List<_StatItem>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CalendarService.listTeacherSchedules(),
        _fetchPendingReviewTotal(),
        _fetchFlaggedStudentTotal(),
        CourseService.listMyCourses(),
      ]);
      final schedules = results[0] as List<ClassScheduleSlot>;
      final pending = results[1] as int;
      final flagged = results[2] as int;
      final courses = (results[3] as List<CourseSummary>)
          .where((c) => c.isActive)
          .length;
      final todayIndex = DateTime.now().weekday - 1;
      final todayCount = schedules
          .where((s) => s.dayOfWeek == todayIndex)
          .length;

      if (!mounted) return;
      setState(() {
        _stats = [
          _StatItem(
            'คาบสอนวันนี้',
            '$todayCount',
            Icons.co_present_rounded,
            TeacherPalette.blue,
            const Color(0xFFF1EEF9),
          ),
          _StatItem(
            'งานรอตรวจ',
            '$pending',
            Icons.fact_check_rounded,
            TeacherPalette.orange,
            const Color(0xFFFFF1E6),
          ),
          _StatItem(
            'ต้องติดตาม',
            '$flagged',
            Icons.groups_3_rounded,
            TeacherPalette.red,
            const Color(0xFFFDE9E9),
          ),
          _StatItem(
            'วิชาที่สอน',
            '$courses',
            Icons.menu_book_rounded,
            TeacherPalette.green,
            const Color(0xFFE8F6EF),
          ),
        ];
      });
    } catch (_) {
      // เงียบไว้ — แถบนี้แสดง "-" ค้างต่อ ไม่ใช่จุดหลักของหน้า
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats =
        _stats ??
        const [
          _StatItem(
            'คาบสอนวันนี้',
            '-',
            Icons.co_present_rounded,
            TeacherPalette.blue,
            Color(0xFFF1EEF9),
          ),
          _StatItem(
            'งานรอตรวจ',
            '-',
            Icons.fact_check_rounded,
            TeacherPalette.orange,
            Color(0xFFFFF1E6),
          ),
          _StatItem(
            'ต้องติดตาม',
            '-',
            Icons.groups_3_rounded,
            TeacherPalette.red,
            Color(0xFFFDE9E9),
          ),
          _StatItem(
            'วิชาที่สอน',
            '-',
            Icons.menu_book_rounded,
            TeacherPalette.green,
            Color(0xFFE8F6EF),
          ),
        ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final itemWidth = wide
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats
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

class _ClassesCarousel extends StatefulWidget {
  const _ClassesCarousel();

  @override
  State<_ClassesCarousel> createState() => _ClassesCarouselState();
}

class _ClassesCarouselState extends State<_ClassesCarousel> {
  List<_ClassItem>? _items;
  String? _error;

  static const _gradients = [
    [TeacherPalette.primary, TeacherPalette.primary2],
    [TeacherPalette.skyDeep, TeacherPalette.skyMid],
    [TeacherPalette.skyBright, TeacherPalette.skyVivid],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final courses = await CourseService.listMyCourses();
      final items = <_ClassItem>[];
      for (var i = 0; i < courses.length; i++) {
        final c = courses[i];
        var studentCount = 0;
        try {
          studentCount = (await CourseService.listCourseStudents(c.id)).length;
        } catch (_) {
          studentCount = 0;
        }
        items.add(
          _ClassItem(
            c.termId.length > 8
                ? c.termId.substring(0, 8).toUpperCase()
                : c.termId.toUpperCase(),
            c.subjectName,
            c.room ?? c.gradeLevel ?? '-',
            studentCount,
            Icons.menu_book_rounded,
            c.isActive ? 'กำลังเปิดสอน' : 'ปิดแล้ว',
            c.isActive ? TeacherPalette.green : TeacherPalette.muted,
            _gradients[i % _gradients.length],
          ),
        );
      }
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'โหลดรายวิชาไม่สำเร็จ: $e');
    }
  }

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
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                color: TeacherPalette.red,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (_items == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          else if (_items!.isEmpty)
            const Text(
              'ยังไม่มีรายวิชาที่คุณสอน',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            )
          else
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
                  children: _items!
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
        onTap: () => _openClassDetail(context, item),
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

class _ScheduleCard extends StatefulWidget {
  const _ScheduleCard();

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  List<_LessonItem>? _lessons;
  String? _error;

  static const _rowColors = [
    TeacherPalette.primary,
    TeacherPalette.skyDeep,
    TeacherPalette.orange,
    TeacherPalette.skyMid,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final slots = await CalendarService.listTeacherSchedules();
      // ClassScheduleSlot.dayOfWeek: 0=จันทร์...6=อาทิตย์, DateTime.weekday: 1=จันทร์...7=อาทิตย์
      final todayIndex = DateTime.now().weekday - 1;
      final today = slots.where((s) => s.dayOfWeek == todayIndex).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      setState(() {
        _lessons = [
          for (var i = 0; i < today.length; i++)
            _LessonItem(
              today[i].timeRangeLabel,
              today[i].subjectName,
              today[i].room ?? 'ไม่ระบุห้อง',
              '',
              Icons.menu_book_rounded,
              _rowColors[i % _rowColors.length],
              _rowColors[i % _rowColors.length].withValues(alpha: 0.08),
            ),
        ];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'โหลดตารางสอนไม่สำเร็จ');
    }
  }

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
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                color: TeacherPalette.red,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (_lessons == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          else if (_lessons!.isEmpty)
            const Text(
              'วันนี้ไม่มีคาบสอนในตาราง',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._lessons!.map((lesson) => _ScheduleTile(lesson: lesson)),
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
        onTap: () => _openLessonDetail(context, lesson),
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
                    fontSize: 13,
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
                      lesson.subtitleLabel,
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
                  lesson.subtitleLabel,
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
            onPressed: () => showTeacherMockAction(
              context,
              'เปิดคาบ ${lesson.title} (${lesson.room})',
            ),

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
class _MiniCalendarCard extends StatefulWidget {
  const _MiniCalendarCard();

  @override
  State<_MiniCalendarCard> createState() => _MiniCalendarCardState();
}

class _MiniCalendarCardState extends State<_MiniCalendarCard> {
  // "วันนี้" ของ mock ทั้งแอปคือพุธ 5/6 ส.ค. 2569 (ดู _TeacherTopBar) — ยึด
  // วันเดียวกันไว้ตรงนี้เพื่อให้ปฏิทินตรงกับข้อความหัวหน้าจอ
  static final DateTime _mockToday = DateTime(2026, 8, 6);
  late DateTime _displayedMonth = DateTime(_mockToday.year, _mockToday.month);
  int? _selectedDay;

  static const _thaiMonths = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];
  static const _weekdays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
  static const _markedDays = {13, 20, 27};

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_thaiMonths[_displayedMonth.month - 1]} ${_displayedMonth.year + 543}';
    // DateTime.weekday: จันทร์=1 ... อาทิตย์=7 ตรงกับลำดับ _weekdays พอดี
    final firstWeekday = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    ).weekday;
    final leadingBlanks = firstWeekday - 1;
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final isCurrentMonth =
        _displayedMonth.year == _mockToday.year &&
        _displayedMonth.month == _mockToday.month;
    final todayDay = isCurrentMonth ? _mockToday.day : null;

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _changeMonth(-1),
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
                onTap: () => _changeMonth(1),
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
              for (final w in _weekdays)
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
              final isToday = day == todayDay;
              final isSelected = day == _selectedDay;
              final isMarked = _markedDays.contains(day);
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? TeacherPalette.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: (isSelected && !isToday)
                        ? Border.all(color: TeacherPalette.primary, width: 1.4)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isToday ? Colors.white : TeacherPalette.ink,
                          fontSize: 11.5,
                          fontWeight: (isToday || isSelected)
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

Future<int> _fetchNotSubmittedStudentTotal() async {
  final courses = (await CourseService.listMyCourses())
      .where((c) => c.isActive)
      .toList();
  final notSubmitted = <String>{};
  for (final course in courses) {
    final roster = await CourseService.listCourseStudents(course.id);
    if (roster.isEmpty) continue;
    final assignments = (await AssignmentService.listAssignments(
      course.id,
    )).where((a) => a.status == 'published');
    for (final assignment in assignments) {
      final submissions = await AssignmentService.listSubmissions(
        assignment.id,
      );
      final submittedIds = submissions.map((s) => s.studentId).toSet();
      for (final student in roster) {
        if (!submittedIds.contains(student.studentId)) {
          notSubmitted.add(student.studentId);
        }
      }
    }
  }
  return notSubmitted.length;
}

/// เวลาเริ่มคาบถัดไปของวันนี้ (HH:mm) หรือ null ถ้าไม่มีคาบเหลือแล้ว
Future<String?> _fetchNextPeriodLabel() async {
  final schedules = await CalendarService.listTeacherSchedules();
  final todayIndex = DateTime.now().weekday - 1;
  final today = schedules.where((s) => s.dayOfWeek == todayIndex).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  final now = DateTime.now();
  final nowStr =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
  for (final slot in today) {
    if (slot.startTime.compareTo(nowStr) >= 0) {
      return slot.startTime.substring(0, 5);
    }
  }
  return null;
}

class _TodayFocusCard extends StatefulWidget {
  const _TodayFocusCard();

  @override
  State<_TodayFocusCard> createState() => _TodayFocusCardState();
}

class _TodayFocusCardState extends State<_TodayFocusCard> {
  int? _pending;
  int? _notSubmitted;
  String? _nextPeriod;
  bool _nextPeriodLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _fetchPendingReviewTotal(),
        _fetchNotSubmittedStudentTotal(),
        _fetchNextPeriodLabel(),
      ]);
      if (!mounted) return;
      setState(() {
        _pending = results[0] as int;
        _notSubmitted = results[1] as int;
        _nextPeriod = results[2] as String?;
        _nextPeriodLoaded = true;
      });
    } catch (_) {
      // เงียบไว้ — แถวจะโชว์ "-" ค้างต่อ ไม่ใช่จุดหลักของหน้า
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'โฟกัสวันนี้',
            subtitle: 'สิ่งที่ควรทำก่อนเริ่มคาบ',
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 16),
          _FocusRow(
            label: 'เช็คชื่อนักเรียน',
            value: '',
            color: TeacherPalette.violet,
            icon: Icons.checklist_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherAttendancePage()),
            ),
          ),
          _FocusRow(
            label: 'งานรอตรวจ',
            value: _pending == null ? '-' : '$_pending ชิ้น',
            color: TeacherPalette.orange,
            icon: Icons.assignment_rounded,
          ),
          _FocusRow(
            label: 'นักเรียนไม่ส่งงาน',
            value: _notSubmitted == null ? '-' : '$_notSubmitted คน',
            color: TeacherPalette.red,
            icon: Icons.person_search_rounded,
          ),
          _FocusRow(
            label: 'คาบถัดไป',
            value: !_nextPeriodLoaded
                ? '-'
                : (_nextPeriod ?? 'ไม่มีคาบแล้ว'),
            color: TeacherPalette.blue,
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }
}

class _ReviewQueueCard extends StatefulWidget {
  const _ReviewQueueCard();

  @override
  State<_ReviewQueueCard> createState() => _ReviewQueueCardState();
}

class _ReviewQueueCardState extends State<_ReviewQueueCard> {
  List<_ReviewTask>? _tasks;
  String? _error;

  static const _colors = [
    TeacherPalette.orange,
    TeacherPalette.skyDeep,
    TeacherPalette.red,
    TeacherPalette.primary,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final courses = (await CourseService.listMyCourses())
          .where((c) => c.isActive)
          .toList();
      final tasks = <_ReviewTask>[];
      for (final course in courses) {
        final assignments = await AssignmentService.listAssignments(course.id);
        for (final assignment in assignments) {
          if (assignment.status != 'published') continue;
          final submissions = await AssignmentService.listSubmissions(
            assignment.id,
          );
          final pending = submissions
              .where((s) => s.status == 'submitted')
              .length;
          if (pending == 0) continue;
          tasks.add(
            _ReviewTask(
              assignment.title,
              '${course.subjectName} · ส่งเข้ามา $pending ชิ้น',
              '$pending',
              Icons.assignment_rounded,
              _colors[tasks.length % _colors.length],
            ),
          );
        }
      }
      tasks.sort(
        (a, b) => int.parse(b.count).compareTo(int.parse(a.count)),
      );
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'โหลดงานรอตรวจไม่สำเร็จ');
    }
  }

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
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                color: TeacherPalette.red,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (_tasks == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          else if (_tasks!.isEmpty)
            const Text(
              'ไม่มีงานรอตรวจตอนนี้',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._tasks!.map((task) => _ReviewTaskTile(task: task)),
        ],
      ),
    );
  }
}

class _StudentsWatchCard extends StatefulWidget {
  const _StudentsWatchCard();

  @override
  State<_StudentsWatchCard> createState() => _StudentsWatchCardState();
}

class _StudentsWatchCardState extends State<_StudentsWatchCard> {
  List<_StudentWatch>? _students;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final flagged = await StudentSupportService.listAutoFlaggedStudents();
      if (!mounted) return;
      setState(() {
        _students = flagged
            .map(
              (f) => _StudentWatch(
                f.studentName,
                f.detail,
                f.actionLabel,
                f.severity == 'urgent'
                    ? TeacherPalette.red
                    : TeacherPalette.orange,
              ),
            )
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'โหลดรายชื่อนักเรียนที่ต้องติดตามไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'นักเรียนที่ต้องติดตาม',
            subtitle: 'ดูจากงานค้าง การเข้าเรียน และคะแนน',
            icon: Icons.groups_3_rounded,
          ),
          const SizedBox(height: 14),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                color: TeacherPalette.red,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (_students == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          else if (_students!.isEmpty)
            const Text(
              'ไม่มีนักเรียนที่ต้องติดตามตอนนี้',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._students!.map(
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
    return FutureBuilder<List<TeacherIncidentReport>>(
      future: IncidentService.listTeacherIncidentReports(status: 'new'),
      builder: (context, snapshot) {
        final pending = snapshot.data ?? [];
        if (pending.isEmpty) return const SizedBox.shrink();

        final hasSos = pending.any((i) => i.category == IncidentCategory.sos);
        final color = hasSos
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);

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
      },
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
    this.freshness = SensorFreshness.noData,
    this.timeLabel,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String level;
  final String? value;
  final String? unit;
  final SensorFreshness freshness;
  final String? timeLabel;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isNormal = level == 'ปกติ';
    final isModerate = level == 'ปานกลาง';

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

    // "ดิบ" (raw/uncalibrated, e.g. MQ-2) ใช้โทนสีเทาเป็นกลางเดียวกับ
    // "ไม่มีข้อมูล" — ไม่ใช่เพราะไม่มีข้อมูลจริง แต่เพราะยังไม่มีเกณฑ์
    // calibrate มาตัดสินว่า "ปกติ/ปานกลาง/เกิน" ได้ ไม่ควรฟันธงเป็นสีแดง/
    // เขียวลอยๆ
    final isNoData = level == 'ไม่มีข้อมูล' || level == 'ดิบ';
    final Color badgeBgColor;
    final Color badgeTextColor;
    final Color badgeDotColor;
    final Color badgeBorderColor;
    if (isNoData) {
      badgeBgColor = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF64748B);
      badgeDotColor = const Color(0xFF94A3B8);
      badgeBorderColor = const Color(0xFFCBD5E1).withValues(alpha: 0.6);
    } else if (isNormal) {
      badgeBgColor = const Color(0xFFECFDF5);
      badgeTextColor = const Color(0xFF059669);
      badgeDotColor = const Color(0xFF10B981);
      badgeBorderColor = const Color(0xFFA7F3D0).withValues(alpha: 0.6);
    } else if (isModerate) {
      badgeBgColor = const Color(0xFFFFFBEB);
      badgeTextColor = const Color(0xFFB45309);
      badgeDotColor = const Color(0xFFF59E0B);
      badgeBorderColor = const Color(0xFFFDE68A).withValues(alpha: 0.6);
    } else {
      badgeBgColor = const Color(0xFFFEF2F2);
      badgeTextColor = const Color(0xFFDC2626);
      badgeDotColor = const Color(0xFFEF4444);
      badgeBorderColor = const Color(0xFFFECACA).withValues(alpha: 0.6);
    }

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
                if (timeLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'อัปเดต $timeLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: freshness.color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Badge เดียวต่อแถว: ข้อมูลสด/ล่าช้าเล็กน้อย → โชว์ระดับความปลอดภัย
          // (ปกติ/ไม่ปลอดภัย) เหมือนเดิม; เซนเซอร์ไม่ทำงาน/ไม่มีข้อมูล → โชว์
          // สถานะนั้นแทน ไม่โชว์ทั้งสองอันซ้อนกัน (จะขัดแย้งกันเอง เช่น
          // "ปกติ" สีเขียวคู่กับ "เซนเซอร์ไม่ทำงาน" สีแดง)
          if (freshness == SensorFreshness.live ||
              freshness == SensorFreshness.delayed)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
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
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: freshness.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: freshness.color.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: freshness.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      freshness.label,
                      style: TextStyle(
                        color: freshness.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        letterSpacing: 0.1,
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
class _SmartWiringLabCard extends StatefulWidget {
  const _SmartWiringLabCard();

  @override
  State<_SmartWiringLabCard> createState() => _SmartWiringLabCardState();
}

class _SmartWiringLabCardState extends State<_SmartWiringLabCard> {
  WiringLabSummary? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await WiringGroupService.getWiringLabSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'โหลดข้อมูลชุดฝึก AIoT ไม่สำเร็จ');
    }
  }

  String _deviceStatusLabel(String? status) => switch (status) {
    'error' => 'ขัดข้อง',
    'offline' => 'ไม่ตอบสนอง',
    _ => 'ไม่มีสัญญาณล่าสุด',
  };

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AIoT Smart Wiring Lab',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary == null
                          ? 'กำลังโหลด...'
                          : 'ชุดฝึกทั้งหมด ${summary.kitsTotal} ชุด',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                color: TeacherPalette.red,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (summary == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          else if (summary.kitsTotal == 0)
            const Text(
              'ยังไม่มีชุดฝึก AIoT ที่ผูกกับวิชาที่คุณสอน',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760
                    ? 3
                    : constraints.maxWidth >= 480
                    ? 2
                    : 1;
                final itemWidth =
                    (constraints.maxWidth - ((columns - 1) * 10)) / columns;
                final metrics = [
                  _LabMetric(
                    label: 'ชุดฝึกพร้อม',
                    value: '${summary.kitsReady}/${summary.kitsTotal}',
                    icon: Icons.checklist_rounded,
                    color: TeacherPalette.green,
                  ),
                  _LabMetric(
                    label: 'อุปกรณ์ออนไลน์',
                    value: '${summary.devicesOnline}/${summary.devicesTotal}',
                    icon: Icons.memory_rounded,
                    color: TeacherPalette.primary,
                  ),
                  _LabMetric(
                    label: 'กำลังต่อสาย',
                    value: '${summary.wiringCount} กลุ่ม',
                    icon: Icons.cable_rounded,
                    color: TeacherPalette.skyDeep,
                  ),
                  _LabMetric(
                    label: 'ผ่านการตรวจ',
                    value: '${summary.passedCount} กลุ่ม',
                    icon: Icons.verified_rounded,
                    color: TeacherPalette.green,
                  ),
                  _LabMetric(
                    label: 'รอเริ่มระบบจริง',
                    value: '${summary.waitingToRunCount} กลุ่ม',
                    icon: Icons.pending_actions_rounded,
                    color: TeacherPalette.orange,
                  ),
                  _LabMetric(
                    label: 'ต้องตรวจสอบ',
                    value: '${summary.needsReviewCount} รายการ',
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
            if (summary.alertKitCode != null) ...[
              const SizedBox(height: 14),
              _LabDeviceNotice(
                text:
                    'ชุดฝึก ${summary.alertKitCode}: ${summary.alertDeviceName} '
                    '${_deviceStatusLabel(summary.alertDeviceStatus)} ต้องตรวจสาย USB ก่อนเริ่มคาบ',
              ),
            ],
          ],
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

class _LabDeviceNotice extends StatelessWidget {
  const _LabDeviceNotice({required this.text});

  final String text;

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
      child: Row(
        children: [
          const Icon(
            Icons.portable_wifi_off_rounded,
            size: 18,
            color: TeacherPalette.red,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
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
/// การ์ด "การใช้น้ำ-ไฟ" ของห้องประจำชั้น — ย้ายมาจากเวอร์ชันโต้ตอบได้ใน
/// storybook ("Card 8: Homeroom Utility 2-Line Chart") แทนเวอร์ชันเดิมที่
/// เป็น static เฉยๆ เพราะแตะ/ชี้เมาส์ที่แต่ละวันแล้วเห็นตัวเลขจริงของวันนั้น
/// ได้เลย (ป้ายค่า "26 kWh"/"0.6 m³" ลอยเหนือจุดกราฟ) ไม่ต้องเดาจากเส้นกราฟ
/// อย่างเดียว ข้อมูลยังเป็น mock ทั้งหมดเหมือนเดิม
class _HomeroomUtilityCard extends StatefulWidget {
  const _HomeroomUtilityCard();

  @override
  State<_HomeroomUtilityCard> createState() => _HomeroomUtilityCardState();
}

class _HomeroomUtilityCardState extends State<_HomeroomUtilityCard>
    with SingleTickerProviderStateMixin {
  static const _thaiWeekdayAbbr = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

  late final AnimationController _pulseController;
  int _selectedDayIdx = 0;

  List<String> _days = const ['-', '-', '-', '-', '-'];
  List<double> _electricByDay = const [0, 0, 0, 0, 0];
  List<double> _waterByDay = const [0, 0, 0, 0, 0];

  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;
  UtilityEfficiencyScore? _energyScore;
  UtilityEfficiencyScore? _waterScore;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _selectedDayIdx = _days.length - 1;
    _loadRealUsage();
  }

  Future<void> _loadRealUsage() async {
    try {
      final results = await Future.wait([
        UtilityService.getEnergyUsageSummary(period: 'week'),
        UtilityService.getWaterUsageSummary(period: 'week'),
        UtilityService.getEnergyEfficiencyScore(),
        UtilityService.getWaterEfficiencyScore(),
        UtilityService.getEnergyUsageTrend(days: 5),
        UtilityService.getWaterUsageTrend(days: 5),
      ]);
      if (!mounted) return;

      final energyTrend = results[4] as List<UtilityTrendPoint>;
      final waterTrend = results[5] as List<UtilityTrendPoint>;

      // Real trend RPCs only return days that actually have a reading —
      // fill the last 5 calendar days so a day with zero usage shows as
      // 0, not as a missing/skipped point on the chart.
      final today = DateTime.now();
      final last5 = List.generate(
        5,
        (i) => DateTime(today.year, today.month, today.day - (4 - i)),
      );
      double valueForDay(List<UtilityTrendPoint> trend, DateTime day) {
        for (final p in trend) {
          if (p.day.year == day.year &&
              p.day.month == day.month &&
              p.day.day == day.day) {
            return p.value;
          }
        }
        return 0;
      }

      setState(() {
        _energySummary = results[0] as EnergyUsageSummary?;
        _waterSummary = results[1] as WaterUsageSummary?;
        _energyScore = results[2] as UtilityEfficiencyScore?;
        _waterScore = results[3] as UtilityEfficiencyScore?;
        _days = last5.map((d) => _thaiWeekdayAbbr[d.weekday - 1]).toList();
        _electricByDay = last5.map((d) => valueForDay(energyTrend, d)).toList();
        _waterByDay = last5.map((d) => valueForDay(waterTrend, d)).toList();
        _selectedDayIdx = _days.length - 1;
      });
    } catch (_) {
      // Keep the zeroed placeholder state on error — honest, not fake.
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Real week-over-week % change from get_*_efficiency_score's
  /// current/previous (7 days vs the 7 days before that). "ไม่มีข้อมูลเทียบ"
  /// when there's no prior week to compare against yet, rather than a fake
  /// percentage.
  String _trendLabel(UtilityEfficiencyScore? score) {
    if (score == null || score.previous <= 0) return 'ไม่มีข้อมูลเทียบ';
    final pct = ((score.current - score.previous) / score.previous * 100);
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}%';
  }

  double _trendProgress(UtilityEfficiencyScore? score) {
    if (score == null || score.previous <= 0) return 0.0;
    return (score.current / score.previous).clamp(0.0, 1.0);
  }

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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _UtilitySplitMetric(
                    label: 'ไฟฟ้า',
                    dotColor: TeacherPalette.orange,
                    value: _energySummary != null
                        ? _energySummary!.totalKwh.toStringAsFixed(0)
                        : '-',
                    unit: 'kWh',
                    trendUp:
                        (_energyScore?.current ?? 0) >
                        (_energyScore?.previous ?? 0),
                    trendLabel: _trendLabel(_energyScore),
                    progress: _trendProgress(_energyScore),
                    barColor: TeacherPalette.orange,
                  ),
                ),
                Container(
                  height: 56,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: _UtilitySplitMetric(
                    label: 'น้ำ',
                    dotColor: _kWaterBlue,
                    value: _waterSummary != null
                        ? _waterSummary!.totalM3.toStringAsFixed(1)
                        : '-',
                    unit: 'm³',
                    trendUp:
                        (_waterScore?.current ?? 0) >
                        (_waterScore?.previous ?? 0),
                    trendLabel: _trendLabel(_waterScore),
                    progress: _trendProgress(_waterScore),
                    barColor: _kWaterBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ค่าเฉลี่ยรายวัน',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: const [
                  _UtilityLegendDot(
                    color: TeacherPalette.orange,
                    label: 'ไฟฟ้า',
                  ),
                  SizedBox(width: 10),
                  _UtilityLegendDot(color: _kWaterBlue, label: 'น้ำ'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return MouseRegion(
                  onHover: (event) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localX = box.globalToLocal(event.position).dx;
                      final ratio = (localX / box.size.width).clamp(0.0, 1.0);
                      final index = (ratio * (_days.length - 1)).round();
                      if (index != _selectedDayIdx) {
                        setState(() => _selectedDayIdx = index);
                      }
                    }
                  },
                  child: CustomPaint(
                    painter: _UtilityGradientAreaChartPainter(
                      electricValues: _electricByDay,
                      waterValues: _waterByDay,
                      selectedDayIdx: _selectedDayIdx,
                      pulsePhase: _pulseController.value,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_days.length, (idx) {
              final isSelected = idx == _selectedDayIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIdx = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TeacherPalette.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _days[idx],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected
                            ? TeacherPalette.primary
                            : TeacherPalette.muted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _UtilitySplitMetric extends StatelessWidget {
  const _UtilitySplitMetric({
    required this.label,
    required this.dotColor,
    required this.value,
    required this.unit,
    required this.trendUp,
    required this.trendLabel,
    required this.progress,
    required this.barColor,
  });

  final String label;
  final Color dotColor;
  final String value;
  final String unit;
  final bool trendUp;
  final String trendLabel;
  final double progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final trendColor = trendUp
        ? const Color(0xFFDC2626)
        : const Color(0xFF059669);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: TeacherPalette.muted,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    trendUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 10,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trendLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$value ',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: TeacherPalette.ink,
                  height: 1.0,
                ),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TeacherPalette.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: barColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
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

/// วาดกราฟพื้นที่ไล่สี 2 เส้น (ไฟฟ้า/น้ำ) พร้อมลำแสงวิ่งเรืองแสงและ
/// tooltip ลอยเหนือจุดที่เลือก — ย้ายมาจาก storybook ปรับชื่อคลาสให้
/// สื่อความหมายตรงกับที่ใช้งานจริง (ของเดิมชื่อ "MembersGradientArea"
/// เป็นชื่อที่ตกค้างมาจากการ์ดอื่น ไม่เกี่ยวกับน้ำ-ไฟ)
class _UtilityGradientAreaChartPainter extends CustomPainter {
  _UtilityGradientAreaChartPainter({
    required this.electricValues,
    required this.waterValues,
    required this.selectedDayIdx,
    required this.pulsePhase,
  });

  final List<double> electricValues;
  final List<double> waterValues;
  final int selectedDayIdx;
  final double pulsePhase;

  static const _electricColor = TeacherPalette.orange;
  static const _waterColor = _kWaterBlue;
  static const _electricGlow = Color(0xFFFDBA74);
  static const _waterGlow = Color(0xFF7DD3FC);

  List<Offset> _buildPoints(
    List<double> values,
    double w,
    double h,
    double topFraction,
    double bottomFraction,
  ) {
    final maxVal = values.reduce(math.max) * 1.15;
    final minVal = values.reduce(math.min) * 0.7;
    final count = values.length;
    final band = bottomFraction - topFraction;
    return [
      for (var i = 0; i < count; i++)
        Offset(
          (w / (count - 1)) * i,
          h * bottomFraction -
              (h * band) * ((values[i] - minVal) / (maxVal - minVal)),
        ),
    ];
  }

  Path _buildCurve(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final electricPoints = _buildPoints(electricValues, w, h, 0.06, 0.52);
    final waterPoints = _buildPoints(waterValues, w, h, 0.58, 0.92);
    final electricCurve = _buildCurve(electricPoints);
    final waterCurve = _buildCurve(waterPoints);

    final waterFillPath = Path.from(waterCurve)
      ..lineTo(w, h * 0.92)
      ..lineTo(0, h * 0.92)
      ..close();

    final electricFillPath = Path.from(electricCurve)
      ..lineTo(w, h * 0.92)
      ..lineTo(0, h * 0.92)
      ..close();

    final gradientRect = Rect.fromLTWH(0, 0, w, h);

    canvas.drawPath(
      waterFillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _waterColor.withValues(alpha: 0.22),
            _waterColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.50, w, h * 0.45))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      electricFillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _electricColor.withValues(alpha: 0.26),
            _electricColor.withValues(alpha: 0.03),
          ],
        ).createShader(gradientRect)
        ..style = PaintingStyle.fill,
    );

    const electricStrokeGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFFFD8A8), Color(0xFFFB923C), Color(0xFFEA580C)],
      stops: [0.0, 0.5, 1.0],
    );

    const waterStrokeGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFBAE6FD), Color(0xFF38BDF8), Color(0xFF0284C7)],
      stops: [0.0, 0.5, 1.0],
    );

    canvas.drawPath(
      electricCurve,
      Paint()
        ..shader = electricStrokeGradient.createShader(gradientRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      waterCurve,
      Paint()
        ..shader = waterStrokeGradient.createShader(gradientRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    _drawGlowBeam(canvas, electricCurve, _electricGlow, pulsePhase, 3.0);
    _drawGlowBeam(
      canvas,
      waterCurve,
      _waterGlow,
      (pulsePhase + 0.5) % 1.0,
      2.4,
    );

    final idx = selectedDayIdx.clamp(0, electricPoints.length - 1);
    final electricNode = electricPoints[idx];
    final waterNode = waterPoints[idx];

    final focusPaint = Paint()
      ..color = const Color(0xFFE2D9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(electricNode.dx, math.min(electricNode.dy, waterNode.dy) - 14),
      Offset(electricNode.dx, h),
      focusPaint,
    );

    canvas.drawCircle(electricNode, 5.0, Paint()..color = _electricColor);
    canvas.drawCircle(
      electricNode,
      5.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(waterNode, 4.5, Paint()..color = _waterColor);
    canvas.drawCircle(
      waterNode,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawTooltipPill(
      canvas,
      electricNode,
      '${electricValues[idx].toStringAsFixed(0)} kWh',
      _electricColor,
    );
    _drawTooltipPill(
      canvas,
      waterNode,
      '${waterValues[idx].toStringAsFixed(1)} m³',
      _waterColor,
    );
  }

  void _drawGlowBeam(
    Canvas canvas,
    Path path,
    Color color,
    double phase,
    double strokeWidth,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final totalLen = metric.length;
      final headDist = totalLen * phase;
      final tailLen = totalLen * 0.26;
      final pulsePath = metric.extractPath(
        (headDist - tailLen).clamp(0.0, totalLen),
        headDist.clamp(0.0, totalLen),
      );
      canvas.drawPath(
        pulsePath,
        Paint()
          ..color = color.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.5),
      );
      canvas.drawPath(
        pulsePath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  void _drawTooltipPill(Canvas canvas, Offset point, String text, Color bg) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillW = textPainter.width + 16;
    const pillH = 22.0;
    final pillOffset = Offset(
      (point.dx - pillW / 2).clamp(0.0, double.infinity),
      point.dy - pillH - 8,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillOffset.dx, pillOffset.dy, pillW, pillH),
      const Radius.circular(11),
    );

    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0x1F000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(rect, Paint()..color = bg);
    textPainter.paint(
      canvas,
      Offset(
        pillOffset.dx + (pillW - textPainter.width) / 2,
        pillOffset.dy + (pillH - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _UtilityGradientAreaChartPainter oldDelegate) =>
      true;
}

/// การ์ดเซนเซอร์สภาพอากาศ AIoT — เนื้อหา/เลย์เอาต์แบบเดียวกับ
/// AiotWeatherSensorsCard ฝั่งนักเรียน (aiot_weather_sensors_card.dart)
/// แต่ปรับให้ใช้ TeacherPalette/_GlassCard ของแดชบอร์ดครูแทน SchoolPalette
/// เพื่อให้เข้ากับ Design System เดิมของหน้านี้ ปุ่มด้านล่างพาไปหน้า
/// AiotDashboardPage ตัวจริง (อ่านค่าเซนเซอร์สดจาก Supabase) เหมือนกัน
class _AiotWeatherSensorsCard extends StatefulWidget {
  const _AiotWeatherSensorsCard();

  @override
  State<_AiotWeatherSensorsCard> createState() =>
      _AiotWeatherSensorsCardState();
}

class _AiotWeatherSensorsCardState extends State<_AiotWeatherSensorsCard> {
  // ต้อง cache stream ไว้ครั้งเดียวใน initState ห้ามเรียก
  // RealtimeService.sensorStream(...)/rawReadingsStream() แบบ inline ใน
  // builder: ของ StreamBuilder — เพราะ builder: ของ StreamBuilder ชั้นนอก
  // (rawReadingsStream) จะถูกเรียกซ้ำทุก ~5 วินาทีตาม poll tick ของมันเอง
  // ถ้า sensorStream(...) อยู่ inline ข้างในนั้น จะได้ Stream object ใหม่
  // ทุกครั้ง ทำให้ StreamBuilder ชั้นในตัด connection เดิมทิ้งแล้วต่อใหม่
  // ทุก 5 วินาทีวนไปเรื่อยๆ ไม่มีทางได้ข้อมูลจริงมาแสดงเลย (บั๊กเดียวกับที่
  // เจอในหน้านักเรียน — director_overview_page.dart ทำถูกอยู่แล้วด้วย
  // pattern นี้ ใช้เป็นต้นแบบ)
  late final Stream<List<Map<String, dynamic>>> _rawStream;
  late final Stream<SensorModel?> _sensorStream;

  @override
  void initState() {
    super.initState();
    _rawStream = RealtimeService.rawReadingsStream();
    _sensorStream = RealtimeService.sensorStream(
      schoolId: '',
      building: '',
      floor: '',
      room: '',
    );
  }

  String _levelLabel(SensorLevel level) => switch (level) {
    SensorLevel.good => 'ปกติ',
    SensorLevel.moderate => 'ปานกลาง',
    SensorLevel.danger => 'ไม่ปลอดภัย',
  };

  // Confirmed with the board's firmware author (2026-08-31): the "aqi"
  // metric is the ENS160 (ScioSense) gas sensor's own AQI-UBA index — a
  // 1-5 scale from the German Federal Environmental Agency (UBA)
  // guideline, derived internally by the chip from its TVOC signal. This
  // is NOT the 0-500 US EPA / Thai PCD Air Quality Index most people
  // expect from the term "AQI" — do not convert it 1:1 to that scale.
  String _aqiUbaLabel(double value) {
    switch (value.round()) {
      case 1:
        return 'ดีมาก';
      case 2:
        return 'ดี';
      case 3:
        return 'ปานกลาง';
      case 4:
        return 'แย่';
      case 5:
        return 'ไม่ปลอดภัย';
      default:
        return 'ไม่ทราบระดับ';
    }
  }

  static ({double value, DateTime? ts})? _latestValueOf(
    List<Map<String, dynamic>> rows,
    String metric,
  ) {
    Map<String, dynamic>? latest;
    DateTime? latestTs;
    for (final r in rows) {
      if (r['metric'] != metric) continue;
      final ts = DateTime.tryParse(r['ts'] as String? ?? '');
      if (latest == null ||
          (ts != null && (latestTs == null || ts.isAfter(latestTs)))) {
        latest = r;
        latestTs = ts;
      }
    }
    final v = latest?['value'];
    if (v is! num) return null;
    return (value: v.toDouble(), ts: latestTs);
  }

  static SensorFreshness _freshnessOf(DateTime? ts) {
    if (ts == null) return SensorFreshness.noData;
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age <= const Duration(minutes: 2)) return SensorFreshness.live;
    if (age <= const Duration(minutes: 10)) return SensorFreshness.delayed;
    return SensorFreshness.offline;
  }

  static String _relativeTimeLabel(DateTime? ts) {
    if (ts == null) return 'ไม่มีข้อมูล';
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age.inSeconds < 60) return 'เมื่อสักครู่';
    if (age.inMinutes < 60) return '${age.inMinutes} นาทีที่แล้ว';
    if (age.inHours < 24) return '${age.inHours} ชม.ที่แล้ว';
    return '${age.inDays} วันที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    // เดิมโค้ดนี้ดึงข้อมูลแค่ครั้งเดียวตอน initState แล้วไม่รีเฟรชอีกเลย —
    // บั๊กเดียวกับที่เจอในหน้านักเรียน/ผู้บริหาร (ค่าค้าง เวลานับถอยหลัง
    // เดินต่อจนดูเหมือนเซนเซอร์หลุดทั้งที่จริงยังส่งข้อมูลอยู่) เปลี่ยนเป็น
    // poll ต่อเนื่องเหมือนหน้าอื่นแทน
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _rawStream,
      builder: (context, rawSnapshot) {
        final rawRows = rawSnapshot.data ?? const <Map<String, dynamic>>[];
        final aqi = _latestValueOf(rawRows, 'aqi');
        final gas = _latestValueOf(rawRows, 'gas_mq2_percent');

        return StreamBuilder<SensorModel?>(
          stream: _sensorStream,
          builder: (context, snapshot) {
            final sensor = snapshot.data;
            final headerFreshness =
                sensor?.overallFreshnessOf(const [
                  'pm25',
                  'temperature',
                  'humidity',
                  'light_lux',
                ]) ??
                SensorFreshness.noData;
            final bool hasPm25 =
                sensor?.metricUpdatedAt.containsKey('pm25') ?? false;
            final bool hasTemp =
                sensor?.metricUpdatedAt.containsKey('temperature') ?? false;
            final bool hasHumidity =
                sensor?.metricUpdatedAt.containsKey('humidity') ?? false;
            final bool hasLux =
                sensor?.metricUpdatedAt.containsKey('light_lux') ?? false;
            final bool hasCo2 =
                sensor?.metricUpdatedAt.containsKey('co2') ?? false;
            final bool hasTvoc =
                sensor?.metricUpdatedAt.containsKey('tvoc') ?? false;

            return _GlassCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusPulseDot(color: headerFreshness.color),
                      const SizedBox(width: 8),
                      const Expanded(
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
                  _AiotSensorRow(
                    icon: Icons.air_rounded,
                    title: 'ฝุ่น PM2.5 (ห้องเรียนปลอดภัย)',
                    value: hasPm25 ? '${sensor!.pm25.toInt()}' : '-',
                    unit: 'µg/m³',
                    subtitle: hasPm25
                        ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: hasPm25
                        ? _levelLabel(sensor!.pm25Level)
                        : 'ไม่มีข้อมูล',
                    freshness:
                        sensor?.freshnessOf('pm25') ?? SensorFreshness.noData,
                    timeLabel: sensor?.relativeTimeLabel('pm25'),
                    showDivider: true,
                  ),
                  _AiotSensorRow(
                    icon: Icons.thermostat_rounded,
                    title: 'อุณหภูมิห้องเรียน',
                    value: hasTemp
                        ? sensor!.temperature.toStringAsFixed(1)
                        : '-',
                    unit: '°C',
                    subtitle: hasTemp
                        ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: hasTemp
                        ? _levelLabel(sensor!.tempLevel)
                        : 'ไม่มีข้อมูล',
                    freshness:
                        sensor?.freshnessOf('temperature') ??
                        SensorFreshness.noData,
                    timeLabel: sensor?.relativeTimeLabel('temperature'),
                    showDivider: true,
                  ),
                  _AiotSensorRow(
                    icon: Icons.water_drop_rounded,
                    title: 'ความชื้นสัมพัทธ์',
                    value: hasHumidity
                        ? sensor!.humidity.toStringAsFixed(1)
                        : '-',
                    unit: '%RH',
                    subtitle: hasHumidity
                        ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: hasHumidity
                        ? _levelLabel(sensor!.humidityLevel)
                        : 'ไม่มีข้อมูล',
                    freshness:
                        sensor?.freshnessOf('humidity') ??
                        SensorFreshness.noData,
                    timeLabel: sensor?.relativeTimeLabel('humidity'),
                    showDivider: true,
                  ),
                  _AiotSensorRow(
                    icon: Icons.wb_sunny_rounded,
                    title: 'ความเข้มแสง',
                    value: hasLux ? '${sensor!.lux.toInt()}' : '-',
                    unit: 'lux',
                    subtitle: hasLux
                        ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: hasLux
                        ? _levelLabel(sensor!.luxLevel)
                        : 'ไม่มีข้อมูล',
                    freshness:
                        sensor?.freshnessOf('light_lux') ??
                        SensorFreshness.noData,
                    timeLabel: sensor?.relativeTimeLabel('light_lux'),
                    showDivider: true,
                  ),
                  // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): นี่คือดัชนี
                  // AQI-UBA ของชิป ENS160 สเกล 1-5 (ตาม German UBA) ไม่ใช่
                  // AQI มาตรฐาน 0-500 ของ US EPA/กรมควบคุมมลพิษไทย
                  _AiotSensorRow(
                    icon: Icons.eco_rounded,
                    title: 'AQI-UBA (ENS160)',
                    value: aqi != null ? aqi.value.toStringAsFixed(0) : '-',
                    subtitle: aqi != null
                        ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: aqi != null
                        ? _aqiUbaLabel(aqi.value)
                        : 'ไม่มีข้อมูล',
                    freshness: _freshnessOf(aqi?.ts),
                    timeLabel: aqi != null
                        ? _relativeTimeLabel(aqi.ts)
                        : null,
                    showDivider: true,
                  ),
                  // MQ-2 ตอบสนองต่อทั้งแก๊สติดไฟและควันจริงตามสเปกชิป แต่
                  // ส่งออกมาเป็นสัญญาณตัวเลขเดียวรวมกัน แยกไม่ออกว่าเกิดจาก
                  // แก๊สหรือควัน — ห้ามเขียนค่าเป็น "แก๊ส/ควัน X%" เฉยๆ
                  // (จะดูเหมือนความเข้มข้นที่ calibrate แล้ว) ต้องกำกับ
                  // "(ดิบ)" เสมอจนกว่าจะ calibrate เป็น ppm จริง — ไม่มีสี
                  // ระดับ (ปกติ/ปานกลาง/เกิน) เพราะไม่มีเกณฑ์ calibrate จริง
                  _AiotSensorRow(
                    icon: Icons.local_fire_department_rounded,
                    title: 'แก๊ส/ควัน (MQ-2)',
                    value: gas != null
                        ? '${gas.value.toStringAsFixed(0)}%'
                        : '-',
                    subtitle: gas != null
                        ? 'สัญญาณดิบ ยังไม่ calibrate เป็น ppm'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: gas != null ? 'ดิบ' : 'ไม่มีข้อมูล',
                    freshness: _freshnessOf(gas?.ts),
                    timeLabel: gas != null
                        ? _relativeTimeLabel(gas.ts)
                        : null,
                    showDivider: true,
                  ),
                  // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): บอร์ดใช้ชิป
                  // แก๊ส ENS160 (ScioSense, MOX multi-gas) ค่า "co2" ที่ส่ง
                  // เข้าระบบคือ eCO2 (Equivalent CO2) ที่ชิปคำนวณจาก
                  // VOCs/hydrogen ภายใน ไม่ใช่การวัด CO2 ตรงแบบเซนเซอร์
                  // NDIR — ต้องเขียนกำกับว่า "ประมาณการ" เสมอ
                  _AiotSensorRow(
                    icon: Icons.cloud_outlined,
                    title: 'eCO2 (ประมาณการ)',
                    value: hasCo2 ? sensor!.co2.toStringAsFixed(0) : '-',
                    unit: 'ppm',
                    subtitle: hasCo2
                        ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: hasCo2
                        ? _levelLabel(sensor!.co2Level)
                        : 'ไม่มีข้อมูล',
                    freshness:
                        sensor?.freshnessOf('co2') ?? SensorFreshness.noData,
                    timeLabel: sensor?.relativeTimeLabel('co2'),
                    showDivider: true,
                  ),
                  // ใช้เกณฑ์ SensorModel.tvocLevel ที่มีอยู่แล้วใน
                  // widgets/sensor_card.dart — แต่ยังไม่ยืนยัน 100% ว่าหน่วย
                  // ที่ ENS160 ส่งมาคือ ppb (ตามที่แสดงไว้) หรือ mg/m³ (ตามที่
                  // sensor_card.dart กำกับหน่วยไว้) ถ้าคลาดเคลื่อน ระดับ
                  // ตรงนี้อาจผิดไปด้วย — ควรยืนยันหน่วยกับผู้ทำ firmware
                  // อีกครั้ง
                  _AiotSensorRow(
                    icon: Icons.science_outlined,
                    title: 'TVOC',
                    value: hasTvoc ? sensor!.tvoc.toStringAsFixed(0) : '-',
                    unit: 'ppb',
                    subtitle: hasTvoc
                        ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                        : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
                    level: hasTvoc
                        ? _levelLabel(sensor!.tvocLevel)
                        : 'ไม่มีข้อมูล',
                    freshness:
                        sensor?.freshnessOf('tvoc') ?? SensorFreshness.noData,
                    timeLabel: sensor?.relativeTimeLabel('tvoc'),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
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
          },
        );
      },
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

class _SensorSnapshotCard extends StatefulWidget {
  const _SensorSnapshotCard();

  @override
  State<_SensorSnapshotCard> createState() => _SensorSnapshotCardState();
}

class _SensorSnapshotCardState extends State<_SensorSnapshotCard> {
  SensorModel? _sensor;
  Set<String> _availableMetrics = const {};

  @override
  void initState() {
    super.initState();
    _loadRealSensor();
  }

  Future<void> _loadRealSensor() async {
    try {
      final results = await Future.wait([
        RealtimeService.getSensorOnce(
          schoolId: '',
          building: '',
          floor: '',
          room: '',
        ),
        RealtimeService.getWeatherMetricsWithData(),
      ]);
      if (!mounted) return;
      setState(() {
        _sensor = results[0] as SensorModel?;
        _availableMetrics = results[1] as Set<String>;
      });
    } catch (_) {
      // Keep the honest "no data" state on error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensor = _sensor;
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
          _SensorMiniMetric(
            label: 'PM2.5',
            value: _availableMetrics.contains('pm25')
                ? '${sensor!.pm25.toInt()}'
                : '-',
            unit: 'µg/m³',
            color: TeacherPalette.blue,
            freshness: sensor?.freshnessOf('pm25') ?? SensorFreshness.noData,
            timeLabel: sensor?.relativeTimeLabel('pm25'),
          ),
          const SizedBox(height: 8),
          _SensorMiniMetric(
            label: 'Temp',
            value: _availableMetrics.contains('temperature')
                ? sensor!.temperature.toStringAsFixed(1)
                : '-',
            unit: '°C',
            color: TeacherPalette.orange,
            freshness:
                sensor?.freshnessOf('temperature') ?? SensorFreshness.noData,
            timeLabel: sensor?.relativeTimeLabel('temperature'),
          ),
          const SizedBox(height: 8),
          _SensorMiniMetric(
            label: 'Humidity',
            value: _availableMetrics.contains('humidity')
                ? sensor!.humidity.toStringAsFixed(1)
                : '-',
            unit: '%RH',
            color: TeacherPalette.primary2,
            freshness:
                sensor?.freshnessOf('humidity') ?? SensorFreshness.noData,
            timeLabel: sensor?.relativeTimeLabel('humidity'),
          ),
          const SizedBox(height: 8),
          _SensorMiniMetric(
            label: 'ความเข้มแสง',
            value: _availableMetrics.contains('light_lux')
                ? '${sensor!.lux.toInt()}'
                : '-',
            unit: 'lux',
            color: TeacherPalette.violet,
            freshness:
                sensor?.freshnessOf('light_lux') ?? SensorFreshness.noData,
            timeLabel: sensor?.relativeTimeLabel('light_lux'),
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
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
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
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: onTap == null
          ? row
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: row,
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
            onPressed: () =>
                showTeacherMockAction(context, 'จัดการ ${task.title}'),

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
    this.freshness = SensorFreshness.noData,
    this.timeLabel,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final SensorFreshness freshness;
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (timeLabel != null) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: freshness.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  freshness == SensorFreshness.live
                      ? 'สด • $timeLabel'
                      : '${freshness.label} • $timeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: freshness.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentUserModel?.name ?? 'ครูผู้สอน',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TeacherPalette.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  const Text(
                    'ครูผู้สอน ▾',
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
    _MenuItem('ตารางสอน', Icons.calendar_month_rounded),
    _MenuItem('คลังข้อสอบ', Icons.quiz_rounded),
    _MenuItem('คลังความรู้', Icons.folder_special_rounded),
    _MenuItem('นักเรียน', Icons.groups_2_rounded),
    _MenuItem('เช็คชื่อ', Icons.checklist_rounded),
    _MenuItem('อนุมัติใบลา', Icons.event_available_rounded),
    _MenuItem('ตรวจงาน', Icons.assignment_turned_in_rounded),
    _MenuItem('คะแนน', Icons.bar_chart_rounded),
    _MenuItem('ยืนยัน G-Score', Icons.verified_rounded),
    _MenuItem('ช่วยเหลือนักเรียน', Icons.support_rounded),
    _MenuItem('อนุมัติผูกบัญชี', Icons.family_restroom_rounded),
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

  String get subtitleLabel => note.trim().isEmpty ? room : '$room · $note';
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

/// เปิดหน้ารายละเอียดวิชาจากการ์ด `_TeacherClassCard` — `_ClassItem` ไม่มี
/// ทุกฟิลด์ที่ `TeacherCourseModel` ต้องการ (เช่น จำนวนงานค้างตรวจจริง)
/// เพราะเป็น mock คนละชุดกัน ค่าที่ไม่มีข้อมูลจริงจึงใส่เป็น 0/ว่างไว้ก่อน
/// แทนที่จะเดาตัวเลขขึ้นมาเอง
void _openClassDetail(BuildContext context, _ClassItem item) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TeacherCourseDetailPage(
        course: TeacherCourseModel(
          code: item.code,
          name: item.title,
          category: item.status,
          rooms: [item.room],
          studentCount: item.students,
          activeAssignments: 0,
          pendingGradingCount: 0,
          completionRate: 0,
          coverGradient: item.gradient,
          accentColor: item.statusColor,
          nextPeriodText: item.status,
        ),
      ),
    ),
  );
}

/// แสดงรายละเอียดคาบเรียนจากตารางสอนวันนี้ — `_LessonItem` ไม่มีการผูกกับ
/// วิชา/หน้ารายละเอียดใดโดยตรง จึงโชว์เป็นแผ่นข้อมูลสรุปแทนการเดา
/// นำทางไปหน้าอื่นที่อาจไม่ตรงกับคาบเรียนจริง
void _openLessonDetail(BuildContext context, _LessonItem lesson) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: TeacherPalette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lesson.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(lesson.icon, color: lesson.color),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      '${lesson.time} · ${lesson.room}',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lesson.note.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TeacherPalette.sidebar,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                lesson.note,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _TeacherSearchSuggestion {
  const _TeacherSearchSuggestion(this.label, this.query, this.icon);

  final String label;
  final String query;
  final IconData icon;
}

const _teacherSearchSuggestions = [
  _TeacherSearchSuggestion('ทั้งหมด', '', Icons.grid_view_rounded),
  _TeacherSearchSuggestion('AIoT', 'AIoT', Icons.memory_rounded),
  _TeacherSearchSuggestion('ฟิสิกส์', 'ฟิสิกส์', Icons.science_rounded),
  _TeacherSearchSuggestion('ชีววิทยา', 'ชีววิทยา', Icons.eco_rounded),
];

/// ป็อปอัพตัวอย่างแจ้งเตือนแบบกระจกฝ้า (glassmorphic) — สไตล์เดียวกับ
/// `_openGlassNotificationModal` ฝั่งนักเรียน (student_navigation_prototype.
/// dart): เบลอพื้นหลัง + การ์ดขาวโปร่งแสง + โชว์ 3 รายการล่าสุด + ปุ่ม
/// "ดูการแจ้งเตือนทั้งหมด" พาไปหน้าเต็ม `TeacherNotificationsPage` (ของเดิม
/// ที่มีระบบกรอง/mark-as-read ครบอยู่แล้ว ไม่ได้แตะ) ใช้ข้อมูล mock ชุด
/// เดียวกับหน้าเต็มผ่าน `mockTeacherNotifications()` กันข้อมูลไม่ตรงกัน
void _showTeacherNotificationPreview(BuildContext context) {
  final notifications = mockTeacherNotifications();
  final preview = notifications.take(3).toList();

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (dialogContext) {
      return Dialog(
        alignment: Alignment.topRight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.only(
          right: 16,
          left: 16,
          top: 90,
          bottom: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xF7FFFFFF),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0x1F0F172A), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                    blurRadius: 34,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'การแจ้งเตือน 🔔',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF334155),
                            tooltip: 'ปิด',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (preview.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'ไม่มีการแจ้งเตือนใหม่',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final notif in preview)
                          _GlassNotificationTile(notif: notif),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TeacherNotificationsPage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_rounded,
                            size: 18,
                          ),
                          label: const Text('ดูการแจ้งเตือนทั้งหมด'),
                          style: TextButton.styleFrom(
                            foregroundColor: TeacherPalette.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _GlassNotificationTile extends StatelessWidget {
  const _GlassNotificationTile({required this.notif});

  final NotificationItemModel notif;

  Color get _categoryColor => switch (notif.category) {
    'emergency' => TeacherPalette.red,
    'sensor' => TeacherPalette.orange,
    'grading' => TeacherPalette.primary,
    'camera' => TeacherPalette.skyDeep,
    _ => TeacherPalette.muted,
  };

  IconData get _categoryIcon => switch (notif.category) {
    'emergency' => Icons.warning_amber_rounded,
    'sensor' => Icons.sensors_rounded,
    'grading' => Icons.assignment_turned_in_rounded,
    'camera' => Icons.videocam_rounded,
    _ => Icons.notifications_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon, size: 18, color: _categoryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: notif.isRead
                        ? FontWeight.w700
                        : FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notif.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notif.timestamp,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!notif.isRead)
            Container(
              margin: const EdgeInsets.only(top: 4, left: 4),
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: TeacherPalette.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// ป็อปอัพค้นหาวิชาที่สอนและคาบเรียนวันนี้ — ทำสไตล์กระจกฝ้า (glassmorphic)
/// แบบเดียวกับป็อปอัพค้นหาของฝั่งนักเรียน (`_showSearchPopup` ใน
/// student_course_catalog_page.dart) เพื่อให้หน้าตาเป็นชุดเดียวกันทั้งแอป
/// แม้ข้อมูลที่ค้นหาจะเป็นคนละชุด (วิชา+ตารางสอนของครู แทนรายวิชาของ
/// นักเรียน) — ใช้ StatefulBuilder ภายในเพื่อให้ผลลัพธ์/ชิปอัปเดตสดขณะพิมพ์
/// โดยไม่ต้องผูก state เข้ากับหน้าเดิม
Future<void> _showTeacherSearchDialog(BuildContext context) async {
  final searchController = TextEditingController();
  var query = '';

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final q = query.trim().toLowerCase();
          final classes = TeacherMock.classes
              .where(
                (c) =>
                    q.isEmpty ||
                    c.title.toLowerCase().contains(q) ||
                    c.code.toLowerCase().contains(q) ||
                    c.room.toLowerCase().contains(q),
              )
              .toList();
          final lessons = TeacherMock.lessons
              .where(
                (l) =>
                    q.isEmpty ||
                    l.title.toLowerCase().contains(q) ||
                    l.room.toLowerCase().contains(q),
              )
              .toList();
          final hasResults = classes.isNotEmpty || lessons.isNotEmpty;

          return Dialog(
            alignment: Alignment.topCenter,
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 52,
              bottom: 24,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 560,
                      maxHeight: 560,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'ค้นหาวิชาและตารางสอน 🔍',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                icon: const Icon(Icons.close_rounded),
                                color: const Color(0xFF334155),
                                tooltip: 'ปิด',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.0,
                                ),
                              ),
                              child: TextField(
                                controller: searchController,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                onChanged: (value) =>
                                    setDialogState(() => query = value),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9),
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  border: InputBorder.none,
                                  hintText:
                                      'ค้นหาวิชา รหัสวิชา หรือห้องเรียน...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(
                                      left: 14,
                                      right: 8,
                                    ),
                                    child: Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 18,
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  suffixIcon: query.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                            color: Color(0xFF64748B),
                                          ),
                                          onPressed: () => setDialogState(() {
                                            query = '';
                                            searchController.clear();
                                          }),
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _teacherSearchSuggestions.map((s) {
                              final selected = s.query.isEmpty
                                  ? query.isEmpty
                                  : query.toLowerCase() ==
                                        s.query.toLowerCase();
                              return InkWell(
                                onTap: () => setDialogState(() {
                                  query = s.query;
                                  searchController.text = s.query;
                                  searchController.selection =
                                      TextSelection.collapsed(
                                        offset: s.query.length,
                                      );
                                }),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF93C5FD)
                                          : const Color(0xFFD7E1EA),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        s.icon,
                                        size: 14,
                                        color: selected
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF475569),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        s.label,
                                        style: TextStyle(
                                          color: selected
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF334155),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: !hasResults
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Text(
                                        'ไม่พบผลลัพธ์',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (classes.isNotEmpty) ...[
                                          const _TeacherSearchSectionLabel(
                                            'รายวิชา',
                                          ),
                                          for (final item in classes)
                                            ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: Icon(
                                                item.icon,
                                                color: item.statusColor,
                                              ),
                                              title: Text(item.title),
                                              subtitle: Text(
                                                '${item.code} · ${item.room}',
                                              ),
                                              onTap: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                                _openClassDetail(context, item);
                                              },
                                            ),
                                        ],
                                        if (lessons.isNotEmpty) ...[
                                          const _TeacherSearchSectionLabel(
                                            'ตารางสอนวันนี้',
                                          ),
                                          for (final lesson in lessons)
                                            ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: Icon(
                                                lesson.icon,
                                                color: lesson.color,
                                              ),
                                              title: Text(lesson.title),
                                              subtitle: Text(
                                                '${lesson.time} · ${lesson.room}',
                                              ),
                                              onTap: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                                _openLessonDetail(
                                                  context,
                                                  lesson,
                                                );
                                              },
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('ปิด'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  searchController.dispose();
}

class _TeacherSearchSectionLabel extends StatelessWidget {
  const _TeacherSearchSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: TeacherPalette.muted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
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
    case 'ตารางสอน':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherClassSchedulePage()),
      );
    case 'คลังข้อสอบ':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherQuestionBankPage()),
      );
    case 'คลังความรู้':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherKnowledgeLibraryPage()),
      );
    case 'นักเรียน':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherStudentsPage()),
      );
    case 'เช็คชื่อ':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherAttendancePage()),
      );
    case 'อนุมัติใบลา':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherLeaveApprovalPage()),
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
    case 'ยืนยัน G-Score':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherGScoreConfirmPage()),
      );
    case 'ช่วยเหลือนักเรียน':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherStudentSupportPage()),
      );
    case 'อนุมัติผูกบัญชี':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TeacherParentBindingApprovalPage(),
        ),
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
