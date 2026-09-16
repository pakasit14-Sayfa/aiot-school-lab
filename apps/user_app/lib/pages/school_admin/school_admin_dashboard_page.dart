import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

import 'theme/school_admin_palette.dart';
import 'school_resources_page.dart';
import 'school_students_page.dart';
import 'school_teachers_page.dart';
import 'school_import_page.dart';
import 'school_permissions_page.dart';
import 'school_buildings_page.dart';
import 'school_devices_page.dart';
import 'school_alerts_page.dart';
import 'school_reports_page.dart';
import 'school_settings_page.dart';
import 'school_scan_page.dart';
import 'school_admin_profile_page.dart';
import 'school_admin_energy_page.dart';
import 'school_admin_cctv_page.dart';
import 'school_admin_device_schedule_page.dart';
import 'school_admin_esg_page.dart';
import 'school_admin_device_control_page.dart';
import 'school_admin_incident_inbox_page.dart';
import 'school_learning_tracks_page.dart';
import 'school_admin_attendance_settings_page.dart';
import 'school_admin_leave_approval_page.dart';
import 'school_admin_report_requirements_page.dart';

class SchoolAdminDashboardPage extends StatefulWidget {
  const SchoolAdminDashboardPage({
    super.key,
    this.loadEnergy,
    this.loadWater,
    this.loadSensor,
    this.loadMetricsWithData,
    this.loadSummary,
  });

  /// Read seams for the home page's resource card, threaded down to
  /// `_HomeResourceOverview`. Production passes nothing and the real
  /// services are used; widget tests supply these to drive loading / data /
  /// empty / error deterministically without a live Supabase client.
  final Future<EnergyUsageSummary?> Function()? loadEnergy;
  final Future<WaterUsageSummary?> Function()? loadWater;
  final Future<SensorModel?> Function()? loadSensor;
  final Future<Set<String>> Function()? loadMetricsWithData;

  /// Feeds the real school name into the sidebar/drawer scope card. Kept
  /// separate from `_HomeSummaryGrid`'s own summary load (same RPC, but
  /// that widget only mounts on the home tab — the sidebar/drawer are
  /// always on screen regardless of which menu item is selected).
  final Future<SchoolAdminDashboardSummary> Function()? loadSummary;

  @override
  State<SchoolAdminDashboardPage> createState() =>
      _SchoolAdminDashboardPageState();
}

class _SchoolAdminDashboardPageState extends State<SchoolAdminDashboardPage> {
  int _selectedIndex = 0;
  bool _profileOpen = false;

