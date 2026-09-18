import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'widgets/student_empty_state.dart';
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
  const StudentSafetyPage({
    super.key,
    this.loadRoom,
    this.loadIncidents,
    this.submitIncident,
    this.loadIncidentDetail,
    this.watchIncidents,
  });

  /// Read/write seams threaded to the corresponding IncidentService static
  /// calls in production — widget tests supply these to drive the SOS
  /// submit flow and history list without a live Supabase client.
  final Future<MyStudentRoom?> Function()? loadRoom;
  final Future<List<MyIncidentReport>> Function()? loadIncidents;
  final Future<String> Function({
    required IncidentCategory category,
    String? room,
    String? reason,
    String? severity,
  })?
  submitIncident;
  final Future<IncidentReportDetail> Function(String incidentId)?
  loadIncidentDetail;
  final Stream<List<Map<String, dynamic>>> Function()? watchIncidents;

  @override
  State<StudentSafetyPage> createState() => _StudentSafetyPageState();
}

class _StudentSafetyPageState extends State<StudentSafetyPage> {
  bool _loading = true;
  String? _room;
  List<MyIncidentReport> _myIncidents = [];
  StreamSubscription? _incidentSub;

  bool get _hasOpenIncident => _myIncidents.any((i) => i.isOpen);

  @override
  void initState() {
    super.initState();
    _load();
    final watch =
        widget.watchIncidents ?? IncidentService.streamIncidentReports;
    _incidentSub = watch().listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _incidentSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final loadRoom = widget.loadRoom ?? IncidentService.getMyStudentRoom;
      final loadIncidents =
          widget.loadIncidents ?? IncidentService.listMyIncidentReports;
      final room = await loadRoom();
      final incidents = await loadIncidents();
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
    final result = await showModalBottomSheet<_IncidentConfirmResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncidentConfirmSheet(category: category, room: _room),
    );
    if (result != null && mounted) {
      await _submitIncident(
        category,
        result.room,
        result.reason,
        result.severity,
      );
    }
  }

  Future<void> _submitIncident(
    IncidentCategory category,
    String room,
    String reason,
    String severity,
  ) async {
    final submit =
        widget.submitIncident ?? IncidentService.createIncidentReport;
    await submit(
      category: category,
      room: room.trim().isEmpty ? null : room.trim(),
      reason: reason.trim().isEmpty ? null : reason.trim(),
      severity: severity,
    );
    await _load();
    if (!mounted) return;
    _showSubmittedSheet(room, reason, severity);
  }

  void _showSubmittedSheet(String room, String reason, String severity) {
    final sevText = switch (severity) {
      'high' => '🔴 เหตุใหญ่ / ฉุกเฉินด่วน',
      'medium' => '🟠 เหตุปานกลาง',
      _ => '🟢 เหตุเล็ก / ทั่วไป',
    };

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
                'แจ้งครูประจำห้อง $room ($sevText) แล้ว',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (reason.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'เหตุผลที่ระบุ: "${reason.trim()}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SchoolPalette.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'ครูได้รับข้อมูลเหตุผลและความรุนแรงเพื่อประเมินสถานการณ์ล่วงหน้าแล้ว '
                'ติดตามสถานะได้จากประวัติด้านล่าง',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
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
          future:
              (widget.loadIncidentDetail ?? IncidentService.getIncidentReport)(
                incident.id,
              ),
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
                  Row(
                    children: [
                      Text(
                        _categoryLabel(detail.category),
                        style: const TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSeverityBadge(detail.severity),
                    ],
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
        if (detail.reason != null && detail.reason!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เหตุผลที่แจ้งให้ครูทราบ:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SchoolPalette.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.reason!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: SchoolPalette.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String? severity) {
    final (label, color) = switch (severity) {
      'high' => ('🔴 เหตุใหญ่', const Color(0xFFDC2626)),
      'medium' => ('🟠 เหตุปานกลาง', const Color(0xFFD97706)),
      _ => ('🟢 เหตุเล็ก', const Color(0xFF16A34A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
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
              // Status hero: green gradient while the room is clear, red
              // while one of this student's incidents is still open.
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  gradient: _hasOpenIncident
                      ? const LinearGradient(
                          colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : SchoolPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        _hasOpenIncident
                            ? Icons.warning_amber_rounded
                            : Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _room != null
                                ? 'ห้อง $_room'
                                : 'ยังไม่ได้ตั้งค่าห้องประจำตัว',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'สถานะห้องเรียน:',
                                style: TextStyle(
                                  color: SchoolPalette.cream,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _hasOpenIncident
                                      ? 'มีเหตุผิดปกติ'
                                      : 'ปกติ / ปลอดภัย',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                  ),
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
              const SizedBox(height: 22),
              const Text(
                'แจ้งเหตุ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: SchoolPalette.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'เลือกให้ตรงกับความรุนแรงของเหตุ',
                style: TextStyle(
                  fontSize: 12,
                  color: SchoolPalette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // IntrinsicHeight: stretch inside a scroll view has unbounded
              // height (same trap as aiot_weather_sensors_card.dart).
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ReportActionTile(
                        enabled: !_hasOpenIncident,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        icon: Icons.emergency_rounded,
                        badge: 'SOS',
                        title: 'ฉุกเฉินวิกฤต',
                        subtitle: 'อุบัติเหตุรุนแรง ทะเลาะวิวาท ภัยคุกคาม',
                        action: 'แจ้งด่วน',
                        onTap: () => _openConfirmSheet(IncidentCategory.sos),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ReportActionTile(
                        enabled: !_hasOpenIncident,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        icon: Icons.warning_amber_rounded,
                        title: 'เหตุผิดปกติ',
                        subtitle: 'ของชำรุด ไฟรั่ว พื้นลื่น จุดเสี่ยง',
                        action: 'แจ้งเหตุ',
                        onTap: () =>
                            _openConfirmSheet(IncidentCategory.anomaly),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasOpenIncident) ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: SchoolPalette.muted,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'มีเหตุที่ยังเปิดอยู่ — แจ้งใหม่ได้เมื่อครูปิดเหตุแล้ว',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: SchoolPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                const StudentEmptyState(
                  icon: Icons.shield_outlined,
                  title: 'ยังไม่มีประวัติการแจ้งเหตุ',
                  hint: 'เหตุที่คุณแจ้งจะแสดงที่นี่พร้อมสถานะจากครู',
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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _categoryLabel(incident.category),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: SchoolPalette.ink,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildSeverityBadge(incident.severity),
                                    ],
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
                                  if (incident.reason != null &&
                                      incident.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'เหตุผล: ${incident.reason}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: SchoolPalette.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
class _IncidentConfirmResult {
  const _IncidentConfirmResult({
    required this.room,
    required this.reason,
    required this.severity,
  });

  final String room;
  final String reason;
  final String severity;
}

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
  late final TextEditingController _reasonController;

  late String _severity;

  final List<String> _quickReasons = const [
    '🩺 เจ็บป่วย / ไม่สบายด่วน',
    '🛠️ อุปกรณ์ชำรุด / เป็นอันตราย',
    '⚠️ ทะเลาะวิวาท / มีปากเสียง',
    '🚨 ฉุกเฉินร้ายแรง / บุกรุก',
  ];

  bool get _isSOS => widget.category == IncidentCategory.sos;

  bool get _canSubmit => _reasonController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController(text: widget.room ?? '');
    _reasonController = TextEditingController();
    _reasonController.addListener(() {
      if (mounted) setState(() {});
    });
    _severity = _isSOS ? 'high' : 'low';
  }

  void _startHold() {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ กรุณาเลือกชิปเหตุผลด้านบน หรือพิมพ์ระบุสิ่งที่พบเห็นก่อนกดปุ่มยืนยัน',
          ),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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
          Navigator.pop(
            context,
            _IncidentConfirmResult(
              room: _roomController.text,
              reason: _reasonController.text,
              severity: _severity,
            ),
          );
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
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isSOS ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final gradient = _isSOS
        ? const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} น.';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner in the category colour — the one thing the eye
                // must get right before anything else: what is being sent.
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 14, 18),
                  decoration: BoxDecoration(gradient: gradient),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              _isSOS
                                  ? Icons.emergency_rounded
                                  : Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSOS ? 'SOS ฉุกเฉิน' : 'แจ้งเหตุผิดปกติ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isSOS
                                      ? 'ครูและผู้ดูแลจะได้รับแจ้งทันที'
                                      : 'ครูจะได้รับแจ้งและเข้ามาตรวจสอบ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(context, null),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kept for the tests and as the form's own heading.
                      const Text(
                        'ระบุเหตุผลและยืนยันการแจ้งเหตุ',
                        style: TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _stepLabel('1', 'ความรุนแรง'),
                      const SizedBox(height: 8),
                      // iOS-style segmented control.
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: SchoolPalette.softGreenBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildSeverityChip('low', '🟢 เหตุเล็ก'),
                            _buildSeverityChip('medium', '🟠 เหตุปานกลาง'),
                            _buildSeverityChip('high', '🔴 เหตุใหญ่ / ด่วน'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _stepLabel('2', 'เหตุผล / สิ่งที่พบเห็น', required: true),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              mainAxisExtent: 52,
                            ),
                        itemCount: _quickReasons.length,
                        itemBuilder: (_, i) {
                          final r = _quickReasons[i];
                          final isSelected = _reasonController.text == r;
                          return Material(
                            color: isSelected
                                ? accent.withValues(alpha: 0.10)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected
                                    ? accent
                                    : SchoolPalette.glassBorder,
                                width: isSelected ? 1.6 : 1.2,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  setState(() => _reasonController.text = r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.25,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? accent
                                              : SchoolPalette.ink,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: accent,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reasonController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'หรือพิมพ์รายละเอียดเพิ่มเติม…',
                          hintStyle: const TextStyle(
                            color: SchoolPalette.muted,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(
                            Icons.notes_rounded,
                            size: 20,
                            color: SchoolPalette.muted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: SchoolPalette.glassBorder,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: SchoolPalette.softGreenBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.meeting_room_outlined,
                                    size: 18,
                                    color: SchoolPalette.muted,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ห้อง',
                                    style: TextStyle(
                                      color: SchoolPalette.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _roomController,
                                      style: const TextStyle(
                                        color: SchoolPalette.ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        isCollapsed: true,
                                        hintText: 'เช่น ม.5/2',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: SchoolPalette.softGreenBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: SchoolPalette.muted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: SchoolPalette.ink,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Hold-to-send bar: same GestureDetector, timer and
                      // validation as before; the fill is the 3-second
                      // progress.
                      GestureDetector(
                        onTapDown: (_) => _startHold(),
                        onTapUp: (_) => _cancelHold(),
                        onTapCancel: _cancelHold,
                        child: Container(
                          height: 60,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            gradient: _canSubmit ? gradient : null,
                            color: _canSubmit
                                ? null
                                : SchoolPalette.glassBorder,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _canSubmit
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _canSubmit
                                    ? _progress.clamp(0.0, 1.0)
                                    : 0.0,
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSOS
                                          ? Icons.emergency_rounded
                                          : Icons.warning_amber_rounded,
                                      color: _canSubmit
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      !_canSubmit
                                          ? 'เลือกเหตุผลก่อน'
                                          : _holding
                                          ? 'กำลังส่ง… กดค้างไว้'
                                          : (_isSOS
                                                ? 'กดค้างเพื่อส่ง SOS'
                                                : 'กดค้างเพื่อส่งแจ้งเหตุ'),
                                      style: TextStyle(
                                        color: _canSubmit
                                            ? Colors.white
                                            : const Color(0xFF94A3B8),
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
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _canSubmit
                              ? 'กดค้าง 3 วินาที · ปล่อยก่อนครบเพื่อยกเลิก'
                              : 'ครูจะเห็นเหตุผลที่คุณเลือกก่อนถึงห้อง',
                          style: const TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepLabel(String n, String text, {bool required = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: SchoolPalette.ink,
            shape: BoxShape.circle,
          ),
          child: Text(
            n,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: SchoolPalette.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSeverityChip(String value, String label) {
    final isSelected = _severity == value;
    final color = switch (value) {
      'high' => const Color(0xFFDC2626),
      'medium' => const Color(0xFFD97706),
      _ => const Color(0xFF16A34A),
    };
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _severity = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? color : SchoolPalette.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// One report action as a tall tile — two of them sit side by side. The
/// whole tile is the button; the gradient icon block and the action pill
/// make that unmistakable (2026-09-18 owner review). Greyed while an
/// incident is still open.
class _ReportActionTile extends StatelessWidget {
  const _ReportActionTile({
    required this.enabled,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.badge,
  });

  final bool enabled;
  final LinearGradient gradient;
  final IconData icon;
  final String? badge;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = enabled
        ? gradient
        : const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)]);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: enabled
                ? gradient.colors.first.withValues(alpha: 0.35)
                : SchoolPalette.glassBorder,
            width: 1.4,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: g,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: gradient.colors.last.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: badge == null ? 28 : 22,
                      ),
                      if (badge != null)
                        Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: g,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
