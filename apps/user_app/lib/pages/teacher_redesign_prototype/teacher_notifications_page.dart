// PROTOTYPE: Teacher Notifications Center Page (ศูนย์รวมการแจ้งเตือนทั้งหมด)
// Wireframe MVP v1 Section 2.9.1
// Consolidates sensor alerts, emergency triggers, camera security events, and grading tasks into a unified notifications inbox with deep linking.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_aiot_dashboard_page.dart' show TeacherAiotDashboardPage;
import 'teacher_emergency_events_page.dart' show TeacherEmergencyEventsPage;
import 'teacher_grading_page.dart' show TeacherGradingPage;
import 'teacher_incident_inbox_page.dart' show TeacherIncidentInboxPage;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart' show TeacherMockPageShell;

/// Model สำหรับรายการแจ้งเตือนแต่ละประเภท
class NotificationItemModel {
  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category, // 'sensor', 'emergency', 'camera', 'grading'
    required this.timestamp,
    required this.isRead,
    required this.targetRoute,
  });

  String id;
  String title;
  String message;
  String category;
  String timestamp;
  bool isRead;
  String targetRoute;
}

/// ข้อมูลแจ้งเตือน mock ชุดเดียวที่ทั้งหน้าเต็ม (`TeacherNotificationsPage`)
/// และป็อปอัพตัวอย่างแจ้งเตือนแบบกระจกฝ้าบนแดชบอร์ดใช้ร่วมกัน กันไม่ให้
/// ข้อมูลไม่ตรงกันระหว่างสองที่
List<NotificationItemModel> mockTeacherNotifications() {
  return [
    NotificationItemModel(
      id: 'notif-1',
      title: '🚨 เกิดเหตุ SOS ฉุกเฉิน!',
      message:
          'ปุ่มกดกายภาพ PANIC-BTN-05B ถูกกดที่ ห้องปฏิบัติการเคมี (ห้อง 532)',
      category: 'emergency',
      timestamp: '14:22 น. (วันนี้)',
      isRead: false,
      targetRoute: 'emergency',
    ),
    NotificationItemModel(
      id: 'notif-2',
      title: '⚠️ ค่าดัชนีรังสี UV สูงเกินขอบเขต',
      message:
          'เซนเซอร์ AIoT-Node-01 ห้อง ม.5/2 ตรวจพบรังสี UV ระดับ 6 (เกินเกณฑ์สูงสุด UV 5)',
      category: 'sensor',
      timestamp: '13:45 น. (วันนี้)',
      isRead: false,
      targetRoute: 'aiot',
    ),
    NotificationItemModel(
      id: 'notif-3',
      title: '📝 มีนักเรียนส่งใบงานทดลองใหม่รอตรวจ 18 รายการ',
      message:
          'วิชา ม.5/2 การออกแบบเทคโนโลยี — ใบงานทดลองที่ 3 การวัดค่าฝุ่น PM2.5',
      category: 'grading',
      timestamp: '11:30 น. (วันนี้)',
      isRead: true,
      targetRoute: 'grading',
    ),
    NotificationItemModel(
      id: 'notif-4',
      title: '📷 กล้อง AI Security ตรวจพบความผิดปกติ',
      message: 'กล้องประตูหลังโรงเรียน ตรวจพบเคสความปลอดภัยรอการรีวิว',
      category: 'camera',
      timestamp: '09:10 น. (วันนี้)',
      isRead: true,
      targetRoute: 'camera',
    ),
  ];
}

class TeacherNotificationsPage extends StatefulWidget {
  const TeacherNotificationsPage({super.key});

  @override
  State<TeacherNotificationsPage> createState() =>
      _TeacherNotificationsPageState();
}

class _TeacherNotificationsPageState extends State<TeacherNotificationsPage> {
  String _selectedCategory =
      'ทั้งหมด'; // 'ทั้งหมด', 'ฉุกเฉิน/SOS', 'เซนเซอร์', 'ตรวจงาน'

