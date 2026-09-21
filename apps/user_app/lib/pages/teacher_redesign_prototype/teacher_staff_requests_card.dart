import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;

/// A teacher's own requests (ขอเข้าพบ ผอ. / ขอไปราชการ) with a form to file
/// a new one and a cancel for the ones still pending.
///
/// Until 2026-09-17 `create_staff_request` had no caller anywhere in the app:
/// executives had a review queue (MeetingRequestsDialog) that could only
/// ever be empty. DECISIONS D: two-tier approval, head of ฝ่าย → ผอ.
class TeacherStaffRequestsCard extends StatefulWidget {
  const TeacherStaffRequestsCard({super.key, this.service});

  /// Injectable for tests; production builds the real service.
  final StaffRequestService? service;

  @override
  State<TeacherStaffRequestsCard> createState() =>
      _TeacherStaffRequestsCardState();
}

class _TeacherStaffRequestsCardState extends State<TeacherStaffRequestsCard> {
  late final StaffRequestService _service =
      widget.service ?? StaffRequestService();

  List<StaffRequest> _requests = const [];
  bool _loading = true;
  bool _failed = false;
  final Set<String> _cancelling = <String>{};

  static const _typeLabels = {
    'meet_request': 'ขอเข้าพบผู้อำนวยการ',
    'meeting_request': 'ขอเข้าพบผู้อำนวยการ',
    'official_duty': 'ขอไปราชการ',
  };
  static const _statusLabels = {
    'pending_head': 'รอหัวหน้าฝ่าย',
    'pending_executive': 'รอผู้อำนวยการ',
    'approved': 'อนุมัติแล้ว',
    'rejected': 'ไม่อนุมัติ',
    'cancelled': 'ยกเลิกแล้ว',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final rows = await _service.list();
      if (!mounted) return;
      setState(() {
        _requests = rows;
        _loading = false;
      });
    } catch (e) {
      debugPrint('TeacherStaffRequestsCard load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  static DateTime? _parseDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(t);
    if (m == null) return null;
    return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year + 543}';

  Future<void> _openCreate() async {
    final subjectCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    var type = 'meet_request';
    var submitting = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            final subject = subjectCtrl.text.trim();
            final start = _parseDate(startCtrl.text);
            final end = _parseDate(endCtrl.text);
            if (subject.isEmpty) {
              setSheet(() => error = 'กรอกเรื่องที่ขอ');
              return;
            }
            if (start == null) {
              setSheet(
                () => error = 'กรอกวันที่เป็น ปี-เดือน-วัน เช่น 2026-09-20',
              );
              return;
            }
            if (end != null && end.isBefore(start)) {
              setSheet(() => error = 'วันสิ้นสุดต้องไม่ก่อนวันเริ่ม');
              return;
            }
            setSheet(() {
              submitting = true;
              error = null;
            });
            try {
              final created = await _service.create(
                type: type,
                subject: subject,
                startDate: start,
                endDate: end,
                location: locationCtrl.text,
                detail: detailCtrl.text,
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (!mounted) return;
              await _load();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ยื่นคำขอแล้ว — สถานะ: ${_statusLabels[created.status] ?? created.status}',
                  ),
                ),
              );
            } catch (e) {
              debugPrint('TeacherStaffRequestsCard create failed: $e');
              if (!sheetContext.mounted) return;
              final raw = e.toString();
              setSheet(() {
                submitting = false;
                error = raw.contains('invalid_date_range')
                    ? 'วันสิ้นสุดต้องไม่ก่อนวันเริ่ม'
                    : raw.contains('too_long')
                    ? 'ช่วงวันยาวเกินที่ระบบรับ'
                    : 'ยื่นคำขอไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
              });
            }
          }

          return _OwnControllers(
            controllers: [
              subjectCtrl,
              startCtrl,
              endCtrl,
              locationCtrl,
              detailCtrl,
            ],
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ยื่นคำขอ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'ประเภทคำขอ',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'meet_request',
                            child: Text('ขอเข้าพบผู้อำนวยการ'),
                          ),
                          DropdownMenuItem(
                            value: 'official_duty',
                            child: Text('ขอไปราชการ'),
                          ),
                        ],
                        onChanged: (v) => setSheet(() => type = v ?? type),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subjectCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'เรื่อง'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: startCtrl,
                        decoration: InputDecoration(
                          labelText: type == 'official_duty'
                              ? 'วันเริ่ม (ปี-เดือน-วัน)'
                              : 'วันที่ขอเข้าพบ (ปี-เดือน-วัน)',
                        ),
                      ),
                      if (type == 'official_duty') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: endCtrl,
                          decoration: const InputDecoration(
                            labelText: 'วันสิ้นสุด (ถ้าวันเดียวเว้นว่าง)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: locationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'สถานที่',
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: detailCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'รายละเอียด (ถ้ามี)',
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: const Text('ยกเลิก'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: submitting ? null : submit,
                            child: Text(submitting ? 'กำลังส่ง…' : 'ยื่นคำขอ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancel(StaffRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยกเลิกคำขอ'),
        content: Text('ถอนคำขอ "${r.subject}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ไม่'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ยกเลิกคำขอ'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancelling.add(r.id));
    try {
      await _service.cancel(r.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยกเลิกคำขอแล้ว (ยืนยันกับระบบเรียบร้อย)'),
        ),
      );
    } catch (e) {
      debugPrint('TeacherStaffRequestsCard cancel failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยกเลิกไม่สำเร็จ คำขอยังอยู่ในคิว')),
      );
    } finally {
      if (mounted) setState(() => _cancelling.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_failed) {
      body = Row(
        children: [
          const Expanded(
            child: Text(
              'โหลดคำขอของคุณไม่สำเร็จ',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('ลองใหม่')),
        ],
      );
    } else if (_requests.isEmpty) {
      body = const Text(
        'ยังไม่มีคำขอ',
        style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
      );
    } else {
      body = Column(
        children: [
          for (final r in _requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_typeLabels[r.type] ?? r.type} · ${r.subject}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TeacherPalette.ink,
                          ),
                        ),
                        Text(
                          '${_fmt(r.date)} · ${_statusLabels[r.status] ?? r.status}'
                          '${r.execNote != null && r.execNote!.isNotEmpty ? ' · ${r.execNote}' : ''}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: TeacherPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (r.status == 'pending_head' ||
                      r.status == 'pending_executive')
                    TextButton(
                      onPressed: _cancelling.contains(r.id)
                          ? null
                          : () => _cancel(r),
                      child: const Text('ยกเลิก'),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'คำขอของฉัน (ขอเข้าพบ / ไปราชการ)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('ยื่นคำขอ'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            body,
          ],
        ),
      ),
    );
  }
}

/// Disposes sheet controllers with the sheet's own element (not right after
/// showModalBottomSheet returns, which tears them down mid-animation).
class _OwnControllers extends StatefulWidget {
  const _OwnControllers({required this.controllers, required this.child});
  final List<TextEditingController> controllers;
  final Widget child;
  @override
  State<_OwnControllers> createState() => _OwnControllersState();
}

class _OwnControllersState extends State<_OwnControllers> {
  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
