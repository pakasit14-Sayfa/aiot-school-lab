import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'role_router.dart';

/// หน้าบังคับเปลี่ยนรหัสผ่านสำหรับบัญชีที่ `users.must_change_password = true`
/// (บัญชีที่แอดมินนำเข้าด้วยรหัสชั่วคราว) — RoleRouter เปิดหน้านี้แทนหน้าแรก
/// จนกว่าจะเปลี่ยนสำเร็จ คอลัมน์นี้มีมาตั้งแต่สคีมาแรกแต่ไม่เคยมีใครอ่าน
/// ทำให้บัญชีที่นำเข้าใช้รหัสเดาได้ได้ตลอดไป
class ForcePasswordChangePage extends StatefulWidget {
  const ForcePasswordChangePage({super.key, this.changePassword});

  /// seam สำหรับเทสต์ — production ใช้ AuthService.changeMyPassword
  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })?
  changePassword;

  @override
  State<ForcePasswordChangePage> createState() =>
      _ForcePasswordChangePageState();
}

class _ForcePasswordChangePageState extends State<ForcePasswordChangePage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final next = _next.text;
    if (_current.text.isEmpty) {
      setState(() => _error = 'กรอกรหัสชั่วคราวที่ได้รับ');
      return;
    }
    if (next.length < 8) {
      setState(() => _error = 'รหัสใหม่ต้องยาวอย่างน้อย 8 ตัวอักษร');
      return;
    }
    if (next != _confirm.text) {
      setState(() => _error = 'รหัสใหม่ทั้งสองช่องไม่ตรงกัน');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final change = widget.changePassword ??
          ({required String currentPassword, required String newPassword}) =>
              AuthService.changeMyPassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
              );
      await change(currentPassword: _current.text, newPassword: next);
      if (!mounted) return;
      // currentUserModel ถูกอ่านกลับแล้ว (must_change_password = false) —
      // RoleRouter ตัวใหม่จะพาไปหน้าแรกของบทบาท
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (_) => false,
      );
    } catch (e) {
      debugPrint('ForcePasswordChangePage: change_my_password ล้ม — $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _messageForFailure(e);
      });
    }
  }

  static String _messageForFailure(Object e) {
    final raw = e.toString();
    if (raw.contains('wrong_current_password')) {
      return 'รหัสชั่วคราวไม่ถูกต้อง';
    }
    if (raw.contains('password_too_short')) {
      return 'รหัสใหม่ต้องยาวอย่างน้อย 8 ตัวอักษร';
    }
    if (raw.contains('password_unchanged')) {
      return 'รหัสใหม่ต้องต่างจากรหัสชั่วคราว';
    }
    return 'เปลี่ยนรหัสผ่านไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 36,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ตั้งรหัสผ่านใหม่ก่อนเริ่มใช้งาน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'บัญชี ${user?.email ?? ''} ถูกสร้างด้วยรหัสชั่วคราว '
                      'กรุณาตั้งรหัสผ่านของคุณเองก่อนเข้าใช้งาน',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _current,
                      obscureText: true,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'รหัสชั่วคราวที่ได้รับ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _next,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      onSubmitted: (_) => _submitting ? null : _submit(),
                      decoration: const InputDecoration(
                        labelText: 'ยืนยันรหัสผ่านใหม่',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting ? 'กำลังบันทึก…' : 'ตั้งรหัสผ่านและเข้าใช้งาน',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              await AuthService.signOut();
                              if (!context.mounted) return;
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (_) => false,
                              );
                            },
                      child: const Text('ออกจากระบบ'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
