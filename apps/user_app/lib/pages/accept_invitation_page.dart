import 'package:flutter/material.dart';

import 'package:shared_core/shared_core.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

class AcceptInvitationPage extends StatefulWidget {
  const AcceptInvitationPage({super.key});

  @override
  State<AcceptInvitationPage> createState() => _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends State<AcceptInvitationPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isLoading = false;

  void accept() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await AuthService.acceptInvitation(
        invitationToken: tokenController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สร้างบัญชีสำเร็จ ยินดีต้อนรับ'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสเชิญไม่ถูกต้อง หมดอายุ หรือถูกใช้ไปแล้ว'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    tokenController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รับคำเชิญเข้าใช้งาน')),
      body: AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthHeader(
                icon: Icons.mail_outline,
                title: 'มีรหัสเชิญ?',
                subtitle: 'กรอกรหัสเชิญที่ได้รับจากแอดมินโรงเรียน '
                    'พร้อมตั้งชื่อและรหัสผ่านเพื่อสร้างบัญชี',
              ),

              const SizedBox(height: 28),

              CustomTextField(
                controller: tokenController,
                labelText: 'รหัสเชิญ (Invitation Token)',
                hintText: 'วางรหัสเชิญที่ได้รับ',
                prefixIcon: Icons.vpn_key,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกรหัสเชิญ'
                    : null,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: firstNameController,
                labelText: 'ชื่อ',
                hintText: 'กรอกชื่อของคุณ',
                prefixIcon: Icons.person,
                validator: AppValidators.name,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: lastNameController,
                labelText: 'นามสกุล',
                hintText: 'กรอกนามสกุลของคุณ',
                prefixIcon: Icons.person_outline,
                validator: AppValidators.name,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: passwordController,
                labelText: 'ตั้งรหัสผ่าน',
                hintText: 'กรอกรหัสผ่าน',
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
                validator: AppValidators.password,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: confirmPasswordController,
                labelText: 'ยืนยันรหัสผ่าน',
                hintText: 'กรอกรหัสผ่านอีกครั้ง',
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
                validator: (value) => AppValidators.confirmPassword(
                  value: value,
                  password: passwordController.text.trim(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : accept,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(isLoading ? 'กำลังสร้างบัญชี...' : 'สร้างบัญชี'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
