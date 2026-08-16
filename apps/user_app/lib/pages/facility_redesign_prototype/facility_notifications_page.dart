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
                                  child: Icon(
                                    n.icon,
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
                                      const SizedBox(height: 3),
                                      Text(
                                        n.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
