import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> notifications = [];
  bool isLoading = true;
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'ทั้งหมด',
    'ยังไม่อ่าน',
    'การบ้าน',
    'คะแนน',
    'ประกาศ',
  ];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() => isLoading = true);
    try {
      final result = await NotificationService.listMyNotifications();
      if (mounted) setState(() => notifications = result);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openNotification(AppNotification notification) async {
    if (notification.isUnread) {
      await NotificationService.markNotificationRead(notification.id);
      await loadNotifications();
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม. ที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
            tooltip: 'รีเฟรช',
            onPressed: loadNotifications,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Segment Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    return ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilterIndex = index);
                        }
                      },
                      selectedColor: const Color.fromARGB(255, 28, 127, 70),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: isSelected
                              ? const Color.fromARGB(255, 28, 127, 70)
                              : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Body Content
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 28, 127, 70),
                        strokeWidth: 2.5,
                      ),
                    )
                  : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    // Demo Notification Items if backend array is empty
    final displayItems = notifications.isNotEmpty
        ? notifications
        : _getDemoNotifications();

    if (displayItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        return _buildNotificationCardItem(item);
      },
    );
  }

  Widget _buildNotificationCardItem(dynamic item) {
    String title = '';
    String body = '';
    DateTime time = DateTime.now();
    bool isUnread = false;
    IconData icon = Icons.notifications_rounded;
    Color iconBg = const Color(0xFF0284C7);

    if (item is AppNotification) {
      title = item.title;
      body = item.body ?? '';
      time = item.createdAt;
      isUnread = item.isUnread;
    } else if (item is Map<String, dynamic>) {
      title = item['title'] ?? '';
      body = item['body'] ?? '';
      time = item['time'] ?? DateTime.now();
      isUnread = item['unread'] ?? false;
      icon = item['icon'] ?? Icons.notifications_rounded;
      iconBg = item['bg'] ?? const Color(0xFF0284C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? const Color.fromARGB(255, 28, 127, 70).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: isUnread ? 1.2 : 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (item is AppNotification) {
              openNotification(item);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Squircle Icon Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: iconBg.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                // Text Content
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
                              style: TextStyle(
                                color: const Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: isUnread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(time),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 28, 127, 70),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                color: Color(0xFF94A3B8),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่มีการแจ้งเตือนค้างอยู่',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'คุณอัปเดตการแจ้งเตือนทั้งหมดแล้ว เรียบร้อยดีมาก!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDemoNotifications() {
    return [
      {
        'title': 'การบ้านบทเรียนที่ 4 ครบกำหนดส่งพรุ่งนี้',
        'body': 'วิชา AIoT สมาร์ตแล็บ • ม.5/1 (อย่าลืมส่งก่อนเวลา 23:59 น.)',
        'time': DateTime.now().subtract(const Duration(minutes: 10)),
        'unread': true,
        'icon': Icons.assignment_rounded,
        'bg': const Color(0xFF0284C7),
      },
      {
        'title': 'บันทึกคะแนนสอบกลางภาควิชา AIoT สำเร็จ',
        'body': 'คุณได้รับคะแนน 92/100 (ระดับดีเยี่ยม) ยินดีด้วย!',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'unread': true,
        'icon': Icons.emoji_events_rounded,
        'bg': const Color(0xFFD97706),
      },
      {
        'title': 'แจ้งกำหนดการสอบประเมินสมรรถนะดิจิทัล',
        'body': 'โรงเรียนวิทยาศาสตร์ประจำภูมิภาค ขอให้นักเรียนเตรียมความพร้อม',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'unread': false,
        'icon': Icons.campaign_rounded,
        'bg': const Color.fromARGB(255, 28, 127, 70),
      },
      {
        'title': 'ครูสมชาย ได้อัปเดตสื่อการเรียนรู้ใหม่',
        'body': 'เพิ่มเอกสารประกอบการสอน สไลด์บทเรียนที่ 5 เรียบร้อยแล้ว',
        'time': DateTime.now().subtract(const Duration(days: 2)),
        'unread': false,
        'icon': Icons.folder_special_rounded,
        'bg': const Color(0xFF8B5CF6),
      },
    ];
  }
}