  late List<NotificationItemModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = mockTeacherNotifications();
    _loadRealNotifications();
  }

  Future<void> _loadRealNotifications() async {
    try {
      final list = await NotificationService.listMyNotifications();
      if (!mounted || list.isEmpty) return;
      setState(() {
        _notifications = list.map((n) {
          return NotificationItemModel(
            id: n.id,
            title: n.title,
            message: n.body ?? '',
            category: n.type == 'emergency'
                ? 'emergency'
                : (n.type == 'sensor' ? 'sensor' : 'grading'),
            timestamp:
                '${n.createdAt.toLocal().toString().substring(11, 16)} น.',
            isRead: n.readAt != null,
            targetRoute: n.type == 'emergency'
                ? 'emergency'
                : (n.type == 'sensor' ? 'aiot' : 'grading'),
          );
        }).toList();
      });
    } catch (_) {}
  }

  void _handleNotificationTap(NotificationItemModel notif) {
    setState(() => notif.isRead = true);
    try {
      NotificationService.markNotificationRead(notif.id);
    } catch (_) {}

    if (notif.targetRoute == 'emergency') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherEmergencyEventsPage()),
      );
    } else if (notif.targetRoute == 'aiot') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherAiotDashboardPage()),
      );
    } else if (notif.targetRoute == 'grading') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherGradingPage()),
      );
    } else if (notif.targetRoute == 'camera') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherIncidentInboxPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เปิดรายละเอียด ${notif.title}'),
          backgroundColor: TeacherPalette.primary,
        ),
      );
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ทำรายการอ่านการแจ้งเตือนทั้งหมดเรียบร้อยแล้ว'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedCategory == 'ฉุกเฉิน/SOS') {
        return n.category == 'emergency';
      } else if (_selectedCategory == 'เซนเซอร์') {
        return n.category == 'sensor';
      } else if (_selectedCategory == 'ตรวจงาน') {
        return n.category == 'grading';
      }
      return true;
    }).toList();

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return TeacherMockPageShell(
      title: 'ศูนย์แจ้งเตือนรวม (Notifications)',
      activeMenuLabel: 'แจ้งเตือน',
      actions: [
        if (unreadCount > 0)
          TextButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('ทำเครื่องหมายว่าอ่านแล้วทั้งหมด'),
            style: TextButton.styleFrom(
              foregroundColor: TeacherPalette.primary,
            ),
          ),
      ],
      builder: (context, isDesktop) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Category Chips Bar
              Row(
                children: [
                  const Text(
                    'หมวดหมู่:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: TeacherPalette.muted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Wrap(
                    spacing: 8,
                    children: ['ทั้งหมด', 'ฉุกเฉิน/SOS', 'เซนเซอร์', 'ตรวจงาน']
                        .map(
                          (cat) => ChoiceChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _selectedCategory = cat);
                              }
                            },
                            selectedColor: TeacherPalette.primary.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: TextStyle(
                              color: _selectedCategory == cat
                                  ? TeacherPalette.primary
                                  : TeacherPalette.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: _selectedCategory == cat
                                  ? TeacherPalette.primary
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Notifications List Loop
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = filtered[index];

                  Color iconBgColor;
                  Color iconColor;
                  IconData iconData;

                  if (notif.category == 'emergency') {
                    iconBgColor = const Color(0xFFFEF2F2);
                    iconColor = const Color(0xFFDC2626);
                    iconData = Icons.emergency_rounded;
                  } else if (notif.category == 'sensor') {
                    iconBgColor = const Color(0xFFFFF7ED);
                    iconColor = const Color(0xFFEA580C);
                    iconData = Icons.warning_amber_rounded;
                  } else if (notif.category == 'grading') {
                    iconBgColor = const Color(0xFFF3E8FF);
                    iconColor = const Color(0xFF7E22CE);
                    iconData = Icons.assignment_rounded;
                  } else {
                    iconBgColor = const Color(0xFFEFF6FF);
                    iconColor = const Color(0xFF2563EB);
                    iconData = Icons.videocam_rounded;
                  }

                  return InkWell(
                    onTap: () => _handleNotificationTap(notif),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: notif.isRead
                            ? Colors.white
                            : const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: notif.isRead
                              ? TeacherPalette.border
                              : const Color(0xFFE9D5FF),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x060F172A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconData, color: iconColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: notif.isRead
                                              ? FontWeight.w800
                                              : FontWeight.w900,
                                          color: TeacherPalette.ink,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: TeacherPalette.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.message,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: TeacherPalette.muted,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notif.timestamp,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
