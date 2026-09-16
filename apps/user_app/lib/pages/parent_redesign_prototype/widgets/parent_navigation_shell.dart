import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../pages/parent/parent_dashboard_page.dart';
import '../pages/parent/parent_learning_page.dart';
import '../pages/parent/parent_attendance_page.dart';
import '../pages/parent/parent_academic_calendar_page.dart';
import '../pages/parent/parent_schedule_page.dart';
import '../pages/parent/parent_messages_page.dart';
import '../pages/parent/parent_settings_page.dart';

typedef ParentPagesBuilder =
    List<Widget> Function(
      String? selectedStudentId,
      ValueChanged<LinkedStudentItem> onStudentSelected,
    );

class ParentNavigationShell extends StatefulWidget {
  final ParentPagesBuilder? pagesBuilder;

  /// seam สำหรับเทสต์ — production ใช้ NotificationService.listMyNotifications
  /// / markNotificationRead
  final Future<List<AppNotification>> Function()? loadNotifications;
  final Future<void> Function(String notificationId)? markNotificationRead;

  const ParentNavigationShell({
    super.key,
    this.pagesBuilder,
    this.loadNotifications,
    this.markNotificationRead,
  });

  @override
  State<ParentNavigationShell> createState() => _ParentNavigationShellState();
}

class _ParentNavigationShellState extends State<ParentNavigationShell> {
  int selectedIndex = 0;
  LinkedStudentItem? _selectedStudent;

