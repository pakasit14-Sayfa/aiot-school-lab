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
//
// ⚠️ เรื่องที่ยังไม่ได้ยืนยัน (เปิดไว้ ไม่ได้ตัดสินใจเอง): SEC-5 escalation
// ควรให้ ผอ เห็นภาพจริงจากกล้องประกอบการตัดสินใจไหม — SEC-4 บอกว่าไม่ใช้
// Face Recognition แต่ไม่ได้ห้ามภาพนิ่งเด็ดขาด และ SEC-9 (สิทธิ์เข้าถึง
// ภาพกล้อง) ก็เปิดช่องให้ "School Admin/ผู้บริหารกรณีจำเป็น" เข้าถึงภาพจริง
// ได้ — แต่เป็นเรื่องละเอียดอ่อนด้าน PDPA จึงยังไม่ใส่ภาพ/พรีวิวกล้องในหน้า
// นี้ ทำแค่ Event Metadata (เวลา/พื้นที่/ประเภท/ระดับความมั่นใจ) ไปก่อน
// เหมือนที่ทำกับ STK-10 ของผู้ดูแลอาคาร — ต้องถามผู้ใช้ก่อนถ้าจะเพิ่มภาพจริง
import 'package:flutter/material.dart';
import 'executive_shared_widgets.dart';

class ExecutiveEscalationInboxPage extends StatefulWidget {
  const ExecutiveEscalationInboxPage({super.key});

  @override
  State<ExecutiveEscalationInboxPage> createState() =>
      _ExecutiveEscalationInboxPageState();
}

class _ExecutiveEscalationInboxPageState
    extends State<ExecutiveEscalationInboxPage>
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
      'confidence': 'ความมั่นใจของระบบ: 62%',
      'note': 'ครูภานุพงศ์: "ไม่แน่ใจว่าเป็นคนหรือแมวจร ขอความเห็นเพิ่ม"',
      'decision': null, // null = รอ, 'confirmed' | 'rejected'
    },
    {
      'id': 'SEC-2026-039',
      'title': 'ตรวจพบการเข้าพื้นที่เสี่ยง (ห้องเก็บสารเคมี)',
      'location': 'อาคาร 3 ชั้น 1',
      'time': '2 ชั่วโมงที่แล้ว',
      'confidence': 'ความมั่นใจของระบบ: 78%',
      'note': 'ครูสมหญิง: "กล้องมุมอับ มองไม่ชัดว่าใครเข้า ขอความเห็นเพิ่ม"',
      'decision': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecutiveTheme.bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                tabs: [
                  Tab(
                    text: 'เหตุฉุกเฉินที่ยกระดับมา ($_pendingEmergencyCount)',
                  ),
                  Tab(text: 'รอความเห็นจากกล้อง AI ($_pendingSecCount)'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildEmergencyList(), _buildSecReviewList()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ExecutiveTheme.primaryIndigo,
            ExecutiveTheme.primaryIndigoLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (Navigator.canPop(context)) const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: ExecutiveTheme.goldAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'ศูนย์แจ้งเตือน/เคสที่ต้องตัดสินใจ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
