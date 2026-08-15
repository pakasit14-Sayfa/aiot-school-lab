// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง สร้าง
// เพื่อให้ facility_building_overview_page.dart มีปลายทางนำทางจริงตาม
// สเปกข้อ 3/10 ("นำทางไปหน้าประวัติการสั่งงาน")
import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';

class _CommandLogEntry {
  const _CommandLogEntry({
    required this.action,
    required this.location,
    required this.actor,
    required this.time,
    required this.icon,
  });

  final String action;
  final String location;
  final String actor;
  final String time;
  final IconData icon;
}

class FacilityCommandHistoryPage extends StatelessWidget {
  const FacilityCommandHistoryPage({super.key});

  static const _mockLog = [
    _CommandLogEntry(
      action: 'เปิดไฟ',
      location: 'อาคาร 3 ชั้น 1',
      actor: 'ครูสมชาย ใจดี',
      time: '14/08/2569 08:12 น.',
      icon: Icons.lightbulb_rounded,
    ),
    _CommandLogEntry(
      action: 'ปิดน้ำ',
      location: 'อาคาร 3 ห้องปฏิบัติการ',
      actor: 'ครูสมชาย ใจดี',
      time: '14/08/2569 08:10 น.',
      icon: Icons.water_drop_rounded,
    ),
    _CommandLogEntry(
      action: 'ปิดไฟ',
      location: 'อาคาร 3 โถงทางเดิน',
      actor: 'ครูสมชาย ใจดี',
      time: '13/08/2569 18:32 น.',
      icon: Icons.lightbulb_outline_rounded,
    ),
    _CommandLogEntry(
      action: 'เปิดน้ำ',
      location: 'อาคาร 3 ชั้น 2',
      actor: 'ครูภานุพงศ์',
      time: '13/08/2569 07:45 น.',
      icon: Icons.water_drop_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacilityTheme.bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: FacilityTheme.inkIndigo,
        title: const Text(
          'ประวัติการสั่งงาน',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _mockLog.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = _mockLog[index];
            return FacilityGlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: FacilityTheme.lightPurpleBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      entry.icon,
                      size: 18,
                      color: FacilityTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.action} · ${entry.location}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: FacilityTheme.inkIndigo,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.actor} · ${entry.time}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: FacilityTheme.softMauve,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
