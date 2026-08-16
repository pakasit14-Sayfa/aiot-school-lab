// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// หน้า 2 ของฝั่งผู้บริหารสถานศึกษา (ผอ) — "ศูนย์แจ้งเตือน/เคสที่ต้อง
// ตัดสินใจ" ไม่ใช่ยูสเคสเดี่ยวๆ แต่รวม 2 จุดที่พบตอนไล่ตรวจวอลต์กลาง (ดู
// NOTES.md) ซึ่งทั้งคู่เป็น Exception Flow ของยูสเคสอื่นที่ดึง ผอ เข้ามา
// เป็นเส้นทางสำรอง ไม่ใช่ผู้รับผิดชอบหลัก:
//
// 1. EMG-4 (Exception): "ไม่มีใครรับทราบภายในเวลาที่กำหนด → ส่งซ้ำ/ยกระดับ
//    แจ้งเตือนไปยังผู้บริหาร" — ครูประจำพื้นที่คือผู้รับแจ้งเตือนหลักตาม
//    Main Flow เดิม (EMG-4), ผอ เป็นเส้นทางสำรองเมื่อไม่มีใครตอบสนอง
// 2. SEC-5 (Exception): "ครูไม่แน่ใจ ต้องการข้อมูลเพิ่ม → ส่งต่อให้ School
//    Admin/ผู้บริหารช่วยตัดสินใจ" — ครูคือผู้ยืนยัน/ปฏิเสธ Alert หลักตาม
//    Main Flow เดิม (SEC-5), ผอ ช่วยตัดสินใจเฉพาะกรณีครูไม่แน่ใจเท่านั้น
// 3. [เพิ่ม 2026-08-16] STK-12 BR6/Exception 2: เมื่อผู้ดูแลอาคารเปิด
//    Warning Light แบบ proactive (STK-12 §3b) "Warning Light ที่เปิดจาก
//    ข้อ 3b ต้องรอครู/ผู้บริหารยืนยันก่อนปิดเท่านั้น" — ผู้ดูแลอาคารเปิดเอง
//    ปิดเองไม่ได้ ต้องมีครูหรือ ผอ ยืนยันก่อนเสมอ และถ้าเกิน 15 นาทีไม่มีใคร
//    ยืนยัน ระบบยกระดับแจ้ง School Admin ให้ยืนยันแทนได้ (Exception 2) —
//    ตกหล่นตอน scope โฟลเดอร์นี้ครั้งแรก พบจากการตรวจสอบเทียบ UC ภายหลัง
//
// [ยืนยันแล้ว 2026-08-16] SEC-5 escalation ให้ ผอ เห็นภาพจริงจากกล้อง
// ประกอบการตัดสินใจได้ — ผู้ใช้ (เจ้าของโปรเจกต์) ยืนยันโดยตรง สอดคล้องกับ
// SEC-9 ที่เปิดช่องให้ "School Admin/ผู้บริหารกรณีจำเป็น" เข้าถึงภาพจริงได้
// อยู่แล้ว — เพิ่มพรีวิวภาพนิ่งต่อเคสในหน้านี้แล้ว (ตอนนี้เป็น placeholder
// เพราะยังไม่มีระบบกล้อง/Storage จริงให้ดึงภาพมา — จุดที่ต้องทำต่อตอนต่อ
// Supabase จริง: ต้องผ่าน SEC-9 policy check ก่อนคืนภาพเสมอ ไม่ใช่แค่เช็ค
// role เฉยๆ เพราะ SEC-9 ระบุ "กรณีจำเป็น" ไม่ใช่สิทธิ์อัตโนมัติเสมอไป)
//
// 2026-08-15: แยกออกมาเป็น content-only widget (ไม่มี Scaffold/gradient
// header ของตัวเองแล้ว) เพื่อให้ ExecutiveHomePage (shell ใหม่) ใช้เป็น
// แท็บที่ 2 ได้ — ตัด _buildHeader() เดิม (รวมถึงปุ่มย้อนกลับ) ออก เพราะ
// shell มี top bar ของตัวเองอยู่แล้ว ไม่ต้องมี header ซ้อนกัน 2 ชั้น
import 'package:flutter/material.dart';
import 'executive_shared_widgets.dart';

class ExecutiveEscalationInboxContent extends StatefulWidget {
  const ExecutiveEscalationInboxContent({super.key});

  @override
  State<ExecutiveEscalationInboxContent> createState() =>
      _ExecutiveEscalationInboxContentState();
}

