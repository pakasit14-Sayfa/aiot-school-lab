import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';
import '../../widgets/sensor_card.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'ครู';
    final schoolId = user?.schoolId ?? '';
    final building = user?.building ?? '';
    final room = user?.room ?? '';
    final hasLocation =
        schoolId.isNotEmpty && building.isNotEmpty && room.isNotEmpty;
    final roomLabel = hasLocation ? room : 'ยังไม่กำหนดห้อง';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ห้องเรียนของฉัน'),
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            color: Colors.blue,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.qr_code,
            title: 'ออกรหัสผูกบัญชีผู้ปกครอง',
            color: Colors.teal,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const IssueBindingCodePage()),
            ),
          ),
          DrawerItem(
            icon: Icons.family_restroom,
            title: 'คำขอผูกบัญชีผู้ปกครอง',
            color: Colors.teal,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const ParentLinkReviewPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.lightbulb,
            title: 'ควบคุมไฟห้องเรียน',
            color: Colors.amber,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.people,
            title: 'เช็คชื่อนักเรียน',
            color: Colors.blue,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.notifications,
            title: 'แจ้งเตือน',
            color: Colors.orange,
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
            Text(
              hasLocation
                  ? 'ห้อง $roomLabel • อาคาร $building'
                  : 'ยังไม่กำหนดห้องเรียน',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            if (!hasLocation)
              const InfoCard(
                icon: Icons.info_outline,
                title: 'ยังไม่กำหนดห้องเรียน',
                value: 'กรุณาติดต่อแอดมิน',
                color: Colors.orange,
              )
            else
              StreamBuilder<SensorModel?>(
                stream: RealtimeService.sensorStream(
                  schoolId: schoolId,
                  building: building,
                  floor: '1',
                  room: room,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SensorLoadingCard();
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SensorNoDataCard();
                  }
                  final sensor = snapshot.data!;
                  return Column(
                    children: [
                      OverallAirQualityCard(sensor: sensor),
                      const SizedBox(height: 16),
                      SensorGrid(sensor: sensor),
                    ],
                  );
                },
              ),

            const SizedBox(height: 16),
            const ComingSoonCard(
              icon: Icons.lightbulb_outline,
              title: 'ควบคุมไฟ / แอร์ / น้ำ',
              phase: 'Phase 4',
              color: Colors.amber,
            ),
            const ComingSoonCard(
              icon: Icons.fact_check,
              title: 'เช็คชื่อนักเรียน',
              phase: 'Phase 7 (LMS)',
              color: Colors.blue,
            ),
            const ComingSoonCard(
              icon: Icons.notifications_active,
              title: 'แจ้งเตือนพฤติกรรมนักเรียน',
              phase: 'Phase 5',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
