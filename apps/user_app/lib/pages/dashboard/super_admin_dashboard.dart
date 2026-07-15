import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'Super Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ผู้ดูแลระบบสูงสุด'),
        backgroundColor: const Color(0xFF212121),
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.school,
            title: 'จัดการโรงเรียนทั้งระบบ',
            color: Colors.blueGrey,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.people,
            title: 'จัดการผู้ใช้ (ข้ามโรงเรียน)',
            color: Colors.blueGrey,
            onTap: (ctx) => Navigator.pushNamed(ctx, '/users'),
          ),
          DrawerItem(
            icon: Icons.receipt_long,
            title: 'Audit Log',
            color: Colors.blueGrey,
            onTap: (_) {},
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
              'Super Admin — platform-level เท่านั้น ไม่มีสิทธิ์ Classroom/AIoT/Emergency/Security',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.admin_panel_settings,
              title: 'บทบาท',
              value: 'ผู้ดูแลระบบสูงสุด',
              color: Colors.blueGrey,
            ),

            InfoCard(
              icon: Icons.people,
              title: 'จัดการผู้ใช้',
              value: 'กดเพื่อจัดการ',
              color: Colors.blueGrey,
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),

            const ComingSoonCard(
              icon: Icons.school,
              title: 'สร้าง/จัดการโรงเรียนทั้งระบบ',
              phase: 'Phase 3',
              color: Colors.indigo,
            ),

            const ComingSoonCard(
              icon: Icons.receipt_long,
              title: 'Audit Log ข้ามโรงเรียน',
              phase: 'Phase 3',
              color: Colors.blueGrey,
            ),

            const ComingSoonCard(
              icon: Icons.settings_ethernet,
              title: 'สถานะอุปกรณ์ (read-only ข้ามโรงเรียน)',
              phase: 'Phase 3',
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
