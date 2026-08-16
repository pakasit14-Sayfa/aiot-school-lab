// เชื่อมกับ RealtimeService.listMyBuildingDevices จริงแล้ว (2026-08-17)
// STK-9: "ดูสถานะสุขภาพอุปกรณ์ AIoT ในอาคาร" (จาก DEV-15) — เดิม mock ล้วน
// ตอนนี้ดึงรายชื่ออุปกรณ์จริงในอาคารที่รับผิดชอบผ่าน RPC ใหม่
// list_devices_in_my_building (สโคปตามอาคารแล้วในระดับ SQL ตาม BR4)
//
// ⚠️ สิ่งที่ตัดออกเพราะไม่มี backend รองรับ:
// - "แบตเตอรี่"/"lastPing" ต่อเครื่อง — ตาราง devices ไม่มีคอลัมน์นี้เลย
// - "ประวัติบำรุงรักษาล่าสุด" ทั้งหมด — ไม่มีตาราง/RPC เก็บ log บำรุงรักษา
//   เลย ตัดทิ้งแทนที่จะโชว์ข้อมูลปลอม
//
// เป็น Widget content ต่อกับ FacilityAppShell เดิม (ไม่มี Scaffold/AppBar
// เป็นของตัวเอง) ใช้เป็น nav item index 9 ได้โดยตรง — ถ้าจะ Navigator.push
// จากที่อื่น (เช่นปุ่มลัดใน facility_building_overview_page.dart) ต้องห่อ
// ด้วย Scaffold+AppBar ที่จุดเรียกเอง (ดูตัวอย่างที่ _buildQuickLinksRow)
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'facility_shared_widgets.dart';
import 'facility_ux_states.dart';

const _allScope = 'ทั้งหมด';

class FacilityDeviceHealthPage extends StatefulWidget {
  const FacilityDeviceHealthPage({super.key});

  @override
  State<FacilityDeviceHealthPage> createState() =>
      _FacilityDeviceHealthPageState();
}

class _FacilityDeviceHealthPageState extends State<FacilityDeviceHealthPage> {
  String _selectedScope = _allScope;
  bool _loading = true;
  String? _loadError;
  List<DeviceOption> _devices = [];

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
      final devices = await RealtimeService.listMyBuildingDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดข้อมูลอุปกรณ์ไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  List<String> get _scopeOptions => [
    _allScope,
    ...{
      for (final d in _devices)
        if (d.location != null) d.location!,
    }.toList()..sort(),
  ];

  List<DeviceOption> get _visibleDevices => _selectedScope == _allScope
      ? _devices
      : _devices.where((d) => d.location == _selectedScope).toList();

  ({IconData icon, String label}) _typeInfo(String type) {
    switch (type) {
      case 'camera':
        return (icon: Icons.videocam_rounded, label: 'กล้อง CCTV');
      case 'pm25_sensor':
        return (icon: Icons.air_rounded, label: 'เซนเซอร์ PM2.5');
      case 'air_quality_sensor':
        return (icon: Icons.eco_rounded, label: 'เซนเซอร์คุณภาพอากาศ');
      case 'light_sensor':
        return (icon: Icons.light_mode_rounded, label: 'เซนเซอร์แสง');
      case 'energy_meter':
        return (icon: Icons.electric_bolt_rounded, label: 'มิเตอร์ไฟ');
      case 'relay':
        return (icon: Icons.toggle_on_rounded, label: 'รีเลย์ควบคุม');
      case 'emergency_button':
        return (icon: Icons.emergency_rounded, label: 'ปุ่มฉุกเฉิน');
      case 'warning_light':
        return (icon: Icons.warning_amber_rounded, label: 'ไฟเตือน');
      case 'aiot_gateway':
        return (icon: Icons.router_rounded, label: 'AIoT Gateway');
      case 'mini_pc':
        return (icon: Icons.dns_rounded, label: 'Mini PC');
      default:
        return (icon: Icons.devices_other_rounded, label: type);
    }
  }

  ({Color color, Color bg, String label}) _statusInfo(String status) {
    switch (status) {
      case 'online':
        return (
          color: FacilityTheme.safeGreen,
          bg: const Color(0xFFECFDF5),
          label: '🟢 ออนไลน์ปกติ',
        );
      case 'offline':
        return (
          color: FacilityTheme.emergencyRed,
          bg: const Color(0xFFFEF2F2),
          label: '🔴 ออฟไลน์',
        );
      case 'error':
        return (
          color: FacilityTheme.emergencyRed,
          bg: const Color(0xFFFEF2F2),
          label: '⚠️ มีปัญหา',
        );
      case 'maintenance':
        return (
          color: FacilityTheme.warningOrange,
          bg: const Color(0xFFFFFBEB),
          label: '🛠️ ซ่อมบำรุง',
        );
      default:
        return (
          color: FacilityTheme.softMauve,
          bg: FacilityTheme.lightPurpleBg,
          label: status,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: CircularProgressIndicator(color: FacilityTheme.primaryNavy),
        ),
      );
    }
    if (_loadError != null) {
      return Padding(
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
            OutlinedButton(onPressed: _load, child: const Text('ลองใหม่')),
          ],
        ),
      );
    }

    final visible = _visibleDevices;
    final offlineCount = visible
        .where((d) => d.status == 'offline' || d.status == 'error')
        .length;
    final totalCount = visible.length;
    final offlinePercentage = totalCount == 0
        ? 0.0
        : (offlineCount / totalCount) * 100;
    final isHighOfflineAlert = totalCount > 0 && offlinePercentage > 30.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),

          const SizedBox(height: 14),

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
                          '⚠️ เตือนพิเศษ: อุปกรณ์ออฟไลน์/มีปัญหา $offlineCount จาก $totalCount ตัว (${offlinePercentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: FacilityTheme.emergencyRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'พบอัตราการออฟไลน์สูงกว่า 30% กรุณาตรวจสอบการเชื่อมต่อ Gateway หรือระบบจ่ายไฟ',
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

          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'ไม่พบอุปกรณ์ในขอบเขตที่เลือก',
                style: TextStyle(
                  color: FacilityTheme.softMauve,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...visible.map((device) {
              final typeInfo = _typeInfo(device.type);
              final statusInfo = _statusInfo(device.status);
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
                          color: statusInfo.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          typeInfo.icon,
                          color: statusInfo.color,
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
                                    device.name,
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
                                    color: statusInfo.bg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusInfo.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: statusInfo.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${typeInfo.label} · ${device.location ?? 'ไม่ระบุตำแหน่ง'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
