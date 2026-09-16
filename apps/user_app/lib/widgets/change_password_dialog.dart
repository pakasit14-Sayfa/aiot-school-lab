import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// Signature of the write behind the dialog — injectable so widget tests can
/// drive success / wrong-current-password / failure without a Supabase client.
typedef PasswordChanger =
    Future<void> Function({
      required String currentPassword,
      required String newPassword,
    });

/// Change-my-password dialog backed by `change_my_password` (verifies the
/// current password, enforces ≥ 8 chars, revokes every other session).
///
/// Shared by the School Admin profile page and the Executive settings page
/// so the validation, error mapping and copy live in one place.
///
/// Returns `true` when the password was changed, `false` when the dialog was
/// dismissed. The caller shows its own confirmation in its own lane's style.
Future<bool> showChangePasswordDialog(
  BuildContext context, {
  PasswordChanger? change,
}) async {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  var submitting = false;
  String? error;
  final changed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialog) {
        Future<void> submit() async {
          if (next.text.length < 8) {
            setDialog(() => error = 'รหัสใหม่ต้องยาวอย่างน้อย 8 ตัวอักษร');
            return;
          }
          if (next.text != confirm.text) {
            setDialog(() => error = 'รหัสใหม่ทั้งสองช่องไม่ตรงกัน');
            return;
          }
          setDialog(() {
            submitting = true;
            error = null;
          });
          try {
            final fn =
                change ??
                ({
                  required String currentPassword,
                  required String newPassword,
                }) => AuthService.changeMyPassword(
                  currentPassword: currentPassword,
                  newPassword: newPassword,
                );
            await fn(currentPassword: current.text, newPassword: next.text);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
          } catch (e) {
            debugPrint('showChangePasswordDialog: change_my_password ล้ม — $e');
            if (!dialogContext.mounted) return;
            final raw = e.toString();
            setDialog(() {
              submitting = false;
              error = raw.contains('wrong_current_password')
                  ? 'รหัสผ่านปัจจุบันไม่ถูกต้อง'
                  : raw.contains('password_unchanged')
                  ? 'รหัสใหม่ต้องต่างจากรหัสเดิม'
                  : 'เปลี่ยนรหัสผ่านไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
            });
          }
        }

        return _OwnControllers(
          controllers: [current, next, confirm],
          child: AlertDialog(
            title: const Text('เปลี่ยนรหัสผ่าน'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: current,
                    obscureText: true,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสผ่านปัจจุบัน',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'ยืนยันรหัสผ่านใหม่',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: Text(submitting ? 'กำลังบันทึก…' : 'เปลี่ยนรหัสผ่าน'),
              ),
            ],
          ),
        );
      },
    ),
  );
  return changed ?? false;
}

/// Disposes the dialog's controllers with the dialog's own element instead of
/// right after `showDialog` returns — the latter tears them down while the
/// close animation is still painting the fields.
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
