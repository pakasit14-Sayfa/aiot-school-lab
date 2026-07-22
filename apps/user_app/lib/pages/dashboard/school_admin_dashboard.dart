import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';

class SchoolAdminDashboard extends StatelessWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final name = currentUserModel?.name ?? 'แอดมิน';

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการโรงเรียน')),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard โรงเรียน',
            color: Colors.purple,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.people,
            title: 'จัดการผู้ใช้',
            color: Colors.purple,
            onTap: (ctx) => Navigator.pushNamed(ctx, '/users'),
          ),
          DrawerItem(
            icon: Icons.policy,
            title: 'Consent Policy',
            color: Colors.teal,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const ConsentPolicyAdminPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.videocam,
            title: 'กล้อง CCTV',
            color: Colors.indigo,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.schedule,
            title: 'ตั้งเวลาอุปกรณ์',
            color: Colors.deepPurple,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.bar_chart,
            title: 'รายงาน ESG',
            color: Colors.green,
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
              'สวัสดี, $name',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text(
              'ภาพรวมระบบทั้งโรงเรียน',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.admin_panel_settings,
              title: 'สิทธิ์การใช้งาน',
              value: 'แอดมินโรงเรียน',
              color: Colors.purple,
              subtitle: 'เข้าถึงได้ทุกระบบ',
            ),

            InfoCard(
              icon: Icons.policy,
              title: 'Consent Policy',
              value: 'จัดการ Version',
              color: Colors.teal,
              subtitle: 'เผยแพร่และยุติ policy พร้อม Audit Log',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsentPolicyAdminPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.people,
              title: 'จัดการผู้ใช้',
              value: 'กดเพื่อจัดการ',
              color: Colors.purple,
              subtitle: 'เพิ่ม / ลบ / เปลี่ยนสิทธิ์',
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),

            const ComingSoonCard(
              icon: Icons.bolt,
              title: 'การใช้พลังงานทั้งโรงเรียน',
              phase: 'Phase 3',
              color: Colors.amber,
            ),

            const ComingSoonCard(
              icon: Icons.videocam,
              title: 'กล้อง CCTV + AI Detection',
              phase: 'Phase 5',
              color: Colors.indigo,
            ),

            const ComingSoonCard(
              icon: Icons.schedule,
              title: 'ตั้งเวลาเปิด-ปิดอุปกรณ์อัตโนมัติ',
              phase: 'Phase 4',
              color: Colors.deepPurple,
            ),

            const ComingSoonCard(
              icon: Icons.eco,
              title: 'รายงาน ESG & Green Score',
              phase: 'Phase 6',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
