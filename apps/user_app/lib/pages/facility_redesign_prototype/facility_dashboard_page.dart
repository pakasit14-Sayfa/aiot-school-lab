// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// ปรับปรุงการจัดวางและหน้าตา (Dashboard Redesign)
// ให้มีความเป็น SaaS Admin ระดับพรีเมียม สบายตา และมีลำดับความสำคัญของข้อมูลชัดเจน
import 'dart:math';
import 'package:flutter/material.dart';
import '../aiot_dashboard_page.dart';
import 'facility_device_health_page.dart';
import 'facility_shared_widgets.dart';
import 'facility_ux_states.dart';

class FacilityDashboardPage extends StatefulWidget {
  const FacilityDashboardPage({
    super.key,
    required this.onNavigateToWizard,
    required this.onNavigateToIncidents,
    required this.onNavigateToMaintenance,
    required this.onNavigateToMap,
  });

  final VoidCallback onNavigateToWizard;
  final VoidCallback onNavigateToIncidents;
  final VoidCallback onNavigateToMaintenance;
  final VoidCallback onNavigateToMap;

  @override
  State<FacilityDashboardPage> createState() => _FacilityDashboardPageState();
}

class _FacilityDashboardPageState extends State<FacilityDashboardPage> {
  String _selectedPeriod = '30 วันที่ผ่านมา';

  // 2026-08-15: เดิมเป็น dropdown ให้สลับดู 'อาคาร 1'/'อาคาร 2'/'ทุกอาคาร
  // รวมกัน' ได้ — ขัดกับ STK-6/7/9/10/11 ที่ทุกตัวกำหนดตรงกันว่า scope =
  // อาคารที่รับผิดชอบเท่านั้น (ผู้ดูแลอาคารดูแลอาคารเดียว ไม่ใช่ทั้งโรงเรียน)
  // เปลี่ยนเป็นค่าคงที่ ไม่มีทางสลับไปอาคารอื่นได้จาก dashboard นี้อีก
  static const String _assignedBuilding = 'อาคาร 3 (วิทยาศาสตร์)';

  String _selectedReportFilter = 'ทั้งหมด';

  // 2026-08-15: 'เหตุฉุกเฉิน/SOS' เดิมสื่อว่าหน้านี้กรองดูเหตุฉุกเฉินบุคคล
  // ได้ — ผิดสโคปตาม STK-12 (ดูรายละเอียดใน NOTES.md) เปลี่ยนเป็นสโคป
  // อุปกรณ์/อาคารให้ตรงกับสิ่งที่ผู้ดูแลอาคารเข้าถึงได้จริง
  final List<String> _reportFilterOptions = [
    'ทั้งหมด',
    'เหตุอุปกรณ์/อาคาร',
    'งานซ่อมบำรุง',
    'สิ่งแวดล้อม',
  ];

