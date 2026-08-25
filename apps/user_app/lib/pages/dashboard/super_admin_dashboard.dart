import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';
import '../super_admin/super_admin_schools_page.dart';
import '../super_admin/super_admin_device_control_page.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'Super Admin';

    return Scaffold(
      appBar: AppBar(title: const Text('ผู้ดูแลระบบสูงสุด')),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.account_balance_rounded,
            title: 'จัดการโรงเรียน (Schools)',
            color: const Color(0xFF0F5B8F),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminSchoolsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.toggle_on_rounded,
            title: 'ควบคุมและอนุมัติอุปกรณ์ (Device Control)',
            color: const Color(0xFF1E88E5),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminDeviceControlPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.people_alt_rounded,
            title: 'จัดการผู้ใช้ (User Management)',
            color: Colors.blueGrey,
            onTap: (ctx) => Navigator.pushNamed(ctx, '/users'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Hello, $name',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Super Admin — ระบบบริหารจัดการระดับแพลตฟอร์ม (Platform Control Center)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.account_balance_rounded,
              title: 'จัดการโรงเรียน (Schools)',
              value: 'โควต้า, ไลเซนส์, สถานะเปิด/ระงับ',
              color: const Color(0xFF0F5B8F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminSchoolsPage()),
              ),
            ),

            InfoCard(
              icon: Icons.toggle_on_rounded,
              title: 'ควบคุม & อนุมัติอุปกรณ์ (Device Control)',
              value: 'สั่งการอุปกรณ์, คำขออนุมัติคำสั่ง',
              color: const Color(0xFF1E88E5),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminDeviceControlPage()),
              ),
            ),

            InfoCard(
              icon: Icons.people_alt_rounded,
              title: 'จัดการผู้ใช้ (User Management)',
              value: 'บัญชีผู้ใช้งานข้ามโรงเรียน',
              color: Colors.blueGrey,
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),
          ],
        ),
      ),
    );
  }
}