  // กระดิ่งบน AppBar เคยเป็น `onPressed: () {}` พร้อมจุดแดงถาวร — ผู้ปกครอง
  // ทุกคนเห็น "มีแจ้งเตือนใหม่" ตลอดเวลาโดยกดแล้วไม่มีอะไรเกิดขึ้น ตอนนี้
  // จุดแดงมาจากจำนวนที่ยังไม่อ่านจริง และกดแล้วเปิดรายการจริง
  List<AppNotification> _notifications = const [];
  bool _notificationsFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await (widget.loadNotifications ??
          NotificationService.listMyNotifications)();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _notificationsFailed = false;
      });
    } catch (e) {
      debugPrint('ParentNavigationShell: โหลดการแจ้งเตือนไม่สำเร็จ — $e');
      if (!mounted) return;
      setState(() => _notificationsFailed = true);
    }
  }

  int get _unreadCount => _notifications.where((n) => n.readAt == null).length;

  /// แตะรายการ = อ่านแล้ว: เขียนผ่าน mark_notification_read แล้วอ่านรายการ
  /// กลับ — จุดแดงจึงหายเมื่อหลังบ้านยืนยันว่าอ่านแล้วจริง ไม่ใช่แค่ในเครื่อง
  Future<bool> _markRead(String id) async {
    try {
      await (widget.markNotificationRead ??
          NotificationService.markNotificationRead)(id);
      await _loadNotifications();
      return true;
    } catch (e) {
      debugPrint('ParentNavigationShell: mark_notification_read ล้ม — $e');
      return false;
    }
  }

  Future<void> _openNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // สร้าง sheet ใหม่ทุกครั้งที่ state ของ shell เปลี่ยน (หลัง mark read)
      // เพื่อให้แถวที่เพิ่งแตะเปลี่ยนเป็น "อ่านแล้ว" ทันทีในแผ่นเดียวกัน
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheet) => _ParentNotificationSheet(
          notifications: _notifications,
          failed: _notificationsFailed,
          onRetry: _loadNotifications,
          onTap: (n) async {
            if (n.readAt != null) return;
            final ok = await _markRead(n.id);
            if (!sheetContext.mounted) return;
            if (ok) {
              setSheet(() {});
            } else {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  content: Text('บันทึกว่าอ่านแล้วไม่สำเร็จ กรุณาลองใหม่'),
                ),
              );
            }
          },
        ),
      ),
    );
    // โหลดใหม่หลังปิดแผ่น เผื่อมีรายการใหม่เข้ามาระหว่างที่เปิดอยู่
    await _loadNotifications();
  }

  List<Widget> get pages {
    final customPages = widget.pagesBuilder?.call(
      _selectedStudent?.studentId,
      _selectStudent,
    );
    if (customPages != null) {
      assert(customPages.length == 7);
      return customPages;
    }
    return [
      ParentDashboardPage(
        selectedStudentId: _selectedStudent?.studentId,
        onStudentSelected: _selectStudent,
      ),
      ParentLearningPage(
        selectedStudentId: _selectedStudent?.studentId,
        onStudentSelected: _selectStudent,
      ),
      ParentAttendancePage(
        selectedStudentId: _selectedStudent?.studentId,
        onStudentSelected: _selectStudent,
      ),
      ParentAcademicCalendarPage(
        selectedStudentId: _selectedStudent?.studentId,
        onStudentSelected: _selectStudent,
      ),
      ParentSchedulePage(
        selectedStudentId: _selectedStudent?.studentId,
        onStudentSelected: _selectStudent,
      ),
      const ParentMessagesPage(),
      const ParentSettingsPage(),
    ];
  }

  void _selectStudent(LinkedStudentItem student) {
    if (student.studentId == _selectedStudent?.studentId) return;
    setState(() => _selectedStudent = student);
  }

  final items = const [
    _NavItem('ภาพรวม', Icons.dashboard_rounded),
    _NavItem('การเรียน', Icons.menu_book_rounded),
    _NavItem('การมาเรียน', Icons.fact_check_rounded),
    _NavItem('ปฏิทินวิชาการ', Icons.calendar_month_rounded),
    _NavItem('ตาราง / การบ้าน', Icons.event_note_rounded),
    _NavItem('ข้อความ', Icons.chat_bubble_rounded),
    _NavItem('ตั้งค่า', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 820;

        if (mobile) {
          return _buildMobileLayout();
        }

        return _buildDesktopLayout();
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      drawer: _buildMobileDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'เปิดเมนู',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(
                Icons.menu_rounded,
                size: 27,
                color: Color(0xFF243044),
              ),
            );
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                items[selectedIndex].icon,
                size: 18,
                color: const Color(0xFF2867B2),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    items[selectedIndex].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF202A3A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Parent Portal',
                    style: TextStyle(color: Color(0xFF8A94A6), fontSize: 8.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'การแจ้งเตือน',
            onPressed: _openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF536071),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDF5660),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 19,
                color: Color(0xFF2867B2),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EBF1)),
        ),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFF7F7FB),
        surfaceTintColor: const Color(0xFFF7F7FB),
        height: 74,
        selectedIndex: selectedIndex <= 3 ? selectedIndex : 4,
        onDestinationSelected: (index) {
          if (index < 4) {
            setState(() {
              selectedIndex = index;
            });
          } else {
            _showMoreMenu();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'ภาพรวม',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'การเรียน',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'มาเรียน',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'ปฏิทิน',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_rounded),
            label: 'เพิ่มเติม',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      width: 285,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F8FD),
                border: Border(bottom: BorderSide(color: Color(0xFFE7EBF2))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA23A), Color(0xFFFF7436)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.family_restroom_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parent Portal',
                              style: TextStyle(
                                color: Color(0xFF202A3A),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'AIoT Smart School',
                              style: TextStyle(
                                color: Color(0xFF8791A3),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5EAF1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: Color(0xFFEAF3FF),
                          child: Icon(
                            Icons.face_rounded,
                            color: Color(0xFF2867B2),
                          ),
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStudent?.fullName ??
                                    'ยังไม่ได้เลือกนักเรียน',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _selectedStudent?.relationship ??
                                    'เลือกจากหน้าข้อมูลนักเรียน',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: Color(0xFF8A94A6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 15, 12, 15),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final active = selectedIndex == index;

                  return Material(
                    color: active
                        ? const Color(0xFFEAF3FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFD9EAFE)
                                    : const Color(0xFFF3F5F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color: active
                                    ? const Color(0xFF2867B2)
                                    : const Color(0xFF687486),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: active
                                      ? const Color(0xFF2867B2)
                                      : const Color(0xFF4E596A),
                                ),
                              ),
                            ),
                            if (active)
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFF2867B2),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA23A), Color(0xFFFF7436)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.family_restroom_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parent Portal',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'AIoT Smart School',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8A94A6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final active = selectedIndex == index;

                      return Material(
                        color: active
                            ? const Color(0xFFEAF3FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: active
                                      ? const Color(0xFF2867B2)
                                      : const Color(0xFF788497),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: active
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: active
                                          ? const Color(0xFF2867B2)
                                          : const Color(0xFF566173),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 5),
                    itemCount: items.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFE3ECF8),
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF2867B2),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ผู้ปกครอง',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _selectedStudent?.fullName ??
                                    'ยังไม่ได้เลือกนักเรียน',
                                style: TextStyle(
                                  color: Color(0xFF8A94A6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: const Color(0xFFE7EAF0)),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final moreIndexes = [4, 5, 6];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'เมนูเพิ่มเติม',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                for (final index in moreIndexes)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    leading: Icon(
                      items[index].icon,
                      color: const Color(0xFF2867B2),
                    ),
                    title: Text(
                      items[index].title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        selectedIndex = index;
                      });
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

class _NavItem {
  final String title;
  final IconData icon;

  const _NavItem(this.title, this.icon);
}

/// รายการแจ้งเตือนจริงของผู้ปกครอง (list_my_notifications) — ว่างบอกว่าว่าง
/// โหลดล้มบอกว่าล้ม ไม่มีรายการตัวอย่าง
class _ParentNotificationSheet extends StatelessWidget {
  const _ParentNotificationSheet({
    required this.notifications,
    required this.failed,
    required this.onRetry,
    required this.onTap,
  });

  final List<AppNotification> notifications;
  final bool failed;
  final Future<void> Function() onRetry;
  final Future<void> Function(AppNotification) onTap;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การแจ้งเตือน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF202A3A),
            ),
          ),
          const SizedBox(height: 10),
          if (failed)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'โหลดการแจ้งเตือนไม่สำเร็จ',
                    style: TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  child: const Text('ลองใหม่'),
                ),
              ],
            )
          else if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'ยังไม่มีการแจ้งเตือน',
                style: TextStyle(color: Color(0xFF8A94A6)),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onTap(n),
                    leading: Icon(
                      n.readAt == null
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: n.readAt == null
                          ? const Color(0xFFDF5660)
                          : const Color(0xFF8A94A6),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.readAt == null
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: n.body == null || n.body!.isEmpty
                        ? null
                        : Text(n.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
