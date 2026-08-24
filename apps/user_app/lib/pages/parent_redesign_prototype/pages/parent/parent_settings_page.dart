import 'package:flutter/material.dart';
import '../../widgets/parent_common_widgets.dart';

class ParentSettingsPage extends StatefulWidget {
  const ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  bool schoolAlerts = true;
  bool homeworkAlerts = true;
  bool safetyAlerts = true;
  bool paymentAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ParentPageHeader(
                    title: 'ตั้งค่าผู้ปกครอง',
                    subtitle: 'จัดการข้อมูลบัญชีและการแจ้งเตือน',
                    icon: Icons.settings_rounded,
                  ),
                  const SizedBox(height: 20),
                  ParentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ข้อมูลบุตรหลาน',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEAF3FF),
                            child: Icon(Icons.face_rounded, color: Color(0xFF2867B2)),
                          ),
                          title: const Text(
                            'น้องมะลิ',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          subtitle: const Text('ม.2/1 · เลขที่ 18'),
                          trailing: TextButton(
                            onPressed: () {},
                            child: const Text('ดูข้อมูล'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ParentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'การแจ้งเตือน',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ประกาศจากโรงเรียน', style: TextStyle(fontSize: 11)),
                          value: schoolAlerts,
                          onChanged: (v) => setState(() => schoolAlerts = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('การบ้านและกำหนดส่ง', style: TextStyle(fontSize: 11)),
                          value: homeworkAlerts,
                          onChanged: (v) => setState(() => homeworkAlerts = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('เหตุความปลอดภัย', style: TextStyle(fontSize: 11)),
                          value: safetyAlerts,
                          onChanged: (v) => setState(() => safetyAlerts = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ค่าใช้จ่ายและกำหนดชำระ', style: TextStyle(fontSize: 11)),
                          value: paymentAlerts,
                          onChanged: (v) => setState(() => paymentAlerts = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ParentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'บัญชี',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.lock_reset_rounded),
                          label: const Text('เปลี่ยนรหัสผ่าน'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('ออกจากระบบ'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
