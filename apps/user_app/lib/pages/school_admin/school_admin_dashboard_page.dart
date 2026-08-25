import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../theme/school_admin_palette.dart';
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

class SchoolAdminDashboardPage extends StatefulWidget {
  const SchoolAdminDashboardPage({super.key});

  @override
  State<SchoolAdminDashboardPage> createState() =>
      _SchoolAdminDashboardPageState();
}

class _SchoolAdminDashboardPageState extends State<SchoolAdminDashboardPage> {
  int _selectedIndex = 0;
  bool _profileOpen = false;

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

  Widget _buildCurrentPage() {
    if (_profileOpen) {
      return SchoolAdminProfilePage(
        onBack: () => _openPage(0),
      );
    }

    if (_selectedIndex == 0) {
      return _HomeDashboard(onOpenPage: _openPage);
    }

    if (_selectedIndex == 1) {
      return const SchoolStudentsPage();
    }

    if (_selectedIndex == 2) {
      return const SchoolTeachersPage();
    }

    if (_selectedIndex == 3) {
      return const SchoolImportPage();
    }

    if (_selectedIndex == 4) {
      return const SchoolPermissionsPage();
    }

    if (_selectedIndex == 5) {
      return const SchoolBuildingsPage();
    }

    if (_selectedIndex == 6) {
      return const SchoolDevicesPage();
    }

    if (_selectedIndex == 7) {
      return const SchoolResourcesPage();
    }

    if (_selectedIndex == 8) {
      return SchoolScanPage(
        onBack: () => _openPage(0),
      );
    }

    if (_selectedIndex == 9) {
      return const SchoolAlertsPage();
    }

    if (_selectedIndex == 10) {
      return const SchoolReportsPage();
    }

    if (_selectedIndex == 11) {
      return const SchoolSettingsPage();
    }

    if (_selectedIndex == 12) {
      return const UserListPage();
    }

    if (_selectedIndex == 13) {
      return const ConsentPolicyAdminPage();
    }

    if (_selectedIndex == 14) {
      return const SchoolAdminEnergyPage();
    }

    if (_selectedIndex == 15) {
      return const SchoolAdminCctvPage();
    }

    if (_selectedIndex == 16) {
      return const SchoolAdminDeviceSchedulePage();
    }

    if (_selectedIndex == 17) {
      return const SchoolAdminEsgPage();
    }

    if (_selectedIndex == 18) {
      return const SchoolAdminDeviceControlPage();
    }

    if (_selectedIndex == 19) {
      return const SchoolAdminIncidentInboxPage();
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox.expand(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 255,
                child: _DesktopSidebar(
                  items: _menuItems,
                  selectedIndex: _selectedIndex,
                  onSelect: _openPage,
                  onOpenProfile: _openProfile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: SchoolAdminPalette.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: SchoolAdminPalette.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      _DesktopTopBar(
                        title: _menuItems[_selectedIndex].title,
                        onOpenAlerts: () => _openPage(9),
                        onOpenScan: () => _openPage(8),
                      ),
                      const Divider(
                        height: 1,
                        color: SchoolAdminPalette.border,
                      ),
                      Expanded(
                        child: ScaffoldMessenger(
                          child: ColoredBox(
                            color: Colors.white,
                            child: SizedBox.expand(
                              child: KeyedSubtree(
                                key: ValueKey<String>(
                                  _profileOpen ? 'profile' : 'page-$_selectedIndex',
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
              ),
            ],
          ),
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
      ),
      appBar: AppBar(
        // แถบด้านบนบนมือถือ เข้มกว่าพื้นหลังเล็กน้อย
        backgroundColor: const Color(0xFFF3EBDD),
        surfaceTintColor: const Color(0xFFF3EBDD),
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
  });

  final List<_MenuItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SchoolAdminPalette.sidebar,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        children: [
          const _BrandHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final bool selected = selectedIndex == index;
                final _MenuItemData item = items[index];

                return Material(
                  color: selected
                      ? SchoolAdminPalette.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => onSelect(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withAlpha(34)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              size: 19,
                              color: selected
                                  ? Colors.white
                                  : SchoolAdminPalette.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? Colors.white
                                    : SchoolAdminPalette.textPrimary,
                              ),
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
          Padding(
            padding: const EdgeInsets.all(10),
            child: _UserCard(
              key: const Key('sidebar_user_card'),
              onTap: onOpenProfile,
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
  });

  final List<_MenuItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: SchoolAdminPalette.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            const _BrandHeader(),
            const Divider(
              height: 1,
              color: SchoolAdminPalette.border,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final bool selected = selectedIndex == index;
                  final _MenuItemData item = items[index];

                  return Material(
                    color: selected
                        ? SchoolAdminPalette.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(index);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: selected
                                  ? Colors.white
                                  : SchoolAdminPalette.primaryDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white
                                      : SchoolAdminPalette.textPrimary,
                                ),
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: _UserCard(
                key: const Key('drawer_user_card'),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenProfile();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: SchoolAdminPalette.primary,
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIoT Smart Lab',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  'ผู้ดูแลโรงเรียน',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SchoolAdminPalette.textSecondary,
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
  const _UserCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SchoolAdminPalette.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: SchoolAdminPalette.primary,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผู้ดูแลโรงเรียน',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      'พร้อมใช้งาน',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: SchoolAdminPalette.green,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SchoolAdminPalette.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
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
  const _BottomMenu({
    required this.selectedIndex,
    required this.onSelect,
  });

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
  });

  final ValueChanged<int> onOpenPage;

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
                builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                ) {
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
                      Expanded(
                        flex: 5,
                        child: assignments,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: alerts,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _HomeResourceOverview(
                onOpenResources: () => onOpenPage(7),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                ) {
                  final Widget rules = const _AutomaticRulePanel();

                  final Widget logs = _HomeRecentActivity(
                    onOpenReports: () => onOpenPage(10),
                  );

                  if (constraints.maxWidth < 930) {
                    return Column(
                      children: [
                        rules,
                        const SizedBox(height: 14),
                        logs,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: rules,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 5,
                        child: logs,
                      ),
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
        border: Border.all(
          color: SchoolAdminPalette.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolAdminPalette.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 16),
                actions,
              ],
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
            const Icon(Icons.error_outline_rounded, color: SchoolAdminPalette.red),
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
    final String placeholder = _loading ? '...' : '--';
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
        value: s != null ? '${s.buildingsCount} / ${s.roomsCount}' : placeholder,
        title: 'อาคาร / ห้อง',
        detail: 'พื้นที่ที่เปิดใช้งาน',
        icon: Icons.apartment_rounded,
        color: const Color(0xFFB77800),
        progress: 1,
      ),
      _SummaryData(
        value: s != null ? '${s.devicesCount} (${s.devicesOnline} ออนไลน์)' : placeholder,
        title: 'อุปกรณ์ / ชุดฝึก',
        detail: 'ลงทะเบียนในระบบ',
        icon: Icons.memory_rounded,
        color: const Color(0xFF3F7650),
        progress: 1,
      ),
    ];

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
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
  const _HomeSummaryCard({
    required this.data,
  });

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(
            minHeight: compact ? 152 : 140,
          ),
          padding: EdgeInsets.all(compact ? 13 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: SchoolAdminPalette.border,
            ),
          ),
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
                      child: Icon(
                        data.icon,
                        color: data.color,
                        size: 22,
                      ),
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
                      child: Icon(
                        data.icon,
                        color: data.color,
                        size: 26,
                      ),
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
        );
      },
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({
    required this.onOpenPage,
  });

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
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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
  const _ManagementCard({
    required this.data,
  });

  final _ManagementData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SchoolAdminPalette.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: data.color.withAlpha(18),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 22,
                ),
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

      final roomsWithTeacher =
          rooms.where((r) => r.teacherName.isNotEmpty).length;
      final buildingsWithManager =
          buildings.where((b) => b.managerName.isNotEmpty).length;
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
              progress:
                  buildings.isEmpty ? 0 : buildingsWithManager / buildings.length,
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
                Icon(Icons.error_outline_rounded, color: SchoolAdminPalette.red, size: 18),
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
                  border: Border.all(
                    color: SchoolAdminPalette.border,
                  ),
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
                icon: const Icon(
                  Icons.co_present_rounded,
                  size: 17,
                ),
                label: const Text('ครูประจำชั้น'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenBuildings,
                icon: const Icon(
                  Icons.apartment_rounded,
                  size: 17,
                ),
                label: const Text('ครูประจำอาคาร'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenPermissions,
                icon: const Icon(
                  Icons.security_rounded,
                  size: 17,
                ),
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
  const _HomeAlertPanel({
    required this.onOpenAlerts,
  });

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
            const Icon(Icons.error_outline_rounded, color: SchoolAdminPalette.red, size: 20),
            const Text(
              'โหลดรายการแจ้งเตือนไม่สำเร็จ',
              style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
            ),
            TextButton(
              onPressed: _loadAlerts,
              child: const Text('ลองใหม่'),
            ),
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
            Icon(Icons.check_circle_outline_rounded, color: SchoolAdminPalette.green, size: 30),
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
              style: TextStyle(fontSize: 11, color: SchoolAdminPalette.textSecondary),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        children: _alerts.take(4).map((SchoolSensorAlertRecord item) {
          final Color badgeColor = item.isNew
              ? SchoolAdminPalette.red
              : (item.isAcknowledged ? SchoolAdminPalette.secondary : SchoolAdminPalette.primary);

          final String statusLabel = item.isNew ? 'ใหม่' : (item.isAcknowledged ? 'รับทราบแล้ว' : item.status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: SchoolAdminPalette.border,
                ),
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
                        border: Border.all(
                          color: badgeColor.withAlpha(45),
                        ),
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

class _HomeResourceOverview extends StatelessWidget {
  const _HomeResourceOverview({
    required this.onOpenResources,
  });

  final VoidCallback onOpenResources;

  @override
  Widget build(BuildContext context) {
    const List<_ResourceData> data = [
      _ResourceData(
        title: 'การใช้ไฟวันนี้',
        value: '428 kWh',
        detail: 'ลดลง 3.2% จากเมื่อวาน',
        icon: Icons.bolt_rounded,
        color: SchoolAdminPalette.primary,
      ),
      _ResourceData(
        title: 'การใช้น้ำวันนี้',
        value: '12.6 m³',
        detail: 'เพิ่มขึ้น 1.1% จากเมื่อวาน',
        icon: Icons.water_drop_rounded,
        color: SchoolAdminPalette.blue,
      ),
      _ResourceData(
        title: 'คุณภาพอากาศ',
        value: 'PM2.5 21',
        detail: 'อยู่ในระดับดี',
        icon: Icons.air_rounded,
        color: SchoolAdminPalette.green,
      ),
    ];

    return _SectionCard(
      title: 'ไฟฟ้า น้ำ และคุณภาพอากาศ',
      subtitle: 'แสดงเฉพาะค่าที่แอดมินควรเห็นเพื่อดูความผิดปกติของโรงเรียน',
      trailing: TextButton.icon(
        onPressed: onOpenResources,
        icon: const Icon(
          Icons.bar_chart_rounded,
          size: 17,
        ),
        label: const Text('ดูรายละเอียด'),
      ),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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
                    border: Border.all(
                      color: SchoolAdminPalette.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: item.color.withAlpha(15),
                        child: Icon(
                          item.icon,
                          color: item.color,
                        ),
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
      title: 'การแจ้งเตือนอัตโนมัติ',
      subtitle:
          'ระบบส่งเรื่องไปยังผู้รับผิดชอบโดยไม่ต้องให้แอดมินตามเองทุกเรื่อง',
      child: const Column(
        children: [
          _AutomaticRuleRow(
            icon: Icons.person_off_outlined,
            title: 'นักเรียนไม่มาเรียน',
            detail: 'แจ้งครูประจำชั้นของนักเรียนคนนั้นอัตโนมัติ',
            color: SchoolAdminPalette.primary,
          ),
          _AutomaticRuleRow(
            icon: Icons.memory_rounded,
            title: 'อุปกรณ์ไม่ตอบสนอง',
            detail: 'แจ้งครูประจำอาคารและแอดมินโรงเรียน',
            color: SchoolAdminPalette.red,
          ),
          _AutomaticRuleRow(
            icon: Icons.bolt_rounded,
            title: 'ไฟหรือน้ำใช้สูงผิดปกติ',
            detail: 'แจ้งผู้ดูแลอาคารเพื่อเข้าตรวจสอบ',
            color: SchoolAdminPalette.secondary,
          ),
          _AutomaticRuleRow(
            icon: Icons.security_rounded,
            title: 'มีการเข้าใช้งานผิดปกติ',
            detail: 'บันทึก Log และแจ้งแอดมินโรงเรียน',
            color: SchoolAdminPalette.blue,
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
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: SchoolAdminPalette.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withAlpha(15),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
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
  const _HomeRecentActivity({
    required this.onOpenReports,
  });

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
            const Icon(Icons.error_outline_rounded, color: SchoolAdminPalette.red, size: 20),
            const Text(
              'โหลดกิจกรรมล่าสุดไม่สำเร็จ',
              style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
            ),
            TextButton(
              onPressed: _loadLogs,
              child: const Text('ลองใหม่'),
            ),
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
            Icon(Icons.history_rounded, color: SchoolAdminPalette.textSecondary, size: 30),
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
              style: TextStyle(fontSize: 11, color: SchoolAdminPalette.textSecondary),
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
                border: Border.all(
                  color: SchoolAdminPalette.border,
                ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: SchoolAdminPalette.border),
        boxShadow: SchoolAdminPalette.smallShadow,
      ),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: trailing!,
                    ),
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
