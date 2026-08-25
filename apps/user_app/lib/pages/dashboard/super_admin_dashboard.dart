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
      appBar: AppBar(title: const Text('ผู้ดูแลระบบสูงสุด')),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.people,
            title: 'จัดการผู้ใช้ (ข้ามโรงเรียน)',
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

            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.open_in_new, color: Colors.indigo.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'จัดการโรงเรียน, Audit Log และสถานะอุปกรณ์ข้ามโรงเรียน',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'งานเหล่านี้ทำผ่านแอปแอดมินแยกต่างหาก (aiot_dev_dashboard) '
                            'ซึ่งเป็นแอปสำหรับผู้ดูแลระบบระดับแพลตฟอร์มโดยเฉพาะ ไม่ได้อยู่ในแอปนี้',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
