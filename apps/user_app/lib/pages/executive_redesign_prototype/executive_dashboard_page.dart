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
import 'executive_shared_widgets.dart';

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

  ({String kwh, String cost}) get _energyByPeriod {
    switch (_selectedPeriod) {
      case '7 วันที่ผ่านมา':
        return (kwh: '1,120 kWh', cost: 'ประมาณ 4,330 บาท');
      case 'ภาคเรียนนี้':
        return (kwh: '20,750 kWh', cost: 'ประมาณ 80,200 บาท');
      default:
        return (kwh: '4,820 kWh', cost: 'ประมาณ 18,650 บาท');
    }
  }

  String get _safetyEventsByPeriod {
    switch (_selectedPeriod) {
      case '7 วันที่ผ่านมา':
        return '6 ครั้ง';
      case 'ภาคเรียนนี้':
        return '102 ครั้ง';
      default:
        return '24 ครั้ง';
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

  ({String users, String rate}) get _activeUsersByGrade {
    switch (_selectedGrade) {
      case 'มัธยมต้น (ม.1-3)':
        return (users: '640 / 730 คน', rate: '87.7% ของบัญชีทั้งหมด');
      case 'มัธยมปลาย (ม.4-6)':
        return (users: '600 / 720 คน', rate: '83.3% ของบัญชีทั้งหมด');
      default:
        return (users: '1,240 / 1,450 คน', rate: '85.5% ของบัญชีทั้งหมด');
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
            subtitle: 'รวมทุกอาคารในโรงเรียน · $_selectedPeriod',
            color: ExecutiveTheme.warningOrange,
            hasData: !_demoMissingEnergyData,
            emptyMessage: 'ยังไม่มีข้อมูล — อาคาร 2 ยังไม่ติดตั้งเซนเซอร์ครบ',
            cards: [
              _StatCardData(
                icon: Icons.electric_bolt_rounded,
                label: 'พลังงานสะสม ($_selectedPeriod)',
                value: _energyByPeriod.kwh,
                trend: _energyByPeriod.cost,
                trendColor: ExecutiveTheme.softMauve,
              ),
              _StatCardData(
                icon: Icons.eco_rounded,
                label: 'จุดตรวจสิ่งแวดล้อมปกติ',
                value: '92%',
                trend: '↗ +3% จากเดือนที่แล้ว',
                trendColor: ExecutiveTheme.safeGreen,
              ),
              _StatCardData(
                icon: Icons.apartment_rounded,
                label: 'อาคารที่มีเซนเซอร์ครบ',
                value: '3 / 3 อาคาร',
                trend: 'ครบทุกอาคารแล้ว',
                trendColor: ExecutiveTheme.safeGreen,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildDimensionSection(
            icon: Icons.shield_rounded,
            title: 'ความปลอดภัย',
            subtitle:
                'อ้างอิงจากรายงานเหตุการณ์ความปลอดภัยทั้งโรงเรียน (SEC-7) · $_selectedPeriod',
            color: ExecutiveTheme.emergencyRed,
            hasData: true,
            cards: [
              _StatCardData(
                icon: Icons.report_rounded,
                label: 'เหตุการณ์ทั้งหมด ($_selectedPeriod)',
                value: _safetyEventsByPeriod,
                trend: '↘ -8% $_periodTrendSuffix',
                trendColor: ExecutiveTheme.safeGreen,
              ),
              _StatCardData(
                icon: Icons.timer_rounded,
                label: 'เวลาตอบสนองเฉลี่ย',
                value: '3 นาที 20 วิ',
                trend: '✓ ตามมาตรฐาน',
                trendColor: ExecutiveTheme.safeGreen,
              ),
              _StatCardData(
                icon: Icons.task_alt_rounded,
                label: 'ปิดเหตุการณ์สำเร็จ',
                value: '96%',
                trend: '↗ +1% $_periodTrendSuffix',
                trendColor: ExecutiveTheme.safeGreen,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildDimensionSection(
            icon: Icons.insights_rounded,
            title: 'การใช้งานระบบ',
            subtitle:
                'ภาพรวมการใช้งานทั้งโรงเรียน · $_selectedPeriod · $_selectedGrade',
            color: ExecutiveTheme.infoCyan,
            hasData: true,
            cards: [
              _StatCardData(
                icon: Icons.people_alt_rounded,
                label: 'ผู้ใช้งาน active วันนี้',
                value: _activeUsersByGrade.users,
                trend: _activeUsersByGrade.rate,
                trendColor: ExecutiveTheme.softMauve,
              ),
              _StatCardData(
                icon: Icons.dns_rounded,
                label: 'Uptime ระบบเดือนนี้',
                value: '99.6%',
                trend: '✓ ตามเป้าหมาย',
                trendColor: ExecutiveTheme.safeGreen,
              ),
              _StatCardData(
                icon: Icons.login_rounded,
                label: 'อัตราล็อกอินสำเร็จ',
                value: '98.2%',
                trend: '↗ +0.4% $_periodTrendSuffix',
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
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('ส่งออกรายงาน PDF/Excel เรียบร้อยแล้ว 📄'),
                    ),
                  );
              },
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
        else
          ExecutiveResponsiveGrid(
            spacing: 12,
            minItemWidth: 220,
            children: [for (final c in cards) _buildStatCard(c)],
          ),
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
