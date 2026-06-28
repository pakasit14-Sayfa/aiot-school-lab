import 'package:flutter/material.dart';
import '../data/user_data.dart';

// หน้า Register / สมัครสมาชิก
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// ส่วนควบคุมของหน้า Register
class _RegisterPageState extends State<RegisterPage> {
  // ตัวอ่านค่าจากช่องชื่อ
  final TextEditingController nameController = TextEditingController();

  // ตัวอ่านค่าจากช่อง Email
  final TextEditingController emailController = TextEditingController();

  // ตัวอ่านค่าจากช่อง Password
  final TextEditingController passwordController = TextEditingController();

  // ตัวอ่านค่าจากช่อง Confirm Password
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // ฟังก์ชันทำงานเมื่อกดสมัครสมาชิก
  void register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    debugPrint('กดปุ่มสมัครสมาชิก');
    debugPrint('ชื่อ: $name');
    debugPrint('Email: $email');

    // ตรวจสอบว่ากรอกข้อมูลครบไหม
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ตรวจสอบว่ารหัสผ่านตรงกันไหม
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกัน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ตรวจสอบว่า Email นี้เคยสมัครแล้วหรือยัง
    if (emailExists(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email นี้ถูกใช้งานแล้ว'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // เพิ่มผู้ใช้ใหม่เข้าไปในระบบจำลอง
    await addUser(name: name, email: email, password: password);
    // แสดงข้อมูลผู้ใช้ทั้งหมดใน Terminal
    printAllUsers();
    debugPrint('สมัครสมาชิกสำเร็จ');
    debugPrint('จำนวนผู้ใช้ทั้งหมด: ${users.length}');
    // แจ้งเตือนว่าสมัครสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('สมัครสมาชิกสำเร็จ'),
        backgroundColor: Colors.green,
      ),
    );

    // กลับไปหน้า Login
    Navigator.pushReplacementNamed(context, '/login');
  }

  // เคลียร์ controller เมื่อไม่ใช้หน้านี้แล้ว
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // วาดหน้าจอ Register
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FD),

      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 40),

              const Icon(Icons.person_add, size: 90, color: Colors.blue),

              const SizedBox(height: 20),

              const Text(
                'สมัครสมาชิก',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              // ช่องกรอกชื่อ
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'กรอกชื่อของคุณ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

              // ช่องยืนยัน Password
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'ยืนยันรหัสผ่าน',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 24),

              // ปุ่มสมัครสมาชิก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 16),

              // ปุ่มกลับไปหน้า Login
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
