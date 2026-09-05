import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';
import 'controllers/staff_emergency_actions.dart';

Color _categoryColor(IncidentCategory c) => c == IncidentCategory.sos
    ? const Color(0xFFDC2626)
    : const Color(0xFFD97706);

String _categoryLabel(IncidentCategory c) =>
    c == IncidentCategory.sos ? 'SOS ฉุกเฉิน' : 'แจ้งเหตุผิดปกติ';

String _statusLabel(String status) => switch (status) {
  'new' => 'รอตรวจสอบ',
  'acknowledged' => 'รับเรื่องแล้ว',
  'in_progress' => 'กำลังดำเนินการ',
  'escalated' => 'ยกระดับแล้ว',
  'resolved' => 'ปิดเหตุแล้ว (เหตุจริง)',
  'cancelled' => 'ปิดเหตุแล้ว (แจ้งเท็จ)',
  _ => status,
};

Color _statusColor(String status) => switch (status) {
  'new' => TeacherPalette.muted,
  'acknowledged' => const Color(0xFF2563EB),
  'in_progress' => const Color(0xFFD97706),
  'escalated' => const Color(0xFFDC2626),
  'resolved' => const Color(0xFF059669),
  'cancelled' => TeacherPalette.muted,
  _ => TeacherPalette.muted,
};

Widget _buildSeverityBadge(String? severity) {
  final (label, color) = switch (severity) {
    'high' => ('🔴 เหตุใหญ่', const Color(0xFFDC2626)),
    'medium' => ('🟠 เหตุปานกลาง', const Color(0xFFD97706)),
    _ => ('🟢 เหตุเล็ก', const Color(0xFF059669)),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  return '${diff.inDays} วันที่แล้ว';
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year;
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm น.';
}


// ==========================================
// S4: หน้ารับแจ้งเหตุ (Inbox) — เชื่อมต่อ Backend จริง (Merge กับ Emergency Events)
// ==========================================

class _EmergencyEvent {
  final String id;
  final String title;
  final String type;
  final String location;
  final String time;
  final String reporter;
  final String source;
  final String status;
  final String priority;
  final String description;
  final String action;
  final IconData icon;
  final Color color;
  final TeacherIncidentReport? originalIncident;

  _EmergencyEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.time,
    required this.reporter,
    required this.source,
    required this.status,
    required this.priority,
    required this.description,
    required this.action,
    required this.icon,
    required this.color,
    this.originalIncident,
  });
}

class TeacherIncidentInboxPage extends StatefulWidget {
  const TeacherIncidentInboxPage({super.key});

  @override
  State<TeacherIncidentInboxPage> createState() =>
      _TeacherIncidentInboxPageState();
}

class _TeacherIncidentInboxPageState extends State<TeacherIncidentInboxPage> {
  String selectedFilter = 'ทั้งหมด';
  String searchText = '';

  bool _isLoadingRealData = false;
  bool sosResolved = true;
  bool sosAccepted = false;
  String? _loadError;
  int _loadGeneration = 0;
  late final StaffEmergencyActions _actions;

  void _actionsChanged() {
    if (mounted) setState(() {});
  }

  Future<String?> _readEventStatus(StaffEmergencySource source, String id) async {
    if (source == StaffEmergencySource.incident) {
      final rows = await IncidentService.listStaffIncidentReports();
      return rows.where((row) => row.id == id).firstOrNull?.status;
    }
    final rows = await EmergencyService.listEmergencyEvents();
    return rows.where((row) => row.id == id).firstOrNull?.status;
  }

