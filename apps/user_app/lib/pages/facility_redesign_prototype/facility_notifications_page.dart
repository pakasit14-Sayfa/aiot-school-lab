// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก
// NotificationService.listMyNotifications จริง — สร้างเพื่อแทนที่ popup
// ข้อความเดียวเดิม ตามสเปกข้อ 6.1 ที่ต้องการ "หน้า" การแจ้งเตือนจริง
// (เปิดหน้า → ดึงรายการ → กดทำเครื่องหมายว่าอ่านแล้วได้)
import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';

class _FacilityNotification {
  _FacilityNotification({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconBg,
    this.isRead = false,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconBg;
  bool isRead;
}

class FacilityNotificationsPage extends StatefulWidget {
  const FacilityNotificationsPage({super.key});

  @override
  State<FacilityNotificationsPage> createState() =>
      _FacilityNotificationsPageState();
}

class _FacilityNotificationsPageState extends State<FacilityNotificationsPage> {
  // 2026-08-15: 2 รายการเดิมในนี้ผิดสโคป — (1) "SOS ฉุกเฉินจากห้อง 302"
  // เป็นเหตุฉุกเฉินบุคคลที่สื่อว่าผู้ดูแลอาคารต้อง "รับเรื่อง" ได้ ขัดกับ
  // STK-12 Exception ข้อ 1 (2) "เปิดอาคาร 3 เรียบร้อยแล้ว" อ้างอิงฟีเจอร์
  // checklist wizard เดิมที่ถูกแทนที่ด้วยควบคุมไฟ/น้ำ STK-11 ไปแล้วเมื่อ
  // 2026-08-14 (ดู NOTES.md) — เปลี่ยนทั้งคู่ให้ตรงกับฟีเจอร์ปัจจุบัน
  final List<_FacilityNotification> _notifications = [
    _FacilityNotification(
      title: 'แจ้งเหตุอุปกรณ์ใหม่: แอร์ห้อง 210 ผิดปกติ',
      subtitle: 'อาคาร 3 ชั้น 2 · ยังไม่มีผู้รับเรื่อง (STK-12)',
      time: '2 นาทีที่แล้ว',
      icon: Icons.report_problem_rounded,
      iconBg: FacilityTheme.emergencyRed,
    ),
    _FacilityNotification(
      title: 'ค่า PM2.5 สูงเกินมาตรฐาน (78 µg/m³)',
      subtitle: 'อาคาร 3 ห้อง 302 · เฝ้าระวัง',
      time: '15 นาทีที่แล้ว',
      icon: Icons.warning_amber_rounded,
      iconBg: FacilityTheme.warningOrange,
    ),
    _FacilityNotification(
      title: 'ปิดไฟอาคาร 3 ทั้งหมดเรียบร้อยแล้ว',
      subtitle: 'อาคาร 3 ทั้งหมด · โดย ผู้ดูแลอาคาร (STK-11)',
      time: '45 นาทีที่แล้ว',
      icon: Icons.check_circle_rounded,
      iconBg: FacilityTheme.safeGreen,
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

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
              onPressed: () {
                setState(() {
                  for (final n in _notifications) {
                    n.isRead = true;
                  }
                });
              },
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
        child: _notifications.isEmpty
            ? const Center(
                child: Text(
                  'ยังไม่มีการแจ้งเตือน',
                  style: TextStyle(
                    color: FacilityTheme.softMauve,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => n.isRead = true),
                    child: FacilityGlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 18,
                      backgroundColor: n.isRead
                          ? Colors.white.withValues(alpha: 0.7)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: n.iconBg,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(n.icon, color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: n.isRead
                                              ? FontWeight.w600
                                              : FontWeight.w800,
                                          color: FacilityTheme.inkIndigo,
                                        ),
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: const BoxDecoration(
                                          color: FacilityTheme.emergencyRed,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  n.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: FacilityTheme.softMauve,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  n.time,
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
    );
  }
}
