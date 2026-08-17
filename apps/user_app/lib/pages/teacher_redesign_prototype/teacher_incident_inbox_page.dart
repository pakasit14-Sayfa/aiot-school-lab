import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

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

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  return '${diff.inDays} วันที่แล้ว';
}

// ==========================================
// S4: หน้ารับแจ้งเหตุ (Inbox) — เชื่อมต่อ Backend จริง
// ==========================================

class TeacherIncidentInboxPage extends StatefulWidget {
  const TeacherIncidentInboxPage({super.key});

  @override
  State<TeacherIncidentInboxPage> createState() =>
      _TeacherIncidentInboxPageState();
}

class _TeacherIncidentInboxPageState extends State<TeacherIncidentInboxPage> {
  int _tabIndex = 0;
  bool _isLoading = true;
  String? _error;
  List<TeacherIncidentReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await IncidentService.listTeacherIncidentReports();
      if (mounted) {
        setState(() {
          _reports = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<TeacherIncidentReport> get _newReports =>
      _reports.where((i) => i.status == 'new').toList()..sort(_urgencySort);

  List<TeacherIncidentReport> get _inProgress =>
      _reports
          .where((i) => i.status == 'acknowledged' || i.status == 'in_progress')
          .toList()
        ..sort(_urgencySort);

  List<TeacherIncidentReport> get _closed => _reports
      .where(
        (i) =>
            i.status == 'resolved' ||
            i.status == 'cancelled' ||
            i.status == 'escalated',
      )
      .toList();

  int _urgencySort(TeacherIncidentReport a, TeacherIncidentReport b) {
    if (a.category != b.category) {
      return a.category == IncidentCategory.sos ? -1 : 1;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  Future<void> _openDetail(TeacherIncidentReport incident) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherIncidentDetailPage(incident: incident),
      ),
    );
    if (mounted) _fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_newReports, _inProgress, _closed];
    final items = _tabIndex < tabs.length
        ? tabs[_tabIndex]
        : <TeacherIncidentReport>[];

    return TeacherMockPageShell(
      title: 'รับแจ้งเหตุฉุกเฉิน',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'รีเฟรช',
          onPressed: _fetchReports,
        ),
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
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: Color(0xFF15803D),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ระบบเชื่อมต่อแจ้งเหตุจริงเรียบร้อยแล้ว — แสดงเฉพาะเหตุในวิชา/ห้องที่ครูสอนตามสิทธิ์ RLS',
                      style: TextStyle(
                        color: Color(0xFF15803D),
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดข้อมูล: $_error',
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              )
            else if (items.isEmpty)
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

  final TeacherIncidentReport incident;
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
                        incident.category == IncidentCategory.sos
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
                            'ห้อง ${incident.room ?? "ไม่ระบุ"} · แจ้งโดย ${incident.reporterName}',
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

    return TeacherMockPageShell(
      title: 'เหตุ ${incident.id}',
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
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _categoryLabel(incident.category),
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
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
                                    'แจ้งเมื่อ ${_timeAgo(incident.createdAt)} (${incident.createdAt.toLocal().toString().substring(0, 16)})',
                                    style: const TextStyle(
                                      color: TeacherPalette.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (isNew)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _acknowledge,
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('รับเรื่อง'),
                                ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _escalate,
                                icon: const Icon(
                                  Icons.priority_high_rounded,
                                  size: 18,
                                ),
                                label: const Text('ยกระดับเป็นเหตุฉุกเฉิน'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                ),
                                onPressed: _close,
                                icon: const Icon(
                                  Icons.task_alt_rounded,
                                  size: 18,
                                ),
                                label: const Text('ปิดเหตุ'),
                              ),
                            ],
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
  bool _isLoading = true;
  List<TeacherIncidentReport> _reports = [];

  static const _statusOptions = [
    'ทั้งหมด',
    'รอตรวจสอบ',
    'กำลังดำเนินการ',
    'ปิดแล้ว',
  ];
  static const _categoryOptions = ['ทั้งหมด', 'SOS', 'ผิดปกติ'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await IncidentService.listTeacherIncidentReports();
      if (mounted) setState(() => _reports = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  bool _matchesStatus(TeacherIncidentReport i) {
    switch (_statusFilter) {
      case 'รอตรวจสอบ':
        return i.status == 'new';
      case 'กำลังดำเนินการ':
        return i.status == 'acknowledged' || i.status == 'in_progress';
      case 'ปิดแล้ว':
        return i.status == 'resolved' ||
            i.status == 'cancelled' ||
            i.status == 'escalated';
      default:
        return true;
    }
  }

  bool _matchesCategory(TeacherIncidentReport i) {
    if (_categoryFilter == 'ทั้งหมด') return true;
    final wantSos = _categoryFilter == 'SOS';
    return (i.category == IncidentCategory.sos) == wantSos;
  }

  @override
  Widget build(BuildContext context) {
    final items =
        _reports.where((i) => _matchesStatus(i) && _matchesCategory(i)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return TeacherMockPageShell(
      title: 'ประวัติเหตุทั้งหมด',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetch),
      ],
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'สถานะ',
              style: TextStyle(
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
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
                      if (mounted) _fetch();
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
