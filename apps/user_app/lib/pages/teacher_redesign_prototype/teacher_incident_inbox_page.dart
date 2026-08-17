// PROTOTYPE ONLY: "รับแจ้งเหตุฉุกเฉิน" — ฝั่งครู/Admin ตาม
// emergency-alert-app-proposal-v1 (S4/S4a/S4b/S4c) UI/UX mock เท่านั้น
// ยังไม่เชื่อม backend จริง — ไม่แตะ emergency_events ของเดิม

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

enum MockIncidentCategory { sos, anomaly }

enum IncidentStatus {
  newReport,
  acknowledged,
  inProgress,
  escalated,
  resolved,
  cancelled,
}

class IncidentActionLog {
  IncidentActionLog({
    required this.actor,
    required this.note,
    required this.time,
  });
  final String actor;
  final String note;
  final DateTime time;
}

class IncidentReportMock {
  IncidentReportMock({
    required this.id,
    required this.category,
    required this.room,
    required this.reporterName,
    required this.createdAt,
    this.status = IncidentStatus.newReport,
    this.acknowledgedBy,
    this.assignedTo,
    List<IncidentActionLog>? timeline,
  }) : timeline = timeline ?? [];

  final String id;
  final MockIncidentCategory category;
  final String room;
  final String reporterName;
  final DateTime createdAt;
  IncidentStatus status;
  String? acknowledgedBy;
  String? assignedTo;
  final List<IncidentActionLog> timeline;
}