  // ชื่อโรงเรียนจริงสำหรับการ์ดใน sidebar/drawer — เดิม _SchoolScopeCard
  // hardcode 'โรงเรียนเทศบาล ๑ (สังกัด สถ.)' ตายตัวให้ทุกโรงเรียนเห็นเหมือนกัน
  String? _schoolName;
  bool _schoolNameLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolName();
  }

  Future<void> _loadSchoolName() async {
    try {
      final summary = await (widget.loadSummary?.call() ??
          SchoolAdminPlatformService().fetchDashboardSummary());
      if (!mounted) return;
      setState(() {
        _schoolName = summary.schoolName;
        _schoolNameLoading = false;
      });
    } catch (e) {
      debugPrint('SchoolAdminDashboardPage fetchDashboardSummary failed: $e');
      // เงียบพอ — การ์ดจะโชว์ 'ยังไม่มีข้อมูล' แทนการลองซ้ำเงียบ ๆ ไม่รู้จบ
      if (!mounted) return;
      setState(() => _schoolNameLoading = false);
    }
  }

  static const List<_MenuItemData> _menuItems = [
    _MenuItemData('หน้าหลัก', Icons.dashboard_rounded),
    _MenuItemData('จัดการนักเรียน', Icons.school_rounded),
    _MenuItemData('ครูและบุคลากร', Icons.groups_rounded),
    _MenuItemData('นำเข้าข้อมูล', Icons.upload_file_rounded),
    _MenuItemData('กำหนดสิทธิ์', Icons.admin_panel_settings_rounded),
    _MenuItemData('อาคารและห้อง', Icons.apartment_rounded),
    _MenuItemData('อุปกรณ์', Icons.memory_rounded),
    _MenuItemData('การใช้ทรัพยากร', Icons.energy_savings_leaf_rounded),
    _MenuItemData('สแกนคิวอาร์โค้ด', Icons.qr_code_scanner_rounded),
    _MenuItemData('การแจ้งเตือน', Icons.notifications_active_rounded),
    _MenuItemData('รายงาน', Icons.bar_chart_rounded),
    _MenuItemData('ตั้งค่าโรงเรียน', Icons.settings_rounded),
    _MenuItemData('จัดการผู้ใช้', Icons.people_alt_rounded),
    _MenuItemData('Consent Policy', Icons.policy_rounded),
    _MenuItemData('พลังงานทั้งโรงเรียน', Icons.bolt_rounded),
    _MenuItemData('กล้อง CCTV', Icons.videocam_rounded),
    _MenuItemData('ตั้งเวลาอุปกรณ์', Icons.schedule_rounded),
    _MenuItemData('รายงาน ESG', Icons.eco_rounded),
    _MenuItemData('ควบคุมไฟและน้ำ', Icons.lightbulb_rounded),
    _MenuItemData('กล่องแจ้งเหตุการณ์', Icons.inbox_rounded),
    // ตำแหน่งในลิสต์นี้ = เลขหน้าใน _buildCurrentPage ตรง ๆ (sidebar ส่ง
    // index ของแถวที่กด) — รายการ "สายการเรียน" (หน้า 20) เคยหายไปจากลิสต์
    // ทำให้ 3 แถวท้ายเลื่อนขึ้นคนละหนึ่ง: กด "ตั้งเวลาปฏิบัติงาน" ได้หน้า
    // สายการเรียน · "อนุมัติการลา" ได้หน้าตั้งเวลา · "รายงานที่ต้องส่ง" ได้
    // หน้าอนุมัติการลา และหน้ารายงานที่ต้องส่ง (23) เปิดจาก sidebar ไม่ได้เลย
    // เทสต์ school_admin_dashboard_page_test ล็อกคู่ป้าย↔หน้าไว้แล้ว
    _MenuItemData('สายการเรียน', Icons.alt_route_rounded),
    _MenuItemData('ตั้งเวลาปฏิบัติงาน', Icons.access_time_rounded),
    _MenuItemData('อนุมัติการลา', Icons.fact_check_rounded),
    _MenuItemData('รายการรายงานที่ต้องส่ง', Icons.assignment_turned_in_rounded),
  ];

  void _openPage(int index) {
    if (index < 0 || index >= _menuItems.length) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _profileOpen = false;
    });
  }

  void _openProfile() {
    setState(() {
      _profileOpen = true;
    });
  }

  String get _currentTitle {
    if (_profileOpen) {
      return 'โปรไฟล์ผู้ใช้งาน';
    }

    return _menuItems[_selectedIndex].title;
  }

  // Design-system-unification (2026-08-26, ticket 03): every School
  // Admin page below is wrapped in the shared structural theme, same
  // mechanism ticket 02 verified on the home page — a page's own
  // per-field/per-button style overrides were removed on a page-by-page
  // basis inside each file, not here. Indices 12/13 (`UserListPage`,
  // `ConsentPolicyAdminPage`) are deliberately NOT wrapped — they live
  // in `shared_ui`, not `school_admin`, and are reused by other roles;
  // migrating them is out of scope for a School Admin-only ticket.
  Widget _themed(Widget child) =>
      Theme(data: SchoolAdminPalette.theme, child: child);

  Widget _buildCurrentPage() {
    if (_profileOpen) {
      return _themed(SchoolAdminProfilePage(onBack: () => _openPage(0)));
    }

    if (_selectedIndex == 0) {
      return _themed(
        _HomeDashboard(
          onOpenPage: _openPage,
          loadEnergy: widget.loadEnergy,
          loadWater: widget.loadWater,
          loadSensor: widget.loadSensor,
          loadMetricsWithData: widget.loadMetricsWithData,
        ),
      );
    }

    if (_selectedIndex == 1) {
      return _themed(const SchoolStudentsPage());
    }

    if (_selectedIndex == 2) {
      return _themed(const SchoolTeachersPage());
    }

    if (_selectedIndex == 3) {
      return _themed(const SchoolImportPage());
    }

    if (_selectedIndex == 4) {
      return _themed(const SchoolPermissionsPage());
    }

    if (_selectedIndex == 5) {
      return _themed(const SchoolBuildingsPage());
    }

    if (_selectedIndex == 6) {
      return _themed(const SchoolDevicesPage());
    }

    if (_selectedIndex == 7) {
      return _themed(const SchoolResourcesPage());
    }

    if (_selectedIndex == 8) {
      return _themed(SchoolScanPage(onBack: () => _openPage(0)));
    }

    if (_selectedIndex == 9) {
      return _themed(const SchoolAlertsPage());
    }

    if (_selectedIndex == 10) {
      return _themed(const SchoolReportsPage());
    }

    if (_selectedIndex == 11) {
      return _themed(const SchoolSettingsPage());
    }

    if (_selectedIndex == 12) {
      return const UserListPage();
    }

    if (_selectedIndex == 13) {
      return const ConsentPolicyAdminPage();
    }

    if (_selectedIndex == 14) {
      return _themed(const SchoolAdminEnergyPage());
    }

    if (_selectedIndex == 15) {
      return _themed(const SchoolAdminCctvPage());
    }

    if (_selectedIndex == 16) {
      return _themed(const SchoolAdminDeviceSchedulePage());
    }

    if (_selectedIndex == 17) {
      return _themed(const SchoolAdminEsgPage());
    }

    if (_selectedIndex == 18) {
      return _themed(const SchoolAdminDeviceControlPage());
    }

    if (_selectedIndex == 19) {
      return _themed(const SchoolAdminIncidentInboxPage());
    }

    if (_selectedIndex == 20) {
      return _themed(const SchoolLearningTracksPage());
    }

    if (_selectedIndex == 21) {
      return _themed(const SchoolAdminAttendanceSettingsPage());
    }

    if (_selectedIndex == 22) {
      return _themed(const SchoolAdminLeaveApprovalPage());
    }

    if (_selectedIndex == 23) {
      return _themed(const SchoolAdminReportRequirementsPage());
    }

    return Center(
      child: Text(
        'ไม่พบหน้านี้',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: SchoolAdminPalette.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1050) {
          return _buildDesktopLayout();
        }

        return _buildMobileLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 268,
                margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                child: _DesktopSidebar(
                  items: _menuItems,
                  selectedIndex: _selectedIndex,
                  onSelect: _openPage,
                  onOpenProfile: _openProfile,
                  schoolName: _schoolName,
                  schoolNameLoading: _schoolNameLoading,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopBar(
                      title: _menuItems[_selectedIndex].title,
                      onOpenAlerts: () => _openPage(9),
                      onOpenScan: () => _openPage(8),
                    ),
                    Expanded(
                      child: ScaffoldMessenger(
                        child: ColoredBox(
                          color: Colors.white,
                          child: SizedBox.expand(
                            child: KeyedSubtree(
                              key: ValueKey<String>(
                                _profileOpen
                                    ? 'profile'
                                    : 'page-$_selectedIndex',
                              ),
                              child: _buildCurrentPage(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _MobileDrawer(
        items: _menuItems,
        selectedIndex: _selectedIndex,
        onSelect: _openPage,
        onOpenProfile: _openProfile,
        schoolName: _schoolName,
        schoolNameLoading: _schoolNameLoading,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SchoolAdminPalette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'AIoT Smart Lab',
              style: TextStyle(
                color: SchoolAdminPalette.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openPage(9),
            tooltip: 'การแจ้งเตือน',
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
        ],
      ),
      body: ScaffoldMessenger(
        child: KeyedSubtree(
          key: ValueKey<String>(
            _profileOpen ? 'profile' : 'page-$_selectedIndex',
          ),
          child: _buildCurrentPage(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPage(8),
        backgroundColor: SchoolAdminPalette.primaryDark,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'สแกนคิวอาร์โค้ด',
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomMenu(
        selectedIndex: _selectedIndex,
        onSelect: _openPage,
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenProfile,
    this.schoolName,
    this.schoolNameLoading = false,
  });

  final List<_MenuItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenProfile;
  final String? schoolName;
  final bool schoolNameLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const _BrandHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final bool selected = selectedIndex == index;
                final _MenuItemData item = items[index];

                return _SidebarMenuTile(
                  item: item,
                  selected: selected,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UserCard(
                  key: const Key('sidebar_user_card'),
                  onTap: onOpenProfile,
                ),
                const SizedBox(height: 8),
                _SchoolScopeCard(
                  schoolName: schoolName,
                  loading: schoolNameLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenProfile,
    this.schoolName,
    this.schoolNameLoading = false,
  });

  final List<_MenuItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenProfile;
  final String? schoolName;
  final bool schoolNameLoading;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide.none,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _BrandHeader(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bool selected = selectedIndex == index;
                  final _MenuItemData item = items[index];

                  return _SidebarMenuTile(
                    item: item,
                    selected: selected,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(index);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UserCard(
                    key: const Key('drawer_user_card'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenProfile();
                    },
                  ),
                  const SizedBox(height: 8),
                  _SchoolScopeCard(
                    schoolName: schoolName,
                    loading: schoolNameLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  const _SidebarMenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _MenuItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? SchoolAdminPalette.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? SchoolAdminPalette.primary
                  : const Color(0xFFF1F5F9),
              width: 1.0,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x28A45C23),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withAlpha(45)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: selected ? Colors.white : SchoolAdminPalette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 4,
                  height: 22,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: SchoolAdminPalette.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x284C2113),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'School Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'AIoT Smart Lab',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
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

class _UserCard extends StatelessWidget {
  const _UserCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF1F5F9),
              width: 1.0,
            ),
          ),
          // เดิม hardcode 'ผู้ดูแลโรงเรียน (Admin)' / 'admin@aiot-school.ac.th'
          // ตายตัว — ทุกคนที่ล็อกอินเห็นชื่อ/อีเมลเดียวกันหมด ไม่ว่าใครเป็นคนใช้
          // currentUserModel เป็น global ที่ auth_service ตั้งไว้ตอนล็อกอินแล้ว
          // อยู่แล้ว (ใช้แบบเดียวกันใน school_admin_profile_page.dart)
          child: Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFF8FAFC),
                child: Icon(
                  Icons.person_rounded,
                  color: SchoolAdminPalette.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentUserModel?.name ?? 'ยังไม่มีข้อมูล',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentUserModel?.email ?? 'ยังไม่มีข้อมูล',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchoolScopeCard extends StatelessWidget {
  const _SchoolScopeCard({this.schoolName, this.loading = false});

  // เดิม hardcode 'โรงเรียนเทศบาล ๑ (สังกัด สถ.)' ตายตัว — ทุกโรงเรียนที่ใช้
  // ระบบนี้เห็นชื่อโรงเรียนเดียวกันหมด ตอนนี้รับชื่อจริงจาก
  // fetchDashboardSummary() ผ่าน state ของหน้าหลัก null ระหว่างโหลด/ล้มเหลว
  final String? schoolName;
  // แยก "กำลังโหลด" ออกจาก "โหลดเสร็จแล้วแต่ไม่มีข้อมูล/ล้มเหลว" —
  // ไม่งั้นเฟรมแรกจะโชว์ 'ยังไม่มีข้อมูล' เสมอก่อนที่ RPC จะตอบกลับด้วยซ้ำ
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFF8FAFC),
            child: Icon(
              Icons.domain_rounded,
              color: SchoolAdminPalette.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loading ? '…' : (schoolName ?? 'ยังไม่มีข้อมูล'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'ระบบบริหารจัดการสถานศึกษา',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
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

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.onOpenAlerts,
    required this.onOpenScan,
  });

  final String title;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onOpenAlerts,
            icon: const Icon(Icons.notifications_none_rounded),
            label: const Text('การแจ้งเตือน'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onOpenScan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('สแกน'),
            style: FilledButton.styleFrom(
              backgroundColor: SchoolAdminPalette.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomMenu extends StatelessWidget {
  const _BottomMenu({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      // แถบเมนูด้านล่างบนมือถือ ใช้โทนเดียวกับ Top Bar
      color: const Color(0xFFF3EBDD),
      surfaceTintColor: const Color(0xFFF3EBDD),
      height: 78,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        children: [
          Expanded(
            child: _BottomButton(
              label: 'หน้าหลัก',
              icon: Icons.home_rounded,
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
          ),
          Expanded(
            child: _BottomButton(
              label: 'นักเรียน',
              icon: Icons.school_rounded,
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
          ),
          const SizedBox(width: 62),
          Expanded(
            child: _BottomButton(
              label: 'อุปกรณ์',
              icon: Icons.memory_rounded,
              selected: selectedIndex == 6,
              onTap: () => onSelect(6),
            ),
          ),
          Expanded(
            child: _BottomButton(
              label: 'ตั้งค่า',
              icon: Icons.settings_rounded,
              selected: selectedIndex == 11,
              onTap: () => onSelect(11),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? SchoolAdminPalette.primary
        : SchoolAdminPalette.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.onOpenPage,
    this.loadEnergy,
    this.loadWater,
    this.loadSensor,
    this.loadMetricsWithData,
  });

  final ValueChanged<int> onOpenPage;
  final Future<EnergyUsageSummary?> Function()? loadEnergy;
  final Future<WaterUsageSummary?> Function()? loadWater;
  final Future<SensorModel?> Function()? loadSensor;
  final Future<Set<String>> Function()? loadMetricsWithData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeWelcomeCard(
                onOpenSettings: () => onOpenPage(11),
                onOpenAlerts: () => onOpenPage(9),
              ),
              const SizedBox(height: 14),
              const _HomeSummaryGrid(),
              const SizedBox(height: 14),
              _ManagementGrid(onOpenPage: onOpenPage),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget assignments = _AssignmentOverview(
                    onOpenTeachers: () => onOpenPage(2),
                    onOpenBuildings: () => onOpenPage(5),
                    onOpenPermissions: () => onOpenPage(4),
                  );

                  final Widget alerts = _HomeAlertPanel(
                    onOpenAlerts: () => onOpenPage(9),
                  );

                  if (constraints.maxWidth < 930) {
                    return Column(
                      children: [
                        assignments,
                        const SizedBox(height: 14),
                        alerts,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: assignments),
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: alerts),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _HomeResourceOverview(
                onOpenResources: () => onOpenPage(7),
                loadEnergy: loadEnergy,
                loadWater: loadWater,
                loadSensor: loadSensor,
                loadMetricsWithData: loadMetricsWithData,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget rules = const _AutomaticRulePanel();

                  final Widget logs = _HomeRecentActivity(
                    onOpenReports: () => onOpenPage(10),
                  );

                  if (constraints.maxWidth < 930) {
                    return Column(
                      children: [rules, const SizedBox(height: 14), logs],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: rules),
                      const SizedBox(width: 14),
                      Expanded(flex: 5, child: logs),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWelcomeCard extends StatelessWidget {
  const _HomeWelcomeCard({
    required this.onOpenSettings,
    required this.onOpenAlerts,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget title = const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: SchoolAdminPalette.primarySoft,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 26,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ภาพรวมการดูแลโรงเรียน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'รวมข้อมูลสำคัญที่แอดมินโรงเรียนต้องใช้ประจำ เช่น บุคลากร อาคาร อุปกรณ์ ชุดฝึก ทรัพยากร สิทธิ์ และการแจ้งเตือน',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.school_outlined),
                label: const Text('ข้อมูลโรงเรียน'),
              ),
              FilledButton.icon(
                onPressed: onOpenAlerts,
                icon: const Icon(Icons.notifications_none_rounded),
                label: const Text('ดูการแจ้งเตือน'),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _HomeSummaryGrid extends StatefulWidget {
  const _HomeSummaryGrid();

  @override
  State<_HomeSummaryGrid> createState() => _HomeSummaryGridState();
}

class _HomeSummaryGridState extends State<_HomeSummaryGrid> {
  SchoolAdminDashboardSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final s = await SchoolAdminPlatformService().fetchDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = s;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _summary == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFECDCA)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: SchoolAdminPalette.red,
            ),
            const Text(
              'โหลดข้อมูลสรุปไม่สำเร็จ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _loadSummary,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    final s = _summary;
    // '--' เดิมกำกวม: อ่านไม่ออกว่ากำลังโหลด หรือโรงเรียนยังไม่มีข้อมูลจริง
    final String placeholder = _loading ? '…' : 'ยังไม่มีข้อมูล';
    final List<_SummaryData> data = [
      _SummaryData(
        value: s != null ? s.studentsCount.toString() : placeholder,
        title: 'นักเรียนทั้งหมด',
        detail: 'รายชื่อในระบบโรงเรียน',
        icon: Icons.school_rounded,
        color: SchoolAdminPalette.primaryDark,
        progress: 1,
      ),
      _SummaryData(
        value: s != null ? s.teachersCount.toString() : placeholder,
        title: 'ครูและบุคลากร',
        detail: 'มีบัญชีในระบบ',
        icon: Icons.groups_rounded,
        color: const Color(0xFF4F6078),
        progress: 1,
      ),
      _SummaryData(
        value: s != null
            ? '${s.buildingsCount} / ${s.roomsCount}'
            : placeholder,
        title: 'อาคาร / ห้อง',
        detail: 'พื้นที่ที่เปิดใช้งาน',
        icon: Icons.apartment_rounded,
        color: const Color(0xFFB77800),
        progress: 1,
      ),
      _SummaryData(
        value: s != null
            ? '${s.devicesCount} (${s.devicesOnline} ออนไลน์)'
            : placeholder,
        title: 'อุปกรณ์ / ชุดฝึก',
        detail: 'ลงทะเบียนในระบบ',
        icon: Icons.memory_rounded,
        color: const Color(0xFF3F7650),
        progress: 1,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;

        if (constraints.maxWidth < 1050) {
          columns = 2;
        }

        // โทรศัพท์ทั่วไปให้คงเป็น 2 คอลัมน์แบบ 2 x 2
        // ลดเหลือ 1 คอลัมน์เฉพาะหน้าจอที่แคบมากจริง ๆ
        if (constraints.maxWidth < 300) {
          columns = 1;
        }

        const double spacing = 12;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: data.map((_SummaryData item) {
            return SizedBox(
              width: width,
              child: _HomeSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HomeSummaryCard extends StatelessWidget {
  const _HomeSummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 240;

        // Design-system-unification (2026-08-26): shell now comes from
        // the ambient `Theme.of(context).cardTheme` via the real `Card`
        // widget instead of a hand-rolled `BoxDecoration` — see
        // `_SectionCard` above for the same change with more detail.
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 152 : 140),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(compact ? 13 : 16),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: data.color.withAlpha(28),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: data.color.withAlpha(95),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(data.icon, color: data.color, size: 22),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          data.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 23,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            height: 1.35,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: data.color.withAlpha(28),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: data.color.withAlpha(95),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(data.icon, color: data.color, size: 26),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 27,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  color: SchoolAdminPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                data.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: SchoolAdminPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  height: 1.4,
                                  color: SchoolAdminPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({required this.onOpenPage});

  final ValueChanged<int> onOpenPage;

  @override
  Widget build(BuildContext context) {
    final List<_ManagementData> items = [
      _ManagementData(
        title: 'ข้อมูลโรงเรียน',
        subtitle: 'ชื่อโรงเรียน ปีการศึกษา และข้อมูลติดต่อ',
        icon: Icons.school_outlined,
        color: SchoolAdminPalette.primary,
        onTap: () => onOpenPage(11),
      ),
      _ManagementData(
        title: 'นักเรียน',
        subtitle: 'เพิ่ม แก้ไข ค้นหา และจัดการบัญชี',
        icon: Icons.groups_2_outlined,
        color: SchoolAdminPalette.blue,
        onTap: () => onOpenPage(1),
      ),
      _ManagementData(
        title: 'ครูและบุคลากร',
        subtitle: 'เพิ่มรายชื่อและกำหนดหน้าที่',
        icon: Icons.badge_outlined,
        color: SchoolAdminPalette.secondary,
        onTap: () => onOpenPage(2),
      ),
      _ManagementData(
        title: 'ครูประจำชั้น',
        subtitle: 'จับคู่ครูกับระดับชั้นและห้อง',
        icon: Icons.co_present_rounded,
        color: SchoolAdminPalette.green,
        onTap: () => onOpenPage(2),
      ),
      _ManagementData(
        title: 'ครูประจำอาคาร',
        subtitle: 'กำหนดผู้รับผิดชอบแต่ละอาคาร',
        icon: Icons.engineering_outlined,
        color: SchoolAdminPalette.primaryDark,
        onTap: () => onOpenPage(5),
      ),
      _ManagementData(
        title: 'อาคารและห้อง',
        subtitle: 'สร้างอาคาร ห้อง และพื้นที่ใช้งาน',
        icon: Icons.apartment_rounded,
        color: SchoolAdminPalette.orange,
        onTap: () => onOpenPage(5),
      ),
      _ManagementData(
        title: 'สายการเรียน',
        subtitle: 'ตั้งชื่อสายและกำหนดสายให้ห้องเรียน',
        icon: Icons.alt_route_rounded,
        color: SchoolAdminPalette.primary,
        onTap: () => onOpenPage(20),
      ),
      _ManagementData(
        title: 'อุปกรณ์',
        subtitle: 'ดูสถานะ เพิ่ม แก้ไข และค้นหาอุปกรณ์',
        icon: Icons.memory_rounded,
        color: SchoolAdminPalette.blue,
        onTap: () => onOpenPage(6),
      ),
      _ManagementData(
        title: 'ชุดฝึก',
        subtitle: 'จัดการชุดฝึก รหัส และอุปกรณ์ภายในชุด',
        icon: Icons.handyman_outlined,
        color: SchoolAdminPalette.secondary,
        onTap: () => onOpenPage(6),
      ),
      _ManagementData(
        title: 'สิทธิ์ผู้ใช้งาน',
        subtitle: 'กำหนดว่าใครเข้าถึงส่วนใดได้บ้าง',
        icon: Icons.admin_panel_settings_outlined,
        color: SchoolAdminPalette.red,
        onTap: () => onOpenPage(4),
      ),
      _ManagementData(
        title: 'การใช้ทรัพยากร',
        subtitle: 'ดูไฟฟ้า น้ำ และคุณภาพอากาศ',
        icon: Icons.energy_savings_leaf_outlined,
        color: SchoolAdminPalette.green,
        onTap: () => onOpenPage(7),
      ),
      _ManagementData(
        title: 'การแจ้งเตือน',
        subtitle: 'ดูรายการผิดปกติที่ควรตรวจสอบ',
        icon: Icons.notifications_active_outlined,
        color: SchoolAdminPalette.red,
        onTap: () => onOpenPage(9),
      ),
      _ManagementData(
        title: 'Log และรายงาน',
        subtitle: 'ดูประวัติการใช้งานและสร้างรายงาน',
        icon: Icons.description_outlined,
        color: SchoolAdminPalette.primary,
        onTap: () => onOpenPage(10),
      ),
      _ManagementData(
        title: 'จัดการผู้ใช้',
        subtitle: 'จัดการบัญชีและรายชื่อผู้ใช้งานทั้งหมด',
        icon: Icons.people_alt_outlined,
        color: Colors.indigo,
        onTap: () => onOpenPage(12),
      ),
      _ManagementData(
        title: 'Consent Policy',
        subtitle: 'นโยบายความยินยอม PDPA ของโรงเรียน',
        icon: Icons.policy_outlined,
        color: Colors.teal,
        onTap: () => onOpenPage(13),
      ),
      _ManagementData(
        title: 'พลังงานทั้งโรงเรียน',
        subtitle: 'กราฟและสรุปการใช้พลังงานไฟฟ้า',
        icon: Icons.bolt_outlined,
        color: Colors.amber.shade800,
        onTap: () => onOpenPage(14),
      ),
      _ManagementData(
        title: 'กล้อง CCTV',
        subtitle: 'จัดการสิทธิ์เข้าถึงกล้องและบันทึก',
        icon: Icons.videocam_outlined,
        color: Colors.blueGrey,
        onTap: () => onOpenPage(15),
      ),
      _ManagementData(
        title: 'ตั้งเวลาอุปกรณ์',
        subtitle: 'ตารางเวลาเปิด-ปิดอุปกรณ์อัตโนมัติ',
        icon: Icons.schedule_outlined,
        color: Colors.deepPurple,
        onTap: () => onOpenPage(16),
      ),
      _ManagementData(
        title: 'รายงาน ESG',
        subtitle: 'คะแนน Green Score และความยั่งยืน',
        icon: Icons.eco_outlined,
        color: Colors.green.shade700,
        onTap: () => onOpenPage(17),
      ),
      _ManagementData(
        title: 'ควบคุมไฟและน้ำ',
        subtitle: 'สั่งการสวิตช์รีเลย์ไฟแสงสว่างและปั๊มน้ำ',
        icon: Icons.lightbulb_outline,
        color: Colors.orange.shade800,
        onTap: () => onOpenPage(18),
      ),
      _ManagementData(
        title: 'กล่องแจ้งเหตุการณ์',
        subtitle: 'ติดตามเรื่องร้องเรียนและเหตุขัดข้อง',
        icon: Icons.inbox_outlined,
        color: Colors.redAccent,
        onTap: () => onOpenPage(19),
      ),
    ];

    return _SectionCard(
      title: 'เมนูจัดการโรงเรียน',
      subtitle: 'รวมงานหลักของแอดมินไว้ให้เข้าถึงได้ง่ายจากหน้าเดียว',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 4;

          if (constraints.maxWidth < 1180) {
            columns = 3;
          }

          if (constraints.maxWidth < 860) {
            columns = 2;
          }

          // โทรศัพท์ให้กลับเป็นการ์ดเดี่ยวเหมือนเดิม
          if (constraints.maxWidth < 560) {
            columns = 1;
          }

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((_ManagementData item) {
              return SizedBox(
                width: width,
                child: _ManagementCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.data});

  final _ManagementData data;

  @override
  Widget build(BuildContext context) {
    // Design-system-unification (2026-08-26): shell radius/color/border
    // now come from the ambient `Theme.of(context).cardTheme` (see
    // `buildRoleTheme` in shared_ui) instead of 3 separately hardcoded
    // `circular(18)`/`Colors.white` values — `Material`+`InkWell` (not
    // `Card`) is kept deliberately, since this card needs a real tap
    // ripple, which plain `Card` doesn't provide on its own.
    final cardShape =
        Theme.of(context).cardTheme.shape as RoundedRectangleBorder;
    final BorderRadius radius = cardShape.borderRadius as BorderRadius;
    final Color borderColor = (cardShape.side).color;
    final Color cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return Material(
      color: cardColor,
      borderRadius: radius,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: data.color.withAlpha(18),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: SchoolAdminPalette.textMuted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentOverview extends StatefulWidget {
  const _AssignmentOverview({
    required this.onOpenTeachers,
    required this.onOpenBuildings,
    required this.onOpenPermissions,
  });

  final VoidCallback onOpenTeachers;
  final VoidCallback onOpenBuildings;
  final VoidCallback onOpenPermissions;

  @override
  State<_AssignmentOverview> createState() => _AssignmentOverviewState();
}

class _AssignmentOverviewState extends State<_AssignmentOverview> {
  bool _loading = true;
  String? _error;
  List<_TeacherData> _data = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        SchoolAdminPlatformService().fetchRooms(),
        SchoolAdminPlatformService().fetchBuildings(),
        UserAdminService.getAllUsers(),
      ]);
      final rooms = results[0] as List<SchoolRoomRecord>;
      final buildings = results[1] as List<SchoolBuildingRecord>;
      final users = results[2] as List<UserModel>;

      final roomsWithTeacher = rooms
          .where((r) => r.teacherName.isNotEmpty)
          .length;
      final buildingsWithManager = buildings
          .where((b) => b.managerName.isNotEmpty)
          .length;
      final activeUsers = users.where((u) => u.status == 'active').length;

      if (mounted) {
        setState(() {
          _data = [
            _TeacherData(
              name: 'ครูประจำชั้น',
              duty: rooms.isEmpty
                  ? 'ยังไม่มีห้องเรียนในระบบ'
                  : 'กำหนดแล้ว $roomsWithTeacher ห้อง จาก ${rooms.length} ห้อง',
              progress: rooms.isEmpty ? 0 : roomsWithTeacher / rooms.length,
              color: SchoolAdminPalette.primary,
            ),
            _TeacherData(
              name: 'ครูประจำอาคาร',
              duty: buildings.isEmpty
                  ? 'ยังไม่มีอาคารในระบบ'
                  : 'กำหนดแล้ว $buildingsWithManager อาคาร จาก ${buildings.length} อาคาร',
              progress: buildings.isEmpty
                  ? 0
                  : buildingsWithManager / buildings.length,
              color: SchoolAdminPalette.green,
            ),
            _TeacherData(
              name: 'สิทธิ์ผู้ใช้งาน',
              duty: users.isEmpty
                  ? 'ยังไม่มีบัญชีในระบบ'
                  : 'ใช้งานอยู่ $activeUsers จาก ${users.length} บัญชี',
              progress: users.isEmpty ? 0 : activeUsers / users.length,
              color: SchoolAdminPalette.secondary,
            ),
          ];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final VoidCallback onOpenTeachers = widget.onOpenTeachers;
    final VoidCallback onOpenBuildings = widget.onOpenBuildings;
    final VoidCallback onOpenPermissions = widget.onOpenPermissions;

    if (_loading) {
      return const _SectionCard(
        title: 'การมอบหมายและสิทธิ์',
        subtitle: 'ตรวจสอบว่าครูและผู้ใช้งานได้รับหน้าที่ครบหรือยัง',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return _SectionCard(
        title: 'การมอบหมายและสิทธิ์',
        subtitle: 'ตรวจสอบว่าครูและผู้ใช้งานได้รับหน้าที่ครบหรือยัง',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.error_outline_rounded,
                  color: SchoolAdminPalette.red,
                  size: 18,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'โหลดข้อมูลไม่สำเร็จ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _load, child: const Text('ลองใหม่')),
            ),
          ],
        ),
      );
    }

    final List<_TeacherData> data = _data;

    return _SectionCard(
      title: 'การมอบหมายและสิทธิ์',
      subtitle: 'ตรวจสอบว่าครูและผู้ใช้งานได้รับหน้าที่ครบหรือยัง',
      trailing: TextButton(
        onPressed: onOpenTeachers,
        child: const Text('จัดการครู'),
      ),
      child: Column(
        children: [
          ...data.map((_TeacherData item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: SchoolAdminPalette.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: item.color.withAlpha(15),
                      child: Icon(
                        item.name == 'สิทธิ์ผู้ใช้งาน'
                            ? Icons.admin_panel_settings_rounded
                            : item.name == 'ครูประจำอาคาร'
                            ? Icons.apartment_rounded
                            : Icons.co_present_rounded,
                        color: item.color,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.duty,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: SchoolAdminPalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              minHeight: 6,
                              backgroundColor: SchoolAdminPalette.sandSoft,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                item.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(item.progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenTeachers,
                icon: const Icon(Icons.co_present_rounded, size: 17),
                label: const Text('ครูประจำชั้น'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenBuildings,
                icon: const Icon(Icons.apartment_rounded, size: 17),
                label: const Text('ครูประจำอาคาร'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenPermissions,
                icon: const Icon(Icons.security_rounded, size: 17),
                label: const Text('จัดการสิทธิ์'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeAlertPanel extends StatefulWidget {
  const _HomeAlertPanel({required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  State<_HomeAlertPanel> createState() => _HomeAlertPanelState();
}

class _HomeAlertPanelState extends State<_HomeAlertPanel> {
  List<SchoolSensorAlertRecord> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final alerts = await IncidentService.listSchoolAlerts(status: 'open');
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading && _alerts.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    } else if (_error != null && _alerts.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: SchoolAdminPalette.red,
              size: 20,
            ),
            const Text(
              'โหลดรายการแจ้งเตือนไม่สำเร็จ',
              style: TextStyle(
                fontSize: 12,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
            TextButton(onPressed: _loadAlerts, child: const Text('ลองใหม่')),
          ],
        ),
      );
    } else if (_alerts.isEmpty) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FEF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1FADF)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: SchoolAdminPalette.green,
              size: 30,
            ),
            SizedBox(height: 6),
            Text(
              'ไม่มีรายการแจ้งเตือนที่ต้องตรวจสอบ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'ระบบและอุปกรณ์ทำงานปกติ',
              style: TextStyle(
                fontSize: 11,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        children: _alerts.take(4).map((SchoolSensorAlertRecord item) {
          final Color badgeColor = item.isNew
              ? SchoolAdminPalette.red
              : (item.isAcknowledged
                    ? SchoolAdminPalette.secondary
                    : SchoolAdminPalette.primary);

          final String statusLabel = item.isNew
              ? 'ใหม่'
              : (item.isAcknowledged ? 'รับทราบแล้ว' : item.status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: SchoolAdminPalette.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: badgeColor.withAlpha(15),
                    child: Icon(
                      item.isNew
                          ? Icons.warning_amber_rounded
                          : Icons.notifications_none_rounded,
                      color: badgeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.deviceName} (${item.metric})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ค่า: ${item.value} • ${item.deviceCode}',
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(13),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: badgeColor.withAlpha(45)),
                      ),
                      child: Text(
                        statusLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return _SectionCard(
      title: 'รายการที่ต้องตรวจสอบ',
      subtitle: 'แสดงเฉพาะเรื่องที่เกี่ยวกับการดูแลระบบโรงเรียน',
      trailing: TextButton(
        onPressed: widget.onOpenAlerts,
        child: const Text('ดูทั้งหมด'),
      ),
      child: content,
    );
  }
}

/// Electricity / water / air-quality summary on the School Admin home page.
///
/// Until 2026-09-07 every figure here was a `const` literal — "428 kWh",
/// "12.6 m³", "PM2.5 21" — together with invented day-over-day deltas
/// ("ลดลง 3.2% จากเมื่อวาน"). It was the first card the school admin saw and
/// none of it came from the database. On a local stack with zero rows in
/// `sensor_readings` it still displayed those numbers confidently.
///
/// Everything is now read through RPCs that `school_admin` is already
/// allowed to call (verified against the running database, not the migration
/// files): `get_energy_usage_summary`, `get_water_usage_summary` and
/// `sensor_latest`. No new backend was needed.
///
/// The day-over-day comparison was NOT reimplemented: those summary RPCs
/// return a total for a window, not a previous-period delta, so there is
/// nothing truthful to compute it from. Showing device count and estimated
/// cost — which the RPCs really do return — is preferred over resurrecting a
/// trend line the backend cannot support.
class _HomeResourceOverview extends StatefulWidget {
  const _HomeResourceOverview({
    required this.onOpenResources,
    this.loadEnergy,
    this.loadWater,
    this.loadSensor,
    this.loadMetricsWithData,
  });

  final VoidCallback onOpenResources;

  /// Injectable read seams so the four states can be driven in widget tests
  /// without a live Supabase client, matching the pattern used by the
  /// already-connected School Admin pages.
  final Future<EnergyUsageSummary?> Function()? loadEnergy;
  final Future<WaterUsageSummary?> Function()? loadWater;
  final Future<SensorModel?> Function()? loadSensor;
  final Future<Set<String>> Function()? loadMetricsWithData;

  @override
  State<_HomeResourceOverview> createState() => _HomeResourceOverviewState();
}

class _HomeResourceOverviewState extends State<_HomeResourceOverview> {
  bool _loading = true;
  bool _failed = false;

  EnergyUsageSummary? _energy;
  WaterUsageSummary? _water;
  SensorModel? _sensor;
  Set<String> _metricsWithData = const <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final results = await Future.wait([
        widget.loadEnergy?.call() ?? UtilityService.getEnergyUsageSummary(),
        widget.loadWater?.call() ?? UtilityService.getWaterUsageSummary(),
        widget.loadSensor?.call() ??
            RealtimeService.getSensorOnce(
              schoolId: '',
              building: '',
              floor: '',
              room: '',
            ),
        widget.loadMetricsWithData?.call() ??
            RealtimeService.getWeatherMetricsWithData(),
      ]);
      if (!mounted) return;
      setState(() {
        _energy = results[0] as EnergyUsageSummary?;
        _water = results[1] as WaterUsageSummary?;
        _sensor = results[2] as SensorModel?;
        _metricsWithData = results[3] as Set<String>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('_HomeResourceOverview load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  static const String _empty = 'ยังไม่มีข้อมูล';

  String _stateText() => _loading ? '…' : (_failed ? 'โหลดไม่สำเร็จ' : _empty);

  _ResourceData _energyCard() {
    final e = _energy;
    return _ResourceData(
      title: 'การใช้ไฟ (ช่วงที่ระบบสรุป)',
      value: e != null ? '${e.totalKwh.toStringAsFixed(1)} kWh' : _stateText(),
      detail: e != null
          ? 'จากมิเตอร์ ${e.deviceCount} จุด · ประมาณ ${e.estimatedCostThb.toStringAsFixed(0)} บาท'
          : 'ยังไม่มีมิเตอร์ไฟที่ส่งค่าเข้ามา',
      icon: Icons.bolt_rounded,
      color: SchoolAdminPalette.primary,
    );
  }

  _ResourceData _waterCard() {
    final w = _water;
    return _ResourceData(
      title: 'การใช้น้ำ (ช่วงที่ระบบสรุป)',
      value: w != null ? '${w.totalM3.toStringAsFixed(1)} m³' : _stateText(),
      detail: w != null
          ? 'จากมิเตอร์ ${w.deviceCount} จุด · ประมาณ ${w.estimatedCostThb.toStringAsFixed(0)} บาท'
          : 'ยังไม่มีมิเตอร์น้ำที่ส่งค่าเข้ามา',
      icon: Icons.water_drop_rounded,
      color: SchoolAdminPalette.blue,
    );
  }

  _ResourceData _airCard() {
    // SensorModel defaults an absent metric to 0, which is indistinguishable
    // from a genuine reading of 0 — so presence is checked against the set of
    // metrics that actually have at least one row, never against the number.
    final hasPm25 = _metricsWithData.contains('pm25') && _sensor != null;
    return _ResourceData(
      title: 'คุณภาพอากาศ',
      value: hasPm25 ? 'PM2.5 ${_sensor!.pm25.toStringAsFixed(0)}' : _stateText(),
      detail: hasPm25
          ? 'ค่าล่าสุดจากเซนเซอร์ในโรงเรียน'
          : 'ยังไม่มีเซนเซอร์ที่ส่งค่า PM2.5',
      icon: Icons.air_rounded,
      color: SchoolAdminPalette.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_ResourceData> data = [_energyCard(), _waterCard(), _airCard()];

    return _SectionCard(
      title: 'ไฟฟ้า น้ำ และคุณภาพอากาศ',
      subtitle: 'แสดงเฉพาะค่าที่แอดมินควรเห็นเพื่อดูความผิดปกติของโรงเรียน',
      trailing: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_failed)
            TextButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('ลองใหม่'),
            ),
          TextButton.icon(
            onPressed: widget.onOpenResources,
            icon: const Icon(Icons.bar_chart_rounded, size: 17),
            label: const Text('ดูรายละเอียด'),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 3;

          if (constraints.maxWidth < 800) {
            columns = 1;
          }

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: data.map((_ResourceData item) {
              return SizedBox(
                width: width,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 102),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SchoolAdminPalette.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: item.color.withAlpha(15),
                        child: Icon(item.icon, color: item.color),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: SchoolAdminPalette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: SchoolAdminPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.detail,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: item.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AutomaticRulePanel extends StatelessWidget {
  const _AutomaticRulePanel();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      // Each row states whether the automation actually runs. Checked against
      // the live database on 2026-09-07 (`pg_trigger` + `cron.job`), not
      // against docs: the only jobs that exist are `threshold-violation-check`
      // and `device-schedules-tick`, and the only notification triggers are
      // notify_assignment_publication / notify_grade_confirmation /
      // notify_lesson_publication.
      //
      // The card previously promised all four as working and told the admin
      // "ไม่ต้องตามเองทุกเรื่อง" — for absence and unresponsive devices
      // nothing happens at all, so an admin trusting it would simply never
      // follow up. Rows are kept (they describe the intended design) but are
      // now labelled with their real status instead of being deleted.
      title: 'การแจ้งเตือนอัตโนมัติ',
      subtitle: 'สถานะจริงของแต่ละกฎ — กฎที่ยังไม่เปิดใช้งานต้องตามเอง',
      child: const Column(
        children: [
          _AutomaticRuleRow(
            icon: Icons.bolt_rounded,
            title: 'ไฟหรือน้ำใช้สูงผิดปกติ',
            detail:
                'เปิดใช้งานอยู่ — ระบบตรวจทุกนาทีและสร้างการแจ้งเตือนเมื่อค่าเกินเกณฑ์',
            color: SchoolAdminPalette.secondary,
            active: true,
          ),
          _AutomaticRuleRow(
            icon: Icons.security_rounded,
            title: 'มีการเข้าใช้งานผิดปกติ',
            detail:
                'บันทึก Log อยู่จริง แต่ยังไม่มีการแจ้งเตือน ต้องเปิดดูหน้ารายงานเอง',
            color: SchoolAdminPalette.blue,
            active: false,
          ),
          _AutomaticRuleRow(
            icon: Icons.person_off_outlined,
            title: 'นักเรียนไม่มาเรียน',
            detail: 'ยังไม่เปิดใช้งาน — ระบบยังไม่แจ้งครูประจำชั้นให้อัตโนมัติ',
            color: SchoolAdminPalette.primary,
            active: false,
          ),
          _AutomaticRuleRow(
            icon: Icons.memory_rounded,
            title: 'อุปกรณ์ไม่ตอบสนอง',
            detail: 'ยังไม่เปิดใช้งาน — ต้องดูสถานะอุปกรณ์เองในหน้าอุปกรณ์',
            color: SchoolAdminPalette.red,
            active: false,
          ),
        ],
      ),
    );
  }
}

class _AutomaticRuleRow extends StatelessWidget {
  const _AutomaticRuleRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  /// Whether this automation actually runs today. A rule that does not run
  /// must not look identical to one that does — that is what let this card
  /// promise four working automations when only one existed.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color tone = active ? color : SchoolAdminPalette.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: tone.withAlpha(15),
            child: Icon(
              active ? icon : Icons.pause_circle_outline_rounded,
              color: tone,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: active
                              ? SchoolAdminPalette.textPrimary
                              : SchoolAdminPalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        active ? 'เปิดใช้งาน' : 'ยังไม่เปิดใช้งาน',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: tone,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline_rounded,
            color: SchoolAdminPalette.green,
            size: 19,
          ),
        ],
      ),
    );
  }
}

class _HomeRecentActivity extends StatefulWidget {
  const _HomeRecentActivity({required this.onOpenReports});

  final VoidCallback onOpenReports;

  @override
  State<_HomeRecentActivity> createState() => _HomeRecentActivityState();
}

class _HomeRecentActivityState extends State<_HomeRecentActivity> {
  List<SchoolAdminAuditLog> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 4);
      if (mounted) {
        setState(() {
          _logs = logs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading && _logs.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    } else if (_error != null && _logs.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: SchoolAdminPalette.red,
              size: 20,
            ),
            const Text(
              'โหลดกิจกรรมล่าสุดไม่สำเร็จ',
              style: TextStyle(
                fontSize: 12,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
            TextButton(onPressed: _loadLogs, child: const Text('ลองใหม่')),
          ],
        ),
      );
    } else if (_logs.isEmpty) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SchoolAdminPalette.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.history_rounded,
              color: SchoolAdminPalette.textSecondary,
              size: 30,
            ),
            SizedBox(height: 6),
            Text(
              'ยังไม่มีกิจกรรมและ Log ล่าสุด',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'เมื่อมีการดำเนินงานในระบบ รายการจะปรากฏที่นี่',
              style: TextStyle(
                fontSize: 11,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        children: _logs.map((SchoolAdminAuditLog item) {
          final String timeStr =
              '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')} น.';

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: SchoolAdminPalette.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: SchoolAdminPalette.primary.withAlpha(15),
                    child: const Icon(
                      Icons.history_rounded,
                      color: SchoolAdminPalette.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.action,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.detail.isNotEmpty ? item.detail : item.target,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      timeStr,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: SchoolAdminPalette.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return _SectionCard(
      title: 'กิจกรรมและ Log ล่าสุด',
      subtitle: 'ดูว่าใครทำอะไรในระบบ และเกิดเหตุการณ์อะไรล่าสุด',
      trailing: TextButton(
        onPressed: widget.onOpenReports,
        child: const Text('ดู Log และรายงาน'),
      ),
      child: content,
    );
  }
}

class _ManagementData {
  const _ManagementData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Design-system-unification (2026-08-26): the card *shell*
    // (radius/border/background) now comes from the ambient
    // `Theme.of(context).cardTheme` (see `buildRoleTheme` in
    // shared_ui) via the real `Card` widget, instead of a hand-rolled
    // `Container(decoration: BoxDecoration(...))`. Everything inside
    // — title/subtitle layout, spacing — is unchanged; only the shell
    // now matches the shared structural language.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (trailing == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                    ],
                  );
                }

                if (constraints.maxWidth < 320) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.centerLeft, child: trailing!),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: SchoolAdminPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing!,
                  ],
                );
              },
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _SummaryData {
  const _SummaryData({
    required this.value,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String value;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final double progress;
}

class _TeacherData {
  const _TeacherData({
    required this.name,
    required this.duty,
    required this.progress,
    required this.color,
  });

  final String name;
  final String duty;
  final double progress;
  final Color color;
}

class _ResourceData {
  const _ResourceData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}
