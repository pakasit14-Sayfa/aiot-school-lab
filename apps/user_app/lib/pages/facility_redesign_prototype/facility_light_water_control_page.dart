// เชื่อมกับ RealtimeService จริงแล้ว (2026-08-17) — เดิม mock ล้วน
// STK-11: สั่งงานผ่าน queueDeviceCommand จริง (queue_device_command RPC)
// ซึ่งเซิร์ฟเวอร์ตรวจสิทธิ์ role + school_id เองอยู่แล้วทุกครั้งที่สั่ง —
// รายชื่ออุปกรณ์มาจาก RealtimeService.listMyBuildingDevices() จริง (สโคป
// ตามอาคารที่รับผิดชอบในระดับ SQL ตาม BR4)
//
// ⚠️ ข้อจำกัดจริงที่ต่างจาก mock เดิม 3 จุด:
// 1. ตาราง devices เก็บแค่ status ออนไลน์/ออฟไลน์ (การเชื่อมต่อ) ไม่มีที่
//    เก็บ "สถานะเปิด/ปิด" ของรีเลย์เลย และ device_commands ก็เป็นแค่ log คำ
//    สั่งที่ส่งไป ไม่ใช่สถานะที่ยืนยันแล้ว — สถานะเปิด/ปิดที่แสดงในหน้านี้
//    จึงเป็นการอัปเดตแบบ optimistic ฝั่ง Flutter เท่านั้น (อิงจากคำสั่ง
//    ล่าสุดที่กดสำเร็จ) ไม่ใช่สถานะจริงจากบอร์ด รีเฟรชหน้าจะรีเซ็ตกลับเป็น
//    "ไม่ทราบสถานะ" เสมอ
// 2. อุปกรณ์ประเภท relay ในสคีมาไม่ได้แยก "ไฟ" กับ "น้ำ" เป็นคนละ type —
//    แยกด้วยชื่ออุปกรณ์แบบ heuristic แทน (ชื่อมีคำว่า "น้ำ" → ไอคอนน้ำ
//    นอกนั้นถือเป็นไฟ) แทนที่จะบังคับให้ทุกห้องมีทั้งไฟ+น้ำคู่กันแบบ mock
//    เดิม (ความจริงคือ 1 รีเลย์ = 1 อุปกรณ์ควบคุมอิสระ)
// 3. location เป็น string อิสระจากฐานข้อมูลจริง ไม่มีโครงสร้าง 3 ระดับ
//    "อาคาร · ชั้น · ห้อง" แบบตายตัวเหมือน mock เดิม — ใช้ location ดิบเป็น
//    ตัวจัดกลุ่มแทน ไม่แยกชั้น/ห้องเป็น dropdown 2 ชั้นซ้อนอีกต่อไป
//
// เป็น Widget content ต่อกับ FacilityAppShell เดิม (ไม่มี Scaffold/AppBar
// เป็นของตัวเอง) ใช้เป็น nav item index 1 ได้โดยตรง
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'facility_shared_widgets.dart';

class FacilityLightWaterControlPage extends StatefulWidget {
  const FacilityLightWaterControlPage({super.key});

  @override
  State<FacilityLightWaterControlPage> createState() =>
      _FacilityLightWaterControlPageState();
}

