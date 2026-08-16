import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/student_redesign_palette.dart';

class MockIncident {
  final String id;
  final DateTime timestamp;
  final String type; // 'SOS' or 'WARNING'
  final String room;
  String
  status; // 'รอตรวจสอบ', 'ครูรับเรื่องแล้ว', 'กำลังดำเนินการ', 'ปิดเหตุแล้ว'
  final List<String> timelineNotes;
  final List<DateTime> timelineTimes;

  MockIncident({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.room,
    required this.status,
    required this.timelineNotes,
    required this.timelineTimes,
  });
}

class MockAlert {
  final String id;
  final String title;
  final String content;
  final String area;
  bool isAcknowledged;

  MockAlert({
    required this.id,
    required this.title,
    required this.content,
    required this.area,
    this.isAcknowledged = false,
  });
}

class StudentSafetyPage extends StatefulWidget {
  const StudentSafetyPage({super.key});

  @override
  State<StudentSafetyPage> createState() => _StudentSafetyPageState();
}

class _StudentSafetyPageState extends State<StudentSafetyPage> {
  final String currentRoom = 'ห้อง ม.5/2';
  final String currentBuilding = 'อาคาร 3 ชั้น 5';
  String classroomSafetyStatus = 'ปกติ';

  final List<MockIncident> _myIncidents = [
    MockIncident(
      id: 'INC-2026-001',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'WARNING',
      room: 'ห้อง ม.5/2',
      status: 'ปิดเหตุแล้ว',
      timelineTimes: [
        DateTime.now().subtract(const Duration(hours: 2)),
        DateTime.now().subtract(const Duration(minutes: 90)),
        DateTime.now().subtract(const Duration(minutes: 60)),
        DateTime.now().subtract(const Duration(minutes: 30)),
      ],
      timelineNotes: [
        'นักเรียนแจ้งพบสวิตช์ไฟพัดลมชำรุดและมีประกายไฟ',
        'ครูสมชาย (ครูประจำเวร) รับทราบเรื่องแล้ว',
        'ช่างซ่อมบำรุงเข้าสับคัตเอาต์และเปลี่ยนสวิตช์ไฟชุดใหม่',
        'ครูตรวจสอบความปลอดภัยและปิดเหตุการณ์เรียบร้อย',
      ],
    ),
  ];

  final List<MockAlert> _schoolAlerts = [
    MockAlert(
      id: 'ALT-101',
      title: 'แจ้งเตือนฝนตกสะสมและน้ำขังผิวถนน',
      content:
          'หลีกเลี่ยงการสัญจรบริเวณด้านหลังอาคาร 4 และใกล้สระน้ำ เนื่องจากกระเบื้องลื่นและอาจเกิดการลื่นล้มได้ง่าย',
      area: 'บริเวณหลังอาคาร 4 และลานกิจกรรม',
    ),
    MockAlert(
      id: 'ALT-102',
      title: 'ประกาศซ้อมหนีไฟและฝึกซ้อมความปลอดภัย',
      content:
          'ขอให้นักเรียนทุกคนศึกษาจุดรวมพลของอาคารเรียนตนเอง คาบเรียนที่ 7 จะมีการจำลองซ้อมสัญญาณอพยพหนีไฟ',
      area: 'ทุกอาคารเรียนของโรงเรียน',
    ),
  ];

  String? _reportingType;

