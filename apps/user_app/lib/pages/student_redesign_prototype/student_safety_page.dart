import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'widgets/student_redesign_palette.dart';

String _statusLabel(String status) => switch (status) {
  'new' => 'รอตรวจสอบ',
  'acknowledged' => 'ครูรับเรื่องแล้ว',
  'in_progress' => 'กำลังดำเนินการ',
  'escalated' => 'ยกระดับเป็นเหตุฉุกเฉิน',
  'resolved' => 'ปิดเหตุแล้ว',
  'cancelled' => 'ปิดเหตุแล้ว (ไม่ใช่เหตุจริง)',
  _ => status,
};

String _categoryLabel(IncidentCategory category) =>
    category == IncidentCategory.sos
    ? 'ขอความช่วยเหลือด่วน (SOS)'
    : 'แจ้งเหตุผิดปกติ';

class StudentSafetyPage extends StatefulWidget {
  const StudentSafetyPage({super.key});

  @override
  State<StudentSafetyPage> createState() => _StudentSafetyPageState();
}

class _StudentSafetyPageState extends State<StudentSafetyPage> {
  bool _loading = true;
  String? _room;
  List<MyIncidentReport> _myIncidents = [];

  bool get _hasOpenIncident => _myIncidents.any((i) => i.isOpen);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final room = await IncidentService.getMyStudentRoom();
      final incidents = await IncidentService.listMyIncidentReports();
      if (!mounted) return;
      setState(() {
        _room = room?.room;
        _myIncidents = incidents;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // S2: หน้าสรุปข้อมูลก่อนส่ง + ปุ่มกดค้างยืนยัน — กันกดพลาดตามข้อเสนอ
  // emergency-alert-app-proposal-v1 ข้อ 1.2(2) ป้องกันสร้าง incident
  // จากการแตะเดียวโดยไม่ได้ตั้งใจ
  Future<void> _openConfirmSheet(IncidentCategory category) async {
    if (_hasOpenIncident) return;
    final room = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncidentConfirmSheet(category: category, room: _room),
    );
    if (room != null && mounted) {
      await _submitIncident(category, room);
    }
  }

  Future<void> _submitIncident(IncidentCategory category, String room) async {
    await IncidentService.createIncidentReport(
      category: category,
      room: room.trim().isEmpty ? null : room.trim(),
    );
    await _load();
    if (!mounted) return;
    _showSubmittedSheet(room);
  }

  void _showSubmittedSheet(String room) {
    showModalBottomSheet(
      context: context,
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
                'ส่งสัญญาณแจ้งเหตุเรียบร้อยแล้ว',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: SchoolPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'แจ้งครูในขอบเขตห้อง $room แล้ว',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'มีเพียงครูเท่านั้นที่ปิดเหตุได้ หลังจากตรวจสอบและบันทึกผลแล้ว '
                '— ติดตามสถานะได้จากประวัติของฉันด้านล่าง',
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ปิดหน้าต่างนี้',
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

  void _showIncidentDetailModal(MyIncidentReport incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<IncidentReportDetail>(
          future: IncidentService.getIncidentReport(incident.id),
          builder: (context, snapshot) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: !snapshot.hasData
                  ? const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildDetailContent(snapshot.data!),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailContent(IncidentReportDetail detail) {
    final events = <(String, DateTime)>[
      ('แจ้งเหตุ', detail.createdAt),
      if (detail.acknowledgedAt != null)
        ('ครูรับเรื่องแล้ว', detail.acknowledgedAt!),
      if (detail.closedAt != null)
        (
          detail.resolutionType == 'cancelled'
              ? 'ปิดเหตุ (ไม่ใช่เหตุจริง)'
              : 'ปิดเหตุแล้ว',
          detail.closedAt!,
        ),
    ];

    return Column(
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
                color: detail.category == IncidentCategory.sos
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFFFF3C7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                detail.category == IncidentCategory.sos
                    ? Icons.emergency_rounded
                    : Icons.warning_amber_rounded,
                color: detail.category == IncidentCategory.sos
                    ? Colors.red
                    : Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryLabel(detail.category),
                    style: const TextStyle(
                      color: SchoolPalette.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    detail.room ?? 'ไม่ระบุห้อง',
                    style: const TextStyle(
                      color: SchoolPalette.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusPill(detail.status),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'ความคืบหน้า',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: SchoolPalette.ink,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(events.length, (index) {
          final isLast = index == events.length - 1;
          final (label, time) = events[index];
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
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isLast ? FontWeight.w800 : FontWeight.w500,
                        color: isLast ? SchoolPalette.ink : SchoolPalette.muted,
                      ),
                    ),
                    Text(
                      '${time.toLocal().hour.toString().padLeft(2, '0')}:${time.toLocal().minute.toString().padLeft(2, '0')} น.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: SchoolPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          );
        }),
        if (detail.resolutionNote != null &&
            detail.resolutionNote!.trim().isNotEmpty) ...[
          const Divider(color: Color(0xFFF1F5F9)),
          const Text(
            'สรุปผลจากครู',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: SchoolPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.resolutionNote!,
            style: const TextStyle(
              fontSize: 12.5,
              color: SchoolPalette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color color = const Color(0xFF64748B);
    Color bg = const Color(0xFFF1F5F9);
    switch (status) {
      case 'acknowledged':
        color = const Color(0xFF0284C7);
        bg = const Color(0xFFF0F9FF);
        break;
      case 'in_progress':
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        break;
      case 'escalated':
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
        break;
      case 'resolved':
        color = const Color(0xFF16A34A);
        bg = const Color(0xFFF0FDF4);
        break;
      case 'cancelled':
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        color: _hasOpenIncident
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _hasOpenIncident
                            ? Icons.warning_amber_rounded
                            : Icons.security_rounded,
                        color: _hasOpenIncident
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
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
                                _hasOpenIncident
                                    ? 'มีเหตุผิดปกติ'
                                    : 'ปกติ / ปลอดภัย',
                                style: TextStyle(
                                  color: _hasOpenIncident
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _room != null
                                ? 'ห้อง $_room'
                                : 'ยังไม่ได้ตั้งค่าห้องประจำตัว',
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
                'แจ้งเหตุความช่วยเหลือเร่งด่วน',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: SchoolPalette.ink,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _hasOpenIncident
                            ? null
                            : () => _openConfirmSheet(IncidentCategory.sos),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _hasOpenIncident
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
                            boxShadow: _hasOpenIncident
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
                            border: Border.all(color: Colors.white, width: 6),
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
                  onPressed: _hasOpenIncident
                      ? null
                      : () => _openConfirmSheet(IncidentCategory.anomaly),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'แจ้งพบเหตุผิดปกติหรือจุดเสี่ยงในห้องเรียน',
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
              const Text(
                'ประวัติการแจ้งเหตุความปลอดภัยของฉัน',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  color: SchoolPalette.ink,
                ),
              ),
              const SizedBox(height: 12),
              if (_myIncidents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'ยังไม่มีประวัติการแจ้งเหตุ',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ..._myIncidents.map((incident) {
                  final localTime = incident.createdAt.toLocal();
                  final timeStr =
                      '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} น.';
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
                                color: incident.category == IncidentCategory.sos
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFFFF3C7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                incident.category == IncidentCategory.sos
                                    ? Icons.emergency_rounded
                                    : Icons.warning_amber_rounded,
                                color: incident.category == IncidentCategory.sos
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
                                    _categoryLabel(incident.category),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: SchoolPalette.ink,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${incident.room ?? 'ไม่ระบุห้อง'} • แจ้งเมื่อ $timeStr',
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
    );
  }
}

/// S2: หน้าสรุปข้อมูลก่อนส่ง + ปุ่มกดค้าง 3 วินาทีเพื่อยืนยัน
/// (emergency-alert-app-proposal-v1 ข้อ 4.2) — ปล่อยนิ้วก่อนครบ = ยกเลิก
/// อัตโนมัติ ไม่มีอะไรถูกส่ง ต่างจากปุ่มแตะครั้งเดียวที่กดพลาดง่าย
class _IncidentConfirmSheet extends StatefulWidget {
  const _IncidentConfirmSheet({required this.category, required this.room});

  final IncidentCategory category;
  final String? room;

  @override
  State<_IncidentConfirmSheet> createState() => _IncidentConfirmSheetState();
}

class _IncidentConfirmSheetState extends State<_IncidentConfirmSheet> {
  static const _holdMs = 3000;
  static const _tickMs = 50;
  Timer? _holdTimer;
  double _progress = 0;
  bool _holding = false;
  late final TextEditingController _roomController;

  bool get _isSOS => widget.category == IncidentCategory.sos;

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController(text: widget.room ?? '');
  }

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
          Navigator.pop(context, _roomController.text);
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
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isSOS ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} น.';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
            const Text(
              'ยืนยันการแจ้งเหตุ',
              style: TextStyle(
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
                    _isSOS ? 'SOS ฉุกเฉิน' : 'แจ้งเหตุผิดปกติ',
                    accent,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 68,
                        child: Text(
                          'ห้อง',
                          style: TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _roomController,
                          style: const TextStyle(
                            color: SchoolPalette.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'ระบุห้อง เช่น ม.5/2',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
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
              onPressed: () => Navigator.pop(context, null),
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