class _ExecutiveEscalationInboxContentState
    extends State<ExecutiveEscalationInboxContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _emergencyEscalations = [
    {
      'id': 'EMG-2026-014',
      'title': 'กดปุ่ม Emergency ห้อง 305',
      'location': 'อาคาร 2 ชั้น 3',
      'time': '2 นาทีที่แล้ว',
      'detail': 'ไม่มีครู/เวรประจำพื้นที่รับทราบภายใน 5 นาทีตามกำหนด',
      'acknowledged': false,
    },
    {
      'id': 'EMG-2026-013',
      'title': 'กดปุ่ม Emergency โรงอาหาร',
      'location': 'อาคารกลาง ชั้น 1',
      'time': '38 นาทีที่แล้ว',
      'detail': 'ยกระดับมาแล้ว รับทราบและมอบหมายเวรตรวจสอบเรียบร้อย',
      'acknowledged': true,
    },
  ];

  final List<Map<String, dynamic>> _secReviewEscalations = [
    {
      'id': 'SEC-2026-041',
      'title': 'ตรวจพบความเคลื่อนไหวผิดปกติหลังเวลาปิดเรียน',
      'location': 'อาคาร 3 โถงชั้น 2',
      'time': '18 นาทีที่แล้ว',
      'cameraLabel': 'กล้อง C-12 · โถงชั้น 2',
      'confidence': 'ความมั่นใจของระบบ: 62%',
      'note': 'ครูภานุพงศ์: "ไม่แน่ใจว่าเป็นคนหรือแมวจร ขอความเห็นเพิ่ม"',
      'decision': null, // null = รอ, 'confirmed' | 'rejected'
    },
    {
      'id': 'SEC-2026-039',
      'title': 'ตรวจพบการเข้าพื้นที่เสี่ยง (ห้องเก็บสารเคมี)',
      'location': 'อาคาร 3 ชั้น 1',
      'time': '2 ชั่วโมงที่แล้ว',
      'cameraLabel': 'กล้อง C-05 · หน้าห้องเก็บสารเคมี',
      'confidence': 'ความมั่นใจของระบบ: 78%',
      'note': 'ครูสมหญิง: "กล้องมุมอับ มองไม่ชัดว่าใครเข้า ขอความเห็นเพิ่ม"',
      'decision': null,
    },
  ];

  // STK-12 BR6/Exception 2 — ไฟเตือนที่ผู้ดูแลอาคารเปิดแบบ proactive (§3b)
  // ต้องรอครู/ผอ ยืนยันก่อนปิดเท่านั้น ผู้ดูแลอาคารเปิดเองปิดเองไม่ได้
  final List<Map<String, dynamic>> _warningLightEscalations = [
    {
      'id': 'STK-2026-007',
      'title': 'ไฟเตือนพื้นที่ · อาคาร 2 ชั้น 3',
      'location': 'อาคาร 2 ชั้น 3 ใกล้บันไดหนีไฟ',
      'time': '12 นาทีที่แล้ว',
      'triggeredBy':
          'ผู้ดูแลอาคาร (สมชาย ใจดี) แจ้งเชิงรุก: พบสายไฟชำรุดเสี่ยงลัดวงจร',
      'minutesElapsed': 12,
      'confirmed': false,
    },
    {
      'id': 'STK-2026-005',
      'title': 'ไฟเตือนพื้นที่ · โรงอาหาร',
      'location': 'อาคารกลาง ชั้น 1',
      'time': '22 นาทีที่แล้ว',
      'triggeredBy':
          'ผู้ดูแลอาคาร (มานพ ศรีสุข) แจ้งเชิงรุก: กลิ่นแก๊สรั่วบริเวณครัว',
      'minutesElapsed': 22,
      'confirmed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _pendingEmergencyCount =>
      _emergencyEscalations.where((e) => e['acknowledged'] == false).length;
  int get _pendingSecCount =>
      _secReviewEscalations.where((e) => e['decision'] == null).length;
  int get _pendingWarningLightCount =>
      _warningLightEscalations.where((e) => e['confirmed'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            labelColor: ExecutiveTheme.primaryIndigo,
            unselectedLabelColor: ExecutiveTheme.softMauve,
            indicatorColor: ExecutiveTheme.primaryIndigo,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            isScrollable: true,
            tabs: [
              Tab(text: 'เหตุฉุกเฉินที่ยกระดับมา ($_pendingEmergencyCount)'),
              Tab(text: 'รอความเห็นจากกล้อง AI ($_pendingSecCount)'),
              Tab(text: 'ไฟเตือนรอยืนยันปิด ($_pendingWarningLightCount)'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEmergencyList(),
              _buildSecReviewList(),
              _buildWarningLightList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyList() {
    if (_emergencyEscalations.isEmpty) {
      return _buildEmptyState('ไม่มีเหตุฉุกเฉินที่ต้องยกระดับตอนนี้');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _emergencyEscalations.length,
      itemBuilder: (context, i) {
        final item = _emergencyEscalations[i];
        final acknowledged = item['acknowledged'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExecutiveGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      color: acknowledged
                          ? ExecutiveTheme.safeGreen
                          : ExecutiveTheme.emergencyRed,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: ExecutiveTheme.inkIndigo,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['location']} · ${item['time']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ExecutiveTheme.softMauve,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['detail'] as String,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ExecutiveTheme.inkIndigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (!acknowledged)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => item['acknowledged'] = true);
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('รับทราบเหตุ ${item['id']} แล้ว'),
                            ),
                          );
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('รับทราบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ExecutiveTheme.emergencyRed,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: ExecutiveTheme.safeGreen,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'รับทราบแล้ว',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ExecutiveTheme.safeGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecReviewList() {
    if (_secReviewEscalations.isEmpty) {
      return _buildEmptyState('ไม่มีเหตุการณ์รอความเห็นตอนนี้');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _secReviewEscalations.length,
      itemBuilder: (context, i) {
        final item = _secReviewEscalations[i];
        final decision = item['decision'] as String?;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExecutiveGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: ExecutiveTheme.warningOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: ExecutiveTheme.inkIndigo,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['location']} · ${item['time']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ExecutiveTheme.softMauve,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCameraSnapshot(item['cameraLabel'] as String),
                const SizedBox(height: 10),
                Text(
                  item['confidence'] as String,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: ExecutiveTheme.softMauve,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ExecutiveTheme.lightIndigoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['note'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: ExecutiveTheme.inkIndigo,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (decision == null)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _decideSec(item, 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ExecutiveTheme.emergencyRed,
                            foregroundColor: Colors.white,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('ยืนยันเป็นเหตุจริง'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _decideSec(item, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('False Positive'),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: decision == 'confirmed'
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          decision == 'confirmed'
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          size: 14,
                          color: decision == 'confirmed'
                              ? ExecutiveTheme.emergencyRed
                              : ExecutiveTheme.safeGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          decision == 'confirmed'
                              ? 'ยืนยันเป็นเหตุจริงแล้ว'
                              : 'บันทึกเป็น False Positive แล้ว',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: decision == 'confirmed'
                                ? ExecutiveTheme.emergencyRed
                                : ExecutiveTheme.safeGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// STK-12 BR6/Exception 2 — รายการไฟเตือนที่ผู้ดูแลอาคารเปิดแบบ proactive
  /// (§3b) รอครู/ผอ ยืนยันก่อนปิด ผู้ดูแลอาคารเปิดเองปิดเองไม่ได้ และถ้าเกิน
  /// 15 นาทีไม่มีใครยืนยัน ระบบยกระดับแจ้ง School Admin ให้ยืนยันแทนได้
  Widget _buildWarningLightList() {
    if (_warningLightEscalations.isEmpty) {
      return _buildEmptyState('ไม่มีไฟเตือนที่รอยืนยันปิดตอนนี้');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _warningLightEscalations.length,
      itemBuilder: (context, i) {
        final item = _warningLightEscalations[i];
        final confirmed = item['confirmed'] as bool;
        final minutesElapsed = item['minutesElapsed'] as int;
        final escalatedToAdmin = !confirmed && minutesElapsed > 15;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExecutiveGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: confirmed
                          ? ExecutiveTheme.safeGreen
                          : ExecutiveTheme.warningOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: ExecutiveTheme.inkIndigo,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['location']} · ${item['time']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ExecutiveTheme.softMauve,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ExecutiveTheme.lightIndigoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['triggeredBy'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: ExecutiveTheme.inkIndigo,
                    ),
                  ),
                ),
                if (escalatedToAdmin) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.priority_high_rounded,
                          size: 14,
                          color: ExecutiveTheme.warningOrange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'เกิน 15 นาทีไม่มีผู้ยืนยันปิด — ระบบยกระดับแจ้ง '
                            'School Admin ให้ยืนยันแทนได้แล้ว',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: ExecutiveTheme.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (!confirmed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmCloseWarningLight(item),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text('ยืนยันปิดไฟเตือน'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ExecutiveTheme.primaryIndigo,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: ExecutiveTheme.safeGreen,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ยืนยันปิดไฟเตือนแล้ว · ผู้ดูแลอาคารปิดไฟจริงได้',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ExecutiveTheme.safeGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCloseWarningLight(Map<String, dynamic> item) {
    setState(() => item['confirmed'] = true);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('ยืนยันปิดไฟเตือน ${item['id']} แล้ว')),
      );
  }

  /// พรีวิวภาพนิ่งจากกล้อง — ยืนยันกับผู้ใช้แล้วว่าให้เห็นภาพจริงประกอบ
  /// การตัดสินใจได้ (ดูคอมเมนต์หัวไฟล์) ตอนนี้เป็น placeholder เพราะยังไม่
  /// มีระบบกล้อง/Storage จริงให้ดึงภาพมา — ต่อ Supabase จริงทีหลังต้องผ่าน
  /// SEC-9 policy check ก่อนคืนภาพเสมอ ไม่ใช่แค่เช็ค role
  Widget _buildCameraSnapshot(String cameraLabel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 140,
        color: const Color(0xFF1E293B),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white24,
                size: 36,
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ExecutiveTheme.emergencyRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '● LIVE SNAPSHOT (mock)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                cameraLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _decideSec(Map<String, dynamic> item, String decision) {
    setState(() => item['decision'] = decision);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('บันทึกผลการตัดสินใจ ${item['id']} แล้ว')),
      );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt_rounded,
              size: 40,
              color: ExecutiveTheme.softMauve,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ExecutiveTheme.softMauve,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