final List<IncidentReportMock> mockIncidentReports = [
  IncidentReportMock(
    id: 'INC-2026-00214',
    category: MockIncidentCategory.sos,
    room: 'ม.5/2',
    reporterName: 'ณัฐวุฒิ ใจดี',
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
  IncidentReportMock(
    id: 'INC-2026-00213',
    category: MockIncidentCategory.anomaly,
    room: 'ม.4/1',
    reporterName: 'ปวีณา สายทอง',
    createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  IncidentReportMock(
    id: 'INC-2026-00212',
    category: MockIncidentCategory.anomaly,
    room: 'ม.6/2',
    reporterName: 'ธนกร วิจิตร',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  IncidentReportMock(
    id: 'INC-2026-00201',
    category: MockIncidentCategory.anomaly,
    room: 'ม.5/1',
    reporterName: 'กิตติศักดิ์ มั่นคง',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    status: IncidentStatus.resolved,
    acknowledgedBy: 'ครูสมชาย',
    timeline: [
      IncidentActionLog(
        actor: 'ครูสมชาย',
        note: 'รับเรื่องแล้ว กำลังตรวจสอบ',
        time: DateTime.now().subtract(const Duration(hours: 3, minutes: -2)),
      ),
      IncidentActionLog(
        actor: 'ครูสมชาย',
        note: 'ตรวจสอบแล้วเป็นการแจ้งเตือนที่เข้าใจผิด ไม่มีเหตุจริง',
        time: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      ),
    ],
  ),
];

Color _categoryColor(MockIncidentCategory c) => c == MockIncidentCategory.sos
    ? const Color(0xFFDC2626)
    : const Color(0xFFD97706);

String _categoryLabel(MockIncidentCategory c) =>
    c == MockIncidentCategory.sos ? 'SOS ฉุกเฉิน' : 'แจ้งเหตุผิดปกติ';

String _statusLabel(IncidentStatus s) => switch (s) {
  IncidentStatus.newReport => 'รอตรวจสอบ',
  IncidentStatus.acknowledged => 'รับเรื่องแล้ว',
  IncidentStatus.inProgress => 'กำลังดำเนินการ',
  IncidentStatus.escalated => 'ยกระดับแล้ว',
  IncidentStatus.resolved => 'ปิดเหตุแล้ว (เหตุจริง)',
  IncidentStatus.cancelled => 'ปิดเหตุแล้ว (แจ้งเท็จ)',
};

Color _statusColor(IncidentStatus s) => switch (s) {
  IncidentStatus.newReport => TeacherPalette.muted,
  IncidentStatus.acknowledged => const Color(0xFF2563EB),
  IncidentStatus.inProgress => const Color(0xFFD97706),
  IncidentStatus.escalated => const Color(0xFFDC2626),
  IncidentStatus.resolved => const Color(0xFF059669),
  IncidentStatus.cancelled => TeacherPalette.muted,
};

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  return '${diff.inDays} วันที่แล้ว';
}

// ==========================================
// S4: หน้ารับแจ้งเหตุ (Inbox)
// ==========================================

class TeacherIncidentInboxPage extends StatefulWidget {
  const TeacherIncidentInboxPage({super.key});

  @override
  State<TeacherIncidentInboxPage> createState() =>
      _TeacherIncidentInboxPageState();
}

class _TeacherIncidentInboxPageState extends State<TeacherIncidentInboxPage> {
  int _tabIndex = 0;

  List<IncidentReportMock> get _newReports =>
      mockIncidentReports
          .where((i) => i.status == IncidentStatus.newReport)
          .toList()
        ..sort(_urgencySort);

  List<IncidentReportMock> get _inProgress =>
      mockIncidentReports
          .where(
            (i) =>
                i.status == IncidentStatus.acknowledged ||
                i.status == IncidentStatus.inProgress,
          )
          .toList()
        ..sort(_urgencySort);

  List<IncidentReportMock> get _closed => mockIncidentReports
      .where(
        (i) =>
            i.status == IncidentStatus.resolved ||
            i.status == IncidentStatus.cancelled ||
            i.status == IncidentStatus.escalated,
      )
      .toList();

  // กติกาจัดลำดับ (proposal ข้อ 4.3): SOS มาก่อนเหตุผิดปกติเสมอ
  // ภายในกลุ่มเดียวกันเรียงเก่าสุดก่อน (FIFO) กันเหตุตกหล่น
  int _urgencySort(IncidentReportMock a, IncidentReportMock b) {
    if (a.category != b.category) {
      return a.category == MockIncidentCategory.sos ? -1 : 1;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  Future<void> _openDetail(IncidentReportMock incident) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherIncidentDetailPage(incident: incident),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_newReports, _inProgress, _closed];
    final items = tabs[_tabIndex];

    return TeacherMockPageShell(
      title: 'รับแจ้งเหตุฉุกเฉิน',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: 'ประวัติเหตุทั้งหมด',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherIncidentHistoryPage(),
              ),
            );
          },
        ),
      ],
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFB91C1C),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'โหมดทดลอง UI — ยังไม่เชื่อมระบบแจ้งเหตุจริง เหตุที่แจ้งจากแอปนี้แยกจากปุ่มฉุกเฉินทางกายภาพเสมอ',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _tabChip('ใหม่ (${_newReports.length})', 0),
                const SizedBox(width: 8),
                _tabChip('กำลังดำเนินการ (${_inProgress.length})', 1),
                const SizedBox(width: 8),
                _tabChip('ปิดแล้ว (${_closed.length})', 2),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 44,
                      color: TeacherPalette.muted.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ไม่มีเหตุในหมวดนี้',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, cons) {
                  final columns = cons.maxWidth >= 1180
                      ? 3
                      : (cons.maxWidth >= 620 ? 2 : 1);
                  final cardWidth = columns == 1
                      ? cons.maxWidth
                      : (cons.maxWidth - 14 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final incident in items)
                        SizedBox(
                          width: cardWidth,
                          child: _IncidentCard(
                            incident: incident,
                            onTap: () => _openDetail(incident),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _tabChip(String label, int index) {
    final isActive = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? TeacherPalette.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? TeacherPalette.primary : TeacherPalette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : TeacherPalette.ink,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final IncidentReportMock incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryColor(incident.category);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TeacherPalette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        incident.category == MockIncidentCategory.sos
                            ? Icons.emergency_rounded
                            : Icons.warning_amber_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _categoryLabel(incident.category),
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                _timeAgo(incident.createdAt),
                                style: const TextStyle(
                                  color: TeacherPalette.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ห้อง ${incident.room} · แจ้งโดย ${incident.reporterName}',
                            style: const TextStyle(
                              color: TeacherPalette.ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TeacherStatusChip(
                            label: _statusLabel(incident.status),
                            color: _statusColor(incident.status),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: TeacherPalette.muted,
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
}

// ==========================================
// S4a: หน้ารายละเอียดเหตุ (ครู/Admin)
// ==========================================

class TeacherIncidentDetailPage extends StatefulWidget {
  const TeacherIncidentDetailPage({super.key, required this.incident});

  final IncidentReportMock incident;

  @override
  State<TeacherIncidentDetailPage> createState() =>
      _TeacherIncidentDetailPageState();
}

class _TeacherIncidentDetailPageState extends State<TeacherIncidentDetailPage> {
  final _noteCtrl = TextEditingController();
  static const _currentTeacherName = 'ครูวิจิตร (คุณ)';

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _log(String note) {
    setState(() {
      widget.incident.timeline.add(
        IncidentActionLog(
          actor: _currentTeacherName,
          note: note,
          time: DateTime.now(),
        ),
      );
    });
  }

  void _acknowledge() {
    if (widget.incident.status != IncidentStatus.newReport) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('มีผู้รับเรื่องนี้แล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      widget.incident.status = IncidentStatus.acknowledged;
      widget.incident.acknowledgedBy = _currentTeacherName;
    });
    _log('รับเรื่องแล้ว');
  }

  Future<void> _assign() async {
    final controller = TextEditingController(
      text: widget.incident.assignedTo ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'มอบหมายงาน',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'ครู/เวรที่รับผิดชอบต่อ',
            hintText: 'เช่น ครูเวร อาคาร 3',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('มอบหมาย'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    setState(() => widget.incident.assignedTo = result);
    _log('มอบหมายงานให้ $result');
  }

  void _saveNote() {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (widget.incident.status == IncidentStatus.acknowledged) {
        widget.incident.status = IncidentStatus.inProgress;
      }
    });
    _log(text);
    _noteCtrl.clear();
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
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยกระดับเหตุ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => widget.incident.status = IncidentStatus.escalated);
    _log('ยกระดับเป็นเหตุฉุกเฉินจริง — สร้าง Emergency Event แล้ว (mock)');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ยกระดับเหตุแล้ว (mock) — เชื่อม Emergency Event เมื่อพัฒนาจริง',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    setState(() {
      widget.incident.status = isRealIncident
          ? IncidentStatus.resolved
          : IncidentStatus.cancelled;
    });
    _log(
      'ปิดเหตุ — ${isRealIncident ? 'เหตุจริง' : 'แจ้งเท็จ/กดพลาด'}: ${noteCtrl.text.trim()}',
    );
    if (mounted) Navigator.pop(context);
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
    final isNew = incident.status == IncidentStatus.newReport;
    final isTerminal =
        incident.status == IncidentStatus.resolved ||
        incident.status == IncidentStatus.cancelled ||
        incident.status == IncidentStatus.escalated;

    return TeacherMockPageShell(
      title: 'เหตุ ${incident.id}',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero: แถบสีบนสุด + ไอคอนวงกลม ให้เข้าชุดกับการ์ดใบงาน/
            // บทเรียนที่เหลือของแอปฝั่งครู
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
                                color: accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                incident.category == MockIncidentCategory.sos
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
                                  Text(
                                    _categoryLabel(incident.category),
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    incident.id,
                                    style: const TextStyle(
                                      color: TeacherPalette.muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TeacherStatusChip(
                              label: _statusLabel(incident.status),
                              color: _statusColor(incident.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _IncidentMetaTag(
                              icon: Icons.room_outlined,
                              label: 'ห้อง ${incident.room}',
                              color: accent,
                            ),
                            _IncidentMetaTag(
                              icon: Icons.person_outline_rounded,
                              label: incident.reporterName,
                              color: accent,
                            ),
                            _IncidentMetaTag(
                              icon: Icons.schedule_rounded,
                              label: _timeAgo(incident.createdAt),
                              color: accent,
                            ),
                            if (incident.assignedTo != null)
                              _IncidentMetaTag(
                                icon: Icons.assignment_ind_outlined,
                                label: 'มอบหมาย: ${incident.assignedTo}',
                                color: accent,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Timeline',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: TeacherPalette.ink,
              ),
            ),
            const SizedBox(height: 12),
            if (incident.timeline.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: const Center(
                  child: Text(
                    'ยังไม่มีการบันทึกการดำเนินการ',
                    style: TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(incident.timeline.length, (i) {
                    final log = incident.timeline[i];
                    final isLast = i == incident.timeline.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: isLast
                                      ? TeacherPalette.primary
                                      : TeacherPalette.border,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 34,
                                  color: const Color(0xFFE2E8F0),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.note,
                                  style: TextStyle(
                                    fontWeight: isLast
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 13,
                                    color: isLast
                                        ? TeacherPalette.ink
                                        : TeacherPalette.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${log.actor} · ${_timeAgo(log.time)}',
                                  style: const TextStyle(
                                    color: TeacherPalette.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            if (!isTerminal) ...[
              const SizedBox(height: 22),
              // ปุ่มหลัก "รับเรื่อง" เด่นสุดตอนยังเป็นเหตุใหม่ — เข้าชุดกับ
              // แพทเทิร์นปุ่มหลัก+ปุ่มรองที่ใช้ในการ์ดบทเรียน/ใบงาน
              if (isNew)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _acknowledge,
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                    ),
                    label: const Text('รับเรื่องนี้'),
                    style: FilledButton.styleFrom(
                      // อำพัน/ส้ม สื่อ "ต้องลงมือทำตอนนี้" — แยกจากแดง
                      // (SOS/ยกระดับ) และเขียว (ปิดเหตุ) ที่ใช้อยู่แล้ว
                      backgroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _IncidentToolButton(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'มอบหมาย',
                        color: const Color(0xFF2563EB),
                        onTap: _assign,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _IncidentToolButton(
                        icon: Icons.priority_high_rounded,
                        label: 'ยกระดับเหตุ',
                        color: const Color(0xFFDC2626),
                        onTap: _escalate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _IncidentToolButton(
                        icon: Icons.task_alt_rounded,
                        label: 'ปิดเหตุ',
                        color: const Color(0xFF059669),
                        onTap: _close,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TeacherPalette.border),
                  ),
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      hintText: 'บันทึกการดำเนินการ...',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Material(
                          color: TeacherPalette.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _saveNote,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _IncidentMetaTag extends StatelessWidget {
  const _IncidentMetaTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: TeacherPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ปุ่มเครื่องมือทรงกลม+label ใต้ไอคอน ใช้แถวเดียวกัน 3 ปุ่ม (มอบหมาย/
// ยกระดับ/ปิดเหตุ) แทนปุ่มยาวเต็มแถวแบบเดิม ให้กดพลาดยากขึ้นและดูเป็น
// ชุดเครื่องมือมากกว่าปุ่มฟอร์ม
class _IncidentToolButton extends StatelessWidget {
  const _IncidentToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// S6: หน้าประวัติเหตุ (ครู/Admin) — กรองตามสถานะ/ประเภท
// ในของจริงต้องกรองตามขอบเขตพื้นที่/เวรผ่าน RLS ด้วย (proposal ข้อ 6)
// ==========================================

class TeacherIncidentHistoryPage extends StatefulWidget {
  const TeacherIncidentHistoryPage({super.key});

  @override
  State<TeacherIncidentHistoryPage> createState() =>
      _TeacherIncidentHistoryPageState();
}

class _TeacherIncidentHistoryPageState
    extends State<TeacherIncidentHistoryPage> {
  String _statusFilter = 'ทั้งหมด';
  String _categoryFilter = 'ทั้งหมด';

  static const _statusOptions = [
    'ทั้งหมด',
    'รอตรวจสอบ',
    'กำลังดำเนินการ',
    'ปิดแล้ว',
  ];
  static const _categoryOptions = ['ทั้งหมด', 'SOS', 'ผิดปกติ'];

  bool _matchesStatus(IncidentReportMock i) {
    switch (_statusFilter) {
      case 'รอตรวจสอบ':
        return i.status == IncidentStatus.newReport;
      case 'กำลังดำเนินการ':
        return i.status == IncidentStatus.acknowledged ||
            i.status == IncidentStatus.inProgress;
      case 'ปิดแล้ว':
        return i.status == IncidentStatus.resolved ||
            i.status == IncidentStatus.cancelled ||
            i.status == IncidentStatus.escalated;
      default:
        return true;
    }
  }

  bool _matchesCategory(IncidentReportMock i) {
    if (_categoryFilter == 'ทั้งหมด') return true;
    final wantSos = _categoryFilter == 'SOS';
    return (i.category == MockIncidentCategory.sos) == wantSos;
  }

  @override
  Widget build(BuildContext context) {
    final items =
        mockIncidentReports
            .where((i) => _matchesStatus(i) && _matchesCategory(i))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return TeacherMockPageShell(
      title: 'ประวัติเหตุทั้งหมด',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'สถานะ',
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in _statusOptions) ...[
                    _filterChip(
                      s,
                      _statusFilter == s,
                      () => setState(() => _statusFilter = s),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ประเภทเหตุ',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final c in _categoryOptions) ...[
                  _filterChip(
                    c,
                    _categoryFilter == c,
                    () => setState(() => _categoryFilter = c),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'พบ ${items.length} รายการ',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: TeacherPalette.ink,
              ),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: const Center(
                  child: Text(
                    'ไม่พบเหตุตามเงื่อนไขที่กรอง',
                    style: TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              ...items.map(
                (incident) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IncidentCard(
                    incident: incident,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherIncidentDetailPage(incident: incident),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? TeacherPalette.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? TeacherPalette.primary : TeacherPalette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : TeacherPalette.ink,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
