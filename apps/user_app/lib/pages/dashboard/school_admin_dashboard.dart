import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';
import '../school_admin/school_admin_energy_page.dart';
import '../school_admin/school_admin_cctv_page.dart';
import '../school_admin/school_admin_device_schedule_page.dart';
import '../school_admin/school_admin_esg_page.dart';
import '../school_admin/school_admin_device_control_page.dart';
import '../school_admin/school_admin_incident_inbox_page.dart';

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
            icon: Icons.bolt,
            title: 'พลังงานทั้งโรงเรียน',
            color: Colors.amber,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolAdminEnergyPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.videocam,
            title: 'กล้อง CCTV',
            color: Colors.indigo,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolAdminCctvPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.schedule,
            title: 'ตั้งเวลาอุปกรณ์',
            color: Colors.deepPurple,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const SchoolAdminDeviceSchedulePage(),
              ),
            ),
          ),
          DrawerItem(
            icon: Icons.bar_chart,
            title: 'รายงาน ESG',
            color: Colors.green,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolAdminEsgPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.lightbulb,
            title: 'ควบคุมไฟและน้ำ',
            color: Colors.orange,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const SchoolAdminDeviceControlPage(),
              ),
            ),
          ),
          DrawerItem(
            icon: Icons.inbox,
            title: 'กล่องแจ้งเหตุการณ์',
            color: Colors.red,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const SchoolAdminIncidentInboxPage(),
              ),
            ),
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
              icon: Icons.people,
              title: 'จัดการผู้ใช้',
              value: 'กดเพื่อจัดการ',
              color: Colors.purple,
              subtitle: 'เพิ่ม / ลบ / เปลี่ยนสิทธิ์',
              onTap: () => Navigator.pushNamed(context, '/users'),
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
              icon: Icons.bolt,
              title: 'การใช้พลังงานทั้งโรงเรียน',
              value: 'มิเตอร์ IoT ไฟฟ้า & น้ำ',
              color: Colors.amber.shade800,
              subtitle: 'สรุปการใช้งานและคะแนนประสิทธิภาพ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminEnergyPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.videocam,
              title: 'กล้อง CCTV & สิทธิ์การเข้าถึง',
              value: 'PDPA Access Grants',
              color: Colors.indigo,
              subtitle: 'จัดการสิทธิ์เข้าถึงกล้องและ Audit Log',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminCctvPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.schedule,
              title: 'ตั้งเวลาเปิด-ปิดอุปกรณ์อัตโนมัติ',
              value: 'bg pg_cron',
              color: Colors.deepPurple,
              subtitle: 'สร้างและจัดการตารางเวลาเปิด-ปิดอัตโนมัติ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminDeviceSchedulePage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.eco,
              title: 'รายงาน ESG & Green Score',
              value: 'ความยั่งยืนโรงเรียน',
              color: Colors.green,
              subtitle: 'คะแนน Green Score จากการใช้พลังงานจริง',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminEsgPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.lightbulb,
              title: 'ควบคุมอุปกรณ์ (ไฟและน้ำ)',
              value: 'สวิตช์รีเลย์ทั้งโรงเรียน',
              color: Colors.orange,
              subtitle: 'เปิด-ปิดไฟแสงสว่างและปั๊มน้ำทุกอาคาร',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminDeviceControlPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.notifications_active,
              title: 'กล่องข้อความแจ้งเหตุ (Incident Inbox)',
              value: 'ติดตามเหตุการณ์',
              color: Colors.redAccent,
              subtitle: 'รับเรื่องและจัดการข้อขัดข้องทั่วทั้งโรงเรียน',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminIncidentInboxPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
