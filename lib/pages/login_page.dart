import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;

  void login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = await AuthService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ยินดีต้อนรับ ${user.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Email หรือ Password ไม่ถูกต้อง';
      if (e.code == 'user-not-found') message = 'ไม่พบบัญชีผู้ใช้นี้';
      if (e.code == 'wrong-password') message = 'รหัสผ่านไม่ถูกต้อง';
      if (e.code == 'invalid-credential') message = 'Email หรือ Password ไม่ถูกต้อง';
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
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AIoT Smart School')),
      body: AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthHeader(
                icon: Icons.lock,
                title: 'เข้าสู่ระบบ',
                subtitle: 'กรอกข้อมูลเพื่อเข้าใช้งานแอป',
              ),

              const SizedBox(height: 28),

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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : login,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(isLoading ? 'กำลังเข้าสู่ระบบ...' : 'Login'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: const Text('ลืมรหัสผ่าน?'),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
