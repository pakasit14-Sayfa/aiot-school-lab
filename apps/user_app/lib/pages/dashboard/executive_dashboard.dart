import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';

class ExecutiveDashboard extends StatelessWidget {
  const ExecutiveDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final name = currentUserModel?.name ?? 'ผู้บริหาร';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Executive Dashboard'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.dashboard,
            title: 'Executive Dashboard',
            color: Colors.indigo,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.bar_chart,
            title: 'รายงานสรุป ESG',
            color: Colors.green,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.account_balance_wallet,
            title: 'วางแผนงบประมาณ',
            color: Colors.indigo,
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
              'สรุปภาพรวมระดับองค์กร',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.business_center,
              title: 'บทบาท',
              value: 'ผู้บริหาร',
              color: Colors.indigo,
              subtitle: 'ดูภาพรวมและวางแผนงบประมาณ',
            ),

            const ComingSoonCard(
              icon: Icons.bolt,
              title: 'ค่าไฟฟ้ารวมทั้งโรงเรียน (รายเดือน)',
              phase: 'Phase 3',
              color: Colors.amber,
            ),

            const ComingSoonCard(
              icon: Icons.water_drop,
              title: 'ค่าน้ำรวมทั้งโรงเรียน (รายเดือน)',
              phase: 'Phase 3',
              color: Colors.blue,
            ),

            const ComingSoonCard(
              icon: Icons.eco,
              title: 'Green Score & Carbon Reduction',
              phase: 'Phase 6',
              color: Colors.green,
            ),

            const ComingSoonCard(
              icon: Icons.trending_down,
              title: 'คาดการณ์ค่าใช้จ่าย AI Analytics',
              phase: 'Phase 6',
              color: Colors.indigo,
            ),

            const ComingSoonCard(
              icon: Icons.description,
              title: 'รายงาน ESG สำหรับวางแผนงบ',
              phase: 'Phase 6',
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
