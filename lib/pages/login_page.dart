import 'package:flutter/material.dart';
import '../data/user_data.dart';

// หน้า Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// ส่วนควบคุมของหน้า Login
class _LoginPageState extends State<LoginPage> {
  // ตัวอ่านค่าจากช่อง Email
  final TextEditingController emailController = TextEditingController();

  // ตัวอ่านค่าจากช่อง Password
  final TextEditingController passwordController = TextEditingController();

  // ฟังก์ชันทำงานเมื่อกดปุ่ม Login
  void login() async {
    // ดึงค่าที่ผู้ใช้กรอกจากช่อง Email และ Password
    // trim() ใช้ตัดช่องว่างหน้า-หลังออก เช่น เผลอกดเว้นวรรค
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    debugPrint('กดปุ่ม Login แล้ว');
    debugPrint('Email ที่กรอก: $email');

    // ตรวจสอบว่ากรอกครบไหม
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอก Email และ Password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ค้นหาผู้ใช้จากข้อมูลที่สมัครไว้ใน user_data.dart
    final user = findUserByEmailAndPassword(email: email, password: password);

    // ถ้าเจอผู้ใช้ แปลว่า Login สำเร็จ
    if (user != null) {

      currentUser = user;

      await saveCurrentUser(user);

      debugPrint('เข้าสู่ระบบสำเร็จ');
      debugPrint('ชื่อผู้ใช้: ${user['name']}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ยินดีต้อนรับ ${user['name']}'),
          backgroundColor: Colors.green,
        ),
      );

      // ไปหน้า Home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      debugPrint('เข้าสู่ระบบไม่สำเร็จ');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email หรือ Password ไม่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // เคลียร์ controller เมื่อไม่ใช้หน้านี้แล้ว
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // วาดหน้าจอ Login
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FD),

      appBar: AppBar(
        title: const Text('Login App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.lock, size: 90, color: Colors.blue),

            const SizedBox(height: 20),

            const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // ช่องกรอก Email
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'กรอกอีเมลของคุณ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 16),

            // ช่องกรอก Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'กรอกรหัสผ่าน',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 24),

            // ปุ่ม Login
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'ทดลองใช้: admin@gmail.com / 123456',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 10),

            // ปุ่มไปหน้าสมัครสมาชิก
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
            ),
          ],
        ),
      ),
    );
  }
}
