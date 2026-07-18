import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final name = currentUserModel?.name ?? 'ผู้ปกครอง';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามบุตรหลาน'),
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            color: Colors.teal,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.child_care,
            title: 'ข้อมูลบุตรหลาน',
            color: Colors.teal,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.message,
            title: 'สมุดสื่อสาร',
            color: Colors.teal,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.shield,
            title: 'จัดการสิทธิ์ PDPA',
            color: Colors.grey,
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
              'ติดตามบุตรหลานของคุณ',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.family_restroom,
              title: 'บทบาท',
              value: 'ผู้ปกครอง',
              color: Colors.teal,
              subtitle: 'ติดตามและรับแจ้งเตือนบุตรหลาน',
            ),

            const ComingSoonCard(
              icon: Icons.login,
              title: 'ประวัติเข้า-ออกโรงเรียนของบุตรหลาน',
              phase: 'Phase 8',
              color: Colors.teal,
            ),

            const ComingSoonCard(
              icon: Icons.notifications_active,
              title: 'รับแจ้งเตือนเมื่อบุตรหลานมาถึง/กลับบ้าน',
              phase: 'Phase 8',
              color: Colors.orange,
            ),

            const ComingSoonCard(
              icon: Icons.message,
              title: 'สมุดสื่อสารกับครู',
              phase: 'Phase 8',
              color: Colors.blue,
            ),

            const ComingSoonCard(
              icon: Icons.shield,
              title: 'จัดการสิทธิ์ PDPA',
              phase: 'Phase 8',
              color: Colors.grey,
            ),

            const ComingSoonCard(
              icon: Icons.school,
              title: 'ผลการเรียนและความประพฤติ',
              phase: 'Phase 7 (LMS)',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
