import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyDownEvent;
import 'package:shared_core/shared_core.dart';

import '../../login_page.dart';
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

/// Read seams so the notification badge/panel can be driven in a test
/// without a live Supabase session — this shell had none until a request to
/// actually prove (not just claim) that the badge and panel are wired to
/// real data rather than reading NotificationService directly with no way
/// to inject a fixture, the same pattern every other page in this app
/// (director_reports_page.dart's loadReports, director_cctv_page.dart's
/// listSchoolDevices, etc.) already uses.
typedef NotificationCategoriesLoader =
    Future<List<NotificationCategory>> Function();
typedef NotificationsLoader =
    Future<List<AppNotification>> Function(String? category);

class DirectorNavigationShell extends StatefulWidget {
  const DirectorNavigationShell({
    super.key,
    this.loadNotificationCategories,
    this.loadNotifications,
  });

  final NotificationCategoriesLoader? loadNotificationCategories;
  final NotificationsLoader? loadNotifications;

  @override
  State<DirectorNavigationShell> createState() =>
      _DirectorNavigationShellState();
}

class _DirectorNavigationShellState extends State<DirectorNavigationShell> {
  int selectedIndex = 0;

  // 'ตั้งค่า' stays in menuItems (so selectedIndex/_currentPage()'s switch
  // and the top bar's title lookup are all unchanged) but is no longer its
  // own row in the sidebar list — it's one of the two choices that unfurl
  // above the profile card instead (see _profileArea).
  static const int _settingsIndex = 11;

  // Whether the 'ตั้งค่า'/'ออกจากระบบ' rows above the profile card are open.
  bool _profileMenuExpanded = false;

  // Real unread count, loaded once on mount — same categories RPC
  // director_notifications_page.dart sums for its own badge. The red dot
  // used to be hardcoded on regardless of whether anything was unread.
  List<NotificationCategory> _notifCategories = const [];
  int get _unreadCount => _notifCategories.fold(0, (n, c) => n + c.unread);

  @override
  void initState() {
    super.initState();
    _loadNotificationBadge();
  }

  Future<void> _loadNotificationBadge() async {
    try {
      final categories =
          await (widget.loadNotificationCategories?.call() ??
              NotificationService.listCategories());
      if (!mounted) return;
      setState(() => _notifCategories = categories);
    } catch (e) {
      debugPrint('DirectorNavigationShell notification badge load failed: $e');
    }
  }

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