class _FacilityLightWaterControlPageState
    extends State<FacilityLightWaterControlPage> {
  static const _scopeAll = 'ทั้งหมด';

  bool _loading = true;
  String? _loadError;
  List<DeviceOption> _relays = [];
  String _selectedLocation = _scopeAll;

  // อัปเดตแบบ optimistic ฝั่งเครื่อง (ดูคำอธิบายข้อจำกัดข้อ 1 ด้านบน) —
  // ไม่มีที่มาจาก backend เลย เริ่มต้นว่างเปล่า (= ยังไม่ทราบสถานะ)
  final Map<String, bool> _optimisticState = {};
  final Set<String> _sending = {};

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
        _relays = devices.where((d) => d.type == 'relay').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดรายชื่ออุปกรณ์ไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  List<String> get _locationOptions => [
    _scopeAll,
    ...{
      for (final d in _relays)
        if (d.location != null) d.location!,
    }.toList()..sort(),
  ];

  List<DeviceOption> get _filteredRelays => _selectedLocation == _scopeAll
      ? _relays
      : _relays.where((d) => d.location == _selectedLocation).toList();

  Map<String, List<DeviceOption>> get _relaysByLocation {
    final grouped = <String, List<DeviceOption>>{};
    for (final d in _filteredRelays) {
      final loc = d.location ?? 'ไม่ระบุตำแหน่ง';
      grouped.putIfAbsent(loc, () => []).add(d);
    }
    return grouped;
  }

  bool _isWaterDevice(DeviceOption d) => d.name.contains('น้ำ');

  int get _onCount =>
      _filteredRelays.where((d) => _optimisticState[d.id] == true).length;

  Future<void> _toggle(DeviceOption device, bool value) async {
    setState(() => _sending.add(device.id));
    try {
      await RealtimeService.queueDeviceCommand(
        deviceId: device.id,
        command: {'action': value ? 'on' : 'off'},
      );
      if (!mounted) return;
      setState(() => _optimisticState[device.id] = value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('สั่งงานไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _sending.remove(device.id));
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 18),
          _buildSummaryStats(),
          const SizedBox(height: 14),
          _buildUnknownStateNotice(),
          const SizedBox(height: 14),
          _buildScopeFilterBar(),
          const SizedBox(height: 16),
          if (_filteredRelays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'ไม่พบอุปกรณ์ควบคุม (relay) ในขอบเขตที่เลือก',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: FacilityTheme.softMauve,
                  ),
                ),
              ),
            )
          else
            for (final entry in _relaysByLocation.entries) ...[
              _buildLocationSectionHeader(entry.key, entry.value.length),
              const SizedBox(height: 10),
              FacilityResponsiveGrid(
                spacing: 14,
                minItemWidth: 280,
                children: [
                  for (final device in entry.value)
                    _ControlCard(
                      device: device,
                      isWater: _isWaterDevice(device),
                      value: _optimisticState[device.id],
                      isSending: _sending.contains(device.id),
                      onChanged: (v) => _toggle(device, v),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
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
              Icons.lightbulb_rounded,
              color: Color(0xFFE8A519),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ควบคุมไฟและน้ำ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'STK-11 · อุปกรณ์ในอาคารที่รับผิดชอบ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final total = _filteredRelays.length;
    return FacilityResponsiveGrid(
      spacing: 12,
      minItemWidth: 160,
      children: [
        _buildStatCard(
          icon: Icons.toggle_on_rounded,
          label: 'สั่งเปิดไว้ (เครื่องนี้)',
          value: '$_onCount / $total จุด',
          color: FacilityTheme.safeGreen,
          bg: const Color(0xFFECFDF5),
        ),
        _buildStatCard(
          icon: Icons.settings_remote_rounded,
          label: 'อุปกรณ์ควบคุมทั้งหมด',
          value: '$total ตัว',
          color: FacilityTheme.primaryPurple,
          bg: FacilityTheme.lightPurpleBg,
        ),
      ],
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// อธิบายตรงๆ ว่าสถานะเปิด/ปิดที่เห็นเป็นแค่คำสั่งล่าสุดที่กดจากเครื่องนี้
  /// ไม่ใช่สถานะจริงจากบอร์ด (ดูข้อจำกัดข้อ 1 ที่หัวไฟล์)
  Widget _buildUnknownStateNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'สถานะเปิด/ปิดที่แสดงมาจากคำสั่งล่าสุดที่กดในเครื่องนี้เท่านั้น '
              'ยังไม่มีการยืนยันสถานะจริงจากอุปกรณ์กลับมา',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeFilterBar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ตำแหน่ง:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: FacilityTheme.softMauve,
                ),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isDense: true,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: FacilityTheme.primaryPurple,
                  ),
                  style: const TextStyle(
                    color: FacilityTheme.inkIndigo,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLocation = val);
                  },
                  items: _locationOptions.map((o) {
                    return DropdownMenuItem(value: o, child: Text(o));
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSectionHeader(String location, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: FacilityTheme.primaryPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.inkIndigo,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count จุด',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: FacilityTheme.softMauve,
          ),
        ),
      ],
    );
  }
}

/// กรอบเส้นประบางๆ — ยังต้องคงไว้ในไฟล์นี้เพราะ
/// facility_building_overview_page.dart import คลาสนี้จากที่นี่อยู่
/// (ตัวหน้านี้เองเลิกใช้แล้วหลังตัดแผงทดสอบสิทธิ์ทิ้งไป เพราะสิทธิ์จริง
/// ถูกเซิร์ฟเวอร์ตรวจสอบเองทุกครั้งที่สั่งงานผ่าน queue_device_command แล้ว)
class DottedBorderContainer extends StatelessWidget {
  const DottedBorderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FacilityTheme.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.device,
    required this.isWater,
    required this.value,
    required this.isSending,
    required this.onChanged,
  });

  final DeviceOption device;
  final bool isWater;
  final bool? value;
  final bool isSending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isOn = value == true;
    final accentColor = isWater
        ? const Color(0xFF0284C7)
        : const Color(0xFFE8A519);
    final isOffline = device.status != 'online';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: isOn ? FacilityTheme.safeGreen : const Color(0xFFCBD5E1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: FacilityTheme.inkIndigo,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOffline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: const Text(
                            'ออฟไลน์',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: FacilityTheme.emergencyRed,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isOn
                          ? accentColor.withValues(alpha: 0.08)
                          : FacilityTheme.bgSlate,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isOn
                                ? accentColor.withValues(alpha: 0.18)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWater
                                ? Icons.water_drop_rounded
                                : Icons.lightbulb_rounded,
                            size: 16,
                            color: isOn ? accentColor : FacilityTheme.softMauve,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            value == null
                                ? 'ไม่ทราบสถานะ'
                                : (isOn ? 'เปิดอยู่' : 'ปิดอยู่'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: FacilityTheme.inkIndigo,
                            ),
                          ),
                        ),
                        if (isSending)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: isOn,
                              onChanged: isOffline ? null : onChanged,
                              activeColor: accentColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
