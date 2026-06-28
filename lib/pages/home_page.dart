import 'package:flutter/material.dart';
import '../data/user_data.dart';

// หน้า Home หลังจาก Login สำเร็จ
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // แถบด้านบนของหน้า Home
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // เนื้อหาหลักของหน้า Home
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ไอคอนเครื่องหมายถูก
            const Icon(Icons.check_circle, size: 100, color: Colors.green),

            const SizedBox(height: 20),

            // แสดงชื่อผู้ใช้ที่ Login เข้ามา
            Text(
              'ยินดีต้อนรับ ${currentUser?['name'] ?? 'ผู้ใช้'}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: const Text('โปรไฟล์ของฉัน'),
            ),

            const SizedBox(height: 12),

            if (currentUser?['role'] == 'admin')
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/users');
                },
                child: const Text('ดูรายชื่อผู้ใช้ทั้งหมด'),
              ),

            // ปุ่ม Logout
            ElevatedButton(
              onPressed: () async {
                debugPrint('ผู้ใช้กด Logout');

                // ล้างข้อมูลผู้ใช้ที่ Login ค้างไว้ในเครื่อง
                await logoutUser();

                // กลับไปหน้า Login
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
