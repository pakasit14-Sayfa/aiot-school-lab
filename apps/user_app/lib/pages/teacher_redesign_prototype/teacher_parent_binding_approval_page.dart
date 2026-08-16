// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// STK-1a: อนุมัติการผูกบัญชีผู้ปกครอง — Primary Actor คือครูประจำชั้น/
// School Admin/งานทะเบียน (ไม่ใช่ผู้ปกครอง) ต่อจาก STK-1 ที่ผู้ปกครองยื่นคำ
// ขอผูกบัญชีไว้ (ดู parent_redesign_prototype/parent_binding_page.dart)
// เพิ่มเมื่อ 2026-08-16 หลังผู้ใช้ถามว่าใครเป็นคนอนุมัติคำขอผูกบัญชี

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSectionCard;

class _BindingRequestMock {
  _BindingRequestMock({
    required this.parentName,
    required this.parentEmail,
    required this.studentName,
    required this.studentRoom,
    required this.requestedAt,
    this.coiFlag = false,
  });

  final String parentName;
  final String parentEmail;
  final String studentName;
  final String studentRoom;
  final String requestedAt;
  final bool coiFlag;
  _RequestStatus status = _RequestStatus.pending;
  String? rejectReason;
}

enum _RequestStatus { pending, approved, rejected, escalated }

List<_BindingRequestMock> _mockRequests() => [
  _BindingRequestMock(
    parentName: 'นายสมพงษ์ ใจดี',
    parentEmail: 'sompong.j@example.com',
    studentName: 'ด.ช. ปุณณ์ ใจดี',
    studentRoom: 'ม.5/2',
    requestedAt: 'วันนี้ 09:14 น.',
  ),
  _BindingRequestMock(
    parentName: 'นางสาววิภาวรรณ สายวิทย์',
    parentEmail: 'wipawan.s@example.com',
    studentName: 'ด.ญ. เพลงพิณ สายวิทย์',
    studentRoom: 'ม.5/2',
    requestedAt: 'วันนี้ 08:02 น.',
    // ผู้อนุมัติ (ครูสมชาย สายวิทย์) เป็นนามสกุลเดียวกับคำขอนี้ — จำลอง
    // กรณี CoI ที่ผู้อนุมัติอาจเป็นผู้ปกครองของเด็กคนนี้เอง (Exception 1)
    coiFlag: true,
  ),
  _BindingRequestMock(
    parentName: 'นายอนุชา รุ่งเรือง',
    parentEmail: 'anucha.r@example.com',
    studentName: 'ด.ช. กิตติศักดิ์ ขยันยิ่ง',
    studentRoom: 'ม.4/1',
    requestedAt: 'เมื่อวาน 16:40 น.',
  ),
];

class TeacherParentBindingApprovalPage extends StatefulWidget {
  const TeacherParentBindingApprovalPage({super.key});

  @override
  State<TeacherParentBindingApprovalPage> createState() =>
      _TeacherParentBindingApprovalPageState();
}

class _TeacherParentBindingApprovalPageState
    extends State<TeacherParentBindingApprovalPage> {
  late final List<_BindingRequestMock> _requests = _mockRequests();

  List<_BindingRequestMock> get _pending =>
      _requests.where((r) => r.status == _RequestStatus.pending).toList();

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _approve(_BindingRequestMock request) async {
    if (request.coiFlag) {
      // Exception 1 / BR2: มี CoI ต้อง flag + second review เสมอ ห้าม
      // อนุมัติเองแบบ flow ปกติแม้ผู้ใช้จะพยายามกดก็ตาม
      _showSnack(
        'มีความเสี่ยงผลประโยชน์ทับซ้อน (CoI) — ต้องส่งให้ตรวจสอบซ้ำเท่านั้น ไม่สามารถอนุมัติเองได้',
        TeacherPalette.red,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการอนุมัติ', style: TextStyle(fontSize: 16)),
        content: Text(
          'ยืนยันว่า "${request.parentName}" เป็นผู้ปกครองจริงของ '
          '"${request.studentName}" และต้องการอนุมัติการผูกบัญชีนี้ใช่หรือไม่? '
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
    setState(() => request.status = _RequestStatus.approved);
    _showSnack(
      'อนุมัติการผูกบัญชีของ ${request.parentName} แล้ว',
      const Color(0xFF10B981),
    );
  }

  Future<void> _reject(_BindingRequestMock request) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: FilledButton.styleFrom(backgroundColor: TeacherPalette.red),
            child: const Text('ปฏิเสธคำขอ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      request.status = _RequestStatus.rejected;
      request.rejectReason = reasonCtrl.text.trim();
    });
    _showSnack('ปฏิเสธคำขอของ ${request.parentName} แล้ว', TeacherPalette.red);
  }

  void _escalate(_BindingRequestMock request) {
    setState(() => request.status = _RequestStatus.escalated);
    _showSnack(
      'ส่งคำขอของ ${request.parentName} ให้ School Admin ตรวจสอบซ้ำแล้ว (SLA 24 ชม.ทำการ)',
      const Color(0xFFD97706),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return TeacherMockPageShell(
      title: 'อนุมัติผูกบัญชีผู้ปกครอง',
      activeMenuLabel: 'อนุมัติผูกบัญชี',
      builder: (context, isDesktop) {
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
                'ต้องส่งให้ตรวจสอบซ้ำ ห้ามอนุมัติเอง',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TeacherSectionCard(
              title: 'คำขอรออนุมัติ (${pending.length} รายการ)',
              icon: Icons.family_restroom_rounded,
              child: pending.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'ไม่มีคำขอรออนุมัติแล้ว',
                          style: TextStyle(
                            color: TeacherPalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < pending.length; i++) ...[
                          if (i != 0) const Divider(height: 24),
                          _RequestRow(
                            request: pending[i],
                            onApprove: () => _approve(pending[i]),
                            onReject: () => _reject(pending[i]),
                            onEscalate: () => _escalate(pending[i]),
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
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onEscalate,
  });

  final _BindingRequestMock request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEscalate;

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
                    request.parentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  Text(
                    request.parentEmail,
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ขอผูกกับ ${request.studentName} · ${request.studentRoom}',
                    style: const TextStyle(
                      color: TeacherPalette.softText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    request.requestedAt,
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
        if (request.coiFlag) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 15,
                  color: Color(0xFFDC2626),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ผู้อนุมัติอาจมีผลประโยชน์ทับซ้อน (นามสกุลตรงกับผู้ยื่นคำขอ) — '
                    'ต้องส่งตรวจสอบซ้ำ ไม่สามารถอนุมัติเองได้',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            if (request.coiFlag)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEscalate,
                  icon: const Icon(Icons.forward_rounded, size: 16),
                  label: const Text('ส่งตรวจสอบซ้ำ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFD97706)),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
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
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                  ),
                  child: const Text('อนุมัติ'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
