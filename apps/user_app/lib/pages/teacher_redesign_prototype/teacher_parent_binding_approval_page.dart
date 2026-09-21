// เชื่อมกับ ParentBindingService จริงแล้ว (2026-08-16) — เดิม mock ล้วน
//
// STK-1a: อนุมัติการผูกบัญชีผู้ปกครอง — Primary Actor คือครูประจำชั้น/
// School Admin/งานทะเบียน (ไม่ใช่ผู้ปกครอง) ต่อจาก STK-1 ที่ผู้ปกครองยื่นคำ
// ขอผูกบัญชีไว้ (ดู parent_redesign_prototype/parent_binding_page.dart)
//
// 2026-09-09: backend บังคับตามสเปกนี้จริงแล้ว — เดิม RPC เช็คแค่ว่าครูคนนั้น
// "สอนวิชาที่เด็กลงทะเบียน" ครูสอนวิชาใดก็ได้จึงอนุมัติได้ ตอนนี้ต้องเป็น
// ครูประจำชั้นของห้องเด็กคนนั้น (ห้องหนึ่งมีครูประจำชั้นได้หลายคน อนุมัติได้
// ทุกคน) ดู migration 20260909010000 + pgTAP 49
//
// backend จริงบังคับ CoI (ผลประโยชน์ทับซ้อน) ฝั่งเซิร์ฟเวอร์อยู่แล้ว —
// approve_parent_link จะ throw 'coi_self_approval_blocked' เองถ้าผู้อนุมัติ
// มีความเสี่ยง ไม่ต้องเดาด้วย client heuristic (ชื่อ-สกุลตรงกัน) แบบเดิม
// อีกต่อไป — จับ error นั้นแล้วเปิดไดอะล็อกส่งตรวจสอบซ้ำแทน
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSectionCard;

class TeacherParentBindingApprovalPage extends StatefulWidget {
  const TeacherParentBindingApprovalPage({
    super.key,
    this.listParentLinks,
    this.approveParentLink,
    this.rejectParentLink,
    this.requestParentLinkSecondReview,
  });

  /// Read/write seams threaded to the corresponding ParentBindingService
  /// static calls in production.
  final Future<List<ParentLink>> Function({String status, String? schoolId})?
  listParentLinks;
  final Future<void> Function(String parentLinkId)? approveParentLink;
  final Future<void> Function(String parentLinkId, {String? reason})?
  rejectParentLink;
  final Future<void> Function(String parentLinkId, {required String reason})?
  requestParentLinkSecondReview;

  @override
  State<TeacherParentBindingApprovalPage> createState() =>
      _TeacherParentBindingApprovalPageState();
}

