// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
// STK-9: "ดูสถานะสุขภาพอุปกรณ์ AIoT ในอาคาร" (จาก DEV-15)
//
// เป็น Widget content ต่อกับ FacilityAppShell เดิม (ไม่มี Scaffold/AppBar
// เป็นของตัวเอง) ใช้เป็น nav item index 9 ได้โดยตรง — ถ้าจะ Navigator.push
// จากที่อื่น (เช่นปุ่มลัดใน facility_building_overview_page.dart) ต้องห่อ
// ด้วย Scaffold+AppBar ที่จุดเรียกเอง (ดูตัวอย่างที่ _buildQuickLinksRow)
import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';
import 'facility_ux_states.dart';

class FacilityDeviceHealthPage extends StatefulWidget {
  const FacilityDeviceHealthPage({super.key});

  @override
  State<FacilityDeviceHealthPage> createState() =>
      _FacilityDeviceHealthPageState();
}

class _FacilityDeviceHealthPageState extends State<FacilityDeviceHealthPage> {
  String _selectedScope = 'อาคาร 3 ทั้งหมด';

  final List<String> _scopeOptions = [
    'อาคาร 3 ทั้งหมด',
    'อาคาร 3 ชั้น 1',
    'อาคาร 3 ชั้น 2',
    'อาคาร 3 ชั้น 3 (ห้อง 302)',
  ];

  final List<Map<String, dynamic>> _devices = [
    {
      'id': 'DEV-101',
      'name': 'กล้อง CCTV C-12',
      'location': 'อาคาร 3 ชั้น 2 โถงทางเดิน',
      'status': 'offline', // 'online', 'offline', 'warning'
      'statusText': '🔴 ออฟไลน์',
      'statusColor': FacilityTheme.emergencyRed,
      'statusBg': const Color(0xFFFEF2F2),
      'battery': 'N/A (AC Power)',
      'lastPing': 'ออฟไลน์ 12 นาทีที่แล้ว',
      'icon': Icons.videocam_rounded,
    },
    {
      'id': 'DEV-102',
      'name': 'กล่อง SOS Box #03',
      'location': 'อาคาร 3 ชั้น 3 ห้อง 302',
      'status': 'warning',
      'statusText': '⚠️ แบตเตอรี่ต่ำ (15%)',
      'statusColor': FacilityTheme.warningOrange,
      'statusBg': const Color(0xFFFFFBEB),
      'battery': '15%',
      'lastPing': 'ปกติเมื่อ 1 นาทีที่แล้ว',
      'icon': Icons.sensors_rounded,
    },
    {
      'id': 'DEV-103',
      'name': 'เซนเซอร์ PM2.5 #01',
      'location': 'อาคาร 3 ชั้น 1 ห้องปฏิบัติการ',
      'status': 'online',
      'statusText': '🟢 ออนไลน์ปกติ',
      'statusColor': FacilityTheme.safeGreen,
      'statusBg': const Color(0xFFECFDF5),
      'battery': '95%',
      'lastPing': 'ปกติเมื่อ 15 วินาทีที่แล้ว',
      'icon': Icons.air_rounded,
    },
    {
      'id': 'DEV-104',
      'name': 'IoT Gateway G-01',
      'location': 'อาคาร 3 ชั้น 1 ห้องควบคุม',
      'status': 'online',
      'statusText': '🟢 ออนไลน์ปกติ (99.8%)',
      'statusColor': FacilityTheme.safeGreen,
      'statusBg': const Color(0xFFECFDF5),
      'battery': '100% (AC Power)',
      'lastPing': 'ปกติเมื่อ 5 วินาทีที่แล้ว',
      'icon': Icons.router_rounded,
    },
    {
      'id': 'DEV-105',
      'name': 'กล้อง CCTV C-15',
      'location': 'อาคาร 3 ชั้น 3 หน้าห้อง 302',
      'status': 'offline',
      'statusText': '🔴 ออฟไลน์',
      'statusColor': FacilityTheme.emergencyRed,
      'statusBg': const Color(0xFFFEF2F2),
      'battery': 'N/A',
      'lastPing': 'ออฟไลน์ 45 นาทีที่แล้ว',
      'icon': Icons.videocam_rounded,
    },
  ];

