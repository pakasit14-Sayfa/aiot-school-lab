import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

import '../super_admin_hub_page.dart';
import '../super_admin_schools_page.dart';
import '../super_admin_device_control_page.dart';
import '../super_admin_devices_page.dart';
import '../super_admin_device_test_page.dart';
import '../super_admin_permissions_page.dart';
import '../super_admin_alerts_logs_page.dart';
import '../super_admin_settings_page.dart';
import '../super_admin_scan_page.dart';
import '../super_admin_learning_overview_page.dart';
import '../theme/app_palette.dart';
import '../../login_page.dart';

class _NavItem {
  final IconData icon;
  final IconData outlinedIcon;
  final String title;
  final String shortTitle;
  final Color color;
  final Widget Function() builder;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.title,
    required this.shortTitle,
    required this.color,
    required this.builder,
  });
}

/// Persistent sidebar shell for Super Admin, matching the structure of
/// aiot_dev_dashboard's DevNavigationShell — one always-visible left
/// sidebar on desktop that swaps body content by index (no per-page
/// Navigator.push, no default Flutter hamburger icon), falling back to
/// a Drawer on narrow widths. Each embedded page keeps its own
/// Scaffold/AppBar as-is (decided over stripping every page to
/// body-only) — zero changes to the pages themselves beyond removing
/// SuperAdminHubPage's now-redundant drawer.
class SuperAdminNavigationShell extends StatefulWidget {
  const SuperAdminNavigationShell({super.key});

  @override
  State<SuperAdminNavigationShell> createState() =>
      _SuperAdminNavigationShellState();
}

