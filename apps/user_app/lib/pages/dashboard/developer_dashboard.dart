import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';

class DeveloperDashboard extends StatelessWidget {
  const DeveloperDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'Developer';
    final schoolId = user?.schoolId.isNotEmpty == true ? user!.schoolId : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Developer Console'),
        backgroundColor: const Color(0xFF212121),
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.developer_mode,
            title: 'Developer Console',
            color: Colors.grey,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.receipt_long,
            title: 'System Logs',
            color: Colors.blueGrey,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.bug_report,
            title: 'Error Reports',
            color: Colors.red,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.people,
            title: 'จัดการผู้ใช้',
            color: Colors.grey,
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
              'Developer Mode',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.code,
              title: 'บทบาท',
              value: 'ผู้พัฒนาระบบ',
              color: Colors.blueGrey,
              subtitle: 'โรงเรียน: $schoolId',
            ),

            InfoCard(
              icon: Icons.people,
              title: 'จัดการผู้ใช้',
              value: 'กดเพื่อจัดการ',
              color: Colors.blueGrey,
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),

            const ComingSoonCard(
              icon: Icons.receipt_long,
              title: 'System Logs & Action Logs',
              phase: 'Phase 4',
              color: Colors.blueGrey,
            ),

            const ComingSoonCard(
              icon: Icons.cloud_sync,
              title: 'Firebase Connection Status',
              phase: 'Phase 3',
              color: Colors.orange,
            ),

            const ComingSoonCard(
              icon: Icons.bug_report,
              title: 'Error Reports',
              phase: 'Phase 4',
              color: Colors.red,
            ),

            const ComingSoonCard(
              icon: Icons.settings_ethernet,
              title: 'EdgeBox / IoT Device Status',
              phase: 'Phase 3',
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
