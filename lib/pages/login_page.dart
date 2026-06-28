import 'package:flutter/material.dart';
import '../data/user_data.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

// หน้า Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// ส่วนควบคุมของหน้า Login
class _LoginPageState extends State<LoginPage> {
  // Key สำหรับควบคุม Form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;

  // ฟังก์ชัน Login
  void login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final user = findUserByEmailAndPassword(email: email, password: password);

    if (user != null) {
      currentUser = user;

      await saveCurrentUser(user);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ยินดีต้อนรับ ${user['name']}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email หรือ Password ไม่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
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
      appBar: AppBar(title: const Text('Login App')),
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

              // ช่อง Email
              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                hintText: 'กรอกอีเมลของคุณ',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
              ),

              const SizedBox(height: 16),

              // ช่อง Password
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
                    setState(() {
                      isPasswordHidden = !isPasswordHidden;
                    });
                  },
                ),
                validator: AppValidators.password,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: login,
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'ทดลองใช้: admin@gmail.com / 123456',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

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