  Future<void> _performAction(_EmergencyEvent event, {bool close = false}) async {
    if (_actions.isBusy) return;
    final source = event.originalIncident != null
        ? StaffEmergencySource.incident : StaffEmergencySource.hardware;
    final result = close
        ? await _actions.close(source, event.id, 'ครูตรวจสอบและระงับเหตุเรียบร้อย')
        : await _actions.acknowledge(source, event.id);
    if (!mounted || result == StaffEmergencyResult.busy) return;
    if (result == StaffEmergencyResult.confirmed) {
      await _loadRealData();
      if (!mounted) return;
      _showMessage(close ? 'ปิดเหตุเรียบร้อยแล้ว' : 'รับเรื่องเรียบร้อยแล้ว');
    } else {
      _showMessage(result == StaffEmergencyResult.unconfirmed
          ? 'ส่งคำขอแล้ว แต่ยังยืนยันสถานะล่าสุดไม่ได้ กรุณารีเฟรชก่อนดำเนินการอีกครั้ง'
          : close ? 'ปิดเหตุไม่สำเร็จ กรุณาลองใหม่' : 'รับเหตุไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  EmergencyEventItem? get _activeRealEmergencyEvent {
    if (_realEmergencyEvents.isEmpty) return null;
    return _realEmergencyEvents
        .where((e) => e.status == 'new' || e.status == 'acknowledged')
        .firstOrNull;
  }

  TeacherIncidentReport? get _activeSosIncident => _realIncidents.where((i) => i.category == IncidentCategory.sos && (i.status == 'new' || i.status == 'acknowledged' || i.status == 'in_progress')).firstOrNull;

  TeacherIncidentReport? _lastResolvedSosIncident;

  List<EmergencyEventItem> _realEmergencyEvents = [];
  List<TeacherIncidentReport> _realIncidents = [];
  StreamSubscription? _incidentSub;
  StreamSubscription? _emergencySub;
  
  @override
  void initState() {
    super.initState();
    _actions = StaffEmergencyActions(
      acknowledgeIncident: IncidentService.acknowledgeIncidentReport,
      acknowledgeHardware: EmergencyService.acknowledgeEmergencyEvent,
      closeIncident: (id, note) => IncidentService.closeIncidentReport(
        id, resolutionType: 'resolved', resolutionNote: note),
      closeHardware: (id, note) => EmergencyService.closeEmergencyEvent(
        eventId: id, reviewNote: note),
      readStatus: _readEventStatus,
    )..addListener(_actionsChanged);
    _loadRealData();
    _incidentSub = IncidentService.streamIncidentReports().listen((_) {
      if (mounted) _loadRealData();
    });
    _emergencySub = EmergencyService.streamEmergencyEvents().listen((_) {
      if (mounted) _loadRealData();
    });
  }

  @override
  void dispose() {
    _actions.removeListener(_actionsChanged);
    _actions.dispose();
    _incidentSub?.cancel();
    _emergencySub?.cancel();
    super.dispose();
  }

  Future<void> _loadRealData() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    setState(() { _isLoadingRealData = true; _loadError = null; });
    try {
      final results = await Future.wait<dynamic>([
        EmergencyService.listEmergencyEvents(),
        IncidentService.listStaffIncidentReports(),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _realEmergencyEvents = results[0] as List<EmergencyEventItem>;
        _realIncidents = results[1] as List<TeacherIncidentReport>;
        _isLoadingRealData = false;
        final inc = _activeSosIncident;
        final evt = _activeRealEmergencyEvent;
        _lastResolvedSosIncident = _realIncidents.where((i) =>
            i.category == IncidentCategory.sos &&
            (i.status == 'resolved' || i.status == 'cancelled')).firstOrNull;
        sosResolved = inc == null && evt == null;
        sosAccepted = inc != null
            ? inc.status == 'acknowledged' || inc.status == 'in_progress'
            : evt?.status == 'acknowledged';
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoadingRealData = false;
        _loadError = 'โหลดเหตุฉุกเฉินไม่สำเร็จ ข้อมูลที่แสดงอาจยังไม่เป็นปัจจุบัน';
      });
    }
  }

  _EmergencyEvent _convertIncident(TeacherIncidentReport inc) {
    final localTime = inc.createdAt.toLocal();
    final timeStr = 'วันนี้ • ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} น.';
    final statusDisplay = inc.status == 'new'
        ? 'รอตรวจสอบ'
        : (inc.status == 'acknowledged'
            ? 'รับเรื่องแล้ว'
            : (inc.status == 'resolved' || inc.status == 'cancelled'
                ? 'ปิดเหตุแล้ว'
                : (inc.status == 'escalated' ? 'ยกระดับแล้ว' : 'กำลังช่วยเหลือ')));
    final isSos = inc.category == IncidentCategory.sos;
    return _EmergencyEvent(
      id: inc.id,
      title: inc.reason != null && inc.reason!.isNotEmpty
          ? inc.reason!
          : (isSos ? 'SOS จากนักเรียน' : 'แจ้งเหตุผิดปกติ'),
      type: isSos ? 'SOS' : 'เหตุผิดปกติ',
      location: inc.room != null && inc.room!.isNotEmpty
          ? 'ห้อง ${inc.room}'
          : 'ภายในโรงเรียน',
      time: timeStr,
      reporter: inc.reporterName.isNotEmpty ? inc.reporterName : 'นักเรียน',
      source: 'แอปนักเรียน (SOS)',
      status: statusDisplay,
      priority: isSos ? 'เร่งด่วน' : 'สูง',
      description: inc.reason ?? (isSos ? 'นักเรียนส่งสัญญาณขอความช่วยเหลือเร่งด่วน' : 'นักเรียนรายงานเหตุผิดปกติ'),
      action: 'ตรวจสอบและให้ความช่วยเหลือ',
      icon: isSos ? Icons.notifications_active_rounded : Icons.warning_amber_rounded,
      color: isSos ? TeacherPalette.red : TeacherPalette.orange,
      originalIncident: inc,
    );
  }

  _EmergencyEvent _convertEmergencyEvent(EmergencyEventItem evt) {
    final localTime = evt.triggeredAt.toLocal();
    final timeStr = 'วันนี้ • ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} น.';
    final statusDisplay = evt.status == 'new'
        ? 'รอตรวจสอบ'
        : (evt.status == 'acknowledged' ? 'รับเรื่องแล้ว' : 'ปิดเหตุแล้ว');
    return _EmergencyEvent(
      id: evt.id,
      title: 'เหตุฉุกเฉินจาก ${evt.deviceName}',
      type: 'ปุ่มฉุกเฉิน',
      location: evt.location,
      time: timeStr,
      reporter: 'IoT Sensor',
      source: evt.deviceName,
      status: statusDisplay,
      priority: 'เร่งด่วน',
      description: 'ระบบตรวจพบการกดปุ่มแจ้งเหตุฉุกเฉินที่ ${evt.location}',
      action: 'เข้าตรวจสอบพื้นที่ทันที',
      icon: Icons.emergency_rounded,
      color: TeacherPalette.red,
    );
  }

  List<_EmergencyEvent> get _allDisplayEvents {
    final list = <_EmergencyEvent>[];
    for (final inc in _realIncidents) {
      list.add(_convertIncident(inc));
    }
    for (final evt in _realEmergencyEvents) {
      list.add(_convertEmergencyEvent(evt));
    }
    // Sort by most urgent / newest
    list.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority == 'เร่งด่วน' ? -1 : 1;
      }
      return b.time.compareTo(a.time); // simple string sort for time
    });
    return list;
  }

  List<_EmergencyEvent> _filteredEvents() {
    final query = searchText.trim().toLowerCase();
    final allEvents = _allDisplayEvents;

    return allEvents.where((item) {
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.type.toLowerCase().contains(query) ||
          item.reporter.toLowerCase().contains(query);

      final matchesFilter = selectedFilter == 'ทั้งหมด' ||
          item.status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _openDetail(_EmergencyEvent event) async {
    if (event.originalIncident != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherIncidentDetailPage(incident: event.originalIncident!),
        ),
      );
      if (mounted) _loadRealData();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: TeacherPalette.ink),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ประเภท: ${event.type}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('ตำแหน่ง: ${event.location}'),
              const SizedBox(height: 8),
              Text('เวลา: ${event.time}'),
              const SizedBox(height: 8),
              Text('รายละเอียด: ${event.description}'),
              const SizedBox(height: 8),
              Text('สถานะ: ${event.status}', style: TextStyle(color: event.status == 'ปิดเหตุแล้ว' ? TeacherPalette.green : TeacherPalette.orange, fontWeight: FontWeight.w700)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ปิด', style: TextStyle(color: TeacherPalette.primary)),
            ),
          ],
        ),
      );
    }
  }


  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _acceptSos() async {
    final inc = _activeSosIncident;
    final evt = _activeRealEmergencyEvent;
    if (inc != null) {
      await _performAction(_convertIncident(inc));
    } else if (evt != null) {
      await _performAction(_convertEmergencyEvent(evt));
    }
  }

  Future<void> _closeActiveSos() async {
    final inc = _activeSosIncident;
    final evt = _activeRealEmergencyEvent;
    if (inc != null) {
      await _quickClose(_convertIncident(inc));
    } else if (evt != null) {
      await _quickClose(_convertEmergencyEvent(evt));
    }
  }

  void _showSosDetail() {
    final inc = _activeSosIncident;
    final evt = _activeRealEmergencyEvent;
    if (inc != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherIncidentDetailPage(incident: inc),
        ),
      ).then((_) => _loadRealData());
    } else if (evt != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'เหตุฉุกเฉินจาก ${evt.deviceName}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: TeacherPalette.ink),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ประเภท: ปุ่มกดแจ้งเหตุฉุกเฉิน', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('ตำแหน่ง: ${evt.location}'),
              const SizedBox(height: 8),
              Text('เวลา: ${evt.triggeredAt.toLocal().hour.toString().padLeft(2, '0')}:${evt.triggeredAt.toLocal().minute.toString().padLeft(2, '0')} น.'),
              const SizedBox(height: 8),
              Text('สถานะ: ${evt.status}', style: const TextStyle(color: TeacherPalette.orange, fontWeight: FontWeight.w700)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ปิด', style: TextStyle(color: TeacherPalette.primary)),
            ),
          ],
        ),
      );
    } else {
      _showMessage('ยังไม่มีเหตุฉุกเฉินที่กำลังดำเนินการ');
    }
  }

  Widget _unifiedSpecChip(IconData icon, String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPrimary ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isPrimary ? const Color(0xFFE11D48) : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPrimary ? const Color(0xFF9F1239) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoBadge({String text = 'ข้อมูลจำลอง'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 3.5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _realBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 3.5),
          const Text(
            'ฐานข้อมูลจริง',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosPanel() {
    if (sosResolved) {
      return _sosResolvedCard();
    }
    return _sosActiveCard();
  }

  Widget _sosResolvedCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFDCFCE7), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'สภาวะปกติ • เหตุการณ์ SOS ล่าสุดได้รับการแก้ไขเรียบร้อยแล้ว',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ปิดเหตุเมื่อ 10:48 น. (ระงับเหตุใน 6 นาที)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 780;

                final resolved = _lastResolvedSosIncident;

                final infoSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 24,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      resolved != null
                                          ? (resolved.room != null && resolved.room!.isNotEmpty
                                              ? 'บันทึกการระงับเหตุ: SOS ห้อง ${resolved.room}'
                                              : 'บันทึกการระงับเหตุ: SOS จากนักเรียน')
                                          : 'บันทึกการระงับเหตุ: SOS',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5.5,
                                          height: 5.5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'ปิดเหตุแล้ว',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                resolved != null
                                    ? '${resolved.reason ?? "สัญญาณฉุกเฉิน"} • ${resolved.room != null && resolved.room!.isNotEmpty ? "ห้อง ${resolved.room}" : "ภายในโรงเรียน"} • ${_statusLabel(resolved.status)}'
                                    : 'ปิดเหตุการณ์เรียบร้อยแล้ว',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3.5,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'สรุปผลการปฏิบัติการระงับเหตุ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  resolved != null
                                      ? 'ผู้แจ้ง: ${resolved.reporterName.isNotEmpty ? resolved.reporterName : "นักเรียน"} • สถานะ: ${_statusLabel(resolved.status)}'
                                      : 'ปิดเหตุการณ์เรียบร้อยแล้ว',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    height: 1.45,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _unifiedSpecChip(
                          Icons.place_rounded,
                          resolved?.room != null && resolved!.room!.isNotEmpty
                              ? 'ห้อง ${resolved.room}'
                              : 'ภายในโรงเรียน',
                        ),
                        _unifiedSpecChip(
                          Icons.person_rounded,
                          'ผู้แจ้ง: ${resolved?.reporterName.isNotEmpty == true ? resolved!.reporterName : "นักเรียน"}',
                        ),
                        if (resolved != null)
                          _unifiedSpecChip(
                            Icons.access_time_rounded,
                            _timeAgo(resolved.createdAt),
                          ),
                        _unifiedSpecChip(
                          Icons.check_circle_outline_rounded,
                          _statusLabel(resolved?.status ?? 'resolved'),
                        ),
                      ],
                    ),
                  ],
                );

                final actionSection = Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _showSosDetail,
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text(
                          'ดูรายงานสรุปและไทม์ไลน์',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          foregroundColor: const Color(0xFF475569),
                        ),
                        onPressed: () {
                          final room = resolved?.room;
                          _showMessage(room != null && room.isNotEmpty
                              ? 'กำลังเปิดคลิปบันทึกย้อนหลัง CCTV ห้อง $room ช่วงเกิดเหตุ...'
                              : 'กำลังเปิดคลิปบันทึกย้อนหลัง CCTV ช่วงเกิดเหตุ...');
                        },
                        icon: const Icon(Icons.videocam_outlined, size: 16),
                        label: const Text(
                          'ดูภาพย้อนหลัง CCTV',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoSection,
                      const SizedBox(height: 16),
                      actionSection,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: infoSection),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 230,
                      child: actionSection,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosActiveCard() {
    final isUrgent = !sosAccepted;
    final statusColor = sosAccepted ? const Color(0xFFD97706) : const Color(0xFFE11D48);
    final statusText = sosAccepted ? 'รับเรื่องแล้ว • กำลังช่วยเหลือ' : 'รอรับ SOS ด่วน';

    final activeIncident = _activeSosIncident;
    final activeEvt = _activeRealEmergencyEvent;
    final bool hasActiveReal = activeIncident != null || activeEvt != null;

    final titleText = activeIncident != null
        ? (activeIncident.room != null && activeIncident.room!.isNotEmpty
            ? 'SOS จากนักเรียน ห้อง ${activeIncident.room}'
            : 'SOS จากนักเรียน')
        : (activeEvt != null
            ? 'เหตุฉุกเฉินจาก ${activeEvt.deviceName}'
            : 'SOS จากนักเรียน ห้อง ม.3/2');

    final reasonText = activeIncident != null
        ? 'ประเภทเหตุ: ${activeIncident.reason ?? "สัญญาณฉุกเฉิน (SOS)"}'
        : (activeEvt != null
            ? 'ประเภทเหตุ: ปุ่มกดแจ้งเหตุฉุกเฉิน'
            : 'ประเภทเหตุ: เจ็บป่วยฉุกเฉิน (นักเรียนหมดสติในคาบเรียน)');

    final locationChip = activeIncident != null
        ? (activeIncident.room != null && activeIncident.room!.isNotEmpty
            ? 'ห้อง ${activeIncident.room}'
            : 'บริเวณโรงเรียน')
        : (activeEvt != null
            ? activeEvt.location
            : 'อาคาร 3 ชั้น 2');

    final sensorChip = activeIncident != null
        ? 'แอปนักเรียน (SOS)'
        : (activeEvt != null
            ? activeEvt.deviceName
            : 'ปุ่ม SOS ห้อง ม.3/2');

    final reporterChip = activeIncident != null
        ? 'ผู้แจ้ง: ${activeIncident.reporterName.isNotEmpty ? activeIncident.reporterName : "นักเรียน"}'
        : (activeEvt != null
            ? 'ไม่มี (แจ้งเตือนจากอุปกรณ์)'
            : 'ผู้แจ้ง: ครูสมหญิง ใจดี');

    final timeChip = activeIncident != null
        ? 'แจ้งเมื่อ ${activeIncident.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${activeIncident.createdAt.toLocal().minute.toString().padLeft(2, '0')} น.'
        : (activeEvt != null
            ? 'แจ้งเมื่อ ${activeEvt.triggeredAt.toLocal().hour.toString().padLeft(2, '0')}:${activeEvt.triggeredAt.toLocal().minute.toString().padLeft(2, '0')} น.'
            : 'แจ้งเมื่อ 10:42:18 น.');

    final timerText = activeIncident != null
        ? () {
            final diff = DateTime.now().toUtc().difference(activeIncident.createdAt);
            if (diff.inMinutes < 1) return 'แจ้งมา ${diff.inSeconds} วินาทีที่แล้ว';
            if (diff.inHours < 1) return 'แจ้งมา ${diff.inMinutes} นาทีที่แล้ว';
            return 'แจ้งมา ${diff.inHours} ชม. ที่แล้ว';
          }()
        : (activeEvt != null
            ? () {
                final diff = DateTime.now().toUtc().difference(activeEvt.triggeredAt.toUtc());
                if (diff.inMinutes < 1) return 'แจ้งมา ${diff.inSeconds} วินาทีที่แล้ว';
                if (diff.inHours < 1) return 'แจ้งมา ${diff.inMinutes} นาทีที่แล้ว';
                return 'แจ้งมา ${diff.inHours} ชม. ที่แล้ว';
              }()
            : 'แจ้งมา 28 วินาทีที่แล้ว');

    final narrativeText = activeIncident != null
        ? (activeIncident.reason != null && activeIncident.reason!.isNotEmpty
            ? 'นักเรียนส่งสัญญาณขอความช่วยเหลือ: "${activeIncident.reason}" กำลังประสานผู้ที่เกี่ยวข้องเข้าช่วยเหลือทันที'
            : 'นักเรียนส่งสัญญาณขอความช่วยเหลือฉุกเฉินผ่านระบบ SOS')
        : (activeEvt != null
            ? 'ระบบตรวจพบการกดปุ่มแจ้งเหตุฉุกเฉินที่ ${activeEvt.location}'
            : 'นักเรียนหญิงหมดสติระหว่างเรียนคณิตศาสตร์ ครูประจำวิชากำลังปฐมพยาบาลเบื้องต้น ประสานครูห้องพยาบาลและครูเวรเข้าช่วยเหลือ ระบบส่งพิกัดให้ผู้อำนวยการและครูเวรแล้ว');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFFBFB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor,
          width: isUrgent ? 2.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isUrgent ? 0.22 : 0.08),
            blurRadius: isUrgent ? 24 : 16,
            offset: const Offset(0, 4),
            spreadRadius: isUrgent ? 1 : 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: sosAccepted
                    ? [const Color(0xFFB45309), const Color(0xFFD97706)]
                    : [const Color(0xFF9F1239), const Color(0xFFE11D48), const Color(0xFFBE123C)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;

                final timerPill = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timerText,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );

                final badge = hasActiveReal ? _realBadge() : _demoBadge();

                final titleRow = Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        sosAccepted ? 'กำลังเข้าควบคุมสถานการณ์' : 'LIVE EMERGENCY • สัญญาณ SOS ฉุกเฉิน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          timerPill,
                          badge,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    timerPill,
                    const SizedBox(width: 8),
                    Expanded(child: titleRow),
                    const SizedBox(width: 6),
                    badge,
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 780;

                final infoSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUrgent
                                  ? [const Color(0xFFE11D48), const Color(0xFFBE123C)]
                                  : [const Color(0xFFD97706), const Color(0xFFB45309)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      titleText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                reasonText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _unifiedSpecChip(Icons.place_rounded, locationChip, isPrimary: isUrgent),
                        _unifiedSpecChip(Icons.sensors_rounded, sensorChip, isPrimary: isUrgent),
                        _unifiedSpecChip(Icons.person_rounded, reporterChip),
                        _unifiedSpecChip(Icons.access_time_rounded, timeChip),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: isUrgent ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUrgent ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isUrgent ? const Color(0xFFFFE4E6) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.medical_services_rounded,
                              size: 18,
                              color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'รายละเอียดสถานการณ์:',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  narrativeText,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actionSection = Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: sosAccepted ? const Color(0xFF059669) : const Color(0xFFE11D48),
                          elevation: isUrgent ? 3 : 0,
                          shadowColor: isUrgent ? const Color(0xFFE11D48).withValues(alpha: 0.5) : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _actions.isBusy ? null : (sosAccepted ? _showSosDetail : _acceptSos),
                        icon: Icon(
                          sosAccepted ? Icons.check_circle_rounded : Icons.crisis_alert_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          sosAccepted ? '✓ ครูรับเรื่องแล้ว' : '🚨 รับ SOS ด่วน',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (sosAccepted) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDCFCE7),
                            foregroundColor: const Color(0xFF047857),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _actions.isBusy ? null : _closeActiveSos,
                          icon: const Icon(Icons.task_alt_rounded, size: 16),
                          label: const Text(
                            'ปิดเหตุการณ์ (เสร็จสิ้น)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isUrgent ? const Color(0xFFFECDD3) : const Color(0xFFCBD5E1),
                          ),
                          foregroundColor: isUrgent ? const Color(0xFF9F1239) : const Color(0xFF475569),
                        ),
                        onPressed: _showSosDetail,
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text(
                          'ดูรายละเอียดและไทม์ไลน์',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          final room = activeIncident?.room;
                          _showMessage(room != null && room.isNotEmpty
                              ? 'กำลังเชื่อมต่อสัญญาณกล้อง CCTV ห้อง $room...'
                              : 'กำลังเชื่อมต่อสัญญาณกล้อง CCTV ห้อง ม.3/2...');
                        },
                        icon: const Icon(Icons.videocam_rounded, size: 16, color: Color(0xFFE11D48)),
                        label: const Text(
                          'เปิดดูกล้อง CCTV ห้องนี้',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoSection,
                      const SizedBox(height: 16),
                      actionSection,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: infoSection),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 230,
                      child: actionSection,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents();

    return TeacherMockPageShell(
      title: 'รับแจ้งเหตุฉุกเฉิน',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      builder: (context, isDesktop) {
        return RefreshIndicator(
          onRefresh: _loadRealData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _emergencyHeader(),
                if (_loadError != null)
                  MaterialBanner(
                    content: Text(_loadError!),
                    actions: [TextButton(
                      onPressed: _isLoadingRealData ? null : _loadRealData,
                      child: const Text('ลองใหม่'))],
                  ),
                const SizedBox(height: 16),
                _sosPanel(),
                const SizedBox(height: 16),
                _summaryCards(),
                const SizedBox(height: 16),
                _eventHistoryCard(filtered),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emergencyHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'รับแจ้งเหตุฉุกเฉิน (Inbox)',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: TeacherPalette.ink,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'รับแจ้ง SOS เฝ้าระวังความปลอดภัย และติดตามเหตุการณ์ในวิชา/ห้องที่สอน',
              style: TextStyle(
                fontSize: 10.8,
                color: TeacherPalette.muted,
              ),
            ),
          ],
        );

        final statusBadge = Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_isLoadingRealData)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: TeacherPalette.primary),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'เชื่อมต่อระบบจริง',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isLoadingRealData ? null : _loadRealData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 13, color: TeacherPalette.muted),
                    SizedBox(width: 4),
                    Text(
                      'รีเฟรช',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 8), statusBadge],
          );
        }
        return Row(
          children: [Expanded(child: titleBlock), const SizedBox(width: 10), statusBadge],
        );
      },
    );
  }

  Widget _summaryCards() {
    final int realSosPending = _realIncidents
            .where((i) => i.category == IncidentCategory.sos && (i.status == 'new' || i.status == 'acknowledged'))
            .length +
        _realEmergencyEvents.where((e) => e.status == 'new' || e.status == 'acknowledged').length;

    final int realClosed = _realIncidents
            .where((i) => i.status == 'resolved' || i.status == 'cancelled')
            .length +
        _realEmergencyEvents.where((e) => e.status == 'closed').length;

    final int realActive = _realIncidents
            .where((i) =>
                i.category != IncidentCategory.sos &&
                i.status != 'resolved' &&
                i.status != 'cancelled')
            .length +
        _realEmergencyEvents.where((e) => e.status == 'acknowledged').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final children = [
          _buildStatCard(
            title: 'SOS รอตรวจสอบ',
            value: '$realSosPending',
            icon: Icons.notifications_active_rounded,
            color: TeacherPalette.red,
            bgColor: const Color(0xFFFFE4E6), // light red
          ),
          _buildStatCard(
            title: 'เหตุที่กำลังติดตาม',
            value: '$realActive',
            icon: Icons.warning_amber_rounded,
            color: TeacherPalette.orange,
            bgColor: const Color(0xFFFEF3C7), // light orange
          ),
          _buildStatCard(
            title: 'จัดการเสร็จสิ้น',
            value: '$realClosed',
            icon: Icons.verified_rounded,
            color: TeacherPalette.green,
            bgColor: const Color(0xFFDCFCE7), // light green
          ),
        ];

        if (compact) {
          return Column(
            children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
          );
        }
        return Row(
          children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TeacherPalette.muted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: TeacherPalette.ink,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventHistoryCard(List<_EmergencyEvent> events) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TeacherPalette.skyVivid,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, size: 18, color: TeacherPalette.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ประวัติเหตุการณ์ทั้งหมด',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'รายการเหตุฉุกเฉินและอุบัติเหตุที่เกิดขึ้น',
                        style: TextStyle(
                          fontSize: 11,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TeacherPalette.border),
          _buildFilterBar(),
          const Divider(height: 1, color: TeacherPalette.border),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: TeacherPalette.green),
                    const SizedBox(height: 12),
                    const Text(
                      'ไม่มีเหตุการณ์ในขณะนี้',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TeacherPalette.muted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: TeacherPalette.border),
              itemBuilder: (context, index) {
                final evt = events[index];
                return _buildEventListItem(evt);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 36,
            child: TextField(
              onChanged: (val) => setState(() => searchText = val),
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'ค้นหาเหตุการณ์...',
                hintStyle: const TextStyle(color: TeacherPalette.muted, fontSize: 12.5),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: TeacherPalette.muted),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: TeacherPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: TeacherPalette.border),
                ),
              ),
            ),
          ),
          _filterChip('ทั้งหมด'),
          _filterChip('รอตรวจสอบ'),
          _filterChip('รับเรื่องแล้ว'),
          _filterChip('ปิดเหตุแล้ว'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = selectedFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TeacherPalette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? TeacherPalette.primary : TeacherPalette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : TeacherPalette.muted,
          ),
        ),
      ),
    );
  }
  Future<void> _quickAcknowledge(_EmergencyEvent evt) =>
      _performAction(evt);

  Future<void> _quickClose(_EmergencyEvent evt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันปิดเหตุการณ์'),
        content: const Text('คุณตรวจสอบและระงับเหตุเรียบร้อยแล้วใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('ปิดเหตุ')
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!mounted) return;
    await _performAction(evt, close: true);
  }

  Widget _buildEventListItem(_EmergencyEvent evt) {
    final isTerminal = evt.originalIncident?.status == 'resolved' ||
        evt.originalIncident?.status == 'cancelled' ||
        evt.originalIncident?.status == 'escalated' ||
        evt.status == 'ปิดเหตุแล้ว';

    return InkWell(
      onTap: () => _openDetail(evt),
      hoverColor: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: evt.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(evt.icon, size: 20, color: evt.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        evt.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: evt.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: evt.color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          evt.priority,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: evt.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: evt.status == 'ปิดเหตุแล้ว' ? TeacherPalette.green.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: evt.status == 'ปิดเหตุแล้ว' ? TeacherPalette.green.withValues(alpha: 0.3) : TeacherPalette.border),
                        ),
                        child: Text(
                          evt.status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: evt.status == 'ปิดเหตุแล้ว' ? TeacherPalette.green : TeacherPalette.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${evt.type} • ${evt.location} • รายงานโดย ${evt.reporter}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evt.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TeacherPalette.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evt.time,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.muted,
                    ),
                  ),
                  if (!isTerminal) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (evt.status == 'รอตรวจสอบ') ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _actions.isBusy ? null : () => _quickAcknowledge(evt),
                            icon: const Icon(Icons.check_rounded, size: 14),
                            label: const Text('รับเรื่อง', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            side: const BorderSide(color: Color(0xFF059669)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _actions.isBusy ? null : () => _quickClose(evt),
                          icon: const Icon(Icons.task_alt_rounded, size: 14),
                          label: const Text('ปิดเหตุ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: TeacherPalette.border),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// S4a: หน้ารายละเอียดเหตุ (ครู/Admin)
// ==========================================

class TeacherIncidentDetailPage extends StatefulWidget {
  const TeacherIncidentDetailPage({super.key, required this.incident});

  final TeacherIncidentReport incident;

  @override
  State<TeacherIncidentDetailPage> createState() =>
      _TeacherIncidentDetailPageState();
}

class _TeacherIncidentDetailPageState extends State<TeacherIncidentDetailPage> {
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _acknowledge() async {
    if (widget.incident.status != 'new') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('มีผู้รับเรื่องนี้แล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await IncidentService.acknowledgeIncidentReport(widget.incident.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รับเรื่องเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถรับเรื่องได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await IncidentService.addIncidentAction(widget.incident.id, text);
      _noteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกความคืบหน้าเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถบันทึกได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _escalate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.priority_high_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ยืนยันยกระดับเหตุ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text(
          'การยกระดับจะสร้างเหตุฉุกเฉินจริงในระบบ (เทียบเท่าปุ่มฉุกเฉินทางกายภาพ) '
          'และแจ้งเตือนวงกว้างขึ้นทันที ยืนยันหรือไม่?',
          style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: Size.zero,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยกระดับเหตุ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isSubmitting = true);
    try {
      await IncidentService.escalateIncidentReport(widget.incident.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกระดับเป็นเหตุฉุกเฉินเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถยกระดับได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _close() async {
    final noteCtrl = TextEditingController();
    var isRealIncident = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ยืนยันปิดเหตุ',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _closeChoiceTile(
                      label: 'เหตุจริง',
                      selected: isRealIncident,
                      color: const Color(0xFF059669),
                      onTap: () => setModalState(() => isRealIncident = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _closeChoiceTile(
                      label: 'แจ้งเท็จ/กดพลาด',
                      selected: !isRealIncident,
                      color: TeacherPalette.muted,
                      onTap: () => setModalState(() => isRealIncident = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'สรุปผล *',
                  hintText: 'บันทึกสรุปผลการดำเนินการ',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (noteCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('ปิดเหตุ'),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    setState(() => _isSubmitting = true);
    try {
      final resType = isRealIncident ? 'resolved' : 'cancelled';
      await IncidentService.closeIncidentReport(
        widget.incident.id,
        resolutionType: resType,
        resolutionNote: noteCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปิดเหตุเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถปิดเหตุได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _closeChoiceTile({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? color.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : TeacherPalette.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : TeacherPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final accent = _categoryColor(incident.category);
    final isNew = incident.status == 'new';
    final isTerminal =
        incident.status == 'resolved' ||
        incident.status == 'cancelled' ||
        incident.status == 'escalated';

    final roomLabel =
        incident.room != null && incident.room!.isNotEmpty
            ? ' — ห้อง ${incident.room}'
            : '';

    return TeacherMockPageShell(
      title: 'รายละเอียดการแจ้งเหตุ$roomLabel',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: TeacherPalette.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                incident.category == IncidentCategory.sos
                                    ? Icons.emergency_rounded
                                    : Icons.warning_amber_rounded,
                                color: accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              _categoryLabel(incident.category),
                                              style: TextStyle(
                                                color: accent,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            _buildSeverityBadge(incident.severity),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TeacherStatusChip(
                                        label: _statusLabel(incident.status),
                                        color: _statusColor(incident.status),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ห้อง ${incident.room ?? "ไม่ระบุ"} · แจ้งโดย ${incident.reporterName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: TeacherPalette.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'แจ้งเมื่อ ${_timeAgo(incident.createdAt)} (${_formatDateTime(incident.createdAt)})',
                                    style: const TextStyle(
                                      color: TeacherPalette.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (incident.reason != null &&
                                      incident.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFFCA5A5),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                size: 15,
                                                color: Color(0xFFDC2626),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'เหตุผล / สิ่งที่พบเห็น (แจ้งจากนักเรียน):',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF991B1B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            incident.reason!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: TeacherPalette.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_isSubmitting)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (!isTerminal && !_isSubmitting) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // แถวบน: รับเรื่อง (ถ้ายังใหม่) + ยกระดับเหตุ
                              Row(
                                children: [
                                  if (isNew) ...[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: _acknowledge,
                                        icon: const Icon(Icons.check_rounded, size: 18),
                                        label: const Text('รับเรื่อง'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFDC2626),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _escalate,
                                      icon: const Icon(Icons.priority_high_rounded, size: 18),
                                      label: const Text('ยกระดับเหตุ'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // แถวล่าง: ปิดเหตุ เต็มความกว้างเสมอ
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(color: Color(0xFF059669)),
                                ),
                                onPressed: _close,
                                icon: const Icon(Icons.task_alt_rounded, size: 18),
                                label: const Text('ปิดเหตุ (เสร็จสิ้น)'),
                              ),
                            ],
                          ),
                        ] else if (isTerminal) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    incident.status == 'escalated' 
                                      ? 'เหตุการณ์นี้ถูกยกระดับไปยังผู้บริหารแล้ว (สิ้นสุดหน้าที่ครู)'
                                      : 'เหตุการณ์นี้ถูกปิดหรือยกเลิกไปแล้ว',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!isTerminal && !_isSubmitting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'บันทึกการดำเนินการ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteCtrl,
                            decoration: InputDecoration(
                              hintText: 'พิมพ์ความคืบหน้า...',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TeacherPalette.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            minimumSize: Size.zero,
                          ),
                          onPressed: _saveNote,
                          child: const Text('บันทึก'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ==========================================
// S4b: ประวัติเหตุทั้งหมด
// ==========================================