  // S2: หน้าสรุปข้อมูลก่อนส่ง + ปุ่มกดค้างยืนยัน — กันกดพลาดตามข้อเสนอ
  // emergency-alert-app-proposal-v1 ข้อ 1.2(2) ป้องกันสร้าง incident
  // จากการแตะเดียวโดยไม่ได้ตั้งใจ
  Future<void> _openConfirmSheet(String type) async {
    if (classroomSafetyStatus == 'มีเหตุ') return;
    _reportingType = type;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncidentConfirmSheet(
        type: type,
        room: currentRoom,
        building: currentBuilding,
      ),
    );
    if (confirmed == true && mounted) {
      _submitIncident();
    }
  }

  void _submitIncident() {
    final newId = 'INC-2026-00${_myIncidents.length + 1}';
    final now = DateTime.now();

    final newIncident = MockIncident(
      id: newId,
      timestamp: now,
      type: _reportingType ?? 'SOS',
      room: currentRoom,
      status: 'รอตรวจสอบ',
      timelineTimes: [now],
      timelineNotes: [
        _reportingType == 'SOS'
            ? 'ส่งสัญญาณขอความช่วยเหลือเร่งด่วน (SOS) จากห้องเรียน'
            : 'แจ้งเหตุผิดปกติในห้องเรียน (ส่งพิกัดตำแหน่งอาคารแล้ว)',
      ],
    );

    setState(() {
      _myIncidents.insert(0, newIncident);
      classroomSafetyStatus = 'มีเหตุ';
    });

    _showSOSStatusActivatedSheet(newIncident);
  }

  void _acknowledgeAlert(String alertId) {
    setState(() {
      final alert = _schoolAlerts.firstWhere((e) => e.id == alertId);
      alert.isAcknowledged = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('รับทราบประกาศเรียบร้อยแล้ว'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showIncidentDetailModal(MockIncident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: incident.type == 'SOS'
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFFF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      incident.type == 'SOS'
                          ? Icons.emergency_rounded
                          : Icons.warning_amber_rounded,
                      color: incident.type == 'SOS' ? Colors.red : Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.type == 'SOS'
                              ? 'ขอความช่วยเหลือด่วน (SOS)'
                              : 'แจ้งเตือนพบเหตุผิดปกติ',
                          style: const TextStyle(
                            color: SchoolPalette.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'งาน: ${incident.id} | ${incident.room}',
                          style: const TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusPill(incident.status),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'ความคืบหน้าการช่วยเหลือ 📋',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: SchoolPalette.ink,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(incident.timelineNotes.length, (index) {
                final isLast = index == incident.timelineNotes.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isLast
                                ? SchoolPalette.green
                                : const Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 38,
                            color: const Color(0xFFE2E8F0),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.timelineNotes[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isLast
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isLast
                                  ? SchoolPalette.ink
                                  : SchoolPalette.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 6),
              const Text(
                '* สิทธิ์นักเรียน ST สามารถดูได้เฉพาะ Timeline รายการแจ้งเหตุของตนเองเท่านั้น',
                style: TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSOSStatusActivatedSheet(MockIncident incident) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'ส่งสัญญาณแจ้งเหตุเรียบร้อยแล้ว! 🚨',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: SchoolPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ส่งพิกัดตำแหน่งอาคารไปยังห้องพักครูเวรแล้ว ($currentRoom)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'มีเพียงครูทุกคน และครูอาคาร เท่านั้นที่ปิดเหตุได้ หลังจาก'
                'ตรวจสอบและบันทึกผลแล้ว (ตาม EMG-5) — ติดตามสถานะได้จาก'
                'หน้านี้ ไม่ต้องกดอะไรเพิ่ม',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // จำลองฝั่งครูเวร: รับเรื่อง → ตรวจสอบ → ปิดเหตุ ทั้งหมด
                    // เป็นสถานะที่มาจากครูเท่านั้น นักเรียนไม่มีปุ่มปิดเหตุเอง
                    Future.delayed(const Duration(seconds: 15), () {
                      if (mounted) {
                        setState(() {
                          incident.status = 'ครูรับเรื่องแล้ว';
                          incident.timelineTimes.add(DateTime.now());
                          incident.timelineNotes.add(
                            'ครูวิจิตร (ครูเวรประจำอาคาร) รับทราบเรื่องแล้ว กำลังเดินทางมาที่ห้องเรียน',
                          );
                        });
                      }
                    });
                    Future.delayed(const Duration(seconds: 35), () {
                      if (mounted) {
                        setState(() {
                          incident.status = 'ปิดเหตุแล้ว';
                          incident.timelineTimes.add(DateTime.now());
                          incident.timelineNotes.add(
                            'ครูวิจิตรตรวจสอบที่ห้องเรียนแล้ว บันทึกผลและปิดเหตุเรียบร้อย',
                          );
                          classroomSafetyStatus = 'ปกติ';
                        });
                      }
                    });
                  },
                  child: const Text(
                    'ปิดเพื่อดูสถานะ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color color = Colors.grey;
    Color bg = const Color(0xFFF1F5F9);
    switch (status) {
      case 'รอตรวจสอบ':
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
        break;
      case 'ครูรับเรื่องแล้ว':
        color = const Color(0xFF0284C7);
        bg = const Color(0xFFF0F9FF);
        break;
      case 'กำลังดำเนินการ':
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        break;
      case 'ปิดเหตุแล้ว':
        color = const Color(0xFF16A34A);
        bg = const Color(0xFFF0FDF4);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = _schoolAlerts
        .where((alert) => !alert.isAcknowledged)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'ความปลอดภัยห้องเรียน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: SchoolPalette.ink),
      ),
      body: Column(
        children: [
          // Floating red banner styled beautifully
          Container(
            width: double.infinity,
            color: const Color(0xFFFEF2F2),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'โหมดทดลอง UI — ยังไม่เชื่อมระบบแจ้งเหตุจริง',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room status card - Hero style gradient border
                  SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: classroomSafetyStatus == 'ปกติ'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            classroomSafetyStatus == 'ปกติ'
                                ? Icons.security_rounded
                                : Icons.warning_amber_rounded,
                            color: classroomSafetyStatus == 'ปกติ'
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'สถานะห้องเรียน:',
                                    style: TextStyle(
                                      color: SchoolPalette.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    classroomSafetyStatus == 'ปกติ'
                                        ? 'ปกติ / ปลอดภัย'
                                        : 'มีเหตุผิดปกติ 🚨',
                                    style: TextStyle(
                                      color: classroomSafetyStatus == 'ปกติ'
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$currentRoom ($currentBuilding)',
                                style: const TextStyle(
                                  color: SchoolPalette.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'แจ้งเหตุความช่วยเหลือเร่งด่วน ⚡',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: SchoolPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Circular SOS button - Real tactile alarm button aesthetic
                  Center(
                    child: SoftCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: classroomSafetyStatus == 'มีเหตุ'
                                ? null
                                : () => _openConfirmSheet('SOS'),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: classroomSafetyStatus == 'มีเหตุ'
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF94A3B8),
                                          Color(0xFF64748B),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFEF4444),
                                          Color(0xFFB91C1C),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                boxShadow: classroomSafetyStatus == 'มีเหตุ'
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          spreadRadius: 4,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 6,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emergency_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'ปุ่มแจ้งเหตุฉุกเฉินระดับวิกฤต (SOS)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: SchoolPalette.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'เกิดอุบัติเหตุรุนแรง ทะเลาะวิวาท หรือภัยคุกคามสวัสดิภาพทันที',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: SchoolPalette.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Warning button - Sleek amber gradient action
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBEB),
                        foregroundColor: const Color(0xFFB45309),
                        elevation: 0,
                        side: const BorderSide(
                          color: Color(0xFFFDE68A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: classroomSafetyStatus == 'มีเหตุ'
                          ? null
                          : () => _openConfirmSheet('WARNING'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '⚠️ แจ้งพบเหตุผิดปกติหรือจุดเสี่ยงในห้องเรียน',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Active warning alerts list
                  if (visibleAlerts.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'ประกาศด่วนด้านความปลอดภัย 📢',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                            color: SchoolPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${visibleAlerts.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...visibleAlerts.map((alert) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x060F172A),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFDE68A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notification_important_rounded,
                                    color: Color(0xFFB45309),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: SchoolPalette.ink,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'พื้นที่พบเหตุ: ${alert.area}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFFB45309),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              alert.content,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => _acknowledgeAlert(alert.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB45309),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'รับทราบประกาศ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Reports list
                  const Text(
                    'ประวัติการแจ้งเหตุความปลอดภัยของฉัน 📁',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      color: SchoolPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._myIncidents.map((incident) {
                    final timeStr =
                        '${incident.timestamp.hour.toString().padLeft(2, '0')}:${incident.timestamp.minute.toString().padLeft(2, '0')} น.';
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showIncidentDetailModal(incident),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: incident.type == 'SOS'
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFFFF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  incident.type == 'SOS'
                                      ? Icons.emergency_rounded
                                      : Icons.warning_amber_rounded,
                                  color: incident.type == 'SOS'
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      incident.type == 'SOS'
                                          ? 'แจ้งเหตุความช่วยเหลือ SOS'
                                          : 'แจ้งพบเหตุผิดปกติในห้องเรียน',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: SchoolPalette.ink,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'พิกัด: ${incident.room} • แจ้งเมื่อ $timeStr',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: SchoolPalette.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusPill(incident.status),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// S2: หน้าสรุปข้อมูลก่อนส่ง + ปุ่มกดค้าง 3 วินาทีเพื่อยืนยัน
/// (emergency-alert-app-proposal-v1 ข้อ 4.2) — ปล่อยนิ้วก่อนครบ = ยกเลิก
/// อัตโนมัติ ไม่มีอะไรถูกส่ง ต่างจากปุ่มแตะครั้งเดียวที่กดพลาดง่าย
class _IncidentConfirmSheet extends StatefulWidget {
  const _IncidentConfirmSheet({
    required this.type,
    required this.room,
    required this.building,
  });

  final String type; // 'SOS' or 'WARNING'
  final String room;
  final String building;

  @override
  State<_IncidentConfirmSheet> createState() => _IncidentConfirmSheetState();
}

class _IncidentConfirmSheetState extends State<_IncidentConfirmSheet> {
  static const _holdMs = 3000;
  static const _tickMs = 50;
  Timer? _holdTimer;
  double _progress = 0;
  bool _holding = false;

  bool get _isSOS => widget.type == 'SOS';

  void _startHold() {
    _holdTimer?.cancel();
    setState(() {
      _holding = true;
      _progress = 0;
    });
    _holdTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (t) {
      setState(() {
        _progress += _tickMs / _holdMs;
        if (_progress >= 1) {
          _progress = 1;
          t.cancel();
          Navigator.pop(context, true);
        }
      });
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _holding = false;
      _progress = 0;
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isSOS ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} น.';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ยืนยันการแจ้งเหตุ',
            style: const TextStyle(
              color: SchoolPalette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(
                  'ประเภทเหตุ',
                  _isSOS ? '🚨 SOS ฉุกเฉิน' : '⚠️ แจ้งเหตุผิดปกติ',
                  accent,
                ),
                const SizedBox(height: 8),
                _summaryRow(
                  'ห้อง',
                  '${widget.room} (${widget.building})',
                  SchoolPalette.ink,
                ),
                const SizedBox(height: 8),
                _summaryRow('เวลา', 'วันนี้ $timeStr', SchoolPalette.ink),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _holding
                ? 'กำลังยืนยัน... ห้ามปล่อยนิ้ว'
                : 'กดปุ่มด้านล่างค้างไว้ 3 วินาทีเพื่อยืนยันการส่ง',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _holding ? accent : SchoolPalette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 6,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                    child: Icon(
                      _isSOS
                          ? Icons.emergency_rounded
                          : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                color: SchoolPalette.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              color: SchoolPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
