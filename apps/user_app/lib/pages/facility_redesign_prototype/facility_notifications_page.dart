// เชื่อมกับ NotificationService จริงแล้ว (2026-08-17) — เดิม mock ล้วน
// list_my_notifications/mark_notification_read เป็น RPC ทั่วไปที่ทุก role
// เรียกได้ (ไม่ได้ scope เฉพาะผู้ดูแลอาคาร) จึงใช้ได้ตรงๆ ไม่ต้องเพิ่ม
// backend ใหม่
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'facility_shared_widgets.dart';

class FacilityNotificationsPage extends StatefulWidget {
  const FacilityNotificationsPage({super.key});

  @override
  State<FacilityNotificationsPage> createState() =>
      _FacilityNotificationsPageState();
}

class _FacilityNotificationsPageState extends State<FacilityNotificationsPage> {
  bool _loading = true;
  String? _loadError;
  List<AppNotification> _notifications = [];
  final Set<String> _markingRead = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final notifications = await NotificationService.listMyNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดการแจ้งเตือนไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.readAt != null || _markingRead.contains(n.id)) return;
    setState(() => _markingRead.add(n.id));
    try {
      await NotificationService.markNotificationRead(n.id);
      await _load();
    } catch (_) {
      // เงียบไว้ — ไม่ใช่ action ที่ critical พอจะรบกวนผู้ใช้ด้วย error
    } finally {
      if (mounted) setState(() => _markingRead.remove(n.id));
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => n.readAt == null).toList();
    setState(() => _markingRead.addAll(unread.map((n) => n.id)));
    for (final n in unread) {
      try {
        await NotificationService.markNotificationRead(n.id);
      } catch (_) {
        // ทำต่อรายการอื่นแม้บางรายการล้มเหลว
      }
    }
    await _load();
  }

  ({IconData icon, Color color}) _iconFor(String type) {
    switch (type) {
      case 'incident':
      case 'device_alert':
        return (
          icon: Icons.report_problem_rounded,
          color: FacilityTheme.emergencyRed,
        );
      case 'warning':
      case 'sensor_alert':
        return (
          icon: Icons.warning_amber_rounded,
          color: FacilityTheme.warningOrange,
        );
      case 'device_command':
        return (
          icon: Icons.check_circle_rounded,
          color: FacilityTheme.safeGreen,
        );
      default:
        return (
          icon: Icons.notifications_rounded,
          color: FacilityTheme.primaryPurple,
        );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n.readAt == null).length;

    return Scaffold(
      backgroundColor: FacilityTheme.bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: FacilityTheme.inkIndigo,
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'อ่านทั้งหมดแล้ว',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: FacilityTheme.primaryPurple,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: FacilityTheme.primaryPurple,
                ),
              )
            : _loadError != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loadError!,
                      style: const TextStyle(
                        color: FacilityTheme.emergencyRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              )
            : _notifications.isEmpty
            ? const Center(
                child: Text(
                  'ยังไม่มีการแจ้งเตือน',
                  style: TextStyle(
                    color: FacilityTheme.softMauve,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: FacilityResponsiveGrid(
                      spacing: 12,
                      minItemWidth: 160,
                      children: [
                        _buildStatCard(
                          icon: Icons.notifications_active_rounded,
                          label: 'แจ้งเตือนทั้งหมด',
                          value: '${_notifications.length} รายการ',
                          color: FacilityTheme.primaryPurple,
                          bg: FacilityTheme.lightPurpleBg,
                        ),
                        _buildStatCard(
                          icon: Icons.mark_email_unread_rounded,
                          label: 'ยังไม่ได้อ่าน',
                          value: '$unreadCount รายการ',
                          color: unreadCount > 0
                              ? FacilityTheme.emergencyRed
                              : FacilityTheme.safeGreen,
                          bg: unreadCount > 0
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFECFDF5),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final isRead = n.readAt != null;
                        final iconInfo = _iconFor(n.type);
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _markRead(n),
                          child: FacilityGlassCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 18,
                            backgroundColor: isRead
                                ? Colors.white.withValues(alpha: 0.7)
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: iconInfo.color,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    iconInfo.icon,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: FacilityTheme.inkIndigo,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                left: 6,
                                              ),
                                              decoration: const BoxDecoration(
                                                color:
                                                    FacilityTheme.emergencyRed,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (n.body != null &&
                                          n.body!.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          n.body!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: FacilityTheme.softMauve,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 3),
                                      Text(
                                        _timeAgo(n.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FacilityTheme.softMauve,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
