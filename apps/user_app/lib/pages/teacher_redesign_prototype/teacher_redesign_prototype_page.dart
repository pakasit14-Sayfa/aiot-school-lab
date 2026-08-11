// PROTOTYPE ONLY: Teacher redesigned workspace.
// Three variants of the teacher dashboard, switchable in-app on
// /prototype/teacher-redesign?variant=A, B, or C.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'teacher_aiot_lab_page.dart';
import 'teacher_courses_page.dart';
import 'teacher_grades_page.dart';
import 'teacher_grading_page.dart';
import 'teacher_incident_inbox_page.dart';
import 'teacher_profile_page.dart';
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
          _TeacherSummaryStrip(),
          SizedBox(height: 16),
          _DashboardChartsRow(),
          SizedBox(height: 16),
          _MiniCalendarCard(),
          SizedBox(height: 16),
          _ClassesCarousel(),
          SizedBox(height: 16),
          _ScheduleCard(),
          SizedBox(height: 16),
          _ReviewQueueCard(),
          SizedBox(height: 16),
          _StudentsWatchCard(),
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

  @override
  Widget build(BuildContext context) {
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
            : const Color(0xFFF1EEF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.icon,
        color: active ? Colors.white : TeacherPalette.primary,
        size: 20,
      ),
    );

    final content = Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
      decoration: BoxDecoration(
        color: active ? TeacherPalette.primary : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? TeacherPalette.primary : const Color(0xFFE5D5F2),
          width: 1.2,
        ),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x29542E85),
                  blurRadius: 12,
                  offset: Offset(0, 4),
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
                  color: active ? Colors.white : const Color(0xFF0F172A),
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
        const _TeacherHero(),
        const SizedBox(height: 18),
        const _TeacherSummaryStrip(),
        const SizedBox(height: 20),
        const _DashboardChartsRow(),
        const SizedBox(height: 20),
        const _ClassesCarousel(),
        const SizedBox(height: 20),
        const _ScheduleCard(),
        if (includeRightPanelCardsInline) ...[
          const SizedBox(height: 20),
          const _MiniCalendarCard(),
          const SizedBox(height: 18),
          const _TodayFocusCard(),
          const SizedBox(height: 18),
          const _ReviewQueueCard(),
          const SizedBox(height: 18),
          const _StudentsWatchCard(),
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
          onTap: () => _showComingSoon(context, 'การแจ้งเตือน'),
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
        _MiniCalendarCard(),
        SizedBox(height: 18),
        _TodayFocusCard(),
        SizedBox(height: 18),
        _ReviewQueueCard(),
        SizedBox(height: 18),
        _StudentsWatchCard(),
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1EEF9),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherProfilePage()),
          );
        },
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
              const Text(
                'ครูสมชาย',
                style: TextStyle(
                  color: TeacherPalette.primary,
                  fontWeight: FontWeight.w900,
                ),
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
    _MenuItem('AIoT', Icons.sensors_rounded),
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
    case 'AIoT':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherAiotLabPage()),
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