  // ประวัติบำรุงรักษาล่าสุด (DEV-15 ต้องมีตามสเปก — ก่อนหน้านี้หน้านี้ยังขาดจุดนี้)
  final List<Map<String, String>> _maintenanceHistory = [
    {
      'device': 'กล้อง CCTV C-12',
      'action': 'เปลี่ยนอะแดปเตอร์ไฟเลี้ยง (สงสัยไฟตกเป็นสาเหตุหลุด)',
      'technician': 'ช่างวิทยา (ทีมเทคนิค)',
      'date': '10/10/2024 09:30 น.',
    },
    {
      'device': 'กล่อง SOS Box #03',
      'action': 'เปลี่ยนแบตเตอรี่สำรอง',
      'technician': 'ครูสมชาย (ตรวจเวรประจำวัน)',
      'date': '02/10/2024 15:10 น.',
    },
    {
      'device': 'IoT Gateway G-01',
      'action': 'อัปเดตเฟิร์มแวร์ + รีสตาร์ทตามรอบบำรุงรักษา',
      'technician': 'ช่างวิทยา (ทีมเทคนิค)',
      'date': '28/09/2024 13:00 น.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final offlineCount = _devices.where((d) => d['status'] == 'offline').length;
    final totalCount = _devices.length;
    final offlinePercentage = (offlineCount / totalCount) * 100;
    final isHighOfflineAlert =
        offlinePercentage > 30.0; // DEV-15: ออฟไลน์ > 30% เตือนพิเศษ

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),

          const SizedBox(height: 14),

          // 🏷️ Export Button (ย้ายมาจาก AppBar action เดิม เพื่อให้หน้านี้
          // เป็น content-only ต่อกับ FacilityAppShell ได้)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                FacilityUXStates.showSuccessToast(
                  context,
                  'ส่งออกรายงานสุขภาพอุปกรณ์แล้ว 📡',
                  subtitle:
                      'ระบบทำการประมวลผลและส่งออกรายงานสุขภาพอุปกรณ์ AIoT ครบถ้วนแล้ว',
                  accentColor: FacilityTheme.primaryPurple,
                  icon: Icons.download_done_rounded,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export รายงาน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacilityTheme.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🚨 HIGH OFFLINE ALERT BANNER (DEV-15 Exception Flow: ออฟไลน์ > 30%)
          if (isHighOfflineAlert)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: FacilityTheme.emergencyRed.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: FacilityTheme.emergencyRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ เตือนพิเศษ: อุปกรณ์ออฟไลน์ $offlineCount จาก $totalCount ตัว (${offlinePercentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: FacilityTheme.emergencyRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'พบนนอัตราการออฟไลน์สูงกว่า 30% กรุณาตรวจสอบการเชื่อมต่อ Gateway หรือระบบจ่ายไฟ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: FacilityTheme.inkIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 🏢 Scope Filter Selector
          Row(
            children: [
              const Text(
                'ขอบเขตการดูข้อมูล:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: FacilityTheme.inkIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedScope,
                    isDense: true,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: FacilityTheme.primaryPurple,
                    ),
                    style: const TextStyle(
                      color: FacilityTheme.inkIndigo,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedScope = val);
                    },
                    items: _scopeOptions.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 📊 3 Health Summary Cards
          FacilityResponsiveGrid(
            spacing: 12,
            minItemWidth: 160,
            children: [
              _buildHealthSummaryCard(
                title: 'อุปกรณ์ทั้งหมด',
                value: '$totalCount ตัว',
                color: FacilityTheme.primaryPurple,
                bg: FacilityTheme.lightPurpleBg,
              ),
              _buildHealthSummaryCard(
                title: 'ออนไลน์ปกติ',
                value: '${totalCount - offlineCount} ตัว',
                color: FacilityTheme.safeGreen,
                bg: const Color(0xFFECFDF5),
              ),
              _buildHealthSummaryCard(
                title: 'ออฟไลน์ / มีปัญหา',
                value: '$offlineCount ตัว',
                color: FacilityTheme.emergencyRed,
                bg: const Color(0xFFFEF2F2),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'รายการอุปกรณ์ AIoT และสถานะการเชื่อมต่อ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.inkIndigo,
            ),
          ),

          const SizedBox(height: 12),

          // 📡 Devices List
          ..._devices.map((device) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FacilityGlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (device['statusColor'] as Color).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        device['icon'] as IconData,
                        color: device['statusColor'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  device['name'] as String,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: FacilityTheme.inkIndigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: device['statusBg'] as Color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  device['statusText'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: device['statusColor'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${device['location']} · แบตเตอรี่: ${device['battery']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FacilityTheme.softMauve,
                            ),
                          ),
                          Text(
                            device['lastPing'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: FacilityTheme.softMauve,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // 🛠️ ประวัติบำรุงรักษาล่าสุด (DEV-15 — เพิ่มกลับเข้ามาให้ครบสเปก)
          const Text(
            'ประวัติบำรุงรักษาล่าสุด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.inkIndigo,
            ),
          ),

          const SizedBox(height: 12),

          FacilityGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            borderRadius: 18,
            child: Column(
              children: [
                for (final entry in _maintenanceHistory) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.build_circle_rounded,
                          size: 20,
                          color: FacilityTheme.primaryPurple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['device']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: FacilityTheme.inkIndigo,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry['action']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: FacilityTheme.softMauve,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry['technician']} · ${entry['date']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: FacilityTheme.softMauve,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry != _maintenanceHistory.last)
                    const Divider(height: 1, color: FacilityTheme.purpleBorder),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FacilityTheme.primaryNavy, Color(0xFF2D6A85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: FacilityTheme.primaryNavy.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Color(0xFFE8A519),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สุขภาพอุปกรณ์ AIoT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'STK-9 · $_selectedScope',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard({
    required String title,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: FacilityTheme.softMauve,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
