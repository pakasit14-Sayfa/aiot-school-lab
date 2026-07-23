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
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadNotifications),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text('ไม่มีการแจ้งเตือน', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: n.isUnread ? const Color(0xFFE8F5E9) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        onTap: () => openNotification(n),
                        leading: Icon(
                          n.isUnread ? Icons.circle_notifications : Icons.notifications_none,
                          color: n.isUnread ? const Color(0xFF2E7D32) : Colors.grey,
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: n.body != null && n.body!.isNotEmpty
                            ? Text(n.body!)
                            : null,
                        trailing: Text(
                          _formatTime(n.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
