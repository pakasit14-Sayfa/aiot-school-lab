import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';
import '../super_admin/super_admin_schools_page.dart';
import '../super_admin/super_admin_device_control_page.dart';
import '../super_admin/super_admin_permissions_page.dart';
import '../super_admin/super_admin_alerts_logs_page.dart';
import '../super_admin/super_admin_hub_page.dart';
import '../super_admin/super_admin_devices_page.dart';
import '../super_admin/super_admin_device_test_page.dart';
import '../super_admin/super_admin_settings_page.dart';

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
            icon: Icons.dashboard_rounded,
            title: 'ศูนย์ควบคุมภาพรวม (Hub)',
            color: const Color(0xFF0F5B8F),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminHubPage()),
            ),
          ),
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
            icon: Icons.qr_code_2_rounded,
            title: 'ทะเบียนและ QR Code (Devices & QR)',
            color: const Color(0xFF028090),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminDevicesPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.science_rounded,
            title: 'ทดสอบอุปกรณ์ (Device Diagnostics)',
            color: const Color(0xFF6A4C93),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminDeviceTestPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.admin_panel_settings_rounded,
            title: 'กำหนดสิทธิ์และบทบาท (Permissions)',
            color: const Color(0xFFB0232B),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminPermissionsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.notifications_active_rounded,
            title: 'การแจ้งเตือนและประวัติ (Alerts & Logs)',
            color: const Color(0xFFF18701),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminAlertsLogsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.settings_rounded,
            title: 'ตั้งค่าระบบส่วนกลาง (Settings)',
            color: const Color(0xFF4361EE),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminSettingsPage()),
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
              icon: Icons.dashboard_rounded,
              title: 'ศูนย์ควบคุมภาพรวม (Platform Hub)',
              value: 'ภาพรวมระบบ, สถิติ, ทางลัดควบคุม',
              color: const Color(0xFF0F5B8F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminHubPage()),
              ),
            ),

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
              icon: Icons.qr_code_2_rounded,
              title: 'ทะเบียนและ QR Code (Devices & QR)',
              value: 'จัดการรหัสกำกับ, พิมพ์ QR Code สติกเกอร์',
              color: const Color(0xFF028090),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminDevicesPage()),
              ),
            ),

            InfoCard(
              icon: Icons.science_rounded,
              title: 'ทดสอบอุปกรณ์ (Device Diagnostics)',
              value: 'ตรวจวินิจฉัยความพร้อม, วัด Latency',
              color: const Color(0xFF6A4C93),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminDeviceTestPage()),
              ),
            ),

            InfoCard(
              icon: Icons.admin_panel_settings_rounded,
              title: 'กำหนดสิทธิ์และบทบาท (Permissions)',
              value: 'จัดการสิทธิ์ RBAC, บทบาทรอง, คำเชิญ',
              color: const Color(0xFFB0232B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminPermissionsPage()),
              ),
            ),

            InfoCard(
              icon: Icons.notifications_active_rounded,
              title: 'การแจ้งเตือนและประวัติ (Alerts & Logs)',
              value: 'มอนิเตอร์เซนเซอร์, รับทราบเหตุ, Audit Logs',
              color: const Color(0xFFF18701),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminAlertsLogsPage()),
              ),
            ),

            InfoCard(
              icon: Icons.settings_rounded,
              title: 'ตั้งค่าระบบส่วนกลาง (Settings)',
              value: 'กำหนดเกณฑ์ Thresholds, นโยบายความปลอดภัย',
              color: const Color(0xFF4361EE),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminSettingsPage()),
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
