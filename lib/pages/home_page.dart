import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ออกจากระบบ'),
          content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthService.signOut();
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
    final user = currentUserModel;
    final name = user?.name ?? 'ผู้ใช้';
    final email = user?.email ?? '';
    final role = user?.role ?? UserRole.student;
    final isAdmin = role == UserRole.schoolAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FD),

      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

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
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('โปรไฟล์ของฉัน'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            if (isAdmin)
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

              Text(
                role.label,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                icon: isAdmin
                    ? Icons.admin_panel_settings
                    : Icons.person_outline,
                title: 'สิทธิ์การใช้งาน',
                value: role.label,
                color: isAdmin ? Colors.purple : Colors.green,
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  icon: const Icon(Icons.person),
                  label: const Text('โปรไฟล์ของฉัน'),
                ),
              ),

              if (isAdmin) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/users'),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('จัดการผู้ใช้'),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => confirmLogout(context),
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
