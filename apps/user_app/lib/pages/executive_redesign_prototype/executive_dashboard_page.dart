// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// LA-9 "ดูรายงานภาพรวมของสถานศึกษา" — ยูสเคสหลักของผู้บริหารสถานศึกษา (ผอ)
// Goal: เห็นภาพรวมทั้งโรงเรียน (การเรียนรู้ พลังงาน สิ่งแวดล้อม ความปลอดภัย
// การใช้ระบบ) ในหน้าเดียว กรองตามช่วงเวลา/ระดับชั้นได้
//
// ⚠️ BR1 (สำคัญ ต้องระวังตลอดการแก้ไขหน้านี้ในอนาคต): "ผู้บริหารเห็นภาพรวม
// ระดับโรงเรียน ไม่ใช่ข้อมูลรายคนเชิงลึกที่กระทบความเป็นส่วนตัวเกินจำเป็น"
// ห้ามใส่ชื่อ/รหัสนักเรียนรายคน หรือข้อมูลที่ระบุตัวตนได้ในหน้านี้เด็ดขาด —
// ทุกตัวเลขต้องเป็นค่าสรุป/เฉลี่ยระดับโรงเรียนหรือระดับชั้นเท่านั้น
//
// ที่มาข้อมูล 4 มิติ (ตาม Main Flow ของ LA-9):
// - ผลการเรียน ← รวมจาก LA-3 (Dashboard รายห้องเรียนของครูแต่ละคน)
// - พลังงาน/สิ่งแวดล้อม ← กลุ่ม AIO (Sensor Dashboard)
// - เหตุการณ์ความปลอดภัย ← SEC-7 (รายงานความปลอดภัยทั้งโรงเรียน)
// - การใช้งานระบบ ← ไม่มี UC ต้นทางเฉพาะ เป็นสถิติระบบ (active user/uptime)
//
// 2026-08-15: แยกออกมาเป็น content-only widget (ไม่มี Scaffold ของตัวเอง)
// เพื่อให้ ExecutiveHomePage (shell ใหม่) ใช้เป็นแท็บได้ — เดิมเป็นหน้า
// standalone มี Scaffold เอง ตอนนี้ปุ่มกระดิ่งเรียก onOpenInbox() (callback
// จาก shell) แทนที่จะ Navigator.push ตรงๆ — เพิ่ม demo-state switcher
// ให้ Exception Flow ของ LA-9 ("บางด้านยังไม่มีข้อมูล เช่นยังไม่ติดตั้ง
// เซนเซอร์ → แสดงเฉพาะด้านที่มีข้อมูล ระบุด้านที่ยังไม่มีให้ชัดเจน") ด้วย
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'executive_shared_widgets.dart';

// อุปกรณ์ประเภทเซนเซอร์สิ่งแวดล้อม/พลังงาน — ใช้แยกจากอุปกรณ์ประเภทอื่น
// (กล้อง/ปุ่มฉุกเฉิน/ไฟเตือน ฯลฯ) ตอนคำนวณมิติ "พลังงาน & สิ่งแวดล้อม"
const _environmentDeviceTypes = {
  'pm25_sensor',
  'air_quality_sensor',
  'light_sensor',
  'energy_meter',
};

class ExecutiveDashboardContent extends StatefulWidget {
  const ExecutiveDashboardContent({super.key, required this.onOpenInbox});

  final VoidCallback onOpenInbox;

  @override
  State<ExecutiveDashboardContent> createState() =>
      _ExecutiveDashboardContentState();
}

class _ExecutiveDashboardContentState extends State<ExecutiveDashboardContent> {
  String _selectedPeriod = '30 วันที่ผ่านมา';
  String _selectedGrade = 'ทุกระดับชั้น';

