// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
// STK-10: "ดูรายงานเหตุการณ์ความปลอดภัยระดับอาคาร" (จาก SEC-7)
// **ข้อบังคับห้ามลืม**: สรุปตัวเลขเท่านั้น ห้ามมีภาพจากกล้องเด็ดขาด (SEC-7 / SEC-9)
//
// เป็น Widget content ต่อกับ FacilityAppShell เดิม (ไม่มี Scaffold/AppBar
// เป็นของตัวเอง) ใช้เป็น nav item index 10 ได้โดยตรง — ถ้าจะ Navigator.push
// จากที่อื่น (เช่นปุ่มลัดใน facility_building_overview_page.dart) ต้องห่อ
// ด้วย Scaffold+AppBar ที่จุดเรียกเอง (ดูตัวอย่างที่ _buildQuickLinksRow)
import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';

class FacilitySecurityEventsPage extends StatefulWidget {
  const FacilitySecurityEventsPage({super.key});

  @override
  State<FacilitySecurityEventsPage> createState() =>
      _FacilitySecurityEventsPageState();
}

class _FacilitySecurityEventsPageState
    extends State<FacilitySecurityEventsPage> {
  String _selectedPeriod = '7 วันที่ผ่านมา';
  String _selectedArea = 'อาคาร 3 ทั้งหมด';
  String _selectedEventType = 'ทุกประเภท';

  final List<String> _periodOptions = [
    'วันนี้',
    '7 วันที่ผ่านมา',
    '30 วันที่ผ่านมา',
  ];
  final List<String> _areaOptions = [
    'อาคาร 3 ทั้งหมด',
    'ชั้น 1',
    'ชั้น 2',
    'ชั้น 3 (ห้อง 302)',
  ];
  final List<String> _eventTypeOptions = [
    'ทุกประเภท',
    '🚪 ประตูเปิดค้าง',
    '🚨 SOS ฉุกเฉิน',
    '🚶 ความเคลื่อนไหวเวลากลางคืน',
  ];

  // 2026-08-15: เอาฟิลด์ 'details' (ประโยคอธิบายเหตุการณ์แบบละเอียด) ออก —
  // STK-10 Main Flow ระบุตรงๆ ว่าแสดง "สรุป event ระดับอาคาร (จำนวน/
  // ประเภท/เวลา)" เท่านั้น ข้อความอธิบายละเอียดต่อเหตุการณ์เกินสเปกที่ UC
  // อนุญาต แม้จะไม่มีภาพ/ชื่อเด็กก็ตาม เหลือแค่ type/location/time/status
  final List<Map<String, dynamic>> _securityEvents = [
    {
      'id': 'SEC-801',
      'title': '🚨 กดปุ่ม SOS ฉุกเฉิน',
      'location': 'อาคาร 3 ชั้น 3 ห้อง 302',
      'time': '14/10/2024 08:28 น.',
      'type': 'SOS ฉุกเฉิน',
      'status': 'ยังไม่รับเรื่อง',
      'statusColor': FacilityTheme.emergencyRed,
      'statusBg': const Color(0xFFFEF2F2),
      'icon': Icons.campaign_rounded,
    },
    {
      'id': 'SEC-802',
      'title': '🚪 ประตูแง้ม/เปิดค้างเกิน 10 นาที',
      'location': 'อาคาร 3 ชั้น 2 โถงทางเดิน',
      'time': '14/10/2024 07:15 น.',
      'type': 'ประตูเปิดค้าง',
      'status': 'แก้ไขแล้ว',
      'statusColor': FacilityTheme.safeGreen,
      'statusBg': const Color(0xFFECFDF5),
      'icon': Icons.door_sliding_rounded,
    },
    {
      'id': 'SEC-803',
      'title': '🚶 ตรวจพบความเคลื่อนไหวหลังเวลาปิดอาคาร',
      'location': 'อาคาร 3 ชั้น 1 ห้องปฏิบัติการ',
      'time': '13/10/2024 21:45 น.',
      'type': 'ความเคลื่อนไหวเวลากลางคืน',
      'status': 'ตรวจสอบแล้ว (เจ้าหน้าที่รักษาความปลอดภัย)',
      'statusColor': FacilityTheme.primaryPurple,
      'statusBg': FacilityTheme.lightPurpleBg,
      'icon': Icons.directions_walk_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายงานความปลอดภัยระดับอาคาร (STK-10)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.inkIndigo,
            ),
          ),

          const SizedBox(height: 16),

          // 🛡️ SEC-7 NOTICE BANNER (สรุปตัวเลขเท่านั้น ห้ามภาพกล้อง)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: FacilityTheme.lightPurpleBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FacilityTheme.purpleBorder),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: FacilityTheme.primaryPurple,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'รายงานสรุปสถิติความปลอดภัย (ตาม SEC-7: เฉพาะสรุปตัวเลขและข้อความ ไม่แสดงภาพกล้อง)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: FacilityTheme.inkIndigo,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔍 3 Filters Row (ช่วงเวลา / พื้นที่ / ประเภทเหตุการณ์)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterDropdown(
                'ช่วงเวลา:',
                _selectedPeriod,
                _periodOptions,
                (val) {
                  if (val != null) setState(() => _selectedPeriod = val);
                },
              ),
              _buildFilterDropdown('พื้นที่:', _selectedArea, _areaOptions, (
                val,
              ) {
                if (val != null) setState(() => _selectedArea = val);
              }),
              _buildFilterDropdown(
                'ประเภทเหตุ:',
                _selectedEventType,
                _eventTypeOptions,
                (val) {
                  if (val != null) setState(() => _selectedEventType = val);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 📊 3 Summary Metric Cards
          FacilityResponsiveGrid(
            spacing: 12,
            minItemWidth: 160,
            children: [
              _buildSecurityMetricCard(
                title: 'เหตุการณ์รวม',
                value: '${_securityEvents.length} ครั้ง',
                trend: '↘ -15% จากสัปดาห์ก่อน',
                color: FacilityTheme.primaryPurple,
                bg: FacilityTheme.lightPurpleBg,
              ),
              _buildSecurityMetricCard(
                title: 'เหตุการณ์ด่วน/SOS',
                value: '1 ครั้ง',
                trend: '🚨 ต้องดำเนินการ',
                color: FacilityTheme.emergencyRed,
                bg: const Color(0xFFFEF2F2),
              ),
              _buildSecurityMetricCard(
                title: 'เวลาตอบสนองเฉลี่ย',
                value: '4 นาที',
                trend: '✓ ตามมาตรฐาน SEC-7',
                color: FacilityTheme.safeGreen,
                bg: const Color(0xFFECFDF5),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'ประวัติรายการเหตุการณ์ความปลอดภัย (Text Summary Log)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.inkIndigo,
            ),
          ),

          const SizedBox(height: 12),

          // 📜 Event Summary List (Text Only - No Camera Feed)
          ..._securityEvents.map((event) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: FacilityGlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (event['statusColor'] as Color).withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            event['icon'] as IconData,
                            color: event['statusColor'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['title'] as String,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: event['statusColor'] as Color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${event['location']} · ${event['time']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: FacilityTheme.softMauve,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: event['statusBg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event['status'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: event['statusColor'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String currentValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: FacilityTheme.softMauve,
            ),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isDense: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: FacilityTheme.primaryPurple,
              ),
              style: const TextStyle(
                color: FacilityTheme.inkIndigo,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
              onChanged: onChanged,
              items: options.map((opt) {
                return DropdownMenuItem(value: opt, child: Text(opt));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMetricCard({
    required String title,
    required String value,
    required String trend,
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
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
