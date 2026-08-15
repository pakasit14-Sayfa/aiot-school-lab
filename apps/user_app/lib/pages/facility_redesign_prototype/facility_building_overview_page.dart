// PROTOTYPE — UI/UX เท่านั้น ยังไม่ผูก Supabase จริง (mock data) ดู
// facility_redesign_prototype/NOTES.md หัวข้อ "หน้า ภาพรวมอาคาร ตามสเปก
// หน้า 1: Dashboard ครูอาคาร" สำหรับสเปกต้นฉบับแบบเต็ม — ไฟล์นี้พยายามตรง
// สเปกนั้นให้มากที่สุด รวมถึงกฎ threshold, ลำดับการเรียง, และ UI states
// ทั้งหมด เพื่อให้พร้อมสลับไปผูกข้อมูลจริงทีหลัง
//
// เป็น Widget content ต่อกับ FacilityAppShell เดิม (ไม่ใช่ Scaffold แยก
// ของตัวเอง) ใช้ FacilityGlassCard/FacilityTheme สีม่วงเหมือนหน้าอื่นๆ ใน
// facility_redesign_prototype/ ทั้งหมด — เรียกใช้จาก FacilityStorybookPage
// เป็นตัวเลือกแยก (index 8) ไม่ใช่ "ภาพรวม" เดิม (index 0 ยังเป็น
// facility_dashboard_page.dart) — เคยรวม 2 หน้านี้เป็นหน้าเดียวช่วงสั้นๆ
// (2026-08-14) แล้วแยกกลับมาตามคำขอผู้ใช้ในวันเดียวกัน ดู NOTES.md
// หัวข้อ "แยกกลับ" สำหรับเหตุผลเต็ม
//
// จุดที่ยังไม่ได้ทำตามสเปก (บันทึกไว้ให้ตัดสินใจภายหลัง ไม่ใช่ในรอบนี้):
// - เมนูหลัก 3 หน้าตามสเปกข้อ 10 ยังไม่ได้แทนที่ sidebar เดิม (ใช้
//   แถวปุ่มลัด "เมนู" ในเนื้อหาแทนไปก่อน)
// - การกรองข้อมูลด้วย building ที่ server-side (sensor_latest RPC) แก้แล้ว
//   ที่ backend (20260814000000_facility_manager_building_scope.sql) แต่
//   ยังไม่ได้ต่อ Supabase จริงในหน้านี้ (ยัง mock data ทั้งหมด)
import 'package:flutter/material.dart';
import 'facility_command_history_page.dart';
import 'facility_device_health_page.dart';
import 'facility_light_water_control_page.dart';
import 'facility_notifications_page.dart';
import 'facility_security_events_page.dart';
import 'facility_shared_widgets.dart';

// 2026-08-15: ออกแบบหน้านี้ใหม่ให้ดูพรีเมียมขึ้น ตามแนวทางเดียวกับที่ทำไป
// แล้วในหน้าควบคุมไฟ/น้ำ (STK-11) — ยืม DottedBorderContainer จากไฟล์นั้น
// มาใช้กับแถบ "ทดสอบ State" ให้สไตล์เดียวกันทั้งแอป (แผงทดสอบ = กรอบเส้น
// ประบางๆ แยกจาก UI จริงด้วยสายตา) ไม่ได้แตะ business logic/threshold
// rules ใดๆ ในไฟล์นี้เลย แก้แค่ชั้น UI

enum _OverviewDemoState { normal, loading, noData, noBuilding, staleTemporary }

enum _MetricStatus { normal, watch, abnormal, noData }

class _LocationReading {
  const _LocationReading({
    required this.location,
    required this.pm25,
    required this.temperature,
    required this.humidity,
    required this.lux,
    required this.updatedAt,
  });

  final String location;
  final double? pm25;
  final double? temperature;
  final double? humidity;
  final double? lux;
  final DateTime? updatedAt;
}

