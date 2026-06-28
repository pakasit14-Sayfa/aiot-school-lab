import 'package:flutter/material.dart';
import 'data/user_data.dart';
import 'pages/user_list_page.dart';
import 'pages/profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'theme/app_theme.dart';

// import หน้า Login และ Home เข้ามาใช้
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';

// จุดเริ่มต้นของแอป
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดข้อมูลผู้ใช้ทั้งหมด
  await loadUsers();

  // โหลดผู้ใช้ที่เคย Login ค้างไว้
  await loadCurrentUser();

  runApp(const MyApp());
}

// คลาสหลักของแอป
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // เอาป้าย DEBUG ออก
      debugShowCheckedModeBanner: false,

      // ชื่อแอป
      title: 'Login App',

      theme: AppTheme.lightTheme,

      // หน้าแรกของแอป
      initialRoute: currentUser == null ? '/login' : '/home',

      // กำหนดเส้นทางของแต่ละหน้า
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/users': (context) => const UserListPage(),
        '/profile': (context) => const ProfilePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
