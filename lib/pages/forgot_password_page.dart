import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  void resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await AuthService.resetPassword(emailController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลแล้ว กรุณาตรวจสอบอีเมล'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'เกิดข้อผิดพลาด';
      if (e.code == 'user-not-found') message = 'ไม่พบ Email นี้ในระบบ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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
                subtitle: 'กรอกอีเมลที่สมัครไว้ เราจะส่งลิงก์รีเซ็ตให้',
              ),

              const SizedBox(height: 28),

              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                hintText: 'กรอกอีเมลที่สมัครไว้',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : resetPassword,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(isLoading ? 'กำลังส่ง...' : 'ส่งลิงก์รีเซ็ต'),
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
