import 'package:flutter/material.dart';

import 'package:shared_core/shared_core.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

class ResetPasswordConfirmPage extends StatefulWidget {
  const ResetPasswordConfirmPage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordConfirmPage> createState() =>
      _ResetPasswordConfirmPageState();
}

class _ResetPasswordConfirmPageState extends State<ResetPasswordConfirmPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isLoading = false;

  void confirmReset() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await AuthService.confirmPasswordReset(
        email: widget.email,
        otpCode: otpController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เปลี่ยนรหัสผ่านสำเร็จ กรุณาเข้าสู่ระบบใหม่'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสยืนยันไม่ถูกต้องหรือหมดอายุ กรุณาลองใหม่'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันรหัสและตั้งรหัสผ่านใหม่')),
      body: AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthHeader(
                icon: Icons.mark_email_read,
                title: 'ยืนยันรหัสจากอีเมล',
                subtitle: 'กรอกรหัส 6 หลักที่ส่งไปยัง ${widget.email} '
                    'พร้อมตั้งรหัสผ่านใหม่ (รหัสหมดอายุใน 15 นาที)',
              ),

              const SizedBox(height: 28),

              CustomTextField(
                controller: otpController,
                labelText: 'รหัสยืนยัน (OTP)',
                hintText: 'กรอกรหัส 6 หลัก',
                prefixIcon: Icons.pin,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final code = value?.trim() ?? '';
                  if (code.isEmpty) return 'กรุณากรอกรหัสยืนยัน';
                  if (code.length != 6) return 'รหัสยืนยันต้องมี 6 หลัก';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: newPasswordController,
                labelText: 'รหัสผ่านใหม่',
                hintText: 'กรอกรหัสผ่านใหม่',
                prefixIcon: Icons.lock,
                obscureText: isPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => isPasswordHidden = !isPasswordHidden);
                  },
                ),
                validator: AppValidators.newPassword,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: confirmPasswordController,
                labelText: 'ยืนยันรหัสผ่านใหม่',
                hintText: 'กรอกรหัสผ่านใหม่อีกครั้ง',
                prefixIcon: Icons.lock_outline,
                obscureText: isConfirmPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => isConfirmPasswordHidden =
                        !isConfirmPasswordHidden);
                  },
                ),
                validator: (value) => AppValidators.confirmNewPassword(
                  value: value,
                  newPassword: newPasswordController.text.trim(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : confirmReset,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(isLoading ? 'กำลังบันทึก...' : 'ยืนยันและตั้งรหัสผ่านใหม่'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
