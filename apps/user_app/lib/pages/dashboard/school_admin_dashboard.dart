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
import '../school_admin/school_students_page.dart';
import '../school_admin/school_teachers_page.dart';
import '../school_admin/school_permissions_page.dart';
import '../school_admin/school_import_page.dart';
import '../school_admin/school_alerts_page.dart';
import '../school_admin/school_resources_page.dart';
import '../school_admin/school_devices_page.dart';
import '../school_admin/school_buildings_page.dart';
import '../school_admin/school_reports_page.dart';
import '../school_admin/school_settings_page.dart';
import '../school_admin/school_scan_page.dart';
import '../school_admin/school_admin_dashboard_page.dart';
import '../school_admin/school_admin_profile_page.dart';

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
          DrawerItem(
            icon: Icons.school,
            title: 'ข้อมูลนักเรียน',
            color: Colors.blue,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolStudentsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.badge,
            title: 'ครูและบุคลากร',
            color: Colors.indigo,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolTeachersPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.security,
            title: 'กำหนดสิทธิ์บุคลากร',
            color: Colors.deepPurple,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolPermissionsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.upload_file,
            title: 'นำเข้าข้อมูล (Batch Import)',
            color: Colors.cyan,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolImportPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.notifications_active,
            title: 'การแจ้งเตือนเซนเซอร์ & ระบบ',
            color: Colors.redAccent,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolAlertsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.pie_chart,
            title: 'การใช้ทรัพยากร (น้ำ/ไฟ)',
            color: Colors.teal,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolResourcesPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.devices_other,
            title: 'คลังอุปกรณ์ IoT (Inventory)',
            color: Colors.blueGrey,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolDevicesPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.apartment,
            title: 'อาคารและห้องเรียน (Buildings)',
            color: Colors.deepOrange,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolBuildingsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.assessment,
            title: 'รายงานและสถิติ (Reports)',
            color: Colors.teal,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolReportsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.settings,
            title: 'ตั้งค่าโรงเรียน (Settings)',
            color: Colors.blueGrey,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolSettingsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.qr_code_scanner,
            title: 'สแกน QR Code (Scanner)',
            color: Colors.amber.shade800,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolScanPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.dashboard_customize,
            title: 'ศูนย์กลางแดชบอร์ดใหม่ (Admin Hub)',
            color: Colors.purple,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolAdminDashboardPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.account_circle,
            title: 'โปรไฟล์ผู้ดูแล (Admin Profile)',
            color: Colors.blue,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SchoolAdminProfilePage()),
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
              icon: Icons.school,
              title: 'ข้อมูลนักเรียน',
              value: 'ทะเบียนนักเรียน',
              color: Colors.blue,
              subtitle: 'ค้นหา กรองรายชั้น/ห้อง และจัดการสถานะ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchoolStudentsPage()),
              ),
            ),

            InfoCard(
              icon: Icons.badge,
              title: 'ครูและบุคลากร',
              value: 'บุคลากรโรงเรียน',
              color: Colors.indigo,
              subtitle: 'รายชื่อครู แผนก หน้าที่ และอาคารที่รับผิดชอบ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchoolTeachersPage()),
              ),
            ),

            InfoCard(
              icon: Icons.security,
              title: 'กำหนดสิทธิ์บุคลากร',
              value: 'Role Matrix',
              color: Colors.deepPurple,
              subtitle: 'จัดการบทบาท พื้นที่รับผิดชอบ และสิทธิ์รอง',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolPermissionsPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.upload_file,
              title: 'นำเข้าข้อมูล (Batch Import)',
              value: 'Excel / CSV / Sheets',
              color: Colors.cyan,
              subtitle: 'นำเข้าข้อมูลนักเรียน ครู และอุปกรณ์เป็นชุด',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchoolImportPage()),
              ),
            ),

            InfoCard(
              icon: Icons.notifications_active,
              title: 'การแจ้งเตือนเซนเซอร์ & ระบบ',
              value: 'ศูนย์แจ้งเตือน',
              color: Colors.redAccent,
              subtitle: 'ติดตามและกดรับทราบเหตุขัดข้องเซนเซอร์ IoT',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchoolAlertsPage()),
              ),
            ),

            InfoCard(
              icon: Icons.pie_chart,
              title: 'การใช้ทรัพยากร (น้ำ/ไฟ)',
              value: 'กราฟภาพรวม',
              color: Colors.teal,
              subtitle: 'สถิติการใช้ไฟและน้ำ รายวัน รายเดือน รายปี',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolResourcesPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.devices_other,
              title: 'คลังอุปกรณ์ IoT (Inventory)',
              value: 'รายการอุปกรณ์ทั้งหมด',
              color: Colors.blueGrey,
              subtitle: 'ทะเบียนฮาร์ดแวร์ ตรวจสถานะออนไลน์/ออฟไลน์',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchoolDevicesPage()),
              ),
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
              title: 'ควบคุมสวิตช์รีเลย์ (ไฟและน้ำ)',
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
              icon: Icons.inbox,
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

            InfoCard(
              icon: Icons.apartment,
              title: 'อาคารและห้องเรียน (Buildings & Rooms)',
              value: 'ผังอาคารและห้อง',
              color: Colors.deepOrange,
              subtitle: 'จัดการข้อมูลอาคาร ห้องเรียน ผู้รับผิดชอบ และความจุ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolBuildingsPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.assessment,
              title: 'รายงานและสถิติ (School Reports)',
              value: 'สรุปข้อมูลและส่งออก',
              color: Colors.teal,
              subtitle: 'สร้างรายงานสรุปไฟฟ้า น้ำ คุณภาพอากาศ และนักเรียน',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolReportsPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.settings,
              title: 'ตั้งค่าโรงเรียน (School Settings)',
              value: 'การตั้งค่าระบบ',
              color: Colors.blueGrey,
              subtitle: 'จัดการข้อมูลโรงเรียน ปีการศึกษา และความปลอดภัย',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolSettingsPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.qr_code_scanner,
              title: 'สแกน QR Code (Scanner)',
              value: 'สแกนด่วน',
              color: Colors.amber.shade800,
              subtitle: 'สแกน QR Code อุปกรณ์ หรือจับคู่เทอร์มินัล',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolScanPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.dashboard_customize,
              title: 'ศูนย์กลางแดชบอร์ดใหม่ (Admin Hub)',
              value: 'Modern Dashboard Hub',
              color: Colors.purple,
              subtitle: 'สลับไปยังมุมมองศูนย์รวมการบริหารโรงเรียนแบบใหม่',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminDashboardPage(),
                ),
              ),
            ),

            InfoCard(
              icon: Icons.account_circle,
              title: 'โปรไฟล์ผู้ดูแล (Admin Profile)',
              value: 'บัญชีและประวัติ',
              color: Colors.blue,
              subtitle: 'ดูข้อมูลผู้ใช้ เปลี่ยนรหัสผ่าน และดู Audit Logs',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchoolAdminProfilePage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

