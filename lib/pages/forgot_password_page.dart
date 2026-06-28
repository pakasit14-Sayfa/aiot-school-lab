import 'package:flutter/material.dart';
import '../data/user_data.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

// หน้าลืมรหัสผ่าน / รีเซ็ตรหัสผ่าน
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isNewPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  // ฟังก์ชันรีเซ็ตรหัสผ่าน
  void resetPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final newPassword = newPasswordController.text.trim();

    if (!emailExists(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบ Email นี้ในระบบ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = users.firstWhere((user) => user['email'] == email);
    final name = user['name'] ?? '';

    await updateUserByEmail(
      email: email,
      newName: name,
      newPassword: newPassword,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เปลี่ยนรหัสผ่านสำเร็จ'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthHeader(
                icon: Icons.lock_reset,
                title: 'รีเซ็ตรหัสผ่าน',
                subtitle: 'กรอกอีเมลที่สมัครไว้ และตั้งรหัสผ่านใหม่',
              ),

              const SizedBox(height: 28),

              // ช่อง Email
              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                hintText: 'กรอกอีเมลที่สมัครไว้',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
              ),

              const SizedBox(height: 16),

              // ช่อง New Password
              CustomTextField(
                controller: newPasswordController,
                labelText: 'New Password',
                hintText: 'กรอกรหัสผ่านใหม่',
                prefixIcon: Icons.lock,
                obscureText: isNewPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    isNewPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isNewPasswordHidden = !isNewPasswordHidden;
                    });
                  },
                ),
                validator: AppValidators.newPassword,
              ),

              const SizedBox(height: 16),

              // ช่อง Confirm New Password
              CustomTextField(
                controller: confirmPasswordController,
                labelText: 'Confirm New Password',
                hintText: 'ยืนยันรหัสผ่านใหม่',
                prefixIcon: Icons.lock_outline,
                obscureText: isConfirmPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isConfirmPasswordHidden = !isConfirmPasswordHidden;
                    });
                  },
                ),
                validator: (value) {
                  return AppValidators.confirmNewPassword(
                    value: value,
                    newPassword: newPasswordController.text.trim(),
                  );
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: resetPassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset Password'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('กลับไปหน้า Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
