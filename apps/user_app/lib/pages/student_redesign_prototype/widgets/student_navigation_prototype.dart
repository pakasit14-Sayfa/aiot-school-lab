import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../login_page.dart';
import '../../notifications_page.dart';
import 'student_redesign_palette.dart';
import 'student_search_popup.dart';
import 'student_variant_school_home.dart';
import 'student_assignments_page.dart';
import 'student_course_catalog_minimal_page.dart';
import 'student_profile_page.dart';
import 'student_score_page.dart';
import 'student_calendar_page.dart';
import 'student_qr_login_page.dart';
import '../student_safety_page.dart';

class StudentNavigationPrototype extends StatefulWidget {
  const StudentNavigationPrototype({super.key, this.loadNotifications});

  /// Injectable seam so widget tests can control the unread badge and the
  /// notification-preview modal without initializing a real Supabase
  /// client. Defaults to the real service call used in production.
  final Future<List<AppNotification>> Function()? loadNotifications;

  @override
  State<StudentNavigationPrototype> createState() =>
      _StudentNavigationPrototypeState();
}

class _StudentNavigationPrototypeState
    extends State<StudentNavigationPrototype> {
  int _currentIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey =
      GlobalKey<ScaffoldState>();

  Future<void> _signOut(BuildContext context) async {
    Navigator.pop(context);
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // "คะแนน" ไม่ได้อยู่เป็นแท็บหลัก เพราะเกรดออกเทอมละครั้งเท่านั้น
  // เข้าถึงผ่านปุ่มในหน้าโปรไฟล์แทน (ดู _openScorePage)
  final List<String> _titles = [
    'หน้าแรก',
    'วิชาเรียนและบทเรียน',
    'ใบงานและการบ้าน',
    'ปฏิทิน / ตารางเรียน',
    'ข้อมูลส่วนตัว',
  ];

  void _openInPlaceSearchDialog() {
    _showGlobalGlassSearchDialog(context);
  }

  void _openScorePage() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const StudentScorePage()));
  }

  Future<void> _showGlobalGlassSearchDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.only(
            left: 14,
            right: 14,
            top: 44,
            bottom: 20,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: StudentSearchPopup(
                      onClose: () => Navigator.of(dialogContext).pop(),
                      onOpenTab: (index) =>
                          setState(() => _currentIndex = index),
                      onOpenScore: _openScorePage,
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

  List<Widget> get _pages => [
    StudentVariantSchoolHome(onViewScore: _openScorePage),
    const StudentCourseCatalogMinimalPage(showAppBar: false),
    const StudentAssignmentsPage(),
    const StudentCalendarPage(),
    StudentProfilePage(
      onViewScore: _openScorePage,
      onViewAssignments: () => setState(() => _currentIndex = 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        if (isDesktop) {
          return _buildDesktopShell(context);
        }

        return Scaffold(
          key: _mobileScaffoldKey,
          backgroundColor: Colors.white,
          drawer: _buildMobileDrawer(context),
          // Apple HIG: the status bar belongs to the system — the app bar
          // sits below the full top inset, 44pt tall like a UINavigationBar.
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: true,
            // iOS navigation-bar height (44) instead of Material's 56 —
            // the owner wanted the bar tucked up under the status bar.
            toolbarHeight: 44,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: SchoolPalette.ink,
                size: 24,
              ),
              tooltip: 'เมนู',
              onPressed: () => _mobileScaffoldKey.currentState?.openDrawer(),
            ),
            title: Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: SchoolPalette.ink,
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: SchoolPalette.ink,
                  size: 24,
                ),
                tooltip: 'ค้นหารายวิชาและบทเรียน',
                onPressed: _openInPlaceSearchDialog,
              ),
              StudentNotificationBell(
                loadNotifications: widget.loadNotifications,
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9), // Soft Apple Light Slate Grey
                    ),
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    final displayName = currentUserModel?.name ?? '';
    // "ข้อมูลส่วนตัว" ไม่อยู่ในกลุ่มนี้แล้ว — ย้ายไปกลุ่มบัญชี/ตั้งค่า
    // ด้านล่างเส้นคั่นแทน เพราะเป็นเรื่องจัดการบัญชีตัวเอง คนละหมวดกับ
    // เนื้อหาที่จะไปดู (หน้าแรก/บทเรียน/ใบงาน/ปฏิทิน)
    final navItems = [
      (icon: Icons.home_rounded, label: 'หน้าแรก', index: 0),
      (icon: Icons.menu_book_rounded, label: 'วิชาเรียนและบทเรียน', index: 1),
      (icon: Icons.assignment_rounded, label: 'ใบงานและการบ้าน', index: 2),
      (
        icon: Icons.calendar_month_rounded,
        label: 'ปฏิทิน / ตารางเรียน',
        index: 3,
      ),
    ];

    Widget buildTile({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool selected = false,
    }) {
      return ListTile(
        leading: Icon(
          icon,
          color: selected ? SchoolPalette.deepGreen : SchoolPalette.muted,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? SchoolPalette.deepGreen : SchoolPalette.ink,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        selected: selected,
        selectedTileColor: SchoolPalette.softGreenBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      );
    }

    // The gradient header paints up under the iPhone status bar; only its
    // content is inset. With the SafeArea outside the header a white strip
    // sat above the green on every notched phone.
    final topInset = MediaQuery.paddingOf(context).top;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 20 + topInset, 20, 18),
              decoration: const BoxDecoration(
                gradient: SchoolPalette.primaryGradient,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        StudentGradeLevelText(
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                children: [
                  for (final item in navItems)
                    buildTile(
                      icon: item.icon,
                      label: item.label,
                      selected: _currentIndex == item.index,
                      onTap: () {
                        setState(() => _currentIndex = item.index);
                        Navigator.pop(context);
                      },
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  buildTile(
                    icon: Icons.shield_rounded,
                    label: 'ความปลอดภัยห้องเรียน',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentSafetyPage(),
                        ),
                      );
                    },
                  ),
                  buildTile(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'เข้าสู่ระบบด้วย QR',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const StudentQrLoginPage(startInScanMode: true),
                        ),
                      );
                    },
                  ),
                  // "ช่วยเหลือ" and "ตั้งค่า" drawer tiles used to raise a
                  // "ฟีเจอร์นี้ยังไม่พร้อมใช้งาน" snackbar; there is no help
                  // content and settings live on the profile tab. Removed.
                  buildTile(
                    icon: Icons.logout_rounded,
                    label: 'ออกจากระบบ',
                    onTap: () => _signOut(context),
                  ),
                ],
              ),
            ),
            // "ข้อมูลส่วนตัว" ตรึงติดขอบล่างสุดของ Drawer จริงๆ (นอก
            // ListView ที่เลื่อนได้) เหมือนตำแหน่ง "โปรไฟล์" ใน sidebar
            // เดสก์ท็อปที่ดันไปท้ายสุดด้วย Spacer() — ไม่ใช่แค่รายการ
            // สุดท้ายในลิสต์ที่เลื่อนตามเนื้อหา
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  buildTile(
                    icon: Icons.person_rounded,
                    label: 'ข้อมูลส่วนตัว',
                    selected: _currentIndex == 4,
                    onTap: () {
                      setState(() => _currentIndex = 4);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopShell(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            _buildDesktopSidebar(context),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(context),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _titles[_currentIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SchoolPalette.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _buildDesktopAction(
            icon: Icons.search_rounded,
            onTap: _openInPlaceSearchDialog,
          ),
          const SizedBox(width: 10),
          StudentNotificationBell(
            loadNotifications: widget.loadNotifications,
            decorated: true,
          ),
          const SizedBox(width: 10),
          _buildDesktopAction(
            icon: Icons.qr_code_scanner_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentQrLoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAction({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(icon, color: SchoolPalette.ink, size: 22),
            ),
          ),
        ),
        if (badge)
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    // "โปรไฟล์" แยกไว้ท้ายสุดของ sidebar (ดูตอนสร้าง profileNavItem
    // ด้านล่าง) ส่วนนี้เหลือแค่เมนูหลักที่ใช้งานบ่อย
    final navItems = <_NavItem>[
      _NavItem(icon: Icons.home_rounded, label: 'หน้าแรก'),
      _NavItem(icon: Icons.menu_book_rounded, label: 'รายวิชา'),
      _NavItem(icon: Icons.assignment_rounded, label: 'ใบงาน'),
      _NavItem(icon: Icons.calendar_month_rounded, label: 'ปฏิทิน'),
    ];
    const profileIndex = 4;
    const profileNavItem = _NavItem(
      icon: Icons.person_rounded,
      label: 'โปรไฟล์',
    );

    final isCollapsed = _isSidebarCollapsed;
    final sidebarWidth = isCollapsed ? 104.0 : 292.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: sidebarWidth,
      padding: EdgeInsets.fromLTRB(
        isCollapsed ? 12 : 18,
        18,
        isCollapsed ? 12 : 18,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.86),
            SchoolPalette.softGreenBg.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(
          right: BorderSide(color: Color(0xCCE2E8F0), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 28,
            offset: Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              if (!isCollapsed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 16,
                      color: SchoolPalette.deepGreen.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'เมนู',
                      style: TextStyle(
                        color: SchoolPalette.muted.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              Material(
                color: Colors.white.withValues(alpha: 0.78),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(
                    () => _isSidebarCollapsed = !_isSidebarCollapsed,
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: SchoolPalette.glassBorder),
                    ),
                    child: Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 20,
                      color: SchoolPalette.deepGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSidebarClassCard(isCollapsed: isCollapsed),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: navItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = navItems[index];
              final isSelected = _currentIndex == index;
              return _DesktopNavTile(
                icon: item.icon,
                label: item.label,
                isSelected: isSelected,
                isCollapsed: isCollapsed,
                onTap: () => setState(() => _currentIndex = index),
              );
            },
          ),
          const SizedBox(height: 8),
          _DesktopNavTile(
            icon: Icons.shield_rounded,
            label: 'ความปลอดภัยห้องเรียน',
            isSelected: false,
            isCollapsed: isCollapsed,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentSafetyPage()),
              );
            },
          ),
          const Spacer(),
          _DesktopNavTile(
            icon: profileNavItem.icon,
            label: profileNavItem.label,
            isSelected: _currentIndex == profileIndex,
            isCollapsed: isCollapsed,
            onTap: () => setState(() => _currentIndex = profileIndex),
          ),
          const SizedBox(height: 12),
          _buildSidebarFooter(isCollapsed: isCollapsed),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter({required bool isCollapsed}) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: Icon(
            Icons.eco_rounded,
            size: 18,
            color: SchoolPalette.deepGreen.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          const Divider(height: 1, color: SchoolPalette.glassBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                size: 14,
                color: SchoolPalette.deepGreen.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'AIoT Smart School · v1.0',
                style: TextStyle(
                  color: SchoolPalette.muted.withValues(alpha: 0.8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarClassCard({required bool isCollapsed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCollapsed ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: SchoolPalette.softGreenBg,
                child: Icon(
                  Icons.school_rounded,
                  color: SchoolPalette.deepGreen,
                  size: 18,
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ห้องเรียนของฉัน',
                        style: TextStyle(
                          color: SchoolPalette.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const StudentGradeLevelText(
                        fallback: 'ยังไม่มีข้อมูลชั้นเรียน',
                        style: TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 📱 Bottom Navigation Bar สไตล์พรีเมียมมินิมอล
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: SchoolPalette.green,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'รายวิชา',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'ใบงาน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'ปฏิทิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

/// The real grade-level label shown in both the mobile drawer header and
/// the desktop sidebar's "ห้องเรียนของฉัน" card. Used to be two separate
/// hardcoded/duplicated implementations — the mobile drawer read a real
/// `_gradeLevel` loaded on the nav shell state, while the desktop sidebar
/// had a fully hardcoded 'ม.5/2 · ภาคเรียน 1/2569' string that never used
/// it. Extracted into its own widget (same reasoning as
/// [StudentNotificationBell]) so both call sites share one real-data path
/// and it can be tested in isolation without mounting every other tab.
class StudentGradeLevelText extends StatefulWidget {
  const StudentGradeLevelText({
    super.key,
    required this.style,
    this.fallback,
    this.listMyCourses,
  });

  final TextStyle style;

  /// Shown when there's no real grade level to display. If null, the
  /// widget renders nothing in that case (matches the mobile drawer's
  /// original behavior of just omitting the line).
  final String? fallback;

  /// Injectable seam so widget tests can control the grade level without
  /// initializing a real Supabase client. Defaults to the real service
  /// call used in production.
  final Future<List<CourseSummary>> Function()? listMyCourses;

  @override
  State<StudentGradeLevelText> createState() => _StudentGradeLevelTextState();
}

class _StudentGradeLevelTextState extends State<StudentGradeLevelText> {
  String? _gradeLevel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loadCourses = widget.listMyCourses ?? CourseService.listMyCourses;
      final courses = await loadCourses();
      if (!mounted) return;
      setState(
        () => _gradeLevel = courses.isEmpty ? null : courses.first.gradeLevel,
      );
    } catch (_) {
      // ไม่ต้องโชว์ error แค่ป้ายชั้นเรียนไม่ใช่ข้อมูลหลักของหน้า
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gradeLevel == null) {
      if (widget.fallback == null) return const SizedBox.shrink();
      return Text(
        widget.fallback!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }
    return Text(
      'ชั้น $_gradeLevel',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}

/// The notification bell shown in both the mobile app bar and the desktop
/// top bar: unread-badge dot, tap-to-preview modal, and the canonical
/// refresh after returning from the real [NotificationsPage]. Extracted
/// into its own widget (instead of living inline on the nav shell state)
/// so it can be tested in isolation without mounting every other tab.
class StudentNotificationBell extends StatefulWidget {
  const StudentNotificationBell({
    super.key,
    this.loadNotifications,
    this.decorated = false,
  });

  /// Injectable seam so widget tests can control the unread badge and the
  /// notification-preview modal without initializing a real Supabase
  /// client. Defaults to the real service call used in production.
  final Future<List<AppNotification>> Function()? loadNotifications;

  /// True for the desktop top bar's circular chrome (matches the other
  /// desktop action icons); false for the mobile app bar's bare icon.
  final bool decorated;

  @override
  State<StudentNotificationBell> createState() =>
      _StudentNotificationBellState();
}

class _StudentNotificationBellState extends State<StudentNotificationBell> {
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadStatus();
  }

  Future<void> _loadUnreadStatus() async {
    try {
      final notifications =
          await (widget.loadNotifications ??
              NotificationService.listMyNotifications)();
      if (!mounted) return;
      setState(() => _hasUnread = notifications.any((n) => n.isUnread));
    } catch (_) {
      // ไม่ต้องโชว์ error แค่จุดแดงเล็กๆ ไม่ใช่ข้อมูลหลักของหน้า
    }
  }

  static IconData _iconForNotification(String type) {
    switch (type) {
      case 'incident':
      case 'device_alert':
        return Icons.warning_amber_rounded;
      case 'device_command':
        return Icons.check_circle_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม.';
    return '${diff.inDays} วัน';
  }

  Widget _buildGlassNotificationTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF3), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: iconBg.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.only(
            left: 14,
            right: 14,
            top: 44,
            bottom: 20,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0x1F0F172A),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'การแจ้งเตือน',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ),
                            Material(
                              color: const Color(0xFFF1F5F9),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.of(dialogContext).pop(),
                                child: const SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<AppNotification>>(
                          future:
                              (widget.loadNotifications ??
                              NotificationService.listMyNotifications)(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final items = snapshot.data!.take(3).toList();
                            if (items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'ยังไม่มีการแจ้งเตือน',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12.5,
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: [
                                for (var i = 0; i < items.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  _buildGlassNotificationTile(
                                    icon: _iconForNotification(items[i].type),
                                    iconBg: const Color(0xFF2F8F5B),
                                    title: items[i].title,
                                    subtitle: items[i].body ?? '',
                                    time: _timeAgo(items[i].createdAt),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsPage(),
                                ),
                              );
                              if (mounted) _loadUnreadStatus();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: const Text(
                              'ดูการแจ้งเตือนทั้งหมด',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: Color(0xFF0F172A),
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

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.notifications_none_rounded,
      color: SchoolPalette.ink,
      size: widget.decorated ? 22 : 24,
    );
    final bellButton = widget.decorated
        ? Material(
            color: const Color(0xFFF8FAFC),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openModal,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: icon,
              ),
            ),
          )
        : IconButton(icon: icon, onPressed: _openModal);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        bellButton,
        // White ring makes the dot read clearly as "attached to the bell"
        // instead of a stray mark floating beside it.
        if (_hasUnread)
          Positioned(
            right: widget.decorated ? 1 : 8,
            top: widget.decorated ? 1 : 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _DesktopNavTile extends StatelessWidget {
  const _DesktopNavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = SchoolPalette.softGreenBg;
    final textColor = isSelected ? SchoolPalette.deepGreen : SchoolPalette.ink;
    final iconColor = isSelected
        ? SchoolPalette.deepGreen
        : const Color(0xFF64748B);

    final tile = Material(
      color: isSelected
          ? selectedColor.withValues(alpha: 0.78)
          : Colors.white.withValues(alpha: 0.46),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: isCollapsed ? 58 : 62,
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 14,
            vertical: 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFBFE0D2)
                  : Colors.white.withValues(alpha: 0.78),
              width: 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x14165042),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 22),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SchoolPalette.deepGreen,
                    size: 20,
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: label, child: tile);
    }

    return tile;
  }
}