class _TeacherParentBindingApprovalPageState
    extends State<TeacherParentBindingApprovalPage> {
  bool _loading = true;
  String? _loadError;
  List<ParentLink> _pending = [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final loadLinks =
          widget.listParentLinks ?? ParentBindingService.listParentLinks;
      final links = await loadLinks(status: 'pending');
      if (!mounted) return;
      setState(() {
        _pending = links;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดคำขอผูกบัญชีไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _approve(ParentLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการอนุมัติ', style: TextStyle(fontSize: 16)),
        content: Text(
          'ยืนยันว่า "${link.parentName}" เป็นผู้ปกครองจริงของ '
          '"${link.studentName}" และต้องการอนุมัติการผูกบัญชีนี้ใช่หรือไม่? '
          'หลังอนุมัติ ผู้ปกครองจะเห็นข้อมูลของนักเรียนคนนี้ได้ทันที',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
            ),
            child: const Text('ยืนยันอนุมัติ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy.add(link.id));
    try {
      final approve =
          widget.approveParentLink ?? ParentBindingService.approveParentLink;
      await approve(link.id);
      if (!mounted) return;
      _showSnack(
        'อนุมัติการผูกบัญชีของ ${link.parentName} แล้ว',
        const Color(0xFF10B981),
      );
      await _load();
    } catch (e) {
      if (e.toString().contains('coi_self_approval_blocked')) {
        if (mounted) setState(() => _busy.remove(link.id));
        await _promptEscalate(link);
        return;
      }
      if (!mounted) return;
      _showSnack('อนุมัติไม่สำเร็จ', TeacherPalette.red);
    } finally {
      if (mounted) setState(() => _busy.remove(link.id));
    }
  }

  // เซิร์ฟเวอร์บล็อกไว้แล้วว่าผู้อนุมัติมีความเสี่ยงผลประโยชน์ทับซ้อน (CoI) —
  // ทางเดียวที่ทำต่อได้คือส่งให้ตรวจสอบซ้ำโดยผู้อนุมัติคนอื่น (BR2)
  Future<void> _promptEscalate(ParentLink link) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'พบความเสี่ยงผลประโยชน์ทับซ้อน',
            style: TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ระบบตรวจพบว่าคุณอาจมีความเสี่ยงผลประโยชน์ทับซ้อนกับคำขอนี้ '
                'ไม่สามารถอนุมัติเองได้ — ต้องส่งให้ผู้อนุมัติคนอื่นตรวจสอบซ้ำ',
                style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'ระบุเหตุผล เช่น เป็นผู้ปกครองของนักเรียนคนนี้เอง...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: reasonCtrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
              ),
              child: const Text('ส่งตรวจสอบซ้ำ'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final requestSecondReview =
          widget.requestParentLinkSecondReview ??
          ParentBindingService.requestParentLinkSecondReview;
      await requestSecondReview(link.id, reason: reasonCtrl.text.trim());
      if (!mounted) return;
      _showSnack(
        'ส่งคำขอของ ${link.parentName} ให้ตรวจสอบซ้ำแล้ว',
        const Color(0xFFD97706),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showSnack('ส่งตรวจสอบซ้ำไม่สำเร็จ', TeacherPalette.red);
    }
  }

  Future<void> _reject(ParentLink link) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('ปฏิเสธคำขอ', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ระบุเหตุผลที่ปฏิเสธ (จำเป็น) เพื่อแจ้งให้ผู้ปกครองติดต่อโรงเรียน',
                style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: 'เช่น ข้อมูลไม่ตรงกับทะเบียนนักเรียน...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: reasonCtrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: TeacherPalette.red,
              ),
              child: const Text('ปฏิเสธคำขอ'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy.add(link.id));
    try {
      final reject =
          widget.rejectParentLink ?? ParentBindingService.rejectParentLink;
      await reject(link.id, reason: reasonCtrl.text.trim());
      if (!mounted) return;
      _showSnack('ปฏิเสธคำขอของ ${link.parentName} แล้ว', TeacherPalette.red);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showSnack('ปฏิเสธคำขอไม่สำเร็จ', TeacherPalette.red);
    } finally {
      if (mounted) setState(() => _busy.remove(link.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'อนุมัติผูกบัญชีผู้ปกครอง',
      onRefresh: _load,
      activeMenuLabel: 'อนุมัติผูกบัญชี',
      builder: (context, isDesktop) {
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          );
        }
        if (_loadError != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadError!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('ลองใหม่')),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'STK-1a: ก่อนอนุมัติ ผู้ปกครองยังเห็นข้อมูลบุตรไม่ได้เลย — '
                'ถ้าผู้อนุมัติมีผลประโยชน์ทับซ้อน (เป็นผู้ปกครองของเด็กคนนั้นเอง) '
                'ระบบจะบล็อกอัตโนมัติและต้องส่งให้ตรวจสอบซ้ำ',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TeacherSectionCard(
              title: 'คำขอรออนุมัติ (${_pending.length} รายการ)',
              icon: Icons.family_restroom_rounded,
              child: _pending.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        // ตั้งแต่ migration 20260909010000 ครูเห็น/อนุมัติได้
                        // เฉพาะนักเรียนในห้องที่ตัวเองเป็นครูประจำชั้น ครูที่
                        // เคยเห็นคำขอทั้งโรงเรียนจะเห็นว่างเปล่าโดยไม่รู้ว่า
                        // ทำไม จึงต้องบอกขอบเขตไว้ตรงนี้
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ไม่มีคำขอรออนุมัติแล้ว',
                              style: TextStyle(
                                color: TeacherPalette.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'หน้านี้แสดงเฉพาะคำขอของนักเรียนในห้องที่คุณเป็น'
                              'ครูประจำชั้น — คำขอของห้องอื่นให้ฝ่ายทะเบียนหรือ'
                              'ผู้ดูแลโรงเรียนเป็นผู้อนุมัติ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: TeacherPalette.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _pending.length; i++) ...[
                          if (i != 0) const Divider(height: 24),
                          _RequestRow(
                            link: _pending[i],
                            isBusy: _busy.contains(_pending[i].id),
                            onApprove: () => _approve(_pending[i]),
                            onReject: () => _reject(_pending[i]),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.link,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final ParentLink link;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEF9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: TeacherPalette.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.parentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  Text(
                    link.parentEmail,
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ขอผูกกับ ${link.studentName} (${link.relationship})',
                    style: const TextStyle(
                      color: TeacherPalette.softText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ยื่นคำขอเมื่อ ${link.requestedAt.toLocal()}',
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.red,
                  side: const BorderSide(color: TeacherPalette.red),
                ),
                child: const Text('ปฏิเสธ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: isBusy ? null : onApprove,
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('อนุมัติ'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
