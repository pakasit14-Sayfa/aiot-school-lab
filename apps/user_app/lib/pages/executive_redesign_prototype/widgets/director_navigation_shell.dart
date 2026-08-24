import 'package:flutter/material.dart';

import '../pages/director_academic_calendar_page.dart';
import '../pages/director_classrooms_page.dart';
import '../pages/director_cctv_page.dart';
import '../pages/director_emergency_page.dart';
import '../pages/director_environment_page.dart';
import '../pages/director_learning_page.dart' as learning;
import '../pages/director_meetings_page.dart';
import '../pages/director_notifications_page.dart';
import '../pages/director_overview_page.dart' as overview;
import '../pages/director_reports_page.dart';
import '../pages/director_scan_page.dart';
import '../pages/director_settings_page.dart';
import '../pages/director_teachers_page.dart';
import '../theme/app_palette.dart';
import 'director_bottom_navigation.dart';

class DirectorNavigationShell extends StatefulWidget {
  const DirectorNavigationShell({super.key});

  @override
  State<DirectorNavigationShell> createState() => _DirectorNavigationShellState();
}

class _DirectorNavigationShellState extends State<DirectorNavigationShell> {
  int selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ทางลัดสำหรับแถบนำทางด้านล่าง (มือถือ) — ชี้ไปยัง index ของ menuItems
  final List<_BottomShortcut> bottomShortcuts = const [
    _BottomShortcut('ภาพรวม', Icons.home_rounded, 0),
    _BottomShortcut('ฉุกเฉิน', Icons.warning_amber_rounded, 1),
    _BottomShortcut('นักเรียน', Icons.school_rounded, 2),
    _BottomShortcut('แจ้งเตือน', Icons.notifications_active_rounded, 10),
  ];

  final List<_DirectorMenuItem> menuItems = const [
    _DirectorMenuItem('ภาพรวม', Icons.home_rounded),
    _DirectorMenuItem('เหตุฉุกเฉิน', Icons.warning_amber_rounded),
    _DirectorMenuItem('ภาพรวมนักเรียน', Icons.school_rounded),
    _DirectorMenuItem('ครูและบุคลากร', Icons.co_present_rounded),
    _DirectorMenuItem('ห้องเรียนและรายวิชา', Icons.meeting_room_rounded),
    _DirectorMenuItem('ประชุม / ขอพบ', Icons.calendar_month_rounded),
    _DirectorMenuItem('ปฏิทินวิชาการ', Icons.event_note_rounded),
    _DirectorMenuItem('กล้องวงจรปิด', Icons.videocam_rounded),
    _DirectorMenuItem('สิ่งแวดล้อม / ทรัพยากร', Icons.eco_rounded),
    _DirectorMenuItem('รายงาน', Icons.bar_chart_rounded),
    _DirectorMenuItem('การแจ้งเตือน', Icons.notifications_active_rounded),
    _DirectorMenuItem('ตั้งค่า', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1050;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.pageBg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppPalette.pageBg,
              child: SafeArea(child: _sidebar(closeOnTap: true)),
            ),
      bottomNavigationBar: isDesktop ? null : _bottomBar(),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 280,
                child: _sidebar(),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 18 : 12,
                  12,
                  isDesktop ? 18 : 12,
                  12,
                ),
                child: Column(
                  children: [
                    _topBar(isDesktop),
                    const SizedBox(height: 12),
                    Expanded(child: _currentPage()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentPage() {
    switch (selectedIndex) {
      case 0:
        return overview.DirectorOverviewPage(
          onNavigate: (index) => setState(() => selectedIndex = index),
        );
      case 1:
        return const DirectorEmergencyPage();
      case 2:
        return const learning.DirectorLearningPage();
      case 3:
        return const DirectorTeachersPage();
      case 4:
        return const DirectorClassroomsPage();
      case 5:
        return const DirectorMeetingsPage();
      case 6:
        return const DirectorAcademicCalendarPage();
      case 7:
        return const DirectorCctvPage();
      case 8:
        return const DirectorEnvironmentPage();
      case 9:
        return const DirectorReportsPage();
      case 10:
        return const DirectorNotificationsPage();
      case 11:
        return const DirectorSettingsPage();
      default:
        return overview.DirectorOverviewPage(
          onNavigate: (index) => setState(() => selectedIndex = index),
        );
    }
  }

  Widget _bottomBar() {
    final items = [
      for (final shortcut in bottomShortcuts)
        DirectorBottomNavItem(
          shortcut.title,
          shortcut.icon,
          badge: shortcut.menuIndex == 1
              ? 1
              : shortcut.menuIndex == 10
                  ? 3
                  : null,
        ),
    ];

    final localSelected = bottomShortcuts.indexWhere(
      (shortcut) => shortcut.menuIndex == selectedIndex,
    );

    return SafeArea(
      top: false,
      child: DirectorBottomNavigation(
        items: items,
        selectedIndex: localSelected,
        onTap: (index) =>
            setState(() => selectedIndex = bottomShortcuts[index].menuIndex),
        centerItem: const DirectorBottomNavItem(
          'สแกน',
          Icons.qr_code_scanner_rounded,
        ),
        onCenterTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const DirectorScanPage(),
          ),
        ),
      ),
    );
  }

  Widget _topBar(bool isDesktop) {
    return Row(
      children: [
        if (!isDesktop)
          Builder(
            builder: (context) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPalette.border),
                ),
                child: const Icon(Icons.menu_rounded),
              ),
            ),
          ),
        if (!isDesktop) const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: isDesktop ? 4 : 0),
            child: Text(
              menuItems[selectedIndex].title,
            overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        _topIcon(Icons.search_rounded),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _topIcon(Icons.notifications_none_rounded),
            Positioned(
              right: 8,
              top: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppPalette.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        if (isDesktop) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.border),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppPalette.primaryPink,
                  child: Icon(Icons.person_rounded, size: 15, color: Colors.white),
                ),
                SizedBox(width: 8),
                Text('Director', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _topIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _sidebar({bool closeOnTap = false}) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppPalette.sidebarSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppPalette.tint(Colors.black, 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.primaryPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AIoT Smart Lab', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text(
                      'ศูนย์ควบคุมสำหรับผู้อำนวยการ',
                      style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppPalette.border),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final selected = selectedIndex == index;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() => selectedIndex = index);
                    if (closeOnTap && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppPalette.primaryPinkSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected ? AppPalette.primaryPink : AppPalette.sidebarIconBg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: selected ? Colors.white : AppPalette.sidebarIcon,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                              color: selected ? AppPalette.primaryPinkDark : AppPalette.textDark,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppPalette.primaryPink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.primaryPinkSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppPalette.primaryPink,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผู้อำนวยการโรงเรียน', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Text('Director', style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.more_vert_rounded, color: AppPalette.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectorMenuItem {
  final String title;
  final IconData icon;
  const _DirectorMenuItem(this.title, this.icon);
}

class _BottomShortcut {
  final String title;
  final IconData icon;
  final int menuIndex;
  const _BottomShortcut(this.title, this.icon, this.menuIndex);
}