/// เนื้อหาหน้า "ภาพรวมอาคาร" — หน้าแรกของบทบาทครูอาคาร/ผู้ดูแลอาคาร ตาม
/// สเปก "หน้า 1: Dashboard ครูอาคาร" เน้นดูข้อมูลเซนเซอร์จริงของอาคารที่
/// รับผิดชอบเท่านั้น (ไม่มี SOS/แผนที่/งานซ่อม/checklist ในหน้านี้)
class FacilityBuildingOverviewContent extends StatefulWidget {
  const FacilityBuildingOverviewContent({super.key});

  @override
  State<FacilityBuildingOverviewContent> createState() =>
      _FacilityBuildingOverviewContentState();
}

class _FacilityBuildingOverviewContentState
    extends State<FacilityBuildingOverviewContent> {
  _OverviewDemoState _demoState = _OverviewDemoState.normal;
  int _selectedTab =
      0; // 0 = 🌿 สิ่งแวดล้อม (STK-7), 1 = ⚡ พลังงานไฟฟ้า (STK-6)
  final int _unreadCount = 2; // คำนวณตามรายการการแจ้งเตือนที่ยังไม่ได้อ่านจริง

  static const _userName = 'ครูสมชาย ใจดี';
  static const _building = 'อาคาร 3';

  // mock ของ "ข้อมูลสรุปตามตำแหน่ง" ที่ RealtimeService.buildingSensorStream
  // จะส่งมาจริง — ตั้งใจให้ครอบคลุมทั้ง 3 สถานะ (ปกติ/เฝ้าระวัง/ผิดปกติ)
  // เพื่อทดสอบการเรียงลำดับตามสเปกข้อ 11
  static final _mockReadings = <_LocationReading>[
    _LocationReading(
      location: 'อาคาร 3 ชั้น 1',
      pm25: 10.2,
      temperature: 26.5,
      humidity: 62,
      lux: 420,
      updatedAt: DateTime(2026, 8, 14, 8, 15),
    ),
    _LocationReading(
      location: 'อาคาร 3 ห้องปฏิบัติการ',
      pm25: 45.0, // >=35 → ผิดปกติ
      temperature: 27.0,
      humidity: 60,
      lux: 350,
      updatedAt: DateTime(2026, 8, 14, 8, 16),
    ),
    _LocationReading(
      location: 'อาคาร 3 ชั้น 2',
      pm25: 22.8, // 12-35 → เฝ้าระวัง
      temperature: 30.1, // >28-32 → เฝ้าระวัง
      humidity: 74, // >70-80 → เฝ้าระวัง
      lux: 220, // 150-299 → เฝ้าระวัง
      updatedAt: DateTime(2026, 8, 14, 8, 14),
    ),
    _LocationReading(
      location: 'อาคาร 3 โถงทางเดิน',
      pm25: 8.0,
      temperature: 25.0,
      humidity: 55,
      lux:
          null, // ตัวอย่าง metric ที่ยังไม่มีข้อมูล → โชว์ "–" พร้อม Tooltip อธิบาย
      updatedAt: DateTime(2026, 8, 14, 8, 15),
    ),
  ];

  // --- กฎแสดงสถานะ (สเปกข้อ 7) ---

  static _MetricStatus _pm25Status(double? v) {
    if (v == null) return _MetricStatus.noData;
    if (v < 12) return _MetricStatus.normal;
    if (v < 35) return _MetricStatus.watch;
    return _MetricStatus.abnormal;
  }

  static _MetricStatus _temperatureStatus(double? v) {
    if (v == null) return _MetricStatus.noData;
    if (v >= 20 && v <= 28) return _MetricStatus.normal;
    if (v > 28 && v <= 32) return _MetricStatus.watch;
    return _MetricStatus.abnormal;
  }

  static _MetricStatus _humidityStatus(double? v) {
    if (v == null) return _MetricStatus.noData;
    if (v >= 40 && v <= 70) return _MetricStatus.normal;
    if (v > 70 && v <= 80) return _MetricStatus.watch;
    return _MetricStatus.abnormal;
  }

  static _MetricStatus _luxStatus(double? v) {
    if (v == null) return _MetricStatus.noData;
    if (v >= 300) return _MetricStatus.normal;
    if (v >= 150) return _MetricStatus.watch;
    return _MetricStatus.abnormal;
  }

  /// สถานะรวมของตำแหน่ง: ผิดปกติถ้ามีอย่างน้อยหนึ่งค่าผิดปกติ, เฝ้าระวังถ้า
  /// มีอย่างน้อยหนึ่งค่าเฝ้าระวัง, ปกติถ้าทุกค่าที่มีข้อมูลปกติ, ไม่มีข้อมูล
  /// ถ้าทุก metric ไม่มีข้อมูลเลย
  static _MetricStatus _overallStatus(_LocationReading r) {
    final statuses = [
      _pm25Status(r.pm25),
      _temperatureStatus(r.temperature),
      _humidityStatus(r.humidity),
      _luxStatus(r.lux),
    ];
    if (statuses.every((s) => s == _MetricStatus.noData)) {
      return _MetricStatus.noData;
    }
    if (statuses.contains(_MetricStatus.abnormal)) {
      return _MetricStatus.abnormal;
    }
    if (statuses.contains(_MetricStatus.watch)) return _MetricStatus.watch;
    return _MetricStatus.normal;
  }

  static Color _statusColor(_MetricStatus status) {
    switch (status) {
      case _MetricStatus.normal:
        return FacilityTheme.safeGreen;
      case _MetricStatus.watch:
        return FacilityTheme.warningOrange;
      case _MetricStatus.abnormal:
        return FacilityTheme.emergencyRed;
      case _MetricStatus.noData:
        return FacilityTheme.softMauve;
    }
  }

  static String _statusLabel(_MetricStatus status) {
    switch (status) {
      case _MetricStatus.normal:
        return '● ปกติ';
      case _MetricStatus.watch:
        return '⚠️ เฝ้าระวัง';
      case _MetricStatus.abnormal:
        return '🔴 ผิดปกติ';
      case _MetricStatus.noData:
        return '– ไม่มีข้อมูล';
    }
  }

  static IconData _statusIcon(_MetricStatus status) {
    switch (status) {
      case _MetricStatus.normal:
        return Icons.check_circle_rounded;
      case _MetricStatus.watch:
        return Icons.warning_amber_rounded;
      case _MetricStatus.abnormal:
        return Icons.error_rounded;
      case _MetricStatus.noData:
        return Icons.help_outline_rounded;
    }
  }

  /// การเรียงลำดับการ์ดตำแหน่ง (สเปกข้อ 11) — ผิดปกติ → เฝ้าระวัง → ปกติ → ไม่มีข้อมูล
  List<_LocationReading> _sortReadings(List<_LocationReading> list) {
    int rank(_MetricStatus status) {
      switch (status) {
        case _MetricStatus.abnormal:
          return 0;
        case _MetricStatus.watch:
          return 1;
        case _MetricStatus.normal:
          return 2;
        case _MetricStatus.noData:
          return 3;
      }
    }

    final copy = [...list];
    copy.sort((a, b) {
      final rankDiff = rank(_overallStatus(a)) - rank(_overallStatus(b));
      if (rankDiff != 0) return rankDiff;
      return a.location.compareTo(b.location);
    });
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: FacilityTheme.primaryPurple,
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(context),
            const SizedBox(height: 14),
            _buildOverviewTabSwitcher(),
            const SizedBox(height: 14),
            _buildQuickLinksRow(context),
            const SizedBox(height: 14),
            _buildDemoStateSwitcher(),
            const SizedBox(height: 18),
            if (_selectedTab == 0)
              _buildBody(context)
            else
              _buildEnergyTabBody(context),
          ],
        ),
      ),
    );
  }

  /// แถบสลับแท็บ "สิ่งแวดล้อม (STK-7)" และ "พลังงานไฟฟ้า (STK-6)" ตามข้อสรุปการจัดวาง
  Widget _buildOverviewTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 0
                      ? const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.thermostat_rounded,
                      size: 16,
                      color: _selectedTab == 0
                          ? FacilityTheme.primaryPurple
                          : FacilityTheme.softMauve,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '🌿 สิ่งแวดล้อมอาคาร (STK-7)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedTab == 0
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: _selectedTab == 0
                            ? FacilityTheme.primaryPurple
                            : FacilityTheme.softMauve,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 1
                      ? const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: _selectedTab == 1
                          ? FacilityTheme.primaryPurple
                          : FacilityTheme.softMauve,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '⚡ พลังงานไฟฟ้า (STK-6)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedTab == 1
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: _selectedTab == 1
                            ? FacilityTheme.primaryPurple
                            : FacilityTheme.softMauve,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// เนื้อหาแท็บพลังงานไฟฟ้า (STK-6) พร้อมคำเตือน BR2
  Widget _buildEnergyTabBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⚡ BR2 MANDATORY ELECTRICITY COST ESTIMATION WARNING BANNER
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FacilityTheme.warningOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: FacilityTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประมาณการค่าไฟฟ้าสะสมเดือนนี้: 1,450 บาท',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: FacilityTheme.inkIndigo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '⚠️ หมายเหตุ (BR2): ตัวเลขนี้เป็นค่าประมาณการคำนวณจากหน่วยไฟฟ้าสะสม ไม่ใช่ใบแจ้งหนี้หรือบิลค่าไฟฟ้าจริงของการไฟฟ้าฯ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildEnergyMetricCard(
                label: 'กำลังไฟ (W)',
                value: '4,250 W',
                subtitle: '4.25 kW (พีค 5.8 kW)',
                color: FacilityTheme.primaryPurple,
                icon: Icons.flash_on_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnergyMetricCard(
                label: 'แรงดันไฟ (V)',
                value: '228 V',
                subtitle: 'ปกติ (220-230V)',
                color: FacilityTheme.safeGreen,
                icon: Icons.electrical_services_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEnergyMetricCard(
                label: 'กระแสไฟ (A)',
                value: '18.6 A',
                subtitle: 'โหลด 42% ของพิกัด',
                color: const Color(0xFF0284C7),
                icon: Icons.speed_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnergyMetricCard(
                label: 'พลังงานสะสม (kWh)',
                value: '362.5 kWh',
                subtitle: '↗ +3% จากช่วงเดียวกัน',
                color: FacilityTheme.warningOrange,
                icon: Icons.battery_charging_full_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        FacilityGlassCard(
          padding: const EdgeInsets.all(22),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'แนวโน้มการใช้พลังงานไฟฟ้า 7 วันย้อนหลัง',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: FacilityTheme.inkIndigo,
                    ),
                  ),
                  Text(
                    'อัปเดตเรียลไทม์',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: FacilityTheme.primaryPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBarColumn('จ.', 0.4, '12 kWh'),
                    _buildBarColumn('อ.', 0.65, '18 kWh'),
                    _buildBarColumn('พ.', 0.85, '24 kWh'),
                    _buildBarColumn('พฤ.', 0.7, '20 kWh'),
                    _buildBarColumn('ศ.', 0.95, '28 kWh'),
                    _buildBarColumn('ส.', 0.3, '8 kWh'),
                    _buildBarColumn('อา.', 0.25, '6 kWh'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyMetricCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return FacilityGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: FacilityTheme.softMauve,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: FacilityTheme.softMauve,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn(String dayLabel, double heightRatio, String kwhText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          kwhText,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: FacilityTheme.softMauve,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 100 * heightRatio,
          decoration: BoxDecoration(
            color: heightRatio > 0.8
                ? FacilityTheme.warningOrange
                : FacilityTheme.primaryPurple,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: FacilityTheme.inkIndigo,
          ),
        ),
      ],
    );
  }

  /// ปุ่มลัดนำทาง — ลดน้ำหนักภาพลง ไม่ใช้ GlassCard หนาเท่าการ์ดสถานะหลัก (ปรับตามข้อ 2)
  Widget _buildQuickLinksRow(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _QuickLinkButton(
          icon: Icons.toggle_on_rounded,
          label: 'ควบคุมไฟและน้ำ (STK-11)',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              // FacilityLightWaterControlPage เป็น content-only แล้ว (ใช้
              // เป็น nav item index 1 ด้วย) — ตอน push แบบหน้าเดี่ยวต้องห่อ
              // Scaffold+AppBar เอง เหมือน STK-9/STK-10
              builder: (_) => Scaffold(
                backgroundColor: FacilityTheme.bgSlate,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  foregroundColor: FacilityTheme.inkIndigo,
                  title: const Text(
                    'ควบคุมไฟและน้ำ (STK-11)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
                body: const SafeArea(child: FacilityLightWaterControlPage()),
              ),
            ),
          ),
        ),
        _QuickLinkButton(
          icon: Icons.health_and_safety_rounded,
          label: 'สุขภาพอุปกรณ์ (STK-9)',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              // FacilityDeviceHealthPage เป็น content-only (ไม่มี Scaffold
              // ของตัวเอง เพื่อให้ใช้เป็น nav item ใน FacilityAppShell ได้
              // ด้วย) — ตอน push แบบหน้าเดี่ยวจึงต้องห่อ Scaffold+AppBar เอง
              builder: (_) => Scaffold(
                backgroundColor: FacilityTheme.bgSlate,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  foregroundColor: FacilityTheme.inkIndigo,
                  title: const Text(
                    'สถานะสุขภาพอุปกรณ์ AIoT (STK-9)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
                body: const SafeArea(child: FacilityDeviceHealthPage()),
              ),
            ),
          ),
        ),
        _QuickLinkButton(
          icon: Icons.security_rounded,
          label: 'รายงานความปลอดภัย (STK-10)',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              // FacilitySecurityEventsPage เป็น content-only เหมือนกัน —
              // ดูเหตุผลที่คอมเมนต์ของปุ่ม STK-9 ด้านบน
              builder: (_) => Scaffold(
                backgroundColor: FacilityTheme.bgSlate,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  foregroundColor: FacilityTheme.inkIndigo,
                  title: const Text(
                    'รายงานความปลอดภัยระดับอาคาร (STK-10)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
                body: const SafeArea(child: FacilitySecurityEventsPage()),
              ),
            ),
          ),
        ),
        // 2026-08-15: ตัดปุ่ม 'พลังงานอาคาร (STK-6)' ออก — ซ้ำกับแท็บ
        // "⚡ พลังงานไฟฟ้า (STK-6)" ที่อยู่เหนือแถวปุ่มลัดนี้อยู่แล้ว
        // (กดแท็บได้ตรงๆ ไม่ต้องมีปุ่มลัดมาสลับแท็บซ้ำอีกทาง)
        _QuickLinkButton(
          icon: Icons.history_rounded,
          label: 'ประวัติการสั่งงาน',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FacilityCommandHistoryPage(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFF0F9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(
            Icons.sensors_rounded,
            size: 18,
            color: FacilityTheme.primaryPurple,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'ภาพรวมอาคาร',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.inkIndigo,
            ),
          ),
        ),
        // กระดิ่งแจ้งเตือนพร้อม Badge คำนวณ Unread Count จริง (ปรับตามข้อ 3)
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 22),
              tooltip: 'การแจ้งเตือน',
              color: FacilityTheme.primaryPurple,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FacilityNotificationsPage(),
                ),
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: FacilityTheme.emergencyRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        const CircleAvatar(
          radius: 15,
          backgroundColor: FacilityTheme.primaryPurple,
          child: Text(
            'ส',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  /// สลับดู UI state สำหรับ Prototype เท่านั้น — ลดน้ำหนักภาพลง ไม่แย่งสายตา (ปรับตามข้อ 1)
  Widget _buildDemoStateSwitcher() {
    final options = <(_OverviewDemoState, String)>[
      (_OverviewDemoState.normal, 'ปกติ'),
      (_OverviewDemoState.loading, 'กำลังโหลด'),
      (_OverviewDemoState.noData, 'ไม่มีข้อมูล'),
      (_OverviewDemoState.noBuilding, 'ยังไม่ได้กำหนดอาคาร'),
      (_OverviewDemoState.staleTemporary, 'อัปเดตไม่ได้ชั่วคราว'),
    ];

    return DottedBorderContainer(
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 14,
            color: FacilityTheme.softMauve,
          ),
          const SizedBox(width: 6),
          const Text(
            'ทดสอบ State:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: FacilityTheme.softMauve,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((opt) {
                  final isSelected = _demoState == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Material(
                      color: isSelected
                          ? FacilityTheme.lightPurpleBg
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? FacilityTheme.purpleBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _demoState = opt.$1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? FacilityTheme.primaryPurple
                                  : FacilityTheme.softMauve,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_demoState) {
      case _OverviewDemoState.loading:
        return _buildLoadingState();
      case _OverviewDemoState.noBuilding:
        return _buildNoBuildingState();
      case _OverviewDemoState.noData:
        return _buildContentBody(readings: const [], showStaleBanner: false);
      case _OverviewDemoState.normal:
        return _buildContentBody(
          readings: _mockReadings,
          showStaleBanner: false,
        );
      case _OverviewDemoState.staleTemporary:
        return _buildContentBody(
          readings: _mockReadings,
          showStaleBanner: true,
        );
    }
  }

  /// โครงหลักของเนื้อหา: Greeting + 3 Summary Cards + Sensor Cards List
  Widget _buildContentBody({
    required List<_LocationReading> readings,
    required bool showStaleBanner,
  }) {
    final sorted = _sortReadings(readings);
    final totalLocations = readings.length;
    final latestUpdateStr = _computeLatestUpdate(readings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStaleBanner) ...[
          _buildStaleConnectionBanner(),
          const SizedBox(height: 14),
        ],
        _buildUserGreetingHeader(userName: _userName, building: _building),
        const SizedBox(height: 16),
        _buildSummaryCardsRow(
          building: _building,
          totalLocations: totalLocations,
          latestUpdateStr: latestUpdateStr,
        ),
        const SizedBox(height: 22),
        const Text(
          'สถานะเซนเซอร์ภายในอาคาร',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: FacilityTheme.inkIndigo,
          ),
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          _buildEmptySensorCard()
        else
          Column(
            children: [
              for (final reading in sorted) ...[
                _LocationSensorCard(
                  reading: reading,
                  overallStatus: _overallStatus(reading),
                  pm25Status: _pm25Status(reading.pm25),
                  temperatureStatus: _temperatureStatus(reading.temperature),
                  humidityStatus: _humidityStatus(reading.humidity),
                  luxStatus: _luxStatus(reading.lux),
                  statusLabel: _statusLabel,
                  statusColor: _statusColor,
                  statusIcon: _statusIcon,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }

  String _computeLatestUpdate(List<_LocationReading> readings) {
    if (readings.isEmpty) return '–';
    DateTime? latest;
    for (final r in readings) {
      if (r.updatedAt != null) {
        if (latest == null || r.updatedAt!.isAfter(latest)) {
          latest = r.updatedAt;
        }
      }
    }
    if (latest == null) return '–';
    final hh = latest.hour.toString().padLeft(2, '0');
    final mm = latest.minute.toString().padLeft(2, '0');
    return '$hh:$mm น.';
  }

  Widget _buildStaleConnectionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: FacilityTheme.warningOrange,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'กำลังเชื่อมต่อข้อมูลล่าสุด... (แสดงข้อมูลชุดล่าสุดค้างไว้)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌈 Hero greeting card — ไล่เฉดสีน้ำเงินเข้มของธีม (เหมือนหน้าควบคุม
  /// ไฟ/น้ำ STK-11) แทนข้อความเรียบธรรมดา — ยังรับพารามิเตอร์ building
  /// ตามเดิม เพื่อให้ demo state "ยังไม่ได้กำหนดอาคาร" ยังใช้งานได้ถูกต้อง
  Widget _buildUserGreetingHeader({
    required String userName,
    required String building,
  }) {
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
              Icons.waving_hand_rounded,
              color: Color(0xFFE8A519),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สวัสดี, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'อาคารที่รับผิดชอบ: $building',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardsRow({
    required String building,
    required int totalLocations,
    required String latestUpdateStr,
  }) {
    return FacilityResponsiveGrid(
      spacing: 12,
      minItemWidth: 200,
      children: [
        _SummaryGlassCard(
          title: 'อาคารที่รับผิดชอบ',
          value: building,
          icon: Icons.apartment_rounded,
          iconColor: FacilityTheme.primaryPurple,
          iconBg: FacilityTheme.lightPurpleBg,
        ),
        _SummaryGlassCard(
          title: 'จำนวนตำแหน่งที่มีข้อมูล',
          value: '$totalLocations ตำแหน่ง',
          icon: Icons.sensors_rounded,
          iconColor: FacilityTheme.safeGreen,
          iconBg: const Color(0xFFECFDF5),
        ),
        _SummaryGlassCard(
          title: 'เวลาอัปเดตล่าสุด',
          value: latestUpdateStr,
          icon: Icons.access_time_rounded,
          iconColor: FacilityTheme.warningOrange,
          iconBg: const Color(0xFFFFFBEB),
        ),
      ],
    );
  }

  Widget _buildEmptySensorCard() {
    return FacilityGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      borderRadius: 20,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sensors_off_rounded,
              size: 40,
              color: FacilityTheme.softMauve,
            ),
            SizedBox(height: 10),
            Text(
              'ยังไม่มีข้อมูลเซนเซอร์สำหรับอาคารนี้',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: FacilityTheme.inkIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FacilityTheme.primaryPurple,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'กำลังโหลดข้อมูลเซนเซอร์...',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: FacilityTheme.softMauve,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          const _SkeletonCard(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildNoBuildingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserGreetingHeader(
          userName: _userName,
          building: 'ยังไม่ได้กำหนด',
        ),
        const SizedBox(height: 20),
        FacilityGlassCard(
          padding: const EdgeInsets.all(28),
          borderRadius: 24,
          borderColor: const Color(0xFFFDE68A),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.report_problem_rounded,
                  size: 44,
                  color: FacilityTheme.warningOrange,
                ),
                SizedBox(height: 12),
                Text(
                  'ยังไม่ได้กำหนดอาคารที่รับผิดชอบ',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: FacilityTheme.inkIndigo,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'กรุณาติดต่อผู้ดูแลระบบเพื่อเปิดสิทธิ์การใช้งาน',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FacilityTheme.softMauve,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryGlassCard extends StatelessWidget {
  const _SummaryGlassCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
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
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FacilityTheme.softMauve,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
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
}

/// การ์ดแสดงข้อมูลเซนเซอร์ประจำตำแหน่ง — เพิ่ม แถบสีทึบด้านซ้าย 5px (ปรับตามข้อ 4)
class _LocationSensorCard extends StatelessWidget {
  const _LocationSensorCard({
    required this.reading,
    required this.overallStatus,
    required this.pm25Status,
    required this.temperatureStatus,
    required this.humidityStatus,
    required this.luxStatus,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
  });

  final _LocationReading reading;
  final _MetricStatus overallStatus;
  final _MetricStatus pm25Status;
  final _MetricStatus temperatureStatus;
  final _MetricStatus humidityStatus;
  final _MetricStatus luxStatus;
  final String Function(_MetricStatus) statusLabel;
  final Color Function(_MetricStatus) statusColor;
  final IconData Function(_MetricStatus) statusIcon;

  String _fmt(double? v, String unit, {int decimals = 1}) {
    if (v == null) return '–';
    return '${v.toStringAsFixed(decimals)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(overallStatus);
    final timeText = reading.updatedAt == null
        ? '–'
        : '${reading.updatedAt!.hour.toString().padLeft(2, '0')}:'
              '${reading.updatedAt!.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
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
              child: Container(width: 5, color: color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon(overallStatus), size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel(overallStatus),
                        style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'อัปเดต $timeText',
                        style: const TextStyle(
                          color: FacilityTheme.softMauve,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reading.location,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: FacilityTheme.inkIndigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;
                      final metrics = [
                        _MetricTile(
                          'PM2.5',
                          _fmt(reading.pm25, 'µg/m³'),
                          statusColor(pm25Status),
                          isMissing: reading.pm25 == null,
                        ),
                        _MetricTile(
                          'อุณหภูมิ',
                          _fmt(reading.temperature, '°C'),
                          statusColor(temperatureStatus),
                          isMissing: reading.temperature == null,
                        ),
                        _MetricTile(
                          'ความชื้น',
                          _fmt(reading.humidity, '%', decimals: 0),
                          statusColor(humidityStatus),
                          isMissing: reading.humidity == null,
                        ),
                        _MetricTile(
                          'ความสว่าง',
                          _fmt(reading.lux, 'lux', decimals: 0),
                          statusColor(luxStatus),
                          isMissing: reading.lux == null,
                        ),
                      ];
                      if (isNarrow) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: metrics[0]),
                                const SizedBox(width: 10),
                                Expanded(child: metrics[1]),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: metrics[2]),
                                const SizedBox(width: 10),
                                Expanded(child: metrics[3]),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (var i = 0; i < metrics.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(child: metrics[i]),
                          ],
                        ],
                      );
                    },
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

/// การ์ดค่าเซนเซอร์ย่อย — เพิ่ม Tooltip & Icon คำอธิบายกรณีค่าเป็น "–" (ปรับตามข้อ 5)
class _MetricTile extends StatelessWidget {
  const _MetricTile(
    this.label,
    this.value,
    this.color, {
    this.isMissing = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FacilityTheme.bgSlate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: FacilityTheme.softMauve,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isMissing) ...[
                const SizedBox(width: 3),
                const Tooltip(
                  message:
                      'ตำแหน่งนี้ไม่มีเซนเซอร์ตัวนี้ หรืออยู่ระหว่างรอรับข้อมูลสัญญาณ',
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 11,
                    color: FacilityTheme.softMauve,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          if (isMissing)
            Tooltip(
              message:
                  'ตำแหน่งนี้ไม่มีเซนเซอร์ตัวนี้ หรืออยู่ระหว่างรอรับข้อมูลสัญญาณ',
              child: Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '(ไม่มีข้อมูล)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: FacilityTheme.softMauve,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

/// ปุ่มลัดนำทาง — พื้นขาวยกตัวเบาๆ + ไอคอนวงกลมสีม่วงธีม (แทนชิปสีเทาแบน)
class _QuickLinkButton extends StatelessWidget {
  const _QuickLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            // 2026-08-15: จุดที่แก้ตอนแรก (ตัด Flexible ออก) ไม่ใช่สาเหตุ
            // จริง — ตัวการจริงคือ Row มี mainAxisSize เป็น .max โดย default
            // เสมอ พอเป็นลูกของ Wrap (ที่ให้ max width เท่ากับพื้นที่ว่าง
            // ทั้งแถว ไม่ใช่แค่พื้นที่ที่เนื้อหาต้องการ) Row เลยยืดเต็ม
            // ความกว้างนั้นไปเลย ไม่ว่าจะมี Flexible อยู่ข้างในหรือไม่ก็ตาม
            // — แก้จริงคือบังคับ .min ให้ Row หุบตามเนื้อหาเสมอ
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: FacilityTheme.lightPurpleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: FacilityTheme.primaryPurple),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: FacilityTheme.inkIndigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return FacilityGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: SizedBox(
        height: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
