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
          itemCount: _mockLog.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FacilityResponsiveGrid(
                  spacing: 12,
                  minItemWidth: 160,
                  children: [
                    _buildStatCard(
                      icon: Icons.history_rounded,
                      label: 'รายการทั้งหมด',
                      value: '${_mockLog.length} รายการ',
                      color: FacilityTheme.primaryPurple,
                      bg: FacilityTheme.lightPurpleBg,
                    ),
                    _buildStatCard(
                      icon: Icons.access_time_rounded,
                      label: 'ล่าสุดเมื่อ',
                      value: _mockLog.first.time,
                      color: FacilityTheme.warningOrange,
                      bg: const Color(0xFFFFFBEB),
                    ),
                  ],
                ),
              );
            }
            final entry = _mockLog[index - 1];
            final isWater = entry.action.contains('น้ำ');
            final accentColor = isWater
                ? const Color(0xFF0284C7)
                : const Color(0xFFE8A519);
            final accentBg = isWater
                ? const Color(0xFFF0F9FF)
                : const Color(0xFFFFFBEB);
            return FacilityGlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(entry.icon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.action} · ${entry.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: FacilityTheme.inkIndigo,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.actor} · ${entry.time}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