  // Exception Flow ของ LA-9 — จำลองกรณี "บางด้านยังไม่มีข้อมูล" (เช่น
  // อาคารบางหลังยังไม่ติดตั้งเซนเซอร์ครบ) เพื่อทดสอบว่าหน้านี้แสดงผลถูกต้อง
  bool _demoMissingEnergyData = false;

  // มิติ "พลังงาน & สิ่งแวดล้อม" กับ "การใช้งานระบบ" เชื่อมกับข้อมูลจริงแล้ว
  // (2026-08-16) ผ่าน count_school_users_by_role/list_school_devices ที่
  // เพิ่งเปิดสิทธิ์ให้ executive เรียกได้ — ไม่ตอบสนองตัวกรองช่วงเวลา/
  // ระดับชั้นเหมือนมิติอื่น เพราะเป็นตัวเลข ณ ปัจจุบัน ไม่มี RPC สรุปย้อนหลัง
  // ตามช่วงเวลาให้ (ต่างจาก "ผลการเรียน"/"ความปลอดภัย" ที่ยังเป็น mock อยู่
  // เพราะไม่มี RPC สรุปทั้งโรงเรียนเลย ไม่ใช่แค่เรื่องช่วงเวลา)
  bool _loadingRealStats = true;
  String? _realStatsError;
  Map<String, int> _userCountsByRole = {};
  List<DeviceOption> _devices = [];
  List<IncidentSummaryItem> _incidentSummaries = [];
  EnergyUsageSummary? _energySummary;
  WaterUsageSummary? _waterSummary;

  @override
  void initState() {
    super.initState();
    _loadRealStats();
  }

  Future<void> _loadRealStats() async {
    setState(() {
      _loadingRealStats = true;
      _realStatsError = null;
    });
    try {
      final results = await Future.wait([
        UserAdminService.countUsersByRole(),
        LessonService.listSchoolDevices(),
        IncidentService.getIncidentSummary(),
        UtilityService.getEnergyUsageSummary(period: 'month'),
        UtilityService.getWaterUsageSummary(period: 'month'),
      ]);
      if (!mounted) return;
      setState(() {
        _userCountsByRole = results[0] as Map<String, int>;
        _devices = results[1] as List<DeviceOption>;
        _incidentSummaries = results[2] as List<IncidentSummaryItem>;
        _energySummary = results[3] as EnergyUsageSummary?;
        _waterSummary = results[4] as WaterUsageSummary?;
        _loadingRealStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _realStatsError = 'โหลดข้อมูลไม่สำเร็จ: $e';
        _loadingRealStats = false;
      });
    }
  }

  List<DeviceOption> get _environmentDevices =>
      _devices.where((d) => _environmentDeviceTypes.contains(d.type)).toList();

  int get _totalUsers => _userCountsByRole.values.fold(0, (sum, v) => sum + v);

  static const _periodOptions = [
    '7 วันที่ผ่านมา',
    '30 วันที่ผ่านมา',
    'ภาคเรียนนี้',
  ];

  static const _gradeOptions = [
    'ทุกระดับชั้น',
    'มัธยมต้น (ม.1-3)',
    'มัธยมปลาย (ม.4-6)',
  ];

  // ชุดข้อมูลจำลองที่ตอบสนองต่อตัวกรอง — LA-9 Main Flow ข้อ 3 "กรองดูตาม
  // ช่วงเวลา/ระดับชั้นได้" ต้องทำให้ตัวเลขบนหน้าจริงเปลี่ยนตามตัวกรองที่
  // เลือก ไม่ใช่แค่ dropdown ที่กดได้แต่ไม่มีผล
  String get _periodTrendSuffix {
    switch (_selectedPeriod) {
      case '7 วันที่ผ่านมา':
        return 'จากสัปดาห์ที่แล้ว';
      case 'ภาคเรียนนี้':
        return 'จากภาคเรียนที่แล้ว';
      default:
        return 'จากเดือนที่แล้ว';
    }
  }