class _SuperAdminNavigationShellState
    extends State<SuperAdminNavigationShell> {
  int _selectedIndex = 0;

  static final List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_rounded,
      outlinedIcon: Icons.home_outlined,
      title: 'หน้าแรก (ภาพรวม)',
      shortTitle: 'ภาพรวมระบบ',
      color: AppPalette.deepBlue,
      builder: () => const SuperAdminHubPage(embedded: true),
    ),
    _NavItem(
      icon: Icons.apartment_rounded,
      outlinedIcon: Icons.apartment_outlined,
      title: 'จัดการโรงเรียน (Schools)',
      shortTitle: 'จัดการโรงเรียน',
      color: const Color(0xFF0F5B8F),
      builder: () => const SuperAdminSchoolsPage(),
    ),
    _NavItem(
      icon: Icons.toggle_on_rounded,
      outlinedIcon: Icons.toggle_off_outlined,
      title: 'ควบคุมและอนุมัติอุปกรณ์ (Device Control)',
      shortTitle: 'ควบคุมอุปกรณ์',
      color: const Color(0xFF1E88E5),
      builder: () => const SuperAdminDeviceControlPage(),
    ),
    _NavItem(
      icon: Icons.memory_rounded,
      outlinedIcon: Icons.memory_outlined,
      title: 'ทะเบียนและ QR Code (Devices & QR)',
      shortTitle: 'รายการอุปกรณ์',
      color: const Color(0xFF028090),
      builder: () => const SuperAdminDevicesPage(embedded: true),
    ),
    _NavItem(
      icon: Icons.science_rounded,
      outlinedIcon: Icons.science_outlined,
      title: 'ทดสอบอุปกรณ์ (Device Diagnostics)',
      shortTitle: 'ทดสอบอุปกรณ์',
      color: const Color(0xFF6A4C93),
      builder: () => const SuperAdminDeviceTestPage(embedded: true),
    ),
    _NavItem(
      icon: Icons.admin_panel_settings_rounded,
      outlinedIcon: Icons.admin_panel_settings_outlined,
      title: 'กำหนดสิทธิ์และบทบาท (Permissions)',
      shortTitle: 'ผู้ใช้และสิทธิ์',
      color: const Color(0xFFB0232B),
      builder: () => const SuperAdminPermissionsPage(embedded: true),
    ),
    _NavItem(
      icon: Icons.notifications_active_rounded,
      outlinedIcon: Icons.notifications_none_rounded,
      title: 'การแจ้งเตือนและประวัติ (Alerts & Logs)',
      shortTitle: 'แจ้งเตือนและรายงาน',
      color: const Color(0xFFF18701),
      builder: () => const SuperAdminAlertsLogsPage(embedded: true),
    ),
    _NavItem(
      icon: Icons.settings_rounded,
      outlinedIcon: Icons.settings_outlined,
      title: 'ตั้งค่าระบบส่วนกลาง (Settings)',
      shortTitle: 'ตั้งค่าระบบ',
      color: const Color(0xFF4361EE),
      builder: () => const SuperAdminSettingsPage(embedded: true),
    ),
    _NavItem(
      icon: Icons.people_alt_rounded,
      outlinedIcon: Icons.people_alt_outlined,
      title: 'จัดการผู้ใช้ (User Management)',
      shortTitle: 'จัดการผู้ใช้',
      color: Colors.blueGrey,
      builder: () => const UserListPage(),
    ),
    _NavItem(
      icon: Icons.qr_code_scanner_rounded,
      outlinedIcon: Icons.qr_code_scanner_outlined,
      title: 'สแกนอุปกรณ์ (Device Scan)',
      shortTitle: 'สแกนข้อมูล',
      color: const Color(0xFF7C3AED),
      builder: () => const SuperAdminScanPage(embedded: true),
    ),
    _NavItem(
      icon: Icons.school_rounded,
      outlinedIcon: Icons.school_outlined,
      title: 'แพลตฟอร์มการเรียนรู้ (Learning Overview)',
      shortTitle: 'แพลตฟอร์มการเรียนรู้',
      color: const Color(0xFF059669),
      builder: () => const SuperAdminLearningOverviewPage(embedded: true),
    ),
  ];

  void _changePage(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;

        if (!isDesktop) {
          // Narrow widths: only SuperAdminHubPage ever had its own
          // drawer + Navigator.push to the other 7 pages (none of them
          // have a drawer of their own) — reproduce that exact original
          // behavior unchanged, ignoring _selectedIndex entirely, so
          // mobile never gets stranded on a page with no way back.
          return const SuperAdminHubPage(embedded: false);
        }

        final currentPage = KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _items[_selectedIndex].builder(),
        );

        return Scaffold(
          backgroundColor: AppPalette.background,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: AppPalette.background,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: currentPage,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 284,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final item = _items[index];
                final selected = index == _selectedIndex;
                return Tooltip(
                  message: item.title,
                  child: _SidebarMenuItem(
                    icon: selected ? item.icon : item.outlinedIcon,
                    title: item.shortTitle,
                    selected: selected,
                    onTap: () => _changePage(index),
                  ),
                );
              },
            ),
          ),
          _buildSidebarProfile(),
        ],
      ),
    );
  }

  /// RedTeam fix (2026-08-31): the profile card's onTap used to be a
  /// no-op — there was no reachable sign-out path from this desktop
  /// shell at all. Reuses the same AuthService.signOut() + navigate-to-
  /// login pattern already used by AppDrawer.confirmLogout elsewhere in
  /// this app (apps/user_app/lib/widgets/app_drawer.dart).
  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('ออกจากระบบ'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarProfile() {
    final user = currentUserModel;
    final name = user?.name.trim().isNotEmpty == true
        ? user!.name
        : 'ผู้ดูแลระบบ';
    final letter = name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Material(
        color: AppPalette.softBeige.withAlpha(115),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showProfileMenu(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppPalette.deepBlue,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ผู้ดูแลระบบสูงสุด',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_vert_rounded,
                  color: AppPalette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppPalette.deepBlue,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.developer_board_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AIoT Smart Lab',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ศูนย์ควบคุมสำหรับผู้ดูแล',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: AppPalette.softBeige.withAlpha(190),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppPalette.softBeige.withAlpha(158)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: selected
                      ? AppPalette.deepBlue
                      : AppPalette.softBeige.withAlpha(122),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : AppPalette.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppPalette.deepBlue : AppPalette.textPrimary,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppPalette.carnivalRed,
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
