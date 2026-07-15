import 'package:flutter/material.dart';

import 'package:shared_core/shared_core.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isLoading = false;

  void register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await AuthService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthHeader(
                icon: Icons.person_add,
                title: 'สมัครสมาชิก',
                subtitle: 'สร้างบัญชีใหม่เพื่อเข้าใช้งานแอป',
              ),

              const SizedBox(height: 28),

              CustomTextField(
                controller: nameController,
                labelText: 'Name',
                hintText: 'กรอกชื่อของคุณ',
                prefixIcon: Icons.person,
                validator: AppValidators.name,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                hintText: 'กรอกอีเมลของคุณ',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: passwordController,
                labelText: 'Password',
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
                labelText: 'Confirm Password',
                hintText: 'ยืนยันรหัสผ่าน',
                prefixIcon: Icons.lock_outline,
                obscureText: isConfirmPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() =>
                        isConfirmPasswordHidden = !isConfirmPasswordHidden);
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
                  onPressed: isLoading ? null : register,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(isLoading ? 'กำลังสมัคร...' : 'Register'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('มีบัญชีอยู่แล้ว? กลับไป Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
