import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'Technician';
    final schoolId = user?.schoolId.isNotEmpty == true ? user!.schoolId : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('ช่างเทคนิค'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.settings_ethernet,
            title: 'สถานะอุปกรณ์',
            color: Colors.teal,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.build,
            title: 'บำรุงรักษาอุปกรณ์',
            color: Colors.teal,
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
              'ช่างเทคนิค — เน้นดูแลอุปกรณ์ AIoT เท่านั้น',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.build,
              title: 'บทบาท',
              value: 'ช่างเทคนิค',
              color: Colors.teal,
              subtitle: 'โรงเรียน: $schoolId',
            ),

            const ComingSoonCard(
              icon: Icons.settings_ethernet,
              title: 'สถานะอุปกรณ์ทั้งหมด (DEV-3..9)',
              phase: 'Phase 3',
              color: Colors.teal,
            ),

            const ComingSoonCard(
              icon: Icons.build,
              title: 'บันทึกบำรุงรักษา',
              phase: 'Phase 3',
              color: Colors.brown,
            ),
          ],
        ),
      ),
    );
  }
}
