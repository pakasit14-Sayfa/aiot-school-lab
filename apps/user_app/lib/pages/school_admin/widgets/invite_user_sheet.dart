import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_core/shared_core.dart';

/// สร้างคำเชิญบุคลากรผ่าน create_staff_invitation แล้วโชว์ token ครั้งเดียว —
/// ระบบไม่มีอีเมลเชิญ แอดมินต้องส่ง token ให้ผู้ถูกเชิญเอง (ผู้ถูกเชิญกรอกที่
/// หน้า "มีรหัสเชิญจากโรงเรียน — สร้างบัญชี") ใช้ร่วมกันโดยหน้า "สิทธิ์ผู้ใช้งาน"
/// และ "ครูและบุคลากร"
typedef InvitationCreator =
    Future<StaffInvitationTicket> Function({
      required String email,
      required UserRole role,
    });

/// บทบาทที่แอดมินโรงเรียนเชิญได้ (create_staff_invitation ปฏิเสธ super_admin)
const List<UserRole> invitableRoles = [
  UserRole.teacher,
  UserRole.executive,
  UserRole.schoolAdmin,
];

Future<void> showInviteUserSheet(
  BuildContext context, {
  required InvitationCreator create,
  UserRole initialRole = UserRole.teacher,
  VoidCallback? onInvited,
}) async {
  final emailCtrl = TextEditingController();
  var role = initialRole;
  var submitting = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        Future<void> submit() async {
          final email = emailCtrl.text.trim().toLowerCase();
          if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
            setSheet(() => error = 'กรอกอีเมลให้ถูกต้อง');
            return;
          }
          setSheet(() {
            submitting = true;
            error = null;
          });
          try {
            final ticket = await create(email: email, role: role);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            if (!context.mounted) return;
            onInvited?.call();
            await _showTicket(context, email, ticket);
          } catch (e) {
            debugPrint('InviteUserSheet: create_staff_invitation ล้ม — $e');
            if (!sheetContext.mounted) return;
            final raw = e.toString();
            setSheet(() {
              submitting = false;
              error = raw.contains('email_already_registered') ||
                      raw.contains('duplicate')
                  ? 'อีเมลนี้มีบัญชีหรือคำเชิญอยู่แล้ว'
                  : 'ส่งคำเชิญไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
            });
          }
        }

        return _OwnController(
          controller: emailCtrl,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เชิญผู้ใช้งานใหม่',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'ระบบจะออกรหัสเชิญให้ครั้งเดียว ส่งให้ผู้ถูกเชิญไปสร้างบัญชีเอง',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'อีเมลผู้ถูกเชิญ'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'บทบาท'),
                    items: [
                      for (final r in invitableRoles)
                        DropdownMenuItem(value: r, child: Text(r.label)),
                    ],
                    onChanged: submitting ? null : (v) => setSheet(() => role = v ?? role),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: submitting ? null : () => Navigator.of(sheetContext).pop(),
                        child: const Text('ยกเลิก'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: submitting ? null : submit,
                        child: Text(submitting ? 'กำลังส่ง…' : 'สร้างคำเชิญ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _showTicket(
  BuildContext context,
  String email,
  StaffInvitationTicket ticket,
) async {
  String fmt(DateTime? t) {
    if (t == null) return 'ไม่ระบุ';
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year + 543} ${two(l.hour)}:${two(l.minute)}';
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('สร้างคำเชิญแล้ว'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ส่งรหัสนี้ให้ $email — แสดงครั้งเดียว หมดอายุ ${fmt(ticket.expiresAt)}',
              style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 10),
          SelectableText(
            ticket.token,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: ticket.token)),
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('คัดลอก'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('เก็บไว้แล้ว ปิด'),
        ),
      ],
    ),
  );
}

class _OwnController extends StatefulWidget {
  const _OwnController({required this.controller, required this.child});

  final TextEditingController controller;
  final Widget child;

  @override
  State<_OwnController> createState() => _OwnControllerState();
}

class _OwnControllerState extends State<_OwnController> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