  final List<Map<String, dynamic>> _activityHistory = [
    {
      'id': '#FAC-8041',
      'statusText': '✓ ปกติเรียบร้อย',
      'statusColor': FacilityTheme.safeGreen,
      'dateTime': '14/10/2024 08:30 น.',
      'location': 'อาคาร 3 ชั้น 1',
      'user': 'ครูสมชาย',
    },
    {
      'id': '#EQP-3020',
      'statusText': '🔧 แจ้งเหตุอุปกรณ์ด่วน',
      'statusColor': FacilityTheme.warningOrange,
      'dateTime': '14/10/2024 08:28 น.',
      'location': 'อาคาร 3 ชั้น 3',
      'user': 'ยังไม่รับเรื่อง',
    },
    {
      'id': '#WRK-1092',
      'statusText': '🔄 รอดำเนินการ',
      'statusColor': FacilityTheme.warningOrange,
      'dateTime': '14/10/2024 07:45 น.',
      'location': 'อาคาร 3 ชั้น 2',
      'user': 'ช่างอนันต์',
    },
    {
      'id': '#FAC-8039',
      'statusText': '✓ ปกติเรียบร้อย',
      'statusColor': FacilityTheme.safeGreen,
      'dateTime': '14/10/2024 07:12 น.',
      'location': 'อาคาร 3 ชั้น 2',
      'user': 'ครูสมชาย',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 Prominent Integrated Command Header Card
          _buildUnifiedHeaderBanner(),
          const SizedBox(height: 18),

          // ⚡ Modern Quick Actions Bar
          _buildQuickActionsRow(),
          const SizedBox(height: 20),

          // 📊 4 Operational KPI Cards (มี แถบสีทึบด้านซ้าย 5px + Card SOS 1-Click Action)
          _build4OperationalCards(),
          const SizedBox(height: 22),

          // 🌡️ AIoT Weather Sensors Card + 📊 สถานะจุดตรวจ (Donut) — วางคู่กัน
          // ซ้าย-ขวา ตามที่ผู้ใช้ขอ (เดิมการ์ดโดนัทอยู่คู่กับตารางประวัติ
          // ด้านล่างแทน)
          //
          // ⚠️ เคยลอง IntrinsicHeight + CrossAxisAlignment.stretch เพื่อให้
          // สูงเท่ากันเป๊ะ แต่ทำให้ overflow ทั้งสองการ์ดตอนจอแคบ (เพราะ
          // ความสูงที่คำนวณแบบ intrinsic ไม่ตรงกับความสูงจริงที่ Column
          // ต้องการพอดี — เป็นข้อจำกัดที่รู้กันของ IntrinsicHeight ใน
          // Flutter ตรงกับกติกาเดิมในโปรเจกต์ที่เคยห้ามใช้
          // IntrinsicHeight+Row มาก่อนแล้ว) เลยเปลี่ยนกลับมาใช้ Row ธรรมดา
          // แทน — แต่ละการ์ดสูงตามเนื้อหาตัวเอง (อาจไม่เท่ากันเป๊ะแต่ปลอดภัย
          // ไม่มี overflow แน่นอน)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _FacilityAiotWeatherSensorsCard()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildStatisticsDonutCard()),
                  ],
                );
              }
              return Column(
                children: [
                  const _FacilityAiotWeatherSensorsCard(),
                  const SizedBox(height: 20),
                  _buildStatisticsDonutCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          const Divider(color: FacilityTheme.purpleBorder, height: 1),
          const SizedBox(height: 24),

          // 📈 Secondary Reports Section — LayoutBuilder สลับ Row/Column
          // ตาม breakpoint (จอแคบ: ตัวกรอง/ช่วงเวลา/export กว้างรวมกันเกิน
          // จอมือถือ เคย RIGHT OVERFLOW เพราะ Row เดิมให้ความกว้างไม่จำกัด
          // กับ Wrap ข้างใน _buildFilterAndActionControls() ทำให้มันไม่ยอม
          // ตกบรรทัดเลย ต้องวางใน Column ให้ Wrap มีความกว้างจำกัดถึงจะ
          // ตกบรรทัดได้จริง)
          LayoutBuilder(
            builder: (context, constraints) {
              const title = Text(
                'รายงานสถิติประกอบ & ประวัติการทำงาน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: FacilityTheme.inkIndigo,
                ),
              );
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    _buildFilterAndActionControls(),
                  ],
                );
              }
              return Row(
                children: [
                  title,
                  const Spacer(),
                  _buildFilterAndActionControls(),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildTop3KpiCards(),
          const SizedBox(height: 28),

          _buildOrdersHistoryTableCard(),
        ],
      ),
    );
  }

  /// 🟢 Integrated Command Header Card
  Widget _buildUnifiedHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Header Top Row: Welcome & Building Selector — LayoutBuilder
          // เพื่อสลับเป็น Column ตอนจอแคบ (มือถือ) เดิมยัด Expanded(ข้อความ
          // ทักทาย) + Dropdown pill + Status badge ไว้ใน Row เดียวกันตายตัว
          // พอจอแคบ 2 pill ที่ไม่ยอมย่อขนาดบีบพื้นที่ Expanded จนเหลือเกือบ
          // 0 ทำให้ตัวอักษรตกบรรทัดทีละตัวในแนวตั้ง (บั๊กจริงที่เจอ)
          LayoutBuilder(
            builder: (context, constraints) {
              final greeting = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'สวัสดี, ครูสมชาย! 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: FacilityTheme.inkIndigo,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ระบบบริหารจัดการความปลอดภัยและสิ่งแวดล้อมอาคาร',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: FacilityTheme.softMauve,
                    ),
                  ),
                ],
              );

              // 2026-08-15: เปลี่ยนจาก dropdown สลับอาคารเป็น pill แสดง
              // อาคารที่รับผิดชอบเฉยๆ (ดูเหตุผลที่ state ด้านบน) — ไม่มี
              // ทางกดเปลี่ยนอาคารจากตรงนี้แล้ว
              final buildingDropdownPill = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: FacilityTheme.lightPurpleBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FacilityTheme.purpleBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 14,
                      color: FacilityTheme.primaryPurple,
                    ),
                    SizedBox(width: 6),
                    Text(
                      _assignedBuilding,
                      style: TextStyle(
                        color: FacilityTheme.primaryPurple,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );

              final statusBadge = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.door_sliding_rounded,
                      color: FacilityTheme.safeGreen,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'เปิดอาคารอยู่',
                      style: TextStyle(
                        color: FacilityTheme.safeGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    greeting,
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [buildingDropdownPill, statusBadge],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: greeting),
                  const SizedBox(width: 12),
                  buildingDropdownPill,
                  const SizedBox(width: 10),
                  statusBadge,
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          // ⏱️ Duty Timer & Log Navigation Row
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: FacilityTheme.primaryPurple,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'รอบตรวจถัดไป: 16:30 น. (อีก 5 ชม. 30 นาที) · กำหนดปิด: 17:30 น.',
                  style: TextStyle(
                    color: FacilityTheme.inkIndigo,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: widget.onNavigateToWizard,
                icon: const Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 15,
                  color: FacilityTheme.primaryPurple,
                ),
                label: const Text(
                  'ดูบันทึกการตรวจ >',
                  style: TextStyle(
                    color: FacilityTheme.primaryPurple,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),

          // 📡 AIoT Hardware Health Row (Multi-Color Category Chips)
          Row(
            children: [
              const Icon(
                Icons.sensors_rounded,
                size: 16,
                color: FacilityTheme.primaryPurple,
              ),
              const SizedBox(width: 6),
              const Text(
                'สุขภาพ AIoT:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: FacilityTheme.inkIndigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDetailedHealthChip(
                        icon: Icons.videocam_rounded,
                        label: 'กล้อง 12/12 ออนไลน์',
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFF0F9FF),
                      ),
                      const SizedBox(width: 8),
                      _buildDetailedHealthChip(
                        icon: Icons.router_rounded,
                        label: 'Gateway ปกติ (99.8%)',
                        color: FacilityTheme.primaryPurple,
                        bgColor: const Color(0xFFF5F3FF),
                      ),
                      const SizedBox(width: 8),
                      _buildDetailedHealthChip(
                        icon: Icons.battery_charging_full_rounded,
                        label: 'SOS Box #03 แบต 88%',
                        color: FacilityTheme.safeGreen,
                        bgColor: const Color(0xFFECFDF5),
                      ),
                      const SizedBox(width: 8),
                      _buildDetailedHealthChip(
                        icon: Icons.air_rounded,
                        label: 'PM2.5 Active 6/6 จุด',
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFFF0FDFA),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // กัน push ซ้อนหลายหน้าถ้าผู้ใช้แตะรัวๆ (แพทเทิร์นเดียวกับ
                  // จุดอื่นในไฟล์นี้ที่มี Navigator.push)
                  if (ModalRoute.of(context)?.isCurrent ?? true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        // FacilityDeviceHealthPage เป็น content-only (ไม่มี
                        // Scaffold ของตัวเอง เพื่อให้ใช้เป็น nav item ใน
                        // FacilityAppShell ได้ด้วย) — ตอน push แบบหน้าเดี่ยว
                        // จึงต้องห่อ Scaffold+AppBar เอง เหมือนที่
                        // facility_building_overview_page.dart ทำไว้
                        builder: (_) => Scaffold(
                          backgroundColor: FacilityTheme.bgSlate,
                          appBar: AppBar(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            foregroundColor: FacilityTheme.inkIndigo,
                            title: const Text(
                              'สถานะสุขภาพอุปกรณ์ AIoT (STK-9)',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          body: const SafeArea(
                            child: FacilityDeviceHealthPage(),
                          ),
                        ),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'ดูเพิ่มเติม >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: FacilityTheme.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedHealthChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Modern Quick Actions Bar (ปรับปรุงให้สบายตาและเรียบหรู)
  Widget _buildQuickActionsRow() {
    return FacilityResponsiveGrid(
      spacing: 12,
      minItemWidth: 180,
      children: [
        _buildModernQuickActionCard(
          // 2026-08-15: เดิมชื่อ 'เริ่มเปิด-ปิดอาคาร'/'เปิดเวรประจำวัน' +
          // ไอคอนประตู ตกค้างจากก่อนแทนที่ด้วย STK-11 เมื่อวาน (2026-08-14)
          // ทั้งที่ onNavigateToWizard พาไปหน้าควบคุมไฟ/น้ำจริงแล้ว —
          // เปลี่ยนป้าย/ไอคอนให้ตรงปลายทาง (แพทเทิร์นเดียวกับตอนเปลี่ยน
          // ชื่อเมนู index 1 ใน facility_shared_widgets.dart)
          title: 'เปิด-ปิดไฟ/น้ำ',
          subtitle: 'ตามอาคารที่รับผิดชอบ (STK-11)',
          icon: Icons.lightbulb_rounded,
          color: FacilityTheme.primaryPurple,
          bgColor: const Color(0xFFF5F3FF),
          onTap: widget.onNavigateToWizard,
        ),
        // 2026-08-15: เดิมชื่อ 'แจ้งเหตุฉุกเฉิน'/'ส่งสัญญาณ SOS' แต่ปลายทาง
        // จริง (onNavigateToIncidents) คือหน้ารับเรื่องเหตุอุปกรณ์/อาคาร
        // (STK-12) ไม่ใช่การส่ง SOS จริง — ป้ายเดิมชวนเข้าใจผิด เปลี่ยนให้
        // ตรงปลายทาง ส่วนการส่ง SOS จริงใช้ปุ่มลอย FacilityFloatingSOSButton
        _buildModernQuickActionCard(
          title: 'เหตุอุปกรณ์/อาคาร',
          subtitle: 'ดูรายการรับเรื่อง (STK-12)',
          icon: Icons.report_problem_rounded,
          color: FacilityTheme.emergencyRed,
          bgColor: const Color(0xFFFEF2F2),
          onTap: widget.onNavigateToIncidents,
        ),
        _buildModernQuickActionCard(
          title: 'สร้างงานซ่อม',
          subtitle: 'แจ้งอุปกรณ์ชำรุด',
          icon: Icons.build_rounded,
          color: FacilityTheme.warningOrange,
          bgColor: const Color(0xFFFFFBEB),
          onTap: widget.onNavigateToMaintenance,
        ),
        _buildModernQuickActionCard(
          title: 'แผนที่อาคาร',
          subtitle: 'ดูผังจุดตรวจ 3D',
          icon: Icons.map_rounded,
          color: const Color(0xFF0284C7),
          bgColor: const Color(0xFFF0F9FF),
          onTap: widget.onNavigateToMap,
        ),
      ],
    );
  }

  Widget _buildModernQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: FacilityTheme.inkIndigo,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: FacilityTheme.softMauve,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Operational Summary 4 Cards (พร้อม แถบสีทึบด้านซ้าย 5px + 1-Click SOS Action)
  Widget _build4OperationalCards() {
    return FacilityResponsiveGrid(
      spacing: 16,
      minItemWidth: 200,
      children: [
        _buildAccentMetricGlassCard(
          title: 'จุดตรวจปกติ',
          value: '18 จุด',
          trendText: '✓ ตรวจผ่านเรียบร้อย',
          statusColor: FacilityTheme.safeGreen,
          icon: Icons.check_circle_rounded,
          iconBg: const Color(0xFFECFDF5),
        ),
        _buildAccentMetricGlassCard(
          title: 'จุดเฝ้าระวัง',
          value: '2 จุด',
          trendText: '⚠️ PM2.5 / ประตูแง้ม',
          statusColor: FacilityTheme.warningOrange,
          icon: Icons.warning_amber_rounded,
          iconBg: const Color(0xFFFFFBEB),
        ),
        // Card 3: เหตุใหม่ (พร้อม แถบสีทึบด้านซ้าย 5px + 1-Click Quick SOS Action Button)
        _buildSosOperationalCard(),
        _buildAccentMetricGlassCard(
          title: 'งานซ่อมค้าง',
          value: '3 งาน',
          trendText: '🔄 รอดำเนินการ',
          statusColor: const Color(0xFF0284C7),
          icon: Icons.build_rounded,
          iconBg: const Color(0xFFF0F9FF),
        ),
      ],
    );
  }

  Widget _buildAccentMetricGlassCard({
    required String title,
    required String value,
    required String trendText,
    required Color statusColor,
    required IconData icon,
    required Color iconBg,
  }) {
    return SizedBox(
      height: 108,
      child: Container(
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
                child: Container(width: 5, color: statusColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: FacilityTheme.softMauve,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(icon, color: statusColor, size: 15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: FacilityTheme.inkIndigo,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trendText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2026-08-15: เดิมการ์ดนี้เป็น "1-Click SOS Action" ให้ผู้ดูแลอาคารกด
  // "รับเรื่อง SOS" ของเหตุฉุกเฉินบุคคล (ห้อง 302) ได้ตรงจากการ์ดนี้เลย
  // โดยไม่ผ่านอะไรทั้งนั้น — ขัดกับ STK-12 Exception Flow ข้อ 1 ชัดเจน
  // (ห้ามให้ผู้ดูแลอาคารรับเรื่องเหตุฉุกเฉินบุคคลแบบ flow ปกติ) เปลี่ยนเป็น
  // การ์ดสรุปจำนวนเหตุอุปกรณ์ใหม่ที่รอรับเรื่อง กดแล้วพาไปหน้ารับเรื่องจริง
  // (`facility_incident_inbox_page.dart` ที่เพิ่งปรับให้ตรง STK-12 แทน)
  Widget _buildSosOperationalCard() {
    const statusColor = FacilityTheme.emergencyRed;

    return SizedBox(
      height: 108,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onNavigateToIncidents,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: FacilityTheme.emergencyRed.withValues(alpha: 0.4),
              ),
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
                    child: Container(width: 5, color: statusColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'เหตุอุปกรณ์ใหม่',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: FacilityTheme.softMauve,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.report_gmailerrorred_rounded,
                                color: statusColor,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '1 รายการ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '🔧 แอร์ห้อง 210 (ยังไม่รับเรื่อง)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'ไปที่หน้ารับเรื่อง',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: statusColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterAndActionControls() {
    const double barHeight = 36.0;
    const double borderRadius = 14.0;
    const double fontSize = 12.0;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. ปุ่ม "ตัวกรอง"
        Material(
          color: _selectedReportFilter == 'ทั้งหมด'
              ? Colors.white
              : FacilityTheme.lightPurpleBg,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: () {
              if (ModalRoute.of(context)?.isCurrent ?? true) {
                _showReportFilterSheet(context);
              }
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              height: barHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: _selectedReportFilter == 'ทั้งหมด'
                      ? const Color(0xFFE2E8F0)
                      : FacilityTheme.primaryPurple,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: _selectedReportFilter == 'ทั้งหมด'
                        ? FacilityTheme.inkIndigo
                        : FacilityTheme.primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedReportFilter == 'ทั้งหมด'
                        ? 'ตัวกรอง'
                        : 'ตัวกรอง: $_selectedReportFilter',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: _selectedReportFilter == 'ทั้งหมด'
                          ? FacilityTheme.inkIndigo
                          : FacilityTheme.primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Dropdown "30 วันที่ผ่านมา"
        Container(
          height: barHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: FacilityTheme.inkIndigo,
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: FacilityTheme.softMauve,
                    size: 18,
                  ),
                  style: const TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: FacilityTheme.inkIndigo,
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPeriod = val;
                      });
                    }
                  },
                  items:
                      [
                        '7 วันที่ผ่านมา',
                        '30 วันที่ผ่านมา',
                        '3 เดือนที่ผ่านมา',
                      ].map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                ),
              ),
            ],
          ),
        ),

        // 3. ปุ่ม "ออกรายงาน PDF"
        Material(
          color: const Color(0xFF1C4D63),
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: () {
              FacilityUXStates.showSuccessToast(
                context,
                'ส่งออกรายงาน PDF เรียบร้อยแล้ว 📄',
                subtitle:
                    'ระบบทำการประมวลผลและสร้างไฟล์ PDF สถิติประกอบให้เรียบร้อยแล้ว',
                accentColor: const Color(0xFF1C4D63),
                icon: Icons.picture_as_pdf_rounded,
              );
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              height: barHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'ออกรายงาน PDF',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showReportFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'กรองรายงานสถิติประกอบ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: FacilityTheme.inkIndigo,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _reportFilterOptions.map((option) {
                    final isSelected = option == _selectedReportFilter;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(option),
                      onSelected: (_) {
                        setState(() => _selectedReportFilter = option);
                        Navigator.of(sheetContext).pop();
                        FacilityUXStates.showSuccessToast(
                          context,
                          'ปรับใช้ตัวกรองเรียบร้อยแล้ว 🎯',
                          subtitle:
                              'ระบบทำการสลับมาแสดงผลข้อมูลสถิติเฉพาะหมวด "$option"',
                          accentColor: FacilityTheme.primaryPurple,
                          icon: Icons.tune_rounded,
                        );
                      },
                      selectedColor: FacilityTheme.primaryPurple,
                      backgroundColor: FacilityTheme.lightPurpleBg,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : FacilityTheme.inkIndigo,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? FacilityTheme.primaryPurple
                              : FacilityTheme.purpleBorder,
                        ),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTop3KpiCards() {
    return FacilityResponsiveGrid(
      spacing: 20,
      minItemWidth: 240,
      children: [
        _buildMetricGlassCard(
          title: 'จุดตรวจความปลอดภัยรวม',
          value: '18 / 21 จุด',
          trendText: '↗ +5% จากเดือนที่แล้ว',
          trendColor: const Color(0xFF16A34A),
          icon: Icons.shield_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
        ),
        _buildMetricGlassCard(
          title: 'ชั่วโมงปฏิบัติงานเวรสะสม',
          value: '158 ชั่วโมง',
          trendText: '↗ +20% จากเดือนที่แล้ว',
          trendColor: const Color(0xFF16A34A),
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
        ),
        _buildMetricGlassCard(
          title: 'คะแนนประหยัดพลังงาน',
          value: '85 / 100 คะแนน',
          trendText: '↘ -2% จากเดือนที่แล้ว',
          trendColor: const Color(0xFFDC2626),
          icon: Icons.eco_rounded,
          iconColor: const Color(0xFF65A30D),
          iconBg: const Color(0xFFECFCCB),
        ),
      ],
    );
  }

  Widget _buildMetricGlassCard({
    required String title,
    required String value,
    required String trendText,
    required Color trendColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return FacilityGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      borderRadius: 14,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            trendText,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsDonutCard() {
    return FacilityGlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'สถานะจุดตรวจสอบ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: FacilityTheme.inkIndigo,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToMap,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'ดูเพิ่มเติม >',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: FacilityTheme.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLegendRow('✓ ปกติ', '16 จุด (76%)', FacilityTheme.safeGreen),
          const SizedBox(height: 8),
          _buildLegendRow(
            '⚠️ มีปัญหา',
            '2 จุด (10%)',
            FacilityTheme.emergencyRed,
          ),
          const SizedBox(height: 8),
          _buildLegendRow(
            '– ยังไม่ตรวจ',
            '3 จุด (14%)',
            const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: DonutChartPainter(
                      segments: [
                        DonutSegment(
                          value: 16 / 21,
                          color: FacilityTheme.safeGreen,
                        ),
                        DonutSegment(
                          value: 2 / 21,
                          color: FacilityTheme.emergencyRed,
                        ),
                        DonutSegment(
                          value: 3 / 21,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'จุดตรวจทั้งหมด',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FacilityTheme.softMauve,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '21 จุด',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: FacilityTheme.inkIndigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String title, String percent, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: FacilityTheme.softMauve,
          ),
        ),
        const Spacer(),
        Text(
          percent,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: FacilityTheme.inkIndigo,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersHistoryTableCard() {
    return FacilityGlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ประวัติการเปิด-ปิด & แจ้งเหตุล่าสุด',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: FacilityTheme.inkIndigo,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToIncidents,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'ดูเพิ่มเติม >',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: FacilityTheme.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // LayoutBuilder สลับเป็นการ์ดรายการแบบย่อตอนจอแคบ (มือถือ) — ตาราง
          // 5 คอลัมน์เดิมทำให้ข้อความ ("#FAC-8041" ฯลฯ) ตัดคำล้นแนวตั้งในแต่
          // ละคอลัมน์แคบเกินไปบนมือถือ (บั๊กที่ผู้ใช้เจอ)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return Column(
                  children: _activityHistory
                      .map(_buildCompactHistoryRow)
                      .toList(),
                );
              }
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'รหัสรายการ',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: FacilityTheme.softMauve,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'สถานะ',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: FacilityTheme.softMauve,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'วันและเวลา',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: FacilityTheme.softMauve,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ตำแหน่ง',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: FacilityTheme.softMauve,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ผู้ปฏิบัติงาน',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: FacilityTheme.softMauve,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: FacilityTheme.purpleBorder, height: 1),
                  const SizedBox(height: 8),
                  ..._activityHistory.map((row) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: FacilityTheme.purpleBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: FacilityTheme.lightPurpleBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  row['id'] as String,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: FacilityTheme.inkIndigo,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              row['statusText'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: row['statusColor'] as Color,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              row['dateTime'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FacilityTheme.softMauve,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              row['location'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: FacilityTheme.inkIndigo,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              row['user'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FacilityTheme.softMauve,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// การ์ดรายการย่อสำหรับจอแคบ — แทนแถวตาราง 5 คอลัมน์ที่ตัดคำล้นตอนจอ
  /// แคบ ID+สถานะอยู่แถวบน ตำแหน่ง·เวลา กับผู้ปฏิบัติงานอยู่แถวล่าง
  Widget _buildCompactHistoryRow(Map<String, dynamic> row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FacilityTheme.purpleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FacilityTheme.lightPurpleBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  row['id'] as String,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: FacilityTheme.inkIndigo,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                row['statusText'] as String,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: row['statusColor'] as Color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${row['location']} · ${row['dateTime']}',
            style: const TextStyle(
              fontSize: 11,
              color: FacilityTheme.softMauve,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            row['user'] as String,
            style: const TextStyle(
              fontSize: 11,
              color: FacilityTheme.softMauve,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DonutSegment {
  DonutSegment({required this.value, required this.color});
  final double value;
  final Color color;
}

class DonutChartPainter extends CustomPainter {
  DonutChartPainter({required this.segments});
  final List<DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 12;
    const strokeWidth = 24.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;
    const gapAngle = 0.12;

    for (final segment in segments) {
      final sweepAngle = (segment.value * 2 * pi) - gapAngle;
      paint.color = segment.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}

class _FacilityAiotWeatherSensorsCard extends StatelessWidget {
  const _FacilityAiotWeatherSensorsCard();

  @override
  Widget build(BuildContext context) {
    return FacilityGlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: FacilityTheme.safeGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FacilityTheme.safeGreen.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ข้อมูลเซนเซอร์สภาพอากาศ AIoT',
                  style: TextStyle(
                    color: FacilityTheme.inkIndigo,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (ModalRoute.of(context)?.isCurrent ?? true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiotDashboardPage(),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'ไปหน้า AIoT Dashboard >',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: FacilityTheme.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _FacilityAiotSensorRow(
            icon: Icons.air_rounded,
            title: 'ฝุ่น PM2.5 (ห้องเรียนปลอดภัย)',
            value: '18',
            unit: 'µg/m³',
            subtitle: 'สภาพอากาศดีมาก',
            level: 'ปกติ',
            showDivider: true,
          ),
          const _FacilityAiotSensorRow(
            icon: Icons.thermostat_rounded,
            title: 'อุณหภูมิห้องเรียน',
            value: '28.5',
            unit: '°C',
            subtitle: 'อบอุ่นกำลังดี',
            level: 'ปกติ',
            showDivider: true,
          ),
          const _FacilityAiotSensorRow(
            icon: Icons.water_drop_rounded,
            title: 'ความชื้นสัมพัทธ์',
            value: '62',
            unit: '%RH',
            subtitle: 'สภาพแวดล้อมเหมาะสม',
            level: 'ปกติ',
            showDivider: true,
          ),
          const _FacilityAiotSensorRow(
            icon: Icons.wb_sunny_rounded,
            title: 'ดัชนีรังสี UV',
            value: 'UV 6',
            subtitle: 'เฝ้าระวังแสงแดดจัด',
            level: 'ไม่ปลอดภัย',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _FacilityAiotSensorRow extends StatelessWidget {
  const _FacilityAiotSensorRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.level,
    this.value,
    this.unit,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String level;
  final String? value;
  final String? unit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    // ใช้ MediaQuery แทน LayoutBuilder — LayoutBuilder ไม่รองรับการคำนวณ
    // intrinsic dimensions (throw error ตอนถูกห่อด้วย IntrinsicHeight เช่น
    // ตอนวาง _FacilityAiotWeatherSensorsCard คู่กับการ์ดอื่นแบบ stretch
    // height เท่ากัน) ทำให้หน้าเรนเดอร์ไม่ออกทั้งหน้าเงียบๆ ไม่มี error log
    // ชัดเจนใน release — เป็นบั๊กรันไทม์ที่ flutter analyze จับไม่ได้เหมือน
    // บั๊ก ElevatedButton/TextField border ที่เคยเจอมาก่อน
    final isCompact = MediaQuery.sizeOf(context).width < 560;
    final isNormal = level == 'ปกติ';

    Color iconBgColor;
    Color iconColor;
    if (icon == Icons.air_rounded) {
      iconBgColor = const Color(0xFFE0F2FE);
      iconColor = const Color(0xFF0284C7);
    } else if (icon == Icons.thermostat_rounded) {
      iconBgColor = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFEA580C);
    } else if (icon == Icons.water_drop_rounded) {
      iconBgColor = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF2563EB);
    } else {
      iconBgColor = const Color(0xFFFFF1F2);
      iconColor = const Color(0xFFE11D48);
    }

    final badgeBgColor = isNormal
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);
    final badgeTextColor = isNormal
        ? FacilityTheme.safeGreen
        : FacilityTheme.emergencyRed;
    final badgeDotColor = badgeTextColor;
    final badgeBorderColor = isNormal
        ? const Color(0xFFA7F3D0).withValues(alpha: 0.6)
        : const Color(0xFFFECACA).withValues(alpha: 0.6);

    return Container(
      padding: EdgeInsets.only(
        top: isCompact ? 9 : 10,
        bottom: showDivider ? (isCompact ? 9 : 10) : 0,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE8EEF3), width: 1),
              )
            : null,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: isCompact ? 60 : 60),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF475569),
                      fontSize: isCompact ? 12.5 : 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (value != null) const SizedBox(height: 1),
                  if (value != null)
                    Text.rich(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      TextSpan(
                        children: [
                          TextSpan(
                            text: value!,
                            style: TextStyle(
                              color: iconColor,
                              fontWeight: FontWeight.w900,
                              fontSize: isCompact ? 16.5 : 17,
                            ),
                          ),
                          if (unit != null) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: unit!,
                              style: TextStyle(
                                color: iconColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w800,
                                fontSize: isCompact ? 10.5 : 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FacilityTheme.softMauve,
                      fontSize: isCompact ? 10.5 : 10.8,
                      fontWeight: FontWeight.w600,
                      height: 1.12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeBorderColor, width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: badgeDotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: badgeDotColor.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    level,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.2,
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