  ({String score, String submitRate, String attendRate}) get _learningByGrade {
    switch (_selectedGrade) {
      case 'มัธยมต้น (ม.1-3)':
        return (score: '80.2%', submitRate: '85%', attendRate: '93%');
      case 'มัธยมปลาย (ม.4-6)':
        return (score: '76.1%', submitRate: '78%', attendRate: '88%');
      default:
        return (score: '78.5%', submitRate: '82%', attendRate: '91%');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          if (_realStatsError != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: ExecutiveTheme.emergencyRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _realStatsError!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ExecutiveTheme.emergencyRed,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadRealStats,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _buildFilterRow(),
          const SizedBox(height: 14),
          _buildDemoStateSwitcher(),
          const SizedBox(height: 24),
          _buildDimensionSection(
            icon: Icons.school_rounded,
            title: 'ผลการเรียน',
            subtitle:
                'รวมจากทุกห้องเรียนในโรงเรียน · $_selectedPeriod · $_selectedGrade',
            color: ExecutiveTheme.primaryIndigo,
            hasData: true,
            cards: [
              _StatCardData(
                icon: Icons.grade_rounded,
                label: 'คะแนนเฉลี่ยทั้งโรงเรียน',
                value: _learningByGrade.score,
                trend: '↗ +2.1% $_periodTrendSuffix',
                trendColor: ExecutiveTheme.safeGreen,
              ),
              _StatCardData(
                icon: Icons.assignment_turned_in_rounded,
                label: 'อัตราส่งงานตรงเวลา',
                value: _learningByGrade.submitRate,
                trend: '↗ +5% $_periodTrendSuffix',
                trendColor: ExecutiveTheme.safeGreen,
              ),
              _StatCardData(
                icon: Icons.play_lesson_rounded,
                label: 'อัตราเข้าเรียนบทเรียน',
                value: _learningByGrade.attendRate,
                trend: '↘ -1% $_periodTrendSuffix',
                trendColor: ExecutiveTheme.warningOrange,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildDimensionSection(
            icon: Icons.bolt_rounded,
            title: 'พลังงาน & สิ่งแวดล้อม',
            subtitle:
                'รวมทุกอาคารในโรงเรียน · สรุปค่าไฟฟ้าและค่าน้ำโดยประมาณ (ประจำเดือน)',
            color: ExecutiveTheme.warningOrange,
            hasData:
                !_demoMissingEnergyData &&
                (_loadingRealStats ||
                    _environmentDevices.isNotEmpty ||
                    _energySummary != null ||
                    _waterSummary != null),
            emptyMessage:
                'ยังไม่มีข้อมูล — ยังไม่ได้ติดตั้งเซนเซอร์สิ่งแวดล้อมหรือมิเตอร์',
            disclaimerText:
                _energySummary?.disclaimer ?? _waterSummary?.disclaimer,
            cards: _loadingRealStats
                ? const []
                : [
                    _StatCardData(
                      icon: Icons.electric_bolt_rounded,
                      label: 'ประมาณการค่าไฟฟ้า (ประจำเดือน)',
                      value:
                          _energySummary != null &&
                              _energySummary!.deviceCount > 0
                          ? '฿${_energySummary!.estimatedCostThb.toStringAsFixed(2)}'
                          : 'ยังไม่มีมิเตอร์ไฟฟ้าติดตั้ง',
                      trend:
                          _energySummary != null &&
                              _energySummary!.deviceCount > 0
                          ? '${_energySummary!.totalKwh.toStringAsFixed(1)} kWh (${_energySummary!.electricityRateThb.toStringAsFixed(2)} ฿/kWh${_energySummary!.isRateDefault ? ' · อัตราเริ่มต้น' : ''})'
                          : 'นับจากอุปกรณ์ energy_meter',
                      trendColor:
                          _energySummary != null &&
                              _energySummary!.isRateDefault
                          ? ExecutiveTheme.warningOrange
                          : ExecutiveTheme.safeGreen,
                    ),
                    _StatCardData(
                      icon: Icons.water_drop_rounded,
                      label: 'ประมาณการค่าน้ำประปา (ประจำเดือน)',
                      value:
                          _waterSummary != null &&
                              _waterSummary!.deviceCount > 0
                          ? '฿${_waterSummary!.estimatedCostThb.toStringAsFixed(2)}'
                          : 'ยังไม่มีมิเตอร์น้ำติดตั้ง',
                      trend:
                          _waterSummary != null &&
                              _waterSummary!.deviceCount > 0
                          ? '${_waterSummary!.totalM3.toStringAsFixed(1)} m³ (${_waterSummary!.waterRateThb.toStringAsFixed(2)} ฿/m³${_waterSummary!.isRateDefault ? ' · อัตราเริ่มต้น' : ''})'
                          : 'ยังไม่มีอุปกรณ์ water_meter ในระบบ',
                      trendColor:
                          _waterSummary != null &&
                              _waterSummary!.deviceCount > 0
                          ? (_waterSummary!.isRateDefault
                                ? ExecutiveTheme.warningOrange
                                : ExecutiveTheme.safeGreen)
                          : ExecutiveTheme.softMauve,
                    ),
                    _StatCardData(
                      icon: Icons.sensors_rounded,
                      label: 'เซนเซอร์สิ่งแวดล้อมทั้งหมด',
                      value: '${_environmentDevices.length} ตัว',
                      trend:
                          '${_environmentDevices.where((d) => d.status == 'online').length} ตัวออนไลน์',
                      trendColor: ExecutiveTheme.softMauve,
                    ),
                    _StatCardData(
                      icon: Icons.apartment_rounded,
                      label: 'พื้นที่ที่มีเซนเซอร์',
                      value:
                          '${_environmentDevices.map((d) => d.location).toSet().length} จุด',
                      trend: 'นับจากตำแหน่งอุปกรณ์จริง',
                      trendColor: ExecutiveTheme.safeGreen,
                    ),
                  ],
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (context) {
              final totalIncidents = _incidentSummaries.fold(
                0,
                (sum, i) => sum + i.totalCount,
              );
              final sosIncidents = _incidentSummaries
                  .where((i) => i.category == IncidentCategory.sos)
                  .fold(0, (sum, i) => sum + i.totalCount);
              final validAvgTimes = _incidentSummaries
                  .where((i) => i.avgResponseSeconds != null)
                  .map((i) => i.avgResponseSeconds!);
              final avgSec = validAvgTimes.isEmpty
                  ? null
                  : validAvgTimes.reduce((a, b) => a + b) /
                        validAvgTimes.length;
              final avgFormatted = avgSec == null
                  ? 'ยังไม่มีการรับเรื่อง'
                  : avgSec < 60
                  ? '${avgSec.round()} วินาที'
                  : '${(avgSec / 60).floor()} นาที ${(avgSec % 60).round()} วิ';

              return _buildDimensionSection(
                icon: Icons.shield_rounded,
                title: 'ความปลอดภัย',
                subtitle:
                    'อ้างอิงจากรายงานเหตุการณ์ความปลอดภัยทั้งโรงเรียน (SEC-7) · ข้อมูลจริง',
                color: ExecutiveTheme.emergencyRed,
                hasData: !_loadingRealStats,
                cards: _loadingRealStats
                    ? const []
                    : [
                        _StatCardData(
                          icon: Icons.report_rounded,
                          label: 'รายงานเหตุการณ์ทั้งหมด',
                          value: '$totalIncidents ครั้ง',
                          trend:
                              'SOS $sosIncidents ครั้ง · เหตุทั่วไป ${totalIncidents - sosIncidents} ครั้ง',
                          trendColor: ExecutiveTheme.softMauve,
                        ),
                        _StatCardData(
                          icon: Icons.timer_rounded,
                          label: 'เวลาตอบสนองเฉลี่ย',
                          value: avgFormatted,
                          trend: 'คำนวณจากเวลาที่ครูรับเรื่องจริง',
                          trendColor: ExecutiveTheme.safeGreen,
                        ),
                        _StatCardData(
                          icon: Icons.category_rounded,
                          label: 'ประเภทเหตุที่รายงานเข้ามา',
                          value: '${_incidentSummaries.length} ประเภท',
                          trend: 'คำนวณสรุปแบบไม่ระบุตัวตน (PDPA)',
                          trendColor: ExecutiveTheme.safeGreen,
                        ),
                      ],
              );
            },
          ),
          const SizedBox(height: 22),
          _buildDimensionSection(
            icon: Icons.insights_rounded,
            title: 'การใช้งานระบบ',
            subtitle:
                'ภาพรวมการใช้งานทั้งโรงเรียน · ข้อมูล ณ ปัจจุบัน (ไม่แยกตามช่วงเวลา/ระดับชั้น)',
            color: ExecutiveTheme.infoCyan,
            hasData: true,
            cards: _loadingRealStats
                ? const []
                : [
                    _StatCardData(
                      icon: Icons.people_alt_rounded,
                      label: 'ผู้ใช้ทั้งหมดในระบบ',
                      value: '$_totalUsers คน',
                      trend:
                          'ครู ${_userCountsByRole['teacher'] ?? 0} · '
                          'นักเรียน ${_userCountsByRole['student'] ?? 0} · '
                          'ผู้ปกครอง ${_userCountsByRole['parent'] ?? 0}',
                      trendColor: ExecutiveTheme.softMauve,
                    ),
                    _StatCardData(
                      icon: Icons.dns_rounded,
                      label: 'อุปกรณ์ AIoT ทั้งหมด',
                      value: '${_devices.length} ตัว',
                      trend:
                          '${_devices.where((d) => d.status == 'online').length} ตัวออนไลน์',
                      trendColor: ExecutiveTheme.safeGreen,
                    ),
                    _StatCardData(
                      icon: Icons.login_rounded,
                      label: 'อุปกรณ์ออนไลน์',
                      value: _devices.isEmpty
                          ? '-'
                          : '${(_devices.where((d) => d.status == 'online').length / _devices.length * 100).round()}%',
                      trend: 'ข้อมูลสด ณ ตอนนี้',
                      trendColor: ExecutiveTheme.safeGreen,
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  /// 🌈 Hero header — ไล่เฉดสี indigo เข้ม (ธีมของ role นี้) + กระดิ่ง
  /// แจ้งเตือน (เรียก onOpenInbox) + ปุ่ม Export (LA-11)
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ExecutiveTheme.primaryIndigo,
            ExecutiveTheme.primaryIndigoLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ExecutiveTheme.primaryIndigo.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final greeting = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: ExecutiveTheme.goldAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ภาพรวมสถานศึกษา',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ผู้บริหารสถานศึกษา · โรงเรียน AIoT Smart School',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final exportButton = Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showExportFormatPicker(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Export รายงาน',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // ตัวเลข badge (2) เป็น mock คงที่ ยังไม่ได้คำนวณจากจำนวนเคส
          // ค้างจริง — กดแล้วเรียก onOpenInbox() ให้ ExecutiveHomePage
          // (shell) สลับไปแท็บศูนย์แจ้งเตือนแทนการ Navigator.push ตรงๆ
          final notificationBell = Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onOpenInbox,
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: CircleAvatar(
                        radius: 7,
                        backgroundColor: ExecutiveTheme.emergencyRed,
                        child: Text(
                          '2',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                greeting,
                const SizedBox(height: 14),
                Row(
                  children: [
                    notificationBell,
                    const SizedBox(width: 10),
                    Expanded(child: exportButton),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: greeting),
              const SizedBox(width: 12),
              notificationBell,
              const SizedBox(width: 10),
              exportButton,
            ],
          );
        },
      ),
    );
  }

  /// LA-11 Main Flow ข้อ 2 "เลือก 'Export' และรูปแบบไฟล์ (PDF/Excel)" —
  /// ต้องให้เลือกฟอร์แมตก่อนสร้างไฟล์ ไม่ใช่ export ทันทีแบบไม่มีตัวเลือก
  void _showExportFormatPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'เลือกรูปแบบไฟล์ Export',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: ExecutiveTheme.inkIndigo,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: ExecutiveTheme.emergencyRed,
                ),
                title: const Text('PDF'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _exportReport(context, 'PDF');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.table_chart_rounded,
                  color: ExecutiveTheme.safeGreen,
                ),
                title: const Text('Excel'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _exportReport(context, 'Excel');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _exportReport(BuildContext context, String format) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('ส่งออกรายงานเป็น $format เรียบร้อยแล้ว 📄')),
      );
  }

  /// ตัวกรองช่วงเวลา/ระดับชั้น — ตาม LA-9 Main Flow ข้อ 3
  Widget _buildFilterRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildDropdownPill(
          icon: Icons.calendar_today_rounded,
          value: _selectedPeriod,
          options: _periodOptions,
          onChanged: (val) => setState(() => _selectedPeriod = val),
        ),
        _buildDropdownPill(
          icon: Icons.groups_rounded,
          value: _selectedGrade,
          options: _gradeOptions,
          onChanged: (val) => setState(() => _selectedGrade = val),
        ),
      ],
    );
  }

  Widget _buildDropdownPill({
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
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
          Icon(icon, size: 15, color: ExecutiveTheme.primaryIndigo),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: ExecutiveTheme.primaryIndigo,
              ),
              style: const TextStyle(
                color: ExecutiveTheme.inkIndigo,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              items: options.map((o) {
                return DropdownMenuItem(value: o, child: Text(o));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// แผงทดสอบ Exception Flow ของ LA-9 — สไตล์กรอบเส้นประเดียวกับที่ใช้ใน
  /// ฝั่งผู้ดูแลอาคาร (แยกจาก UI จริงด้วยสายตา ไม่ใช่ฟีเจอร์จริง)
  Widget _buildDemoStateSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ExecutiveTheme.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 14,
            color: ExecutiveTheme.softMauve,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ทดสอบ Exception Flow: จำลองบางอาคารยังไม่ติดตั้งเซนเซอร์ (Demo)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: ExecutiveTheme.softMauve,
              ),
            ),
          ),
          Switch(
            value: _demoMissingEnergyData,
            onChanged: (v) => setState(() => _demoMissingEnergyData = v),
            activeColor: ExecutiveTheme.primaryIndigo,
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool hasData,
    required List<_StatCardData> cards,
    String? emptyMessage,
    String? disclaimerText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: ExecutiveTheme.inkIndigo,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: ExecutiveTheme.softMauve,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasData)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: ExecutiveTheme.softMauve,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    emptyMessage ?? 'ยังไม่มีข้อมูลสำหรับมิตินี้',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ExecutiveTheme.softMauve,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ExecutiveResponsiveGrid(
            spacing: 12,
            minItemWidth: 220,
            children: [for (final c in cards) _buildStatCard(c)],
          ),
          if (disclaimerText != null && disclaimerText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ExecutiveTheme.warningOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ExecutiveTheme.warningOrange.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: ExecutiveTheme.warningOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      disclaimerText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ExecutiveTheme.inkIndigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return ExecutiveGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ExecutiveTheme.lightIndigoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data.icon,
              size: 18,
              color: ExecutiveTheme.primaryIndigo,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: ExecutiveTheme.softMauve,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: ExecutiveTheme.inkIndigo,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.trend,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: data.trendColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final Color trendColor;
}