  List<int> get _visibleMenuIndices => [
    for (var i = 0; i < menuItems.length; i++)
      if (i != _settingsIndex) i,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1050;

    return Scaffold(
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
            if (isDesktop) SizedBox(width: 280, child: _sidebar()),
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
          // เดิม menuIndex 1 (ฉุกเฉิน) กับ 10 (แจ้งเตือน) hardcode เป็น 1/3
          // เสมอ ไม่เชื่อมข้อมูลจริงเลย — แจ้งเตือนใช้ _unreadCount ที่หน้านี้
          // โหลดจริงอยู่แล้ว (ตัวเดียวกับกระดิ่งบนเดสก์ท็อป) ส่วนฉุกเฉินยังไม่มี
          // จำนวนจริงให้ใช้ในชั้นนี้ เลยไม่ใส่ badge แทนที่จะใส่เลขปลอม
          badge: shortcut.menuIndex == 10 && _unreadCount > 0
              ? _unreadCount
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
          MaterialPageRoute<void>(builder: (_) => const DirectorScanPage()),
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
        if (isDesktop)
          IconButton(
            tooltip: 'สแกน / ค้นหาอุปกรณ์',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DirectorScanPage()),
            ),
          ),
        _searchTrigger(),
        const SizedBox(width: 8),
        _notificationBell(),
        if (isDesktop) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.border),
            ),
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: AppPalette.primaryPink,
              child: Icon(Icons.person_rounded, size: 17, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  /// V3: command palette (Spotlight/⌘K style) instead of an inline
  /// expanding bar — a floating dialog near the top of the screen, live
  /// filtering as you type, arrow keys + Enter to pick, click works too.
  /// Same quick-nav scope as before (menuItems titles), plus 'ออกจากระบบ' as
  /// a second real command, matching the picked mockup.
  Widget _searchTrigger() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showCommandPalette(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.border),
        ),
        child: const Icon(Icons.search_rounded, size: 20),
      ),
    );
  }

  Future<void> _showCommandPalette(BuildContext context) async {
    final actions = <_PaletteAction>[
      for (final item in menuItems)
        _PaletteAction(
          title: item.title,
          icon: item.icon,
          hint: 'ไปหน้านี้',
          section: 'เมนู',
          onSelect: () =>
              setState(() => selectedIndex = menuItems.indexOf(item)),
        ),
      _PaletteAction(
        title: 'ออกจากระบบ',
        icon: Icons.logout_rounded,
        hint: 'ดำเนินการ',
        section: 'คำสั่ง',
        danger: true,
        onSelect: () => _confirmSignOut(context),
      ),
    ];

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => _CommandPalette(actions: actions),
    );
  }

  Widget _notificationBell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showNotificationsPanel(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.border),
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 20),
          ),
        ),
        if (_unreadCount > 0)
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
    );
  }

  Future<void> _showNotificationsPanel(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => _NotificationsPreview(
        loadNotifications: widget.loadNotifications,
        onOpenAll: () {
          Navigator.of(dialogContext).pop();
          setState(() => selectedIndex = 10);
        },
      ),
    );
    // The panel may have marked things read on the full page in the
    // background of a previous visit; cheap to refresh the badge here too.
    unawaited(_loadNotificationBadge());
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
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AIoT Smart Lab',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ศูนย์ควบคุมสำหรับผู้อำนวยการ',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
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
              itemCount: _visibleMenuIndices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, position) {
                final index = _visibleMenuIndices[position];
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppPalette.primaryPinkSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppPalette.primaryPink
                                : AppPalette.sidebarIconBg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: selected
                                ? Colors.white
                                : AppPalette.sidebarIcon,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selected
                                  ? AppPalette.primaryPinkDark
                                  : AppPalette.textDark,
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
          _profileArea(closeOnTap: closeOnTap),
        ],
      ),
    );
  }

  /// The 'ตั้งค่า'/'ออกจากระบบ' rows unfurl upward above the profile card
  /// instead of a floating menu — the card sits at the very bottom of the
  /// sidebar, so there's more room above it than below, and a popover there
  /// tends to feel like it's escaping the sidebar rather than being part of
  /// it. Collapsed by default so it costs no space until tapped.
  Widget _profileArea({required bool closeOnTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.bottomCenter,
          curve: Curves.easeOut,
          child: !_profileMenuExpanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      _profileMenuRow(
                        icon: Icons.settings_outlined,
                        label: 'ตั้งค่า',
                        onTap: () {
                          setState(() {
                            selectedIndex = _settingsIndex;
                            _profileMenuExpanded = false;
                          });
                          if (closeOnTap && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      _profileMenuRow(
                        icon: Icons.logout_rounded,
                        label: 'ออกจากระบบ',
                        danger: true,
                        onTap: () async {
                          setState(() => _profileMenuExpanded = false);
                          await _confirmSignOut(context);
                        },
                      ),
                    ],
                  ),
                ),
        ),
        _sidebarProfile(),
      ],
    );
  }

  Widget _profileMenuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    // Icon sits in its own tinted box — same treatment every other icon row
    // in this app uses (director_settings_page.dart's security tiles,
    // director_reports_page.dart's stat rail, etc.) — a bare icon on a
    // plain white row read as unfinished next to the tinted rows around it.
    final accent = danger ? AppPalette.danger : AppPalette.primaryPinkDark;
    final boxColor = danger
        ? AppPalette.tint(AppPalette.danger, 0.10)
        : AppPalette.primaryPinkSoft;
    final textColor = danger ? AppPalette.danger : AppPalette.textDark;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarProfile() {
    // Was a hardcoded 'ผู้อำนวยการโรงเรียน' shown to every director.
    final name = currentUserModel?.name.trim().isNotEmpty == true
        ? currentUserModel!.name
        : 'ผู้อำนวยการ';
    final settingsSelected = selectedIndex == _settingsIndex;

    return Material(
      color: settingsSelected
          ? AppPalette.primaryPink
          : AppPalette.primaryPinkSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            setState(() => _profileMenuExpanded = !_profileMenuExpanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: settingsSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppPalette.primaryPink,
                child: Icon(Icons.person_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: settingsSelected ? Colors.white : null,
                      ),
                    ),
                    Text(
                      'Director',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: settingsSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _profileMenuExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: settingsSelected ? Colors.white : AppPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppPalette.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
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

/// Real preview — same `list_my_notifications_in_category` RPC
/// director_notifications_page.dart uses, just capped to the 4 most recent
/// client-side. Same category → color/icon mapping as that page's
/// `_categoryColor`/`_bentoCategoryIcon`, duplicated locally since those are
/// private to that State class.
class _NotificationsPreview extends StatefulWidget {
  const _NotificationsPreview({
    required this.onOpenAll,
    this.loadNotifications,
  });
  final VoidCallback onOpenAll;
  final NotificationsLoader? loadNotifications;

  @override
  State<_NotificationsPreview> createState() => _NotificationsPreviewState();
}

class _NotificationsPreviewState extends State<_NotificationsPreview> {
  List<AppNotification>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = List<AppNotification>.of(
        await (widget.loadNotifications?.call(null) ??
            NotificationService.listInCategory(null)),
      );
      rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() => _items = rows.take(4).toList());
    } catch (e) {
      debugPrint('DirectorNavigationShell notification preview failed: $e');
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  Color _categoryColor(String category) => switch (category) {
    'meeting' => AppPalette.learningBlueDark,
    'request' => AppPalette.warning,
    'incident' => AppPalette.danger,
    'learning' => AppPalette.success,
    _ => AppPalette.textMuted,
  };

  IconData _categoryIcon(String category) => switch (category) {
    'meeting' => Icons.groups_rounded,
    'request' => Icons.assignment_outlined,
    'incident' => Icons.warning_amber_rounded,
    'learning' => Icons.school_outlined,
    _ => Icons.notifications_none,
  };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม. ที่แล้ว';
    if (diff.inDays < 2) return 'เมื่อวาน';
    return '${diff.inDays} วันที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    // Same glassmorphic language as _showTeacherNotificationPreview
    // (teacher_redesign_prototype_page.dart) — blurred backdrop, translucent
    // white card, anchored top-right — per an explicit request to reuse
    // that look here too, after the search dialog already got it.
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
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.textDark.withValues(alpha: 0.14),
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
                              color: AppPalette.textDark,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppPalette.textDark,
                          tooltip: 'ปิด',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_items == null && !_failed)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (_failed)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'โหลดการแจ้งเตือนไม่สำเร็จ',
                            style: TextStyle(
                              color: AppPalette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else if (_items!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'ยังไม่มีการแจ้งเตือน',
                            style: TextStyle(
                              color: AppPalette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final item in _items!)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _categoryColor(
                                    item.category ?? 'other',
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _categoryIcon(item.category ?? 'other'),
                                  size: 18,
                                  color: _categoryColor(
                                    item.category ?? 'other',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppPalette.textDark,
                                        fontSize: 12.5,
                                        fontWeight: item.isUnread
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                      ),
                                    ),
                                    if (item.body != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.body!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppPalette.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      _relativeTime(item.createdAt),
                                      style: const TextStyle(
                                        color: AppPalette.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.isUnread)
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 4,
                                    left: 4,
                                  ),
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppPalette.primaryPink,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: widget.onOpenAll,
                        icon: const Icon(Icons.notifications_rounded, size: 18),
                        label: const Text('ดูการแจ้งเตือนทั้งหมด'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppPalette.primaryPinkDark,
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
  }
}

class _PaletteAction {
  const _PaletteAction({
    required this.title,
    required this.icon,
    required this.hint,
    required this.section,
    required this.onSelect,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final String hint;
  final String section;
  final VoidCallback onSelect;
  final bool danger;
}

/// Restyled to match the glassmorphic search dialog already shipped on the
/// teacher lane (`_showTeacherSearchDialog` in
/// teacher_redesign_prototype_page.dart) per an explicit request to reuse
/// that look here — blurred backdrop, translucent white card anchored near
/// the top, grey search field with a clear button, quick-pick chips, and
/// results grouped into labelled sections instead of one flat list.
/// Live filtering and arrow-key/Enter/Escape navigation are kept from the
/// palette this replaced. Arrow/Enter/Escape are caught by an ANCESTOR
/// `Focus.onKeyEvent` that lets everything else bubble through to the
/// TextField's own (separate) focus node — sharing one FocusNode between a
/// KeyboardListener and the TextField it wraps crashes with "Tried to make
/// a child into a parent of itself" (focus_manager.dart), since both
/// widgets try to attach the same node as their own scope.
class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.actions});
  final List<_PaletteAction> actions;

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  int _selected = 0;

  List<_PaletteAction> get _filtered {
    if (_query.isEmpty) return widget.actions;
    final q = _query.toLowerCase();
    return widget.actions
        .where((a) => a.title.toLowerCase().contains(q))
        .toList();
  }

  /// Same items, grouped by section and in that order — 'เมนู' rows first,
  /// then 'คำสั่ง' — with the section header dropped whenever a group is
  /// empty for the current query.
  Map<String, List<_PaletteAction>> get _grouped {
    final result = <String, List<_PaletteAction>>{};
    for (final action in _filtered) {
      result.putIfAbsent(action.section, () => []).add(action);
    }
    return result;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _choose(_PaletteAction action) {
    Navigator.of(context).pop();
    action.onSelect();
  }

  void _setQuery(String value) {
    setState(() {
      _query = value;
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      _selected = 0;
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final items = _filtered;
    if (items.isEmpty) return KeyEventResult.ignored;
    final current = _selected.clamp(0, items.length - 1);

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selected = (current + 1) % items.length);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _selected = (current - 1 + items.length) % items.length);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _choose(items[current]);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final grouped = _grouped;
    final selected = items.isEmpty ? 0 : _selected.clamp(0, items.length - 1);
    // Index within the flat filtered list that each grouped row corresponds
    // to, so keyboard selection still lines up once rows are split by
    // section header.
    var cursor = 0;

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
      child: Focus(
        onKeyEvent: _handleKey,
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
                    color: AppPalette.textDark.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
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
                              'ค้นหาเมนูและคำสั่ง 🔍',
                              style: TextStyle(
                                color: AppPalette.textDark,
                                fontSize: 18.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: AppPalette.textDark,
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
                            color: AppPalette.pageBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppPalette.border),
                          ),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            style: const TextStyle(
                              color: AppPalette.textDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppPalette.pageBg,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              border: InputBorder.none,
                              hintText: 'ค้นหาเมนู หรือคำสั่ง...',
                              hintStyle: const TextStyle(
                                color: AppPalette.textMuted,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 14, right: 8),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: AppPalette.textMuted,
                                  size: 18,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: AppPalette.textMuted,
                                      ),
                                      onPressed: () => _setQuery(''),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onChanged: _setQuery,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final chip in widget.actions.take(4))
                            _PaletteChip(
                              label: chip.title,
                              icon: chip.icon,
                              selected:
                                  _query.toLowerCase() ==
                                  chip.title.toLowerCase(),
                              onTap: () => _setQuery(chip.title),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: items.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'ไม่พบผลลัพธ์',
                                    style: TextStyle(
                                      color: AppPalette.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final entry in grouped.entries) ...[
                                      _PaletteSectionLabel(entry.key),
                                      for (final action in entry.value)
                                        _PaletteRow(
                                          action: action,
                                          active: (cursor++) == selected,
                                          onTap: () => _choose(action),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
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
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppPalette.primaryPinkSoft : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppPalette.primaryPink : AppPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? AppPalette.primaryPinkDark
                  : AppPalette.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppPalette.primaryPinkDark
                    : AppPalette.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteSectionLabel extends StatelessWidget {
  const _PaletteSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 0, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppPalette.textMuted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.action,
    required this.active,
    required this.onTap,
  });

  final _PaletteAction action;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = action.danger
        ? AppPalette.danger
        : AppPalette.primaryPinkDark;

    return Material(
      color: active ? AppPalette.primaryPinkSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: action.danger
                        ? AppPalette.danger
                        : AppPalette.textDark,
                  ),
                ),
              ),
              Text(
                action.hint,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
