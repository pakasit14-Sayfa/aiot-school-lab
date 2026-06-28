import 'package:flutter/material.dart';
import '../data/user_data.dart';

// หน้า Home หลังจาก Login สำเร็จ
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ฟังก์ชันยืนยันก่อนออกจากระบบ
  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ออกจากระบบ'),
          content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await logoutUser();

                if (!context.mounted) return;

                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );
  }

  // การ์ดแสดงข้อมูลบน Dashboard
  Widget buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = currentUser?['name'] ?? 'ผู้ใช้';
    final email = currentUser?['email'] ?? '';
    final role = currentUser?['role'] ?? 'user';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FD),

      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // เมนูด้านข้าง
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(name),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('โปรไฟล์ของฉัน'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            if (role == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('จัดการผู้ใช้'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/users');
                },
              ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'ออกจากระบบ',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                confirmLogout(context);
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text(
                'สวัสดี, $name',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'ยินดีต้อนรับเข้าสู่ระบบ',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              buildDashboardCard(
                icon: Icons.person,
                title: 'ชื่อผู้ใช้',
                value: name,
                color: Colors.blue,
              ),

              buildDashboardCard(
                icon: Icons.email,
                title: 'อีเมล',
                value: email,
                color: Colors.orange,
              ),

              buildDashboardCard(
                icon: role == 'admin'
                    ? Icons.admin_panel_settings
                    : Icons.person_outline,
                title: 'สิทธิ์การใช้งาน',
                value: role,
                color: role == 'admin' ? Colors.purple : Colors.green,
              ),

              if (role == 'admin')
                buildDashboardCard(
                  icon: Icons.group,
                  title: 'จำนวนผู้ใช้ทั้งหมด',
                  value: '${users.length} คน',
                  color: Colors.teal,
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('โปรไฟล์ของฉัน'),
                ),
              ),

              const SizedBox(height: 12),

              if (role == 'admin')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/users');
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('จัดการผู้ใช้'),
                  ),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    confirmLogout(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
