import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';
import 'facility_ux_states.dart';

class FacilityIncidentInboxPage extends StatefulWidget {
  const FacilityIncidentInboxPage({super.key});

  @override
  State<FacilityIncidentInboxPage> createState() =>
      _FacilityIncidentInboxPageState();
}

class _FacilityIncidentInboxPageState extends State<FacilityIncidentInboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 2026-08-15: STK-12 กำหนดว่าหน้านี้แสดงเฉพาะเหตุการณ์ประเภทอุปกรณ์/
  // โครงสร้างอาคารเท่านั้น (Exception Flow ข้อ 1 ห้ามให้ผู้ดูแลอาคารรับเรื่อง
  // เหตุฉุกเฉินบุคคลแบบ flow ปกติ ต้องส่งให้ครูเท่านั้น) — เดิมมีการ์ด SOS
  // ห้อง 302 (คนกดฉุกเฉิน) ปนอยู่ในลิสต์นี้ ผิดหลัก จึงเอาออก เหตุฉุกเฉิน
  // บุคคลที่ผู้ดูแลอาคารเจอเองระหว่างตรวจ ให้ใช้ปุ่มลอย "แจ้งเหตุ SOS"
  // (FacilityFloatingSOSButton) แทน ไม่ใช่ผ่านลิสต์รับเรื่องนี้
  final List<Map<String, dynamic>> _incidents = [
    {
      'id': 'INC-2026-051',
      'title': '🌡️ เครื่องปรับอากาศห้อง 210 มีเสียงดังผิดปกติ ไม่เย็น',
      'location': 'อาคาร 3 · ชั้น 2 (ห้องเรียน 210)',
      'reporter': 'ครูวิภาดา (ครูประจำวิชา)',
      'timeAgo': '5 นาทีที่แล้ว',
      'tabIndex': 0, // 0: new, 1: in_progress, 2: pending_external, 3: closed
      'statusText': 'ยังไม่มีผู้รับเรื่อง',
      'severity': 'warning',
      'description':
          'เครื่องปรับอากาศมีเสียงดังผิดปกติตั้งแต่เช้า และห้องไม่เย็นเหมือนปกติ',
      'assignedTechnician': 'ยังไม่ได้มอบหมาย',
      'slaRemaining': '25:00 นาที',
    },
    {
      'id': 'INC-2026-042',
      'title': '⚠️ เซนเซอร์ PM2.5 ตรวจพบค่าฝุ่นสูงเกินเกณฑ์',
      'location': 'อาคาร 3 · ชั้น 2 (ห้องเรียน 204)',
      'reporter': 'ระบบ AIoT อัตโนมัติ',
      'timeAgo': '15 นาทีที่แล้ว',
      'tabIndex': 1,
      'statusText': 'กำลังดำเนินการ (กำลังเปิดระบบกรองอากาศ)',
      'severity': 'warning',
      'description':
          'ค่า PM2.5 ขึ้นสูงถึง 78 µg/m³ ระบบเปิดเครื่องฟอกอากาศและแจ้งเตือนครูประจำห้องแล้ว',
      'assignedTechnician': 'ช่างอนันต์ (ช่างไฟฟ้า)',
      'slaRemaining': '25:00 นาที',
    },
    {
      'id': 'INC-2026-039',
      'title': '💧 ท่อน้ำรั่วซึมบริเวณห้องน้ำชั้น 1',
      'location': 'อาคาร 3 · ชั้น 1',
      'reporter': 'นักการประเสริฐ',
      'timeAgo': '45 นาทีที่แล้ว',
      'tabIndex': 2,
      'statusText': 'รอหน่วยงานภายนอก (ส่งเรื่องเทศบาล/การประปา)',
      'severity': 'warning',
      'description':
          'ท่อเมนหลักส่งน้ำอาคารรั่ว ต้องใช้อะไหล่เฉพาะรอช่างการประปาเข้าซ่อมแซม',
      'assignedTechnician': 'ทีมประปาภายนอก',
      'slaRemaining': '02 ชม. 15 นาที',
    },
    {
      'id': 'INC-2026-010',
      'title': '✅ ประตูล็อคห้อง 101 ขัดข้อง (ซ่อมเสร็จแล้ว)',
      'location': 'อาคาร 3 · ชั้น 1',
      'reporter': 'ครูสมหญิง',
      'timeAgo': '3 ชั่วโมงที่แล้ว',
      'tabIndex': 3,
      'statusText': 'ปิดเหตุและสรุปผลเรียบร้อย',
      'severity': 'normal',
      'description': 'เปลี่ยนชุดแม่กุญแจดิจิทัลใหม่ ทดสอบการใช้งานผ่าน 100%',
      'assignedTechnician': 'ช่างอนันต์',
      'slaRemaining': 'เสร็จสิ้นตาม SLA',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _countForTab(int tabIdx) =>
      _incidents.where((i) => i['tabIndex'] == tabIdx).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FacilityTheme.bgSlate,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(),
                const SizedBox(height: 14),
                FacilityResponsiveGrid(
                  spacing: 12,
                  minItemWidth: 160,
                  children: [
                    _buildStatCard(
                      icon: Icons.fiber_new_rounded,
                      label: 'เหตุใหม่',
                      value: '${_countForTab(0)} รายการ',
                      color: FacilityTheme.emergencyRed,
                      bg: const Color(0xFFFEF2F2),
                    ),
                    _buildStatCard(
                      icon: Icons.build_circle_rounded,
                      label: 'กำลังดำเนินการ',
                      value: '${_countForTab(1) + _countForTab(2)} รายการ',
                      color: FacilityTheme.warningOrange,
                      bg: const Color(0xFFFFFBEB),
                    ),
                    _buildStatCard(
                      icon: Icons.task_alt_rounded,
                      label: 'ปิดแล้ว',
                      value: '${_countForTab(3)} รายการ',
                      color: FacilityTheme.safeGreen,
                      bg: const Color(0xFFECFDF5),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          // 2026-08-15: แถบอธิบายขอบเขตของหน้านี้ตาม STK-12 — กันไม่ให้มีใคร
          // (รวมถึง agent อื่น) เอาเหตุฉุกเฉินบุคคลกลับมาใส่ในลิสต์นี้อีก
          Container(
            width: double.infinity,
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'หน้านี้แสดงเฉพาะเหตุการณ์อุปกรณ์/โครงสร้างอาคาร (STK-12) — '
              'ไม่รวมเหตุฉุกเฉินบุคคล ซึ่งเป็นหน้าที่ครูดูแล พบเหตุอันตราย '
              'เฉียบพลันระหว่างตรวจสอบ ให้ใช้ปุ่ม "แจ้งเหตุ SOS" ได้ทันที',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: FacilityTheme.primaryNavy,
              ),
            ),
          ),
          // 📌 TAB BAR (นับจำนวนจริงจากรายการ ไม่ hardcode ตัวเลข)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              labelColor: FacilityTheme.primaryNavy,
              unselectedLabelColor: FacilityTheme.textMuted,
              indicatorColor: FacilityTheme.primaryBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'เหตุใหม่ (${_countForTab(0)}) 🔴'),
                Tab(text: 'กำลังดำเนินการ (${_countForTab(1)}) 🟡'),
                Tab(text: 'รอหน่วยงานอื่น (${_countForTab(2)}) 🔵'),
                Tab(text: 'ปิดแล้ว (${_countForTab(3)}) 🟢'),
              ],
            ),
          ),

          // 📄 TAB VIEW LIST OF INCIDENTS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (tabIdx) {
                final filtered = _incidents
                    .where((i) => i['tabIndex'] == tabIdx)
                    .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: FacilityUXStates.buildEmptyState(
                      title: 'ไม่มีรายการเหตุในหมวดนี้',
                      message: 'ทุกเหตุการณ์ในหมวดนี้ถูกจัดการเรียบร้อยแล้ว',
                      icon: Icons.task_alt_rounded,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return _buildIncidentCard(item);
                  },
                );
              }),
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
              Icons.build_circle_rounded,
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
                  'เหตุอุปกรณ์/อาคาร',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'STK-12 · รับเรื่อง ตรวจสอบ และปิดเหตุ',
                  style: TextStyle(
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

  /// Single Incident Card with Primary Action Button State Machine
  Widget _buildIncidentCard(Map<String, dynamic> item) {
    final severity = item['severity'] as String;
    final tabIdx = item['tabIndex'] as int;

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    String actionBtnLabel;
    IconData actionBtnIcon;

    // Action State Machine mapping
    if (tabIdx == 0) {
      actionBtnLabel = 'รับเรื่องด่วน';
      actionBtnIcon = Icons.how_to_reg_rounded;
    } else if (tabIdx == 1) {
      actionBtnLabel = 'อัปเดต / มอบหมายช่าง';
      actionBtnIcon = Icons.build_circle_rounded;
    } else if (tabIdx == 2) {
      actionBtnLabel = 'ติดตามหน่วยงาน';
      actionBtnIcon = Icons.outbound_rounded;
    } else {
      actionBtnLabel = 'ดูสรุปประวัติ';
      actionBtnIcon = Icons.article_rounded;
    }

    if (severity == 'critical') {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFCA5A5);
      badgeText = FacilityTheme.emergencyRed;
    } else if (severity == 'warning') {
      badgeBg = const Color(0xFFFFFBEB);
      badgeBorder = const Color(0xFFFCD34D);
      badgeText = FacilityTheme.warningOrange;
    } else {
      badgeBg = const Color(0xFFECFDF5);
      badgeBorder = const Color(0xFFA7F3D0);
      badgeText = FacilityTheme.safeGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FacilityGlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Text(
                    item['id'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: badgeText,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: FacilityTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['location']} · ${item['timeAgo']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FacilityTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['description'] as String,
              style: const TextStyle(
                fontSize: 13,
                color: FacilityTheme.textDark,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final assigneeInfo = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      size: 16,
                      color: FacilityTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'ผู้รับผิดชอบ: ${item['assignedTechnician']}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: FacilityTheme.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );

                final actionBtns = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showIncidentDetailDialog(context, item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FacilityTheme.textDark,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('ดูรายละเอียด'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _handlePrimaryAction(item),
                      icon: Icon(actionBtnIcon, size: 15),
                      label: Text(actionBtnLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: badgeText,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
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
                  ],
                );

                if (constraints.maxWidth < 480) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      assigneeInfo,
                      const SizedBox(height: 10),
                      actionBtns,
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: assigneeInfo),
                    const SizedBox(width: 10),
                    actionBtns,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// State machine ต่อ 1 การ์ด — new→in_progress ไม่ต้องมีบันทึก,
  /// แต่ in_progress/pending_external→closed ต้องกรอกผลตรวจสอบก่อนเสมอ
  /// (STK-12 BR2: ปิดเหตุการณ์ได้เฉพาะหลังบันทึกผลตรวจสอบแล้ว)
  void _handlePrimaryAction(Map<String, dynamic> item) {
    final tabIdx = item['tabIndex'] as int;
    if (tabIdx == 0) {
      setState(() {
        item['tabIndex'] = 1;
        item['statusText'] = 'รับเรื่องแล้ว กำลังดำเนินการ';
      });
      FacilityUXStates.showSuccessToast(
        context,
        'รับเรื่อง ${item['id']} เรียบร้อยแล้ว ⚡',
        subtitle: 'เปลี่ยนสถานะเป็นกำลังดำเนินการและบันทึกเวลาลงระบบแล้ว',
        accentColor: FacilityTheme.primaryBlue,
        icon: Icons.check_circle_rounded,
      );
    } else if (tabIdx == 1 || tabIdx == 2) {
      _showCloseIncidentDialog(item);
    } else {
      _showIncidentDetailDialog(context, item);
    }
  }

  void _showCloseIncidentDialog(Map<String, dynamic> item) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('ปิดเหตุ: ${item['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สรุปผลการตรวจสอบ (บังคับกรอกก่อนปิดเหตุ):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'เช่น เปลี่ยนอะไหล่แล้ว ทดสอบใช้งานได้ปกติ...',
                  filled: true,
                  fillColor: FacilityTheme.bgSlate,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: FacilityTheme.primaryPurple,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  FacilityUXStates.showSuccessToast(
                    dialogCtx,
                    'กรุณากรอกสรุปผลการตรวจสอบก่อนปิดเหตุ',
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                setState(() {
                  item['tabIndex'] = 3;
                  item['statusText'] = 'ปิดเหตุแล้ว: $note';
                });
                FacilityUXStates.showSuccessToast(
                  context,
                  'ปิดเหตุ ${item['id']} สมบูรณ์',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FacilityTheme.safeGreen,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
              ),
              child: const Text('ยืนยันปิดเหตุ'),
            ),
          ],
        );
      },
    );
  }

  /// 2-Column Desktop Detail Dialog/Panel
  void _showIncidentDetailDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายละเอียดเหตุการณ์: ${item['id']}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Reporter, Location Map Stub, Description
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลผู้แจ้ง & จุดเกิดเหตุ:',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text('• ผู้แจ้ง: ${item['reporter']}'),
                          Text('• จุดเกิดเหตุ: ${item['location']}'),
                          Text('• เวลาที่เกิด: ${item['timeAgo']}'),
                          const SizedBox(height: 14),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: FacilityTheme.bgSlate,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.map_rounded,
                                    color: FacilityTheme.primaryBlue,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ผังแผนที่ ${item['location']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column: SLA Timer, Technician, Progress Timeline
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'การดำเนินการ & SLA Target:',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '• ช่างผู้รับผิดชอบ: ${item['assignedTechnician']}',
                          ),
                          Text('• SLA คงเหลือ: ${item['slaRemaining']}'),
                          const SizedBox(height: 14),
                          const Text(
                            'Timeline การอัปเดต:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item['timeAgo']} - ${item['reporter']} แจ้งเหตุ 🔴',
                          ),
                          Text('สถานะปัจจุบัน: ${item['statusText']} 🟡'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
